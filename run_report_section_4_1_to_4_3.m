clear; clc; close all;

%% ============================================================
% Final-report runner for Project B: Sections 4.1-4.3
%
% Purpose:
%   1) Run the main S0/S1 dynamics pipeline
%   2) Generate final-report figures for Sections 4.1-4.3
%   3) Generate Appendix Figure A1
%   4) Export compact summary tables used in the report
%
% Main outputs:
%   Figures:
%     - Figure_4_1_S0_Baseline_AllAgents.png
%     - Figure_4_2_S1_MainShock_AllAgents.png
%     - Figure_4_3_BT_ByRole_S0_vs_S1.png
%     - Appendix_A1_RoleSpecific_AllTopics.png
%
%   Tables:
%     - Table_4_2_S0_vs_S1_AllAgentSummary.csv
%     - Table_4_3_BT_ByRole_MainShock.csv
%
% Notes:
%   - This script is the report-facing entry point for Sections 4.1-4.3.
%   - It uses the existing Project B backbone and main S0/S1 runner.
% ============================================================

fprintf('\n============================================================\n');
fprintf('Project B final-report runner: Sections 4.1-4.3\n');
fprintf('============================================================\n');

%% ------------------------------------------------------------
% Run the main S0/S1 dynamics pipeline
% ------------------------------------------------------------
run_S0_S1_dynamics_projectB_single;

%% ------------------------------------------------------------
% Basic safety checks
% ------------------------------------------------------------
if ~exist('results', 'var')
    error(['`results` was not found after running run_S0_S1_dynamics_projectB_single. ', ...
           'Please check that the main dynamics runner still outputs `results`.']);
end

if ~exist('cfg', 'var')
    error(['`cfg` was not found after running run_S0_S1_dynamics_projectB_single. ', ...
           'Please check that the main dynamics runner still outputs `cfg`.']);
end

%% ------------------------------------------------------------
% Report export settings
% ------------------------------------------------------------
cfg.export = struct();
cfg.export.save_fig = true;
cfg.export.outdir   = fullfile(pwd, 'report_outputs_4_1_to_4_3');

if ~exist(cfg.export.outdir, 'dir')
    mkdir(cfg.export.outdir);
end

%% ------------------------------------------------------------
% Generate report figures
% ------------------------------------------------------------
plot_report_section_4_1_to_4_3(results, cfg);

%% ------------------------------------------------------------
% Build compact report tables
% ------------------------------------------------------------
mainTag = choose_main_shock_tag_local(results, cfg);

bt = cfg.topic.idx.BT;
topicNames = string(cfg.topic.names(:));

% ---- Table for Section 4.2: all-agent S0 vs S1 main shock summary ----
S0_final_all = results.S0.dyn.final_all(:);
S1_final_all = results.S1.(mainTag).dyn.final_all(:);
Diff_all     = S1_final_all - S0_final_all;

T_all = table( ...
    topicNames, ...
    S0_final_all, ...
    S1_final_all, ...
    Diff_all, ...
    'VariableNames', {'Topic','S0_Final','S1_Final','Diff_S1_minus_S0'} ...
);

% ---- Table for Section 4.3: BT by role under S0 and S1 ----
nOrd = numel(results.network.idx.ordinary);
nOff = numel(results.network.idx.official);
nEw  = numel(results.network.idx.ewom);

Role = ["ordinary consumers"; "official agents"; "eWOM influencers"];
Role_Count = [nOrd; nOff; nEw];

S0_Final_BT = [ ...
    results.S0.dyn.final_ord(bt); ...
    results.S0.dyn.final_off(bt); ...
    results.S0.dyn.final_ew(bt) ...
];

S1_Final_BT = [ ...
    results.S1.(mainTag).dyn.final_ord(bt); ...
    results.S1.(mainTag).dyn.final_off(bt); ...
    results.S1.(mainTag).dyn.final_ew(bt) ...
];

% Report-facing decline magnitude: positive means larger decline
BT_Decline_vs_S0 = S0_Final_BT - S1_Final_BT;

T_bt_role = table( ...
    Role, ...
    Role_Count, ...
    S0_Final_BT, ...
    S1_Final_BT, ...
    BT_Decline_vs_S0, ...
    'VariableNames', {'Role','Role_Count','S0_Final_BT','S1_Final_BT','BT_Decline_vs_S0'} ...
);

%% ------------------------------------------------------------
% Save tables
% ------------------------------------------------------------
tableA_path = fullfile(cfg.export.outdir, 'Table_4_2_S0_vs_S1_AllAgentSummary.csv');
tableB_path = fullfile(cfg.export.outdir, 'Table_4_3_BT_ByRole_MainShock.csv');

writetable(T_all, tableA_path);
writetable(T_bt_role, tableB_path);

%% ------------------------------------------------------------
% Print compact summaries
% ------------------------------------------------------------
disp(' ');
disp('============================================================');
disp('Table 4.2 summary: S0 vs S1 main shock, all-agent outcomes');
disp('============================================================');
disp(T_all);

disp(' ');
disp('============================================================');
disp('Table 4.3 summary: BT by role under S0 and S1 main shock');
disp('============================================================');
disp(T_bt_role);

%% ------------------------------------------------------------
% Final message
% ------------------------------------------------------------
fprintf('\n============================================================\n');
fprintf('Report outputs generated for Sections 4.1-4.3.\n');
fprintf('Output folder:\n  %s\n', cfg.export.outdir);
fprintf('\nFigures saved:\n');
fprintf('  - Figure_4_1_S0_Baseline_AllAgents.png\n');
fprintf('  - Figure_4_2_S1_MainShock_AllAgents.png\n');
fprintf('  - Figure_4_3_BT_ByRole_S0_vs_S1.png\n');
fprintf('  - Appendix_A1_RoleSpecific_AllTopics.png\n');
fprintf('\nTables saved:\n');
fprintf('  - Table_4_2_S0_vs_S1_AllAgentSummary.csv\n');
fprintf('  - Table_4_3_BT_ByRole_MainShock.csv\n');
fprintf('============================================================\n');

%% ============================================================
% Local helper
% ============================================================
function mainTag = choose_main_shock_tag_local(results, cfg)
% Prefer the tag matching cfg.S1.deltaQ_main; otherwise use first available

    tags = fieldnames(results.S1);
    mainTag = '';

    if isfield(cfg, 'S1') && isfield(cfg.S1, 'deltaQ_main')
        target = cfg.S1.deltaQ_main;
        for i = 1:numel(tags)
            if abs(results.S1.(tags{i}).deltaQ - target) < 1e-12
                mainTag = tags{i};
                return;
            end
        end
    end

    mainTag = tags{1};
end