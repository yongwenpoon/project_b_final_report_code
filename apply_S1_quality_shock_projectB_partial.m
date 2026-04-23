function [X1, shockInfo] = apply_S1_quality_shock_projectB_partial(X0, roles, cfg, deltaQ, idxOrdExposed)
%APPLY_S1_QUALITY_SHOCK_PROJECTB_PARTIAL
% Apply S1 direct shock to:
%   - a selected subset of ordinary consumers
%   - all eWOM agents (if enabled)
%   - no official agents by default
%
% Inputs:
%   X0            : n x m initial state (internal scale)
%   roles         : n x 1 role codes
%   cfg           : config struct
%   deltaQ        : shock magnitude on internal scale
%   idxOrdExposed : indices of ordinary consumers who directly receive shock
%
% Outputs:
%   X1        : shocked state
%   shockInfo : diagnostics

    if nargin < 5
        error('idxOrdExposed must be provided for partial exposure.');
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
    idxOrdExposed = idxOrdExposed(:);

    qIdx  = cfg.topic.idx.Q;
    btIdx = cfg.topic.idx.BT;
    omIdx = cfg.topic.idx.OM;

    roleOrd = cfg.role.code.ordinary;
    roleOff = cfg.role.code.official;
    roleEw  = cfg.role.code.ewom;

    idxOrd = find(roles == roleOrd);
    idxOff = find(roles == roleOff);
    idxEw  = find(roles == roleEw);

    % sanity check: exposed ordinary indices must belong to ordinary set
    if ~all(ismember(idxOrdExposed, idxOrd))
        error('idxOrdExposed contains non-ordinary agents.');
    end

    shockMask = false(n,1);

    % ordinary: partial exposure set
    shockMask(idxOrdExposed) = true;

    % eWOM: fully exposed if requested
    if cfg.S1.keep_ewom_fully_exposed
        shockMask(idxEw) = true;
    end

    % official: keep unshocked by default
    if cfg.S1.shock_official
        shockMask(idxOff) = true;
    end

    X1 = X0;

    q_before = X0(:, qIdx);
    X1(shockMask, qIdx) = X1(shockMask, qIdx) + deltaQ;

    q_after_preclip = X1(:, qIdx);
    X1(:, qIdx) = min(max(X1(:, qIdx), cfg.scale.xmin), cfg.scale.xmax);
    q_after = X1(:, qIdx);

    clippedMask = abs(q_after - q_after_preclip) > 1e-12;

    shockInfo = struct();
    shockInfo.deltaQ = deltaQ;
    shockInfo.q_topic_index = qIdx;

    shockInfo.idxOrdExposed = idxOrdExposed;
    shockInfo.idxEwExposed  = idxEw;
    shockInfo.idxOffExposed = find(shockMask(idxOff));

    shockInfo.numOrdExposed = numel(idxOrdExposed);
    shockInfo.numOrdTotal   = numel(idxOrd);
    shockInfo.ordinaryExposureRate = numel(idxOrdExposed) / numel(idxOrd);

    shockInfo.numEwExposed = sum(shockMask(idxEw));
    shockInfo.numOffExposed = sum(shockMask(idxOff));
    shockInfo.numShockedTotal = sum(shockMask);

    shockInfo.numClippedTotal = sum(clippedMask);

    shockInfo.q_mean_before_all = mean(X0(:, qIdx));
    shockInfo.q_mean_after_all  = mean(X1(:, qIdx));

    shockInfo.q_mean_before_ord = mean(X0(idxOrd, qIdx));
    shockInfo.q_mean_after_ord  = mean(X1(idxOrd, qIdx));

    shockInfo.q_mean_before_off = mean(X0(idxOff, qIdx));
    shockInfo.q_mean_after_off  = mean(X1(idxOff, qIdx));

    shockInfo.q_mean_before_ew = mean(X0(idxEw, qIdx));
    shockInfo.q_mean_after_ew  = mean(X1(idxEw, qIdx));

    shockInfo.max_abs_change_BT = max(abs(X1(:, btIdx) - X0(:, btIdx)));
    shockInfo.max_abs_change_OM = max(abs(X1(:, omIdx) - X0(:, omIdx)));
end