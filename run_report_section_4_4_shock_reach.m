clear; clc; close all;

%% ============================================================
% Final-report runner for Project B: Section 4.4 Shock reach
%
% Purpose:
%   Test whether broader direct quality-shock reach across ordinary
%   consumers produces more severe decline in brand trust, while the
%   baseline system and direct shock magnitude are held fixed.
%
% Main outputs:
%   Figures:
%     - Figure_4_4_ShockReach_BT_Only.png
%     - Appendix_A2_ShockReach_BTQ_VaryingExposure.png
%
%   Tables:
%     - Table_4_4_ShockReach_BT_Summary.csv
%     - Appendix_Table_A2_ShockReach_FullSummary.csv
%
%   Workspace:
%     - Results_ShockReach_VaryingExposure.mat
%
% Notes:
%   - Main-text figure: BT only
%   - Appendix figure: BT + Q supporting comparison
%   - Main-text table: compact BT summary
% ============================================================

cfg = get_cfg_projectB('main');

deltaQ         = cfg.S1.deltaQ_main;
coverageLevels = cfg.S1.ordinary_exposure_levels(:);

outdir = fullfile(pwd, 'report_outputs_4_4_shock_reach');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

fprintf('\n============================================================\n');
fprintf('Project B final-report runner: Section 4.4 Shock reach\n');
fprintf('============================================================\n');
fprintf('Direct shock size (DeltaQ): %.2f\n', deltaQ);
fprintf('Ordinary-consumer exposure levels: ');
disp(coverageLevels.')
fprintf('eWOM fully exposed      : %d\n', cfg.S1.keep_ewom_fully_exposed);
fprintf('Exposure sampling seed  : %d\n', cfg.S1.exposure_seed);

%% ------------------------------------------------------------
% Build one common baseline system
% ------------------------------------------------------------
[A, deg, roles, idx, netinfo] = generate_network_projectB(cfg); %#ok<ASGLU>
[W, lambda, self_w, Winfo]    = build_W_lambda_projectB(A, deg, roles, cfg); %#ok<ASGLU>
[X0, X0info]                  = generate_X0_projectB(roles, cfg); %#ok<ASGLU>
[C, Cinfo]                    = build_C_projectB(cfg); %#ok<ASGLU>

[Xhist_S0, dyn_S0] = run_dynamics_projectB(X0, W, lambda, C, roles, cfg); %#ok<ASGLU>

%% ------------------------------------------------------------
% Fix one random ordering of ordinary consumers
% so 25% is nested inside 50%, and 50% inside 100%
% ------------------------------------------------------------
rng(cfg.S1.exposure_seed, 'twister');
ord_perm = idx.ordinary(randperm(numel(idx.ordinary)));

%% ------------------------------------------------------------
% Run varying-exposure cases
% ------------------------------------------------------------
nCase = numel(coverageLevels);

bt = cfg.topic.idx.BT;
q  = cfg.topic.idx.Q;
om = cfg.topic.idx.OM;

FinalBT   = zeros(nCase,1);
FinalQ    = zeros(nCase,1);
FinalOM   = zeros(nCase,1);
BTDecline = zeros(nCase,1);
QChange   = zeros(nCase,1);
NumOrdExp = zeros(nCase,1);

trajBT = cell(nCase,1);
trajQ  = cell(nCase,1);

results_exposure = struct();
results_exposure.cfg      = cfg;
results_exposure.S0.dyn   = dyn_S0;
results_exposure.S0.Xhist = Xhist_S0;

for i = 1:nCase
    covRate = coverageLevels(i);

    nOrdExp = round(covRate * numel(idx.ordinary));
    nOrdExp = max(0, min(numel(idx.ordinary), nOrdExp));
    idxOrdExposed = ord_perm(1:nOrdExp);

    [X1, shockInfo]  = apply_S1_quality_shock_projectB_partial(X0, roles, cfg, deltaQ, idxOrdExposed);
    [Xhist_S1, dyn_S1] = run_dynamics_projectB(X1, W, lambda, C, roles, cfg);

    FinalBT(i) = dyn_S1.final_all(bt);
    FinalQ(i)  = dyn_S1.final_all(q);
    FinalOM(i) = dyn_S1.final_all(om);

    % Report-facing decline magnitude: positive means larger decline
    BTDecline(i) = dyn_S0.final_all(bt) - dyn_S1.final_all(bt);

    % Neutral supporting quantity for appendix table
    QChange(i) = dyn_S1.final_all(q) - dyn_S1.initial_all(q);

    NumOrdExp(i) = nOrdExp;

    trajBT{i} = dyn_S1.mean_all(:, bt);
    trajQ{i}  = dyn_S1.mean_all(:, q);

    tag = sprintf('cov_%02d', round(100 * covRate));
    results_exposure.(tag).coverage      = covRate;
    results_exposure.(tag).numOrdExposed = nOrdExp;
    results_exposure.(tag).shockInfo     = shockInfo;
    results_exposure.(tag).X1            = X1;
    results_exposure.(tag).Xhist         = Xhist_S1;
    results_exposure.(tag).dyn           = dyn_S1;
end

%% ------------------------------------------------------------
% Build report-facing tables
% Main-text table is sorted in ascending exposure order: 25, 50, 100
% ------------------------------------------------------------
[coverageAsc, orderAsc] = sort(coverageLevels, 'ascend');

NumOrdExp_asc = NumOrdExp(orderAsc);
FinalBT_asc   = FinalBT(orderAsc);
FinalQ_asc    = FinalQ(orderAsc);
FinalOM_asc   = FinalOM(orderAsc);
BTDecline_asc = BTDecline(orderAsc);
QChange_asc   = QChange(orderAsc);

T_BT_exposure = table( ...
    coverageAsc, ...
    NumOrdExp_asc, ...
    FinalBT_asc, ...
    BTDecline_asc, ...
    'VariableNames', { ...
        'ExposureRate', ...
        'ExposedOrdinaryConsumers', ...
        'FinalBT', ...
        'BT_Decline_vs_S0'} ...
);

T_exposure_full = table( ...
    coverageAsc, ...
    NumOrdExp_asc, ...
    FinalBT_asc, ...
    FinalQ_asc, ...
    FinalOM_asc, ...
    BTDecline_asc, ...
    QChange_asc, ...
    'VariableNames', { ...
        'ExposureRate', ...
        'ExposedOrdinaryConsumers', ...
        'FinalBT', ...
        'FinalQ', ...
        'FinalOM', ...
        'BT_Decline_vs_S0', ...
        'Q_Change_from_ShockedInitial'} ...
);

disp(' ');
disp('============================================================');
disp('Table 4.4 summary: BT outcomes under varying ordinary-consumer exposure');
disp('============================================================');
disp(T_BT_exposure);

disp(' ');
disp('============================================================');
disp('Appendix Table A2 summary: full varying-exposure outcomes');
disp('============================================================');
disp(T_exposure_full);

%% ------------------------------------------------------------
% Quick interpretation
% ------------------------------------------------------------
fprintf('\n============================================================\n');
fprintf('Quick interpretation\n');
fprintf('============================================================\n');
fprintf('S0 final BT = %.4f\n', dyn_S0.final_all(bt));

for i = 1:numel(coverageAsc)
    fprintf(['Ordinary exposure = %.0f%% | Num exposed = %d | Final BT = %.4f ', ...
             '| BT decline = %.4f | Final Q = %.4f\n'], ...
        100*coverageAsc(i), NumOrdExp_asc(i), FinalBT_asc(i), BTDecline_asc(i), FinalQ_asc(i));
end

fprintf('\nMain reading:\n');
fprintf('Broader direct exposure produces more severe BT decline.\n');

%% ------------------------------------------------------------
% Save tables
% ------------------------------------------------------------
writetable(T_BT_exposure,   fullfile(outdir, 'Table_4_4_ShockReach_BT_Summary.csv'));
writetable(T_exposure_full, fullfile(outdir, 'Appendix_Table_A2_ShockReach_FullSummary.csv'));

%% ------------------------------------------------------------
% Plot settings
% Keep plot order as 100% -> 50% -> 25% for visual reading
% ------------------------------------------------------------
tt = 0:cfg.sim.Tmax;

colS0   = [0.10 0.10 0.10];
col100  = [0.8500 0.3250 0.0980];
col50   = [0.9290 0.6940 0.1250];
col25   = [0.4940 0.1840 0.5560];
zeroCol = [0.75 0.75 0.75];

plotOrder  = [find(abs(coverageLevels-1.00)<1e-12), ...
              find(abs(coverageLevels-0.50)<1e-12), ...
              find(abs(coverageLevels-0.25)<1e-12)];

plotColors = {col100, col50, col25};
plotLabels = {'100% ordinary exposure', '50% ordinary exposure', '25% ordinary exposure'};

%% ------------------------------------------------------------
% Figure 4.4 (main text): BT only
% ------------------------------------------------------------
f_main = figure('Name', 'Figure_4_4_ShockReach_BT_Only', ...
                'Color', 'w', ...
                'Position', [100 100 1080 500]);

ax_main = axes(f_main);
hold(ax_main, 'on');

hS0_bt = plot(ax_main, tt, dyn_S0.mean_all(:, bt), '--', ...
    'Color', colS0, ...
    'LineWidth', 2.4, ...
    'DisplayName', 'S0 reference');

hCases_bt = gobjects(numel(plotOrder),1);
for j = 1:numel(plotOrder)
    i = plotOrder(j);
    hCases_bt(j) = plot(ax_main, tt, trajBT{i}, '-', ...
        'Color', plotColors{j}, ...
        'LineWidth', 2.8, ...
        'DisplayName', plotLabels{j});
end

yline(ax_main, 0, '--', 'Color', zeroCol, 'HandleVisibility', 'off');

plot(ax_main, tt(end), dyn_S0.mean_all(end, bt), 'o', ...
    'Color', colS0, 'MarkerFaceColor', colS0, 'HandleVisibility', 'off');

for j = 1:numel(plotOrder)
    i = plotOrder(j);
    plot(ax_main, tt(end), trajBT{i}(end), 'o', ...
        'Color', plotColors{j}, ...
        'MarkerFaceColor', plotColors{j}, ...
        'HandleVisibility', 'off');
end

grid(ax_main, 'on');
box(ax_main, 'on');
title(ax_main, sprintf('Shock reach: BT trajectories under varying ordinary-consumer exposure (\\DeltaQ = %.2f)', deltaQ), ...
    'FontSize', 15, 'FontWeight', 'bold');
xlabel(ax_main, 'Time step', 'FontSize', 12);
ylabel(ax_main, 'Mean opinion', 'FontSize', 12);
legend(ax_main, [hS0_bt; hCases_bt], 'Location', 'eastoutside', 'FontSize', 10, 'Box', 'on');

ylim(ax_main, [0.20 0.52]);
xlim(ax_main, [tt(1), tt(end)]);
set(ax_main, 'FontSize', 11);
ax_main.Toolbar.Visible = 'off';
hold(ax_main, 'off');

exportgraphics(f_main, fullfile(outdir, 'Figure_4_4_ShockReach_BT_Only.png'), 'Resolution', 300);

%% ------------------------------------------------------------
% Appendix Figure A2: BT + Q supporting figure
% ------------------------------------------------------------
f_app = figure('Name', 'Appendix_A2_ShockReach_BTQ_VaryingExposure', ...
               'Color', 'w', ...
               'Position', [100 100 1120 760]);

tl = tiledlayout(2,1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --------------------
% BT panel
% --------------------
ax1 = nexttile;
hold(ax1, 'on');

hS0_bt_app = plot(ax1, tt, dyn_S0.mean_all(:, bt), '--', ...
    'Color', colS0, ...
    'LineWidth', 2.2, ...
    'DisplayName', 'S0 reference');

hCases_bt_app = gobjects(numel(plotOrder),1);
for j = 1:numel(plotOrder)
    i = plotOrder(j);
    hCases_bt_app(j) = plot(ax1, tt, trajBT{i}, '-', ...
        'Color', plotColors{j}, ...
        'LineWidth', 2.6, ...
        'DisplayName', plotLabels{j});
end

yline(ax1, 0, '--', 'Color', zeroCol, 'HandleVisibility', 'off');

plot(ax1, tt(end), dyn_S0.mean_all(end, bt), 'o', ...
    'Color', colS0, 'MarkerFaceColor', colS0, 'HandleVisibility', 'off');

for j = 1:numel(plotOrder)
    i = plotOrder(j);
    plot(ax1, tt(end), trajBT{i}(end), 'o', ...
        'Color', plotColors{j}, ...
        'MarkerFaceColor', plotColors{j}, ...
        'HandleVisibility', 'off');
end

grid(ax1, 'on');
box(ax1, 'on');
title(ax1, 'BT trajectories', 'FontSize', 13, 'FontWeight', 'bold');
ylabel(ax1, 'Mean opinion', 'FontSize', 12);
ylim(ax1, [0.20 0.52]);
xlim(ax1, [tt(1), tt(end)]);
set(ax1, 'FontSize', 11);
ax1.Toolbar.Visible = 'off';
hold(ax1, 'off');

% --------------------
% Q panel
% --------------------
ax2 = nexttile;
hold(ax2, 'on');

plot(ax2, tt, dyn_S0.mean_all(:, q), '--', ...
    'Color', colS0, ...
    'LineWidth', 2.2, ...
    'DisplayName', 'S0 reference');

for j = 1:numel(plotOrder)
    i = plotOrder(j);
    plot(ax2, tt, trajQ{i}, '-', ...
        'Color', plotColors{j}, ...
        'LineWidth', 2.6, ...
        'DisplayName', plotLabels{j});
end

yline(ax2, 0, '--', 'Color', zeroCol, 'HandleVisibility', 'off');

plot(ax2, tt(end), dyn_S0.mean_all(end, q), 'o', ...
    'Color', colS0, 'MarkerFaceColor', colS0, 'HandleVisibility', 'off');

for j = 1:numel(plotOrder)
    i = plotOrder(j);
    plot(ax2, tt(end), trajQ{i}(end), 'o', ...
        'Color', plotColors{j}, ...
        'MarkerFaceColor', plotColors{j}, ...
        'HandleVisibility', 'off');
end

grid(ax2, 'on');
box(ax2, 'on');
title(ax2, 'Q trajectories', 'FontSize', 13, 'FontWeight', 'bold');
xlabel(ax2, 'Time step', 'FontSize', 12);
ylabel(ax2, 'Mean opinion', 'FontSize', 12);
ylim(ax2, [-0.15 0.60]);
xlim(ax2, [tt(1), tt(end)]);
set(ax2, 'FontSize', 11);
ax2.Toolbar.Visible = 'off';
hold(ax2, 'off');

lgd = legend(ax1, [hS0_bt_app; hCases_bt_app], ...
    {'S0 reference', '100% ordinary exposure', '50% ordinary exposure', '25% ordinary exposure'}, ...
    'Orientation', 'horizontal', ...
    'FontSize', 10, ...
    'Box', 'on');
lgd.Layout.Tile = 'north';

title(tl, sprintf('Shock reach under varying ordinary-consumer exposure (\\DeltaQ = %.2f)', deltaQ), ...
    'FontSize', 15, 'FontWeight', 'bold');

exportgraphics(f_app, fullfile(outdir, 'Appendix_A2_ShockReach_BTQ_VaryingExposure.png'), 'Resolution', 300);

%% ------------------------------------------------------------
% Save workspace results
% ------------------------------------------------------------
results_exposure.tables.main_BT = T_BT_exposure;
results_exposure.tables.full    = T_exposure_full;

save(fullfile(outdir, 'Results_ShockReach_VaryingExposure.mat'), 'results_exposure');

fprintf('\n============================================================\n');
fprintf('Report outputs generated for Section 4.4.\n');
fprintf('Output folder:\n  %s\n', outdir);
fprintf('\nFigures saved:\n');
fprintf('  - Figure_4_4_ShockReach_BT_Only.png\n');
fprintf('  - Appendix_A2_ShockReach_BTQ_VaryingExposure.png\n');
fprintf('\nTables saved:\n');
fprintf('  - Table_4_4_ShockReach_BT_Summary.csv\n');
fprintf('  - Appendix_Table_A2_ShockReach_FullSummary.csv\n');
fprintf('\nWorkspace saved:\n');
fprintf('  - Results_ShockReach_VaryingExposure.mat\n');
fprintf('============================================================\n');