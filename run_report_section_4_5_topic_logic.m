%% run_report_section_4_5_topic_logic.m
clear; clc; close all;

%% ============================================================
% Final-report runner for Project B: Section 4.5 Topic-logic comparisons
%
% Main-text purpose:
%   Compare three ordinary-consumer topic-logic cases only:
%   1) baseline shared logic
%   2) more quality-driven BT logic on ordinary consumers
%   3) mildly more OM-driven BT logic on ordinary consumers
%
% Main-text outputs:
%   1) Compact summary table for Section 4.5
%   2) One final-BT comparison figure for Section 4.5
%
% Report-facing output files:
%   report_outputs_4_5_topic_logic/
%     - Figure_4_5_TopicLogic_Ordinary_BT.png
%     - Table_4_5_TopicLogic_Ordinary_BT.csv
%     - Results_TopicLogic_Ordinary_BT.mat
% ============================================================

cfg = get_cfg_projectB('main');
deltaQ = cfg.S1.deltaQ_main;

outdir = fullfile(pwd, 'report_outputs_4_5_topic_logic');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

fprintf('\n============================================================\n');
fprintf('Project B final-report runner: Section 4.5 Topic-logic comparisons\n');
fprintf('============================================================\n');
fprintf('Direct shock size (DeltaQ): %.2f\n', deltaQ);

%% ------------------------------------------------------------
% Build one common baseline system
% ------------------------------------------------------------
[A, deg, roles, idx, netinfo] = generate_network_projectB(cfg); %#ok<ASGLU>
[W, lambda, self_w, Winfo]    = build_W_lambda_projectB(A, deg, roles, cfg); %#ok<ASGLU>
[X0, X0info]                  = generate_X0_projectB(roles, cfg); %#ok<ASGLU>
[C_base, Cinfo_base]          = build_C_projectB(cfg); %#ok<ASGLU>

fprintf('\nFixed backbone summary:\n');
fprintf('  n           = %d\n', cfg.population.n);
fprintf('  mean degree = %.3f\n', mean(deg));
fprintf('  max degree  = %d\n', max(deg));

fprintf('\nBaseline C:\n');
disp(C_base);

%% ------------------------------------------------------------
% Define alternative BT rows for ordinary consumers
% ------------------------------------------------------------
C_alt_Q = C_base;
C_alt_Q(cfg.topic.idx.BT, :) = [0.20, 0.60, 0.20];

C_alt_OM = C_base;
C_alt_OM(cfg.topic.idx.BT, :) = [0.30, 0.30, 0.40];

fprintf('Quality-driven alternative C:\n');
disp(C_alt_Q);

fprintf('Mild OM-driven alternative C:\n');
disp(C_alt_OM);

%% ------------------------------------------------------------
% Main-text cases only
% ------------------------------------------------------------
caseNames = { ...
    'baseline_shared', ...
    'ordinary_qdriven', ...
    'ordinary_ommild'};

tableLabels = { ...
    'Baseline shared logic', ...
    'Q-driven BT logic on ordinary', ...
    'Mild OM-driven on ordinary'};

axisLabels = { ...
    'Baseline shared', ...
    'Q-driven on ordinary', ...
    'Mild OM-driven on ordinary'};

nCase = numel(caseNames);

CaseLabel        = strings(nCase,1);
S0_final_BT      = zeros(nCase,1);
S1_final_BT      = zeros(nCase,1);
BT_decline_vs_S0 = zeros(nCase,1);

results_logic_main = struct();
results_logic_main.cfg = cfg;
results_logic_main.network.A = A;
results_logic_main.network.deg = deg;
results_logic_main.network.roles = roles;
results_logic_main.network.idx = idx;
results_logic_main.network.netinfo = netinfo;
results_logic_main.baseline.W = W;
results_logic_main.baseline.lambda = lambda;
results_logic_main.baseline.self_w = self_w;
results_logic_main.baseline.Winfo = Winfo;
results_logic_main.baseline.X0 = X0;
results_logic_main.baseline.X0info = X0info;
results_logic_main.baseline.C_base = C_base;
results_logic_main.baseline.C_alt_Q = C_alt_Q;
results_logic_main.baseline.C_alt_OM = C_alt_OM;
results_logic_main.baseline.Cinfo_base = Cinfo_base;

bt = cfg.topic.idx.BT;

%% ------------------------------------------------------------
% Run the three topic-logic cases
% ------------------------------------------------------------
for i = 1:nCase
    caseName = caseNames{i};
    CaseLabel(i) = string(tableLabels{i});

    C_by_agent = make_C_assignment_topiclogic(caseName, roles, cfg, C_base, C_alt_Q, C_alt_OM);

    % S0
    [Xhist_S0, dyn_S0] = run_dynamics_projectB_heteroC(X0, W, lambda, C_by_agent, roles, cfg);

    % S1 main quality shock
    [X1, shockInfo]    = apply_S1_quality_shock_projectB(X0, roles, cfg, deltaQ);
    [Xhist_S1, dyn_S1] = run_dynamics_projectB_heteroC(X1, W, lambda, C_by_agent, roles, cfg);

    S0_final_BT(i)      = dyn_S0.final_all(bt);
    S1_final_BT(i)      = dyn_S1.final_all(bt);
    BT_decline_vs_S0(i) = S0_final_BT(i) - S1_final_BT(i);

    tag = matlab.lang.makeValidName(caseName);
    results_logic_main.(tag).caseName   = caseName;
    results_logic_main.(tag).tableLabel = tableLabels{i};
    results_logic_main.(tag).axisLabel  = axisLabels{i};
    results_logic_main.(tag).C_by_agent = C_by_agent;

    results_logic_main.(tag).S0.Xhist = Xhist_S0;
    results_logic_main.(tag).S0.dyn   = dyn_S0;

    results_logic_main.(tag).S1.deltaQ    = deltaQ;
    results_logic_main.(tag).S1.X1        = X1;
    results_logic_main.(tag).S1.shockInfo = shockInfo;
    results_logic_main.(tag).S1.Xhist     = Xhist_S1;
    results_logic_main.(tag).S1.dyn       = dyn_S1;
end

%% ------------------------------------------------------------
% Compact summary table for main text
% ------------------------------------------------------------
T_logic_main = table( ...
    CaseLabel, ...
    S0_final_BT, ...
    S1_final_BT, ...
    BT_decline_vs_S0, ...
    'VariableNames', { ...
        'Case', ...
        'S0_final_BT', ...
        'S1_final_BT', ...
        'BT_decline_vs_S0'} ...
);

disp(' ');
disp('============================================================');
disp('Table 4.5 summary: topic-logic comparison on ordinary consumers');
disp('============================================================');
disp(T_logic_main);

%% ------------------------------------------------------------
% Quick interpretation
% ------------------------------------------------------------
fprintf('\n============================================================\n');
fprintf('Quick interpretation\n');
fprintf('============================================================\n');
for i = 1:nCase
    fprintf('%s | S0 final BT = %.4f | S1 final BT = %.4f | BT decline = %.4f\n', ...
        axisLabels{i}, S0_final_BT(i), S1_final_BT(i), BT_decline_vs_S0(i));
end

fprintf('\nMain reading:\n');
fprintf('- The quality-driven case produces the largest BT decline.\n');
fprintf('- The baseline case remains in the middle.\n');
fprintf('- The mildly OM-driven case produces the smallest BT decline.\n');

%% ------------------------------------------------------------
% Save compact summary table
% ------------------------------------------------------------
writetable(T_logic_main, fullfile(outdir, 'Table_4_5_TopicLogic_Ordinary_BT.csv'));

%% ------------------------------------------------------------
% Main-text figure: final BT under S0 and S1 across topic-logic cases
% ------------------------------------------------------------
f = figure('Name', 'Figure_4_5_TopicLogic_Ordinary_BT', ...
           'Color', 'w', ...
           'Position', [100 100 1120 620], ...
           'ToolBar', 'none', ...
           'MenuBar', 'none');

ax = axes(f);
hold(ax, 'on');

Y = [S0_final_BT, S1_final_BT];
bh = bar(ax, Y, 'grouped', 'BarWidth', 0.72);

% S0 bars
bh(1).FaceColor = [0.60 0.60 0.60];
bh(1).EdgeColor = [0.30 0.30 0.30];
bh(1).LineWidth = 1.0;

% S1 bars
bh(2).FaceColor = [0.15 0.45 0.80];
bh(2).EdgeColor = [0.20 0.20 0.20];
bh(2).LineWidth = 1.0;

set(ax, 'XTick', 1:nCase, ...
        'XTickLabel', axisLabels, ...
        'XTickLabelRotation', 12);

ylabel(ax, 'Final BT', 'FontSize', 12);
title(ax, 'Final BT across ordinary-consumer topic-logic cases', ...
    'FontSize', 14, 'FontWeight', 'bold');

grid(ax, 'on');
box(ax, 'on');
ylim(ax, [0 0.60]);
set(ax, 'FontSize', 11);

lgd = legend(ax, {'S0 final BT', 'S1 final BT'}, ...
    'Location', 'northeast', 'FontSize', 10);
set(lgd, 'Interpreter', 'none');

try
    ax.Toolbar.Visible = 'off';
catch
end

% Numeric labels on bars
x1 = bh(1).XEndPoints;
x2 = bh(2).XEndPoints;

for i = 1:nCase
    text(ax, x1(i), S0_final_BT(i) + 0.008, sprintf('%.3f', S0_final_BT(i)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'Color', [0.25 0.25 0.25]);

    text(ax, x2(i), S1_final_BT(i) + 0.008, sprintf('%.3f', S1_final_BT(i)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'Color', [0.10 0.10 0.10]);

    text(ax, mean([x1(i), x2(i)]), max(S0_final_BT(i), S1_final_BT(i)) + 0.038, ...
        sprintf('BT decline = %.3f', BT_decline_vs_S0(i)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 9.5, ...
        'FontWeight', 'bold', ...
        'Color', [0.35 0.00 0.00]);
end

hold(ax, 'off');

exportgraphics(f, fullfile(outdir, 'Figure_4_5_TopicLogic_Ordinary_BT.png'), 'Resolution', 300);

%% ------------------------------------------------------------
% Save results
% ------------------------------------------------------------
results_logic_main.table_main = T_logic_main;
save(fullfile(outdir, 'Results_TopicLogic_Ordinary_BT.mat'), 'results_logic_main');

fprintf('\n============================================================\n');
fprintf('Report outputs generated for Section 4.5.\n');
fprintf('Output folder:\n  %s\n', outdir);
fprintf('\nFigures saved:\n');
fprintf('  - Figure_4_5_TopicLogic_Ordinary_BT.png\n');
fprintf('\nTables saved:\n');
fprintf('  - Table_4_5_TopicLogic_Ordinary_BT.csv\n');
fprintf('\nWorkspace saved:\n');
fprintf('  - Results_TopicLogic_Ordinary_BT.mat\n');
fprintf('============================================================\n');

%% ============================================================
% Local helpers
% ============================================================
function C_by_agent = make_C_assignment_topiclogic(caseName, roles, cfg, C_base, C_alt_Q, C_alt_OM)

    n = numel(roles);
    m = cfg.topic.m;
    C_by_agent = zeros(n, m, m);

    roleOrd = cfg.role.code.ordinary;

    for ii = 1:n
        C_by_agent(ii,:,:) = C_base;
    end

    switch lower(caseName)
        case 'baseline_shared'
            % keep baseline C for all agents

        case 'ordinary_qdriven'
            idx = find(roles == roleOrd);
            for k = 1:numel(idx)
                C_by_agent(idx(k),:,:) = C_alt_Q;
            end

        case 'ordinary_ommild'
            idx = find(roles == roleOrd);
            for k = 1:numel(idx)
                C_by_agent(idx(k),:,:) = C_alt_OM;
            end

        otherwise
            error('Unknown caseName: %s', caseName);
    end
end

function [Xhist, dynInfo] = run_dynamics_projectB_heteroC(Xinit, W, lambda, C_by_agent, roles, cfg)
% Heterogeneous-C version: each agent i uses its own m x m C_i

    [n, m] = size(Xinit);

    if size(W,1) ~= n || size(W,2) ~= n
        error('W must be n x n.');
    end
    if numel(lambda) ~= n
        error('lambda length must equal n.');
    end
    if size(C_by_agent,1) ~= n || size(C_by_agent,2) ~= m || size(C_by_agent,3) ~= m
        error('C_by_agent must be n x m x m.');
    end
    if numel(roles) ~= n
        error('roles length must equal n.');
    end

    lambda = lambda(:);
    roles  = roles(:);
    Tmax = cfg.sim.Tmax;

    Xhist = zeros(n, m, Tmax + 1);
    Xhist(:,:,1) = Xinit;

    stepMaxAbs  = zeros(Tmax, 1);
    stepMeanAbs = zeros(Tmax, 1);

    for t = 1:Tmax
        Xcur = Xhist(:,:,t);

        social_term  = W * Xcur;
        coupled_term = zeros(n, m);

        for ii = 1:n
            Ci = squeeze(C_by_agent(ii,:,:));
            coupled_term(ii,:) = social_term(ii,:) * Ci';
        end

        Xnext = bsxfun(@times, (1 - lambda), Xinit) + ...
                bsxfun(@times, lambda, coupled_term);

        if cfg.sim.clip_each_step
            Xnext = min(max(Xnext, cfg.scale.xmin), cfg.scale.xmax);
        end

        Xhist(:,:,t+1) = Xnext;

        delta = Xnext - Xcur;
        stepMaxAbs(t)  = max(abs(delta(:)));
        stepMeanAbs(t) = mean(abs(delta(:)));
    end

    % Diagnostics
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