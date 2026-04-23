function [C, Cinfo] = build_C_projectB(cfg)
%BUILD_C_PROJECTB
% Build the baseline topic-logic matrix C used in the final-report analyses.
%
% Current implementation:
%   - one shared baseline C across agents
%   - no scenario-specific modification inside this function
%
% Inputs:
%   cfg : config struct from get_cfg_projectB()
%
% Outputs:
%   C     : m x m topic-logic matrix
%   Cinfo : diagnostics

    if ~isfield(cfg, 'C')
        error('cfg.C is missing.');
    end

    if ~isfield(cfg.C, 'mode')
        error('cfg.C.mode is missing.');
    end

    if ~isfield(cfg.C, 'base')
        error('cfg.C.base is missing.');
    end

    switch lower(cfg.C.mode)
        case 'shared_baseline'
            C = cfg.C.base;

        otherwise
            error('Unknown cfg.C.mode: %s', cfg.C.mode);
    end

    % ------------------------------------------------------------
    % Basic validation
    % ------------------------------------------------------------
    m = cfg.topic.m;

    if size(C,1) ~= m || size(C,2) ~= m
        error('C must be %d x %d.', m, m);
    end

    % Baseline expectation:
    % BT row depends on BT, Q, and OM
    % Q row does not depend on BT
    % OM row does not depend on BT
    bt = cfg.topic.idx.BT;
    q  = cfg.topic.idx.Q;
    om = cfg.topic.idx.OM;

    % helpful checks, not hard restrictions beyond the current baseline
    if abs(C(q, bt)) > 1e-12
        warning('Current baseline expects C(Q,BT)=0, but got %.4g.', C(q, bt));
    end
    if abs(C(om, bt)) > 1e-12
        warning('Current baseline expects C(OM,BT)=0, but got %.4g.', C(om, bt));
    end

    rowSums = sum(C, 2);
    absRowSums = sum(abs(C), 2);

    Cinfo = struct();
    Cinfo.mode = cfg.C.mode;
    Cinfo.rowSums = rowSums;
    Cinfo.absRowSums = absRowSums;
    Cinfo.isSquare = true;
    Cinfo.isSharedAcrossRoles = true;

    Cinfo.topic_order = cfg.topic.names;
    Cinfo.BT_row = C(bt, :);
    Cinfo.Q_row  = C(q, :);
    Cinfo.OM_row = C(om, :);

    Cinfo.summary = [ ...
        "BT is downstream and depends on BT/Q/OM"; ...
        "Q is mainly self-maintaining with weak OM coupling"; ...
        "OM is mainly self-maintaining with weak Q coupling" ...
    ];
end