%% run_report_section_4_6_shock_channel.m
clear; clc; close all;

%% ============================================================
% Final-report runner for Project B: Section 4.6 Shock-channel comparison
%
% Main-text question:
%   Holding the baseline system, shocked groups, and direct shock size
%   fixed, does crisis severity depend on which topic is directly shocked?
%
% Main-text comparison:
%   1) S0 reference
%   2) matched quality shock on Q   (direct shock size = -0.70)
%   3) matched OM shock on OM       (direct shock size = -0.70)
%
% Main-text outputs:
%   - Figure_4_6_ShockChannel_BT_Only.png
%   - Table_4_6_ShockChannel_BT_Summary.csv
%
% Appendix-support outputs:
%   - Appendix_A3_ShockChannel_Topics_Q_OM.png
%   - Appendix_A4_ShockChannel_FinalBT_ByRole.png
%   - Appendix_Table_A3_ShockChannel_RoleBT.csv
%
% Result archive:
%   - Results_ShockChannel_MainText.mat
% ============================================================

cfg = get_cfg_projectB('main');
delta_main = -0.70;

outdir = fullfile(pwd, 'report_outputs_4_6_shock_channel');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

fprintf('\n============================================================\n');
fprintf('Project B final-report runner: Section 4.6 Shock-channel comparison\n');
fprintf('============================================================\n');
fprintf('Matched direct shock size: %.2f\n', delta_main);

%% ------------------------------------------------------------
% Build one common baseline system
% ------------------------------------------------------------
[A, deg, roles, idx, netinfo] = generate_network_projectB(cfg); %#ok<ASGLU>
[W, lambda, self_w, Winfo]    = build_W_lambda_projectB(A, deg, roles, cfg); %#ok<ASGLU>
[X0, X0info]                  = generate_X0_projectB(roles, cfg); %#ok<ASGLU>
[C, Cinfo]                    = build_C_projectB(cfg); %#ok<ASGLU>

bt = cfg.topic.idx.BT;
q  = cfg.topic.idx.Q;
om = cfg.topic.idx.OM;

fprintf('\nFixed backbone summary:\n');
fprintf('  n           = %d\n', cfg.population.n);
fprintf('  mean degree = %.3f\n', mean(deg));
fprintf('  max degree  = %d\n', max(deg));

fprintf('\nBaseline C:\n');
disp(C)

%% ------------------------------------------------------------
% Shocked groups held fixed across channels
% ------------------------------------------------------------
shockOrd = true;
shockOff = false;
shockEw  = true;

fprintf('\nShocked groups held fixed:\n');
fprintf('  ordinary = %d\n', shockOrd);
fprintf('  official = %d\n', shockOff);
fprintf('  eWOM     = %d\n', shockEw);

%% ------------------------------------------------------------
% S0 reference
% ------------------------------------------------------------
[Xhist_S0, dyn_S0] = run_dynamics_projectB_sharedC(X0, W, lambda, C, roles, cfg); %#ok<NASGU>

%% ------------------------------------------------------------
% Matched quality shock on Q
% ------------------------------------------------------------
[X_Qshock, shockInfo_Q] = apply_topic_shock_projectB( ...
    X0, roles, cfg, q, delta_main, shockOrd, shockOff, shockEw); %#ok<NASGU>

[Xhist_Qshock, dyn_Qshock] = run_dynamics_projectB_sharedC( ...
    X_Qshock, W, lambda, C, roles, cfg); %#ok<NASGU>

%% ------------------------------------------------------------
% Matched OM shock on OM
% ------------------------------------------------------------
[X_OMshock, shockInfo_OM] = apply_topic_shock_projectB( ...
    X0, roles, cfg, om, delta_main, shockOrd, shockOff, shockEw); %#ok<NASGU>

[Xhist_OMshock, dyn_OMshock] = run_dynamics_projectB_sharedC( ...
    X_OMshock, W, lambda, C, roles, cfg); %#ok<NASGU>

%% ------------------------------------------------------------
% Main-text compact summary table
% ------------------------------------------------------------
Case = ["S0 reference"; "Quality shock"; "OM shock"];
ShockedTopic = ["None"; "Q"; "OM"];
Final_BT = [dyn_S0.final_all(bt); dyn_Qshock.final_all(bt); dyn_OMshock.final_all(bt)];
BT_decline_vs_S0 = [0; ...
    dyn_S0.final_all(bt) - dyn_Qshock.final_all(bt); ...
    dyn_S0.final_all(bt) - dyn_OMshock.final_all(bt)];

T_shock_main = table( ...
    Case, ...
    ShockedTopic, ...
    Final_BT, ...
    BT_decline_vs_S0, ...
    'VariableNames', { ...
        'Case', ...
        'ShockedTopic', ...
        'Final_BT', ...
        'BT_decline_vs_S0'});

disp(' ');
disp('============================================================');
disp('Table 4.6 summary: shock-channel comparison under a shared S0 reference');
disp('============================================================');
disp(T_shock_main);

writetable(T_shock_main, fullfile(outdir, 'Table_4_6_ShockChannel_BT_Summary.csv'));

%% ------------------------------------------------------------
% Appendix-support role-specific BT table
% ------------------------------------------------------------
Ordinary_final_BT = [dyn_S0.final_ord(bt); dyn_Qshock.final_ord(bt); dyn_OMshock.final_ord(bt)];
Official_final_BT = [dyn_S0.final_off(bt); dyn_Qshock.final_off(bt); dyn_OMshock.final_off(bt)];
EWOM_final_BT     = [dyn_S0.final_ew(bt);  dyn_Qshock.final_ew(bt);  dyn_OMshock.final_ew(bt)];

T_roleBT = table( ...
    Case, ...
    Ordinary_final_BT, ...
    Official_final_BT, ...
    EWOM_final_BT, ...
    'VariableNames', { ...
        'Case', ...
        'Ordinary_final_BT', ...
        'Official_final_BT', ...
        'EWOM_final_BT'});

writetable(T_roleBT, fullfile(outdir, 'Appendix_Table_A3_ShockChannel_RoleBT.csv'));

%% ------------------------------------------------------------
% Quick interpretation print
% ------------------------------------------------------------
fprintf('\n============================================================\n');
fprintf('Quick interpretation\n');
fprintf('============================================================\n');
fprintf('S0 reference   | final BT = %.4f\n', dyn_S0.final_all(bt));
fprintf('Quality shock  | final BT = %.4f | BT decline = %.4f\n', ...
    dyn_Qshock.final_all(bt), dyn_S0.final_all(bt) - dyn_Qshock.final_all(bt));
fprintf('OM shock       | final BT = %.4f | BT decline = %.4f\n', ...
    dyn_OMshock.final_all(bt), dyn_S0.final_all(bt) - dyn_OMshock.final_all(bt));

fprintf('\nRole-specific BT reminder:\n');
fprintf('S0 reference   | ordinary = %.4f | official = %.4f | eWOM = %.4f\n', ...
    dyn_S0.final_ord(bt), dyn_S0.final_off(bt), dyn_S0.final_ew(bt));
fprintf('Quality shock  | ordinary = %.4f | official = %.4f | eWOM = %.4f\n', ...
    dyn_Qshock.final_ord(bt), dyn_Qshock.final_off(bt), dyn_Qshock.final_ew(bt));
fprintf('OM shock       | ordinary = %.4f | official = %.4f | eWOM = %.4f\n', ...
    dyn_OMshock.final_ord(bt), dyn_OMshock.final_off(bt), dyn_OMshock.final_ew(bt));

%% ------------------------------------------------------------
% Colors
% ------------------------------------------------------------
cols = [ ...
    0.10 0.10 0.10;       % S0 reference
    0.0000 0.4470 0.7410; % quality shock
    0.8500 0.3250 0.0980  % OM shock
];

roleCols = [ ...
    0.0000 0.4470 0.7410; % ordinary
    0.8500 0.3250 0.0980; % official
    0.9290 0.6940 0.1250  % eWOM
];

tt = 0:cfg.sim.Tmax;

%% ------------------------------------------------------------
% Figure 4.6 main-text figure
% Left panel  = all-agent BT trajectories
% Right panel = final BT by shock channel
% ------------------------------------------------------------
f1 = figure('Name', 'Figure_4_6_ShockChannel_BT_Only', ...
            'Color', 'w', ...
            'Position', [100 100 1380 620], ...
            'ToolBar', 'none', ...
            'MenuBar', 'none');

tl1 = tiledlayout(1,2, 'TileSpacing', 'compact', 'Padding', 'compact');

% Left panel: all-agent BT trajectories
ax1 = nexttile;
hold(ax1, 'on');

h1 = plot(ax1, tt, dyn_S0.mean_all(:, bt), '--', ...
    'Color', cols(1,:), 'LineWidth', 2.2, ...
    'DisplayName', 'S0 reference');

h2 = plot(ax1, tt, dyn_Qshock.mean_all(:, bt), '-', ...
    'Color', cols(2,:), 'LineWidth', 2.8, ...
    'Marker', 's', 'MarkerIndices', 1:4:numel(tt), 'MarkerSize', 5, ...
    'DisplayName', 'Quality shock');

h3 = plot(ax1, tt, dyn_OMshock.mean_all(:, bt), '-', ...
    'Color', cols(3,:), 'LineWidth', 2.8, ...
    'Marker', '^', 'MarkerIndices', 2:4:numel(tt), 'MarkerSize', 5, ...
    'DisplayName', 'OM shock');

grid(ax1, 'on');
box(ax1, 'on');
title(ax1, 'All-agent BT trajectories', 'FontSize', 13, 'FontWeight', 'bold');
xlabel(ax1, 'Time step');
ylabel(ax1, 'Mean opinion');

bt_all = [dyn_S0.mean_all(:,bt); dyn_Qshock.mean_all(:,bt); dyn_OMshock.mean_all(:,bt)];
ylim(ax1, [min(bt_all)-0.03, max(bt_all)+0.03]);
xlim(ax1, [tt(1), tt(end)]);

try
    ax1.Toolbar.Visible = 'off';
catch
end

hold(ax1, 'off');

% Right panel: final BT bars
ax2 = nexttile;
hold(ax2, 'on');

Y = [dyn_S0.final_all(bt), dyn_Qshock.final_all(bt), dyn_OMshock.final_all(bt)];
b = bar(ax2, Y, 0.62, 'FaceColor', 'flat');

for i = 1:3
    b.CData(i,:) = cols(i,:);
end

set(ax2, 'XTick', 1:3, ...
    'XTickLabel', {'S0 reference', 'Quality-shock channel', 'OM-shock channel'}, ...
    'XTickLabelRotation', 10);

ylabel(ax2, 'Final BT');
title(ax2, 'Final BT by shock channel', 'FontSize', 13, 'FontWeight', 'bold');
grid(ax2, 'on');
box(ax2, 'on');
ylim(ax2, [0 0.60]);

for i = 1:3
    text(ax2, i, Y(i)+0.010, sprintf('%.3f', Y(i)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10, ...
        'FontWeight', 'bold');
end

text(ax2, 2, Y(2)+0.048, sprintf('BT decline = %.3f', dyn_S0.final_all(bt) - dyn_Qshock.final_all(bt)), ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'Color', [0.35 0.00 0.00]);

text(ax2, 3, Y(3)+0.048, sprintf('BT decline = %.3f', dyn_S0.final_all(bt) - dyn_OMshock.final_all(bt)), ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'Color', [0.35 0.00 0.00]);

try
    ax2.Toolbar.Visible = 'off';
catch
end

hold(ax2, 'off');

lgd_main = legend(ax1, [h1, h2, h3], ...
    {'S0 reference', 'Quality shock', 'OM shock'}, ...
    'Orientation', 'horizontal', ...
    'FontSize', 10, ...
    'Box', 'on', ...
    'Location', 'northoutside');

title(tl1, sprintf('Shock-channel comparison under matched direct shocks of size %.2f', delta_main), ...
    'FontSize', 15, 'FontWeight', 'bold');

exportgraphics(f1, fullfile(outdir, 'Figure_4_6_ShockChannel_BT_Only.png'), 'Resolution', 300);

%% ------------------------------------------------------------
% Appendix A3: supportive topic-level figure (Q and OM only)
% ------------------------------------------------------------
f2 = figure('Name', 'Appendix_A3_ShockChannel_Topics_Q_OM', ...
            'Color', 'w', ...
            'Position', [120 120 1380 620], ...
            'ToolBar', 'none', ...
            'MenuBar', 'none');

tl2 = tiledlayout(1,2, 'TileSpacing', 'compact', 'Padding', 'compact');

% Q panel
ax3 = nexttile;
hold(ax3, 'on');

hq1 = plot(ax3, tt, dyn_S0.mean_all(:, q), '--', ...
    'Color', cols(1,:), 'LineWidth', 2.2, ...
    'DisplayName', 'S0 reference');

hq2 = plot(ax3, tt, dyn_Qshock.mean_all(:, q), '-', ...
    'Color', cols(2,:), 'LineWidth', 2.8, ...
    'Marker', 's', 'MarkerIndices', 1:4:numel(tt), 'MarkerSize', 5, ...
    'DisplayName', 'Quality shock');

hq3 = plot(ax3, tt, dyn_OMshock.mean_all(:, q), '-', ...
    'Color', cols(3,:), 'LineWidth', 2.8, ...
    'Marker', '^', 'MarkerIndices', 2:4:numel(tt), 'MarkerSize', 5, ...
    'DisplayName', 'OM shock');

grid(ax3, 'on');
box(ax3, 'on');
title(ax3, 'Q trajectories', 'FontSize', 13, 'FontWeight', 'bold');
xlabel(ax3, 'Time step');
ylabel(ax3, 'Mean opinion');

q_all = [dyn_S0.mean_all(:,q); dyn_Qshock.mean_all(:,q); dyn_OMshock.mean_all(:,q)];
ylim(ax3, [min(q_all)-0.03, max(q_all)+0.03]);
xlim(ax3, [tt(1), tt(end)]);

try
    ax3.Toolbar.Visible = 'off';
catch
end

hold(ax3, 'off');

% OM panel
ax4 = nexttile;
hold(ax4, 'on');

ho1 = plot(ax4, tt, dyn_S0.mean_all(:, om), '--', ...
    'Color', cols(1,:), 'LineWidth', 2.2, ...
    'DisplayName', 'S0 reference');

ho2 = plot(ax4, tt, dyn_Qshock.mean_all(:, om), '-', ...
    'Color', cols(2,:), 'LineWidth', 2.8, ...
    'Marker', 's', 'MarkerIndices', 1:4:numel(tt), 'MarkerSize', 5, ...
    'DisplayName', 'Quality shock');

ho3 = plot(ax4, tt, dyn_OMshock.mean_all(:, om), '-', ...
    'Color', cols(3,:), 'LineWidth', 2.8, ...
    'Marker', '^', 'MarkerIndices', 2:4:numel(tt), 'MarkerSize', 5, ...
    'DisplayName', 'OM shock');

grid(ax4, 'on');
box(ax4, 'on');
title(ax4, 'OM trajectories', 'FontSize', 13, 'FontWeight', 'bold');
xlabel(ax4, 'Time step');
ylabel(ax4, 'Mean opinion');

om_all = [dyn_S0.mean_all(:,om); dyn_Qshock.mean_all(:,om); dyn_OMshock.mean_all(:,om)];
ylim(ax4, [min(om_all)-0.03, max(om_all)+0.03]);
xlim(ax4, [tt(1), tt(end)]);

try
    ax4.Toolbar.Visible = 'off';
catch
end

hold(ax4, 'off');

lgd_app = legend(ax3, [hq1, hq2, hq3], ...
    {'S0 reference', 'Quality shock', 'OM shock'}, ...
    'Orientation', 'horizontal', ...
    'FontSize', 10, ...
    'Box', 'on', ...
    'Location', 'northoutside');

title(tl2, 'Supportive Q and OM trajectories by shock channel', ...
    'FontSize', 15, 'FontWeight', 'bold');

exportgraphics(f2, fullfile(outdir, 'Appendix_A3_ShockChannel_Topics_Q_OM.png'), 'Resolution', 300);

%% ------------------------------------------------------------
% Appendix A4: role-specific final BT by shock channel
% ------------------------------------------------------------
f3 = figure('Name', 'Appendix_A4_ShockChannel_FinalBT_ByRole', ...
            'Color', 'w', ...
            'Position', [140 140 1180 560], ...
            'ToolBar', 'none', ...
            'MenuBar', 'none');

ax5 = axes(f3);
hold(ax5, 'on');

Y_role = [ ...
    dyn_S0.final_ord(bt),      dyn_S0.final_off(bt),      dyn_S0.final_ew(bt); ...
    dyn_Qshock.final_ord(bt),  dyn_Qshock.final_off(bt),  dyn_Qshock.final_ew(bt); ...
    dyn_OMshock.final_ord(bt), dyn_OMshock.final_off(bt), dyn_OMshock.final_ew(bt)];

bh = bar(ax5, Y_role, 'grouped', 'BarWidth', 0.78);
for k = 1:3
    bh(k).FaceColor = roleCols(k,:);
    bh(k).EdgeColor = [0.20 0.20 0.20];
end

set(ax5, 'XTick', 1:3, ...
    'XTickLabel', {'S0 reference', 'Quality shock', 'OM shock'}, ...
    'XTickLabelRotation', 10);

ylabel(ax5, 'Final BT');
title(ax5, 'Role-specific final BT by shock channel', ...
    'FontSize', 13, 'FontWeight', 'bold');
grid(ax5, 'on');
box(ax5, 'on');
ylim(ax5, [0 0.95]);

legend(ax5, {'ordinary', 'official', 'eWOM'}, ...
    'Location', 'eastoutside', 'FontSize', 9);

for j = 1:3
    xj = bh(j).XEndPoints;
    yj = bh(j).YEndPoints;
    for i = 1:numel(xj)
        text(ax5, xj(i), yj(i)+0.012, sprintf('%.3f', yj(i)), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 9, ...
            'FontWeight', 'bold');
    end
end

try
    ax5.Toolbar.Visible = 'off';
catch
end

hold(ax5, 'off');

exportgraphics(f3, fullfile(outdir, 'Appendix_A4_ShockChannel_FinalBT_ByRole.png'), 'Resolution', 300);

%% ------------------------------------------------------------
% Save result archive
% ------------------------------------------------------------
results_shock_channel = struct();
results_shock_channel.cfg = cfg;
results_shock_channel.delta_main = delta_main;
results_shock_channel.network.A = A;
results_shock_channel.network.deg = deg;
results_shock_channel.network.roles = roles;
results_shock_channel.network.idx = idx;
results_shock_channel.network.netinfo = netinfo;
results_shock_channel.baseline.W = W;
results_shock_channel.baseline.lambda = lambda;
results_shock_channel.baseline.self_w = self_w;
results_shock_channel.baseline.Winfo = Winfo;
results_shock_channel.baseline.X0 = X0;
results_shock_channel.baseline.X0info = X0info;
results_shock_channel.baseline.C = C;
results_shock_channel.baseline.Cinfo = Cinfo;

results_shock_channel.S0.Xhist = Xhist_S0;
results_shock_channel.S0.dyn = dyn_S0;

results_shock_channel.quality_shock.Xshock = X_Qshock;
results_shock_channel.quality_shock.shockInfo = shockInfo_Q;
results_shock_channel.quality_shock.Xhist = Xhist_Qshock;
results_shock_channel.quality_shock.dyn = dyn_Qshock;

results_shock_channel.OM_shock.Xshock = X_OMshock;
results_shock_channel.OM_shock.shockInfo = shockInfo_OM;
results_shock_channel.OM_shock.Xhist = Xhist_OMshock;
results_shock_channel.OM_shock.dyn = dyn_OMshock;

results_shock_channel.table_main = T_shock_main;
results_shock_channel.table_roleBT = T_roleBT;

save(fullfile(outdir, 'Results_ShockChannel_MainText.mat'), 'results_shock_channel');

fprintf('\n============================================================\n');
fprintf('Report outputs generated for Section 4.6.\n');
fprintf('Output folder:\n  %s\n', outdir);
fprintf('\nFigures saved:\n');
fprintf('  - Figure_4_6_ShockChannel_BT_Only.png\n');
fprintf('  - Appendix_A3_ShockChannel_Topics_Q_OM.png\n');
fprintf('  - Appendix_A4_ShockChannel_FinalBT_ByRole.png\n');
fprintf('\nTables saved:\n');
fprintf('  - Table_4_6_ShockChannel_BT_Summary.csv\n');
fprintf('  - Appendix_Table_A3_ShockChannel_RoleBT.csv\n');
fprintf('\nWorkspace saved:\n');
fprintf('  - Results_ShockChannel_MainText.mat\n');
fprintf('============================================================\n');

%% ============================================================
% Local helpers
% ============================================================
function [Xshock, shockInfo] = apply_topic_shock_projectB(X0, roles, cfg, topicIdx, delta, shockOrd, shockOff, shockEw)

    Xshock = X0;

    roleOrd = cfg.role.code.ordinary;
    roleOff = cfg.role.code.official;
    roleEw  = cfg.role.code.ewom;

    shockMask = false(size(roles));

    if shockOrd
        shockMask = shockMask | (roles == roleOrd);
    end
    if shockOff
        shockMask = shockMask | (roles == roleOff);
    end
    if shockEw
        shockMask = shockMask | (roles == roleEw);
    end

    Xshock(shockMask, topicIdx) = Xshock(shockMask, topicIdx) + delta;

    if isfield(cfg, 'scale') && isfield(cfg.scale, 'xmin') && isfield(cfg.scale, 'xmax')
        Xshock(:, topicIdx) = min(max(Xshock(:, topicIdx), cfg.scale.xmin), cfg.scale.xmax);
    end

    shockInfo = struct();
    shockInfo.topicIdx   = topicIdx;
    shockInfo.topicName  = cfg.topic.names{topicIdx};
    shockInfo.delta      = delta;
    shockInfo.shockOrd   = shockOrd;
    shockInfo.shockOff   = shockOff;
    shockInfo.shockEw    = shockEw;
    shockInfo.numShocked = sum(shockMask);
end

function [Xhist, dynInfo] = run_dynamics_projectB_sharedC(Xinit, W, lambda, C, roles, cfg)

    [n, m] = size(Xinit);

    if size(W,1) ~= n || size(W,2) ~= n
        error('W must be n x n.');
    end
    if numel(lambda) ~= n
        error('lambda length must equal n.');
    end
    if size(C,1) ~= m || size(C,2) ~= m
        error('C must be m x m.');
    end
    if numel(roles) ~= n
        error('roles length must equal n.');
    end

    lambda = lambda(:);
    roles  = roles(:);
    Tmax   = cfg.sim.Tmax;

    Xhist = zeros(n, m, Tmax + 1);
    Xhist(:,:,1) = Xinit;

    stepMaxAbs  = zeros(Tmax, 1);
    stepMeanAbs = zeros(Tmax, 1);

    for t = 1:Tmax
        Xcur = Xhist(:,:,t);

        social_term  = W * Xcur;
        coupled_term = social_term * C';

        Xnext = bsxfun(@times, (1 - lambda), Xinit) + ...
                bsxfun(@times, lambda, coupled_term);

        if cfg.sim.clip_each_step
            Xnext = min(max(Xnext, cfg.scale.xmin), cfg.scale.xmax);
        end

        Xhist(:,:,t+1) = Xnext;

        delta_step = Xnext - Xcur;
        stepMaxAbs(t)  = max(abs(delta_step(:)));
        stepMeanAbs(t) = mean(abs(delta_step(:)));
    end

    roleOrd = cfg.role.code.ordinary;
    roleOff = cfg.role.code.official;
    roleEw  = cfg.role.code.ewom;

    idxOrd = find(roles == roleOrd);
    idxOff = find(roles == roleOff);
    idxEw  = find(roles == roleEw);

    mean_all = zeros(Tmax+1, m);
    mean_ord = zeros(Tmax+1, m);
    mean_off = zeros(Tmax+1, m);
    mean_ew  = zeros(Tmax+1, m);

    for t = 1:(Tmax+1)
        Xt = Xhist(:,:,t);
        mean_all(t,:) = mean(Xt, 1);
        mean_ord(t,:) = mean(Xt(idxOrd,:), 1);
        mean_off(t,:) = mean(Xt(idxOff,:), 1);
        mean_ew(t,:)  = mean(Xt(idxEw,:), 1);
    end

    dynInfo = struct();
    dynInfo.Tmax        = Tmax;
    dynInfo.stepMaxAbs  = stepMaxAbs;
    dynInfo.stepMeanAbs = stepMeanAbs;

    dynInfo.mean_all = mean_all;
    dynInfo.mean_ord = mean_ord;
    dynInfo.mean_off = mean_off;
    dynInfo.mean_ew  = mean_ew;

    dynInfo.final_all = mean_all(end,:);
    dynInfo.final_ord = mean_ord(end,:);
    dynInfo.final_off = mean_off(end,:);
    dynInfo.final_ew  = mean_ew(end,:);

    dynInfo.initial_all = mean_all(1,:);
    dynInfo.initial_ord = mean_ord(1,:);
    dynInfo.initial_off = mean_off(1,:);
    dynInfo.initial_ew  = mean_ew(1,:);

    dynInfo.total_change_all = dynInfo.final_all - dynInfo.initial_all;
    dynInfo.total_change_ord = dynInfo.final_ord - dynInfo.initial_ord;
    dynInfo.total_change_off = dynInfo.final_off - dynInfo.initial_off;
    dynInfo.total_change_ew  = dynInfo.final_ew  - dynInfo.initial_ew;
end