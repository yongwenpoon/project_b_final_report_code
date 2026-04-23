function [X0, X0info] = generate_X0_projectB(roles, cfg)
%GENERATE_X0_PROJECTB
% Generate initial opinions X0 for Research Project B.
%
% Inputs:
%   roles : n x 1 role code vector
%   cfg   : config from get_cfg_projectB()
%
% Outputs:
%   X0     : n x m initial opinion matrix on cfg.scale.internal
%   X0info : diagnostics

    rng(cfg.seed.X0, 'twister');

    roles = roles(:);
    n = numel(roles);
    m = cfg.topic.m;

    if m ~= 3
        error('Project B currently expects exactly 3 topics: BT, Q, OM.');
    end
    if n ~= cfg.population.n
        error('Length of roles does not match cfg.population.n.');
    end

    roleOrd = cfg.role.code.ordinary;
    roleOff = cfg.role.code.official;
    roleEw  = cfg.role.code.ewom;

    idxOrd = find(roles == roleOrd);
    idxOff = find(roles == roleOff);
    idxEw  = find(roles == roleEw);

    if numel(idxOrd) ~= cfg.population.nOrd
        error('ordinary count mismatch in X0 generation.');
    end
    if numel(idxOff) ~= cfg.population.nOff
        error('official count mismatch in X0 generation.');
    end
    if numel(idxEw) ~= cfg.population.nEwom
        error('ewom count mismatch in X0 generation.');
    end

    X0 = zeros(n, m);

    % ------------------------------------------------------------
    % 1) Ordinary block
    % ------------------------------------------------------------
    switch lower(cfg.X0.ordinary.mode)
        case 'beta'
            X_ord_prob = sample_beta_block_from_mean_kappa( ...
                numel(idxOrd), ...
                cfg.X0.ordinary.mu, ...
                cfg.X0.ordinary.kappa);

        otherwise
            error('Unknown cfg.X0.ordinary.mode: %s', cfg.X0.ordinary.mode);
    end

    X0(idxOrd, :) = convert_prob_to_internal_scale(X_ord_prob, cfg);

    % ------------------------------------------------------------
    % 2) Official block
    % ------------------------------------------------------------
    switch lower(cfg.X0.official.mode)
        case 'fixed'
            X_off_prob = repmat(cfg.X0.official.fixed_prob, numel(idxOff), 1);

        otherwise
            error('Unknown cfg.X0.official.mode: %s', cfg.X0.official.mode);
    end

    if cfg.X0.special_noise_std_prob > 0
        X_off_prob = X_off_prob + cfg.X0.special_noise_std_prob .* randn(size(X_off_prob));
    end
    X_off_prob = min(max(X_off_prob, 0), 1);

    X0(idxOff, :) = convert_prob_to_internal_scale(X_off_prob, cfg);

    % ------------------------------------------------------------
    % 3) eWOM block
    % ------------------------------------------------------------
    switch lower(cfg.X0.ewom.mode)
        case 'fixed'
            X_ew_prob = repmat(cfg.X0.ewom.fixed_prob, numel(idxEw), 1);

        otherwise
            error('Unknown cfg.X0.ewom.mode: %s', cfg.X0.ewom.mode);
    end

    if cfg.X0.special_noise_std_prob > 0
        X_ew_prob = X_ew_prob + cfg.X0.special_noise_std_prob .* randn(size(X_ew_prob));
    end
    X_ew_prob = min(max(X_ew_prob, 0), 1);

    X0(idxEw, :) = convert_prob_to_internal_scale(X_ew_prob, cfg);

    % ------------------------------------------------------------
    % 4) Final clip on internal scale
    % ------------------------------------------------------------
    X0 = min(max(X0, cfg.scale.xmin), cfg.scale.xmax);

    % ------------------------------------------------------------
    % 5) Diagnostics
    % ------------------------------------------------------------
    X0info = struct();

    X0info.mean_all = mean(X0, 1);

    X0info.mean_ord = mean(X0(idxOrd,:), 1);
    X0info.mean_off = mean(X0(idxOff,:), 1);
    X0info.mean_ew  = mean(X0(idxEw,:), 1);

    X0info.std_ord = std(X0(idxOrd,:), 0, 1);
    X0info.std_off = std(X0(idxOff,:), 0, 1);
    X0info.std_ew  = std(X0(idxEw,:), 0, 1);

    X0info.idxOrd = idxOrd;
    X0info.idxOff = idxOff;
    X0info.idxEw  = idxEw;
end


% ================================================================
% Helper: sample Beta block from mean + kappa
% ================================================================
function X = sample_beta_block_from_mean_kappa(nRows, mu_vec, kappa_vec)

    mu_vec = mu_vec(:)';
    kappa_vec = kappa_vec(:)';

    m = numel(mu_vec);

    if numel(kappa_vec) ~= m
        error('mu_vec and kappa_vec must have the same length.');
    end

    X = zeros(nRows, m);

    for j = 1:m
        mu = mu_vec(j);
        kappa = kappa_vec(j);

        if mu <= 0 || mu >= 1
            error('Beta mean must lie in (0,1).');
        end
        if kappa <= 0
            error('Beta kappa must be > 0.');
        end

        a = mu * kappa;
        b = (1 - mu) * kappa;

        g1 = randg(a, nRows, 1);
        g2 = randg(b, nRows, 1);

        denom = g1 + g2;
        bad = (denom <= 0) | ~isfinite(denom);

        xj = g1 ./ denom;
        xj(bad) = mu;

        X(:, j) = xj;
    end
end


% ================================================================
% Helper: convert [0,1] probs to internal scale
% ================================================================
function X_internal = convert_prob_to_internal_scale(X_prob, cfg)

    switch lower(cfg.scale.internal)
        case 'prob'
            X_internal = X_prob;

        case 'att'
            X_internal = 2 .* X_prob - 1;

        otherwise
            error('Unknown cfg.scale.internal: %s', cfg.scale.internal);
    end
end