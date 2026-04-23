clear; clc; close all;

%% ============================================================
% Backbone S0/S1 dynamics runner for Sections 4.1-4.3
%
% Purpose:
%   Build the common baseline system, run the S0 reference state,
%   run the main S1 quality-shock scenarios, and store the results
%   consumed by the report-facing Section 4.1-4.3 plotting script.
%
% Main role in the repository:
%   This is a backbone runner, not the report-facing plotting script.
%   The report-facing entry point for Sections 4.1-4.3 is:
%       run_report_section_4_1_to_4_3.m
% ============================================================

%% ============================================================
% 0) Config
% ============================================================
cfg = get_cfg_projectB('main');

fprintf('\n============================================\n');
fprintf('Backbone S0/S1 dynamics runner for Sections 4.1-4.3\n');
fprintf('============================================\n');
fprintf('Preset: %s\n', cfg.preset);
fprintf('Tmax  : %d\n', cfg.sim.Tmax);
fprintf('Topics: ');
disp(cfg.topic.names)

fprintf('Shock list used in this runner: ');
disp(cfg.S1.deltaQ_list)

fprintf('Stored weak comparison shock (not included in the current loop): %.2f\n', ...
    cfg.S1.deltaQ_weak);

%% ============================================================
% 1) Build full baseline system
% ============================================================
[A, deg, roles, idx, netinfo] = generate_network_projectB(cfg);
[W, lambda, self_w, Winfo]    = build_W_lambda_projectB(A, deg, roles, cfg);
[X0, X0info]                  = generate_X0_projectB(roles, cfg);
[C, Cinfo]                    = build_C_projectB(cfg);

fprintf('\n============================================\n');
fprintf('Baseline system summary\n');
fprintf('============================================\n');

fprintf('Network summary:\n');
fprintf('Mean degree: %.3f\n', netinfo.mean_degree);
fprintf('Max degree : %d\n', netinfo.max_degree);
fprintf('Connected  : %d\n', netinfo.is_connected);

fprintf('\nRole counts:\n');
fprintf('ordinary = %d, official = %d, ewom = %d\n', ...
    numel(idx.ordinary), numel(idx.official), numel(idx.ewom));

fprintf('\nOfficial nodes in hub-assignment order:\n');
disp(netinfo.assigned_official_nodes')

fprintf('eWOM nodes in hub-assignment order:\n');
disp(netinfo.assigned_ewom_nodes')

fprintf('\nSelf-weight means:\n');
fprintf('ordinary: %.4f\n', Winfo.mean_self_ord);
fprintf('official: %.4f\n', Winfo.mean_self_off);
fprintf('ewom    : %.4f\n', Winfo.mean_self_ew);

fprintf('\nLambda means:\n');
fprintf('ordinary: %.4f\n', Winfo.mean_lambda_ord);
fprintf('official: %.4f\n', Winfo.mean_lambda_off);
fprintf('ewom    : %.4f\n', Winfo.mean_lambda_ew);

fprintf('\nRow-stochastic check for W:\n');
fprintf('max |rowSum - 1| = %.3e\n', Winfo.row_sum_max_abs_err);

fprintf('\nBaseline C matrix:\n');
disp(C)

fprintf('C row sums:\n');
disp(Cinfo.rowSums)

fprintf('C absolute row sums:\n');
disp(Cinfo.absRowSums)

fprintf('\nBaseline X0 means by role (internal scale):\n');
fprintf('ordinary:\n');
disp(X0info.mean_ord)

fprintf('official:\n');
disp(X0info.mean_off)

fprintf('ewom:\n');
disp(X0info.mean_ew)

%% ============================================================
% 2) S0 baseline dynamics
% ============================================================
[Xhist_S0, dyn_S0] = run_dynamics_projectB(X0, W, lambda, C, roles, cfg);

fprintf('\n============================================\n');
fprintf('S0 baseline dynamics summary\n');
fprintf('============================================\n');

fprintf('Initial means (all):\n');
disp(dyn_S0.initial_all)

fprintf('Final means (all):\n');
disp(dyn_S0.final_all)

fprintf('Total change (all):\n');
disp(dyn_S0.total_change_all)

fprintf('Last-step max abs change: %.4e\n', dyn_S0.stepMaxAbs(end));

fprintf('\nFinal means by role:\n');
fprintf('ordinary:\n');
disp(dyn_S0.final_ord)

fprintf('official:\n');
disp(dyn_S0.final_off)

fprintf('ewom:\n');
disp(dyn_S0.final_ew)

fprintf('\nS0 key trajectory checkpoints (all agents):\n');
fprintf('t=0  : ');
disp(dyn_S0.mean_all(1,:))

fprintf('t=1  : ');
disp(dyn_S0.mean_all(2,:))

fprintf('t=5  : ');
disp(dyn_S0.mean_all(min(6,end),:))

fprintf('t=end: ');
disp(dyn_S0.mean_all(end,:))

%% ============================================================
% 3) Store results container
% ============================================================
results = struct();

results.cfg = cfg;
results.network.A = A;
results.network.deg = deg;
results.network.roles = roles;
results.network.idx = idx;
results.network.netinfo = netinfo;

results.baseline.W = W;
results.baseline.lambda = lambda;
results.baseline.self_w = self_w;
results.baseline.Winfo = Winfo;

results.baseline.X0 = X0;
results.baseline.X0info = X0info;

results.baseline.C = C;
results.baseline.Cinfo = Cinfo;

results.S0.Xhist = Xhist_S0;
results.S0.dyn = dyn_S0;

%% ============================================================
% 4) S1 runs
% ============================================================
for k = 1:numel(cfg.S1.deltaQ_list)

    deltaQ = cfg.S1.deltaQ_list(k);

    [X1, shockInfo] = apply_S1_quality_shock_projectB(X0, roles, cfg, deltaQ);
    [Xhist_S1, dyn_S1] = run_dynamics_projectB(X1, W, lambda, C, roles, cfg);

    fprintf('\n============================================\n');
    fprintf('S1 dynamics summary, deltaQ = %.2f\n', deltaQ);
    fprintf('============================================\n');

    fprintf('Scenario initial means (all):\n');
    disp(dyn_S1.initial_all)

    fprintf('Scenario final means (all):\n');
    disp(dyn_S1.final_all)

    fprintf('Scenario total change (all):\n');
    disp(dyn_S1.total_change_all)

    fprintf('Last-step max abs change: %.4e\n', dyn_S1.stepMaxAbs(end));

    fprintf('\nCompare final means vs S0 final:\n');
    disp(dyn_S1.final_all - dyn_S0.final_all)

    fprintf('\nFinal means by role:\n');
    fprintf('ordinary:\n');
    disp(dyn_S1.final_ord)

    fprintf('official:\n');
    disp(dyn_S1.final_off)

    fprintf('ewom:\n');
    disp(dyn_S1.final_ew)

    fprintf('\nKey trajectory checkpoints (all agents):\n');
    fprintf('t=0  : ');
    disp(dyn_S1.mean_all(1,:))

    fprintf('t=1  : ');
    disp(dyn_S1.mean_all(2,:))

    fprintf('t=5  : ');
    disp(dyn_S1.mean_all(min(6,end),:))

    fprintf('t=end: ');
    disp(dyn_S1.mean_all(end,:))

    % store by shock value
    tag = shock_tag(deltaQ);
    results.S1.(tag).deltaQ = deltaQ;
    results.S1.(tag).X1 = X1;
    results.S1.(tag).shockInfo = shockInfo;
    results.S1.(tag).Xhist = Xhist_S1;
    results.S1.(tag).dyn = dyn_S1;
end

%% ============================================================
% 5) Completion message
% ============================================================
fprintf('\n============================================\n');
fprintf('Backbone S0/S1 dynamics runner completed.\n');
fprintf('Available result fields:\n');
fprintf('  results.S0\n');
fprintf('  results.S1.%s\n', shock_tag(cfg.S1.deltaQ_main));
fprintf('  results.S1.%s\n', shock_tag(cfg.S1.deltaQ_extreme));
fprintf('============================================\n');

% Optional weak comparison case, not run by default:
%
% deltaQ = cfg.S1.deltaQ_weak;
% [X1_weak, shockInfo_weak] = apply_S1_quality_shock_projectB(X0, roles, cfg, deltaQ);
% [Xhist_S1_weak, dyn_S1_weak] = run_dynamics_projectB(X1_weak, W, lambda, C, roles, cfg);
% results.S1.(shock_tag(deltaQ)).deltaQ = deltaQ;
% results.S1.(shock_tag(deltaQ)).X1 = X1_weak;
% results.S1.(shock_tag(deltaQ)).shockInfo = shockInfo_weak;
% results.S1.(shock_tag(deltaQ)).Xhist = Xhist_S1_weak;
% results.S1.(shock_tag(deltaQ)).dyn = dyn_S1_weak;

%% ============================================================
% Local helper
% ============================================================
function tag = shock_tag(deltaQ)
    if deltaQ < 0
        tag = sprintf('neg_%02d', round(abs(deltaQ)*100));
    else
        tag = sprintf('pos_%02d', round(abs(deltaQ)*100));
    end
    tag = matlab.lang.makeValidName(tag);
end