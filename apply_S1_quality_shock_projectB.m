function [X1, shockInfo] = apply_S1_quality_shock_projectB(X0, roles, cfg, deltaQ)
%APPLY_S1_QUALITY_SHOCK_PROJECTB
% Apply Scenario 1 (quality crisis) direct shock to Q only.
%
% Rules:
%   - shock topic: Q only
%   - shocked roles: ordinary + ewom
%   - official: no direct shock
%   - C, W, lambda unchanged here
%
% Inputs:
%   X0     : n x m baseline initial opinions on internal scale
%   roles  : n x 1 role codes
%   cfg    : config struct
%   deltaQ : scalar shock magnitude on internal scale (e.g. -0.35, -0.70)
%
% Outputs:
%   X1        : shocked initial state for S1
%   shockInfo : diagnostics

    if nargin < 4 || isempty(deltaQ)
        deltaQ = cfg.S1.deltaQ_list(1);
    end

    [n, m] = size(X0);

    if n ~= cfg.population.n
        error('X0 row count does not match cfg.population.n.');
    end
    if m ~= cfg.topic.m
        error('X0 column count does not match cfg.topic.m.');
    end
    if numel(roles) ~= n
        error('roles length does not match X0 row count.');
    end

    roles = roles(:);

    qIdx  = cfg.topic.idx.Q;
    btIdx = cfg.topic.idx.BT;
    omIdx = cfg.topic.idx.OM;

    roleOrd = cfg.role.code.ordinary;
    roleOff = cfg.role.code.official;
    roleEw  = cfg.role.code.ewom;

    idxOrd = find(roles == roleOrd);
    idxOff = find(roles == roleOff);
    idxEw  = find(roles == roleEw);

    % ------------------------------------------------------------
    % 1) Decide which agents get direct Q shock
    % ------------------------------------------------------------
    shockMask = false(n,1);

    if cfg.S1.shock_ordinary
        shockMask(idxOrd) = true;
    end
    if cfg.S1.shock_official
        shockMask(idxOff) = true;
    end
    if cfg.S1.shock_ewom
        shockMask(idxEw) = true;
    end

    % ------------------------------------------------------------
    % 2) Apply shock to Q only
    % ------------------------------------------------------------
    X1 = X0;

    q_before = X0(:, qIdx);

    X1(shockMask, qIdx) = X1(shockMask, qIdx) + deltaQ;

    % clip to internal scale bounds
    q_after_preclip = X1(:, qIdx);
    X1(:, qIdx) = min(max(X1(:, qIdx), cfg.scale.xmin), cfg.scale.xmax);
    q_after = X1(:, qIdx);

    % ------------------------------------------------------------
    % 3) Diagnostics
    % ------------------------------------------------------------
    clippedMask = abs(q_after - q_after_preclip) > 1e-12;

    shockInfo = struct();
    shockInfo.deltaQ = deltaQ;
    shockInfo.q_topic_index = qIdx;
    shockInfo.num_shocked_total = sum(shockMask);
    shockInfo.num_clipped_total = sum(clippedMask);

    shockInfo.idx_shocked = find(shockMask);
    shockInfo.idx_clipped = find(clippedMask);

    shockInfo.num_shocked_ord = sum(shockMask(idxOrd));
    shockInfo.num_shocked_off = sum(shockMask(idxOff));
    shockInfo.num_shocked_ew  = sum(shockMask(idxEw));

    % means before / after on Q
    shockInfo.q_mean_before_all = mean(X0(:, qIdx));
    shockInfo.q_mean_after_all  = mean(X1(:, qIdx));

    shockInfo.q_mean_before_ord = mean(X0(idxOrd, qIdx));
    shockInfo.q_mean_after_ord  = mean(X1(idxOrd, qIdx));

    shockInfo.q_mean_before_off = mean(X0(idxOff, qIdx));
    shockInfo.q_mean_after_off  = mean(X1(idxOff, qIdx));

    shockInfo.q_mean_before_ew = mean(X0(idxEw, qIdx));
    shockInfo.q_mean_after_ew  = mean(X1(idxEw, qIdx));

    % sanity checks on untouched topics
    shockInfo.max_abs_change_BT = max(abs(X1(:, btIdx) - X0(:, btIdx)));
    shockInfo.max_abs_change_OM = max(abs(X1(:, omIdx) - X0(:, omIdx)));

    % official direct-shock check
    shockInfo.max_abs_direct_change_official_Q = max(abs(X1(idxOff, qIdx) - X0(idxOff, qIdx)));
end