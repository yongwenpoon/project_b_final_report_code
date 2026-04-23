function [W, lambda, self_w, Winfo] = build_W_lambda_projectB(A, deg, roles, cfg)
%BUILD_W_LAMBDA_PROJECTB
% Build W and lambda for Research Project B.
%
% Inputs:
%   A      : n x n adjacency matrix
%   deg    : n x 1 degree vector
%   roles  : n x 1 role codes
%   cfg    : config struct from get_cfg_projectB()
%
% Outputs:
%   W      : n x n row-stochastic influence matrix
%   lambda : n x 1 susceptibility vector, lambda = 1 - diag(W)
%   self_w : n x 1 self-weight vector
%   Winfo  : diagnostic info

    n = size(A, 1);

    if size(A,2) ~= n
        error('A must be square.');
    end
    if numel(deg) ~= n
        error('deg length must match size(A,1).');
    end
    if numel(roles) ~= n
        error('roles length must match size(A,1).');
    end

    if ~isequal(A, A')
        error('A must be symmetric for the current undirected setting.');
    end
    if any(diag(A) ~= 0)
        error('A must not contain self-loops.');
    end

    deg = deg(:);
    roles = roles(:);

    W = zeros(n, n);
    self_w = zeros(n, 1);

    gamma = cfg.W.degree_bias_gamma;
    kDir  = cfg.W.dirichlet_scale_k;

    % ------------------------------------------------------------
    % 1) Build row by row
    % ------------------------------------------------------------
    for i = 1:n
        nbrs = find(A(i,:) > 0);

        if isempty(nbrs)
            error('Agent %d has no neighbours. Cannot build W row.', i);
        end

        % self-weight by role
        self_w(i) = draw_self_weight_by_role(roles(i), cfg);

        if self_w(i) <= 0 || self_w(i) >= 1
            error('Self-weight for agent %d is outside (0,1).', i);
        end

        remain = 1 - self_w(i);

        % degree-biased Dirichlet over neighbours
        bias = deg(nbrs) .^ gamma;
        if all(bias <= 0)
            bias = ones(size(bias));
        end
        bias = bias / sum(bias);

        alpha = kDir * bias;
        p = dirichlet_sample(alpha);

        % fill row i
        W(i, i) = self_w(i);
        W(i, nbrs) = remain * p;
    end

    % ------------------------------------------------------------
    % 2) Final diagnostics / cleanup
    % ------------------------------------------------------------
    row_sums = sum(W, 2);

    % small numerical cleanup
    for i = 1:n
        if abs(row_sums(i) - 1) > 1e-10
            W(i,:) = W(i,:) / row_sums(i);
        end
    end

    row_sums = sum(W, 2);
    if max(abs(row_sums - 1)) > 1e-8
        error('W is not row-stochastic after cleanup.');
    end

    if any(W(:) < -1e-12)
        error('W contains negative entries.');
    end

    lambda = 1 - diag(W);

    % ------------------------------------------------------------
    % 3) Package diagnostics
    % ------------------------------------------------------------
    roleOrd = cfg.role.code.ordinary;
    roleOff = cfg.role.code.official;
    roleEw  = cfg.role.code.ewom;

    idxOrd = find(roles == roleOrd);
    idxOff = find(roles == roleOff);
    idxEw  = find(roles == roleEw);

    Winfo = struct();
    Winfo.row_sum_max_abs_err = max(abs(sum(W,2) - 1));
    Winfo.mean_self_all = mean(self_w);
    Winfo.mean_lambda_all = mean(lambda);

    Winfo.mean_self_ord = mean(self_w(idxOrd));
    Winfo.mean_self_off = mean(self_w(idxOff));
    Winfo.mean_self_ew  = mean(self_w(idxEw));

    Winfo.mean_lambda_ord = mean(lambda(idxOrd));
    Winfo.mean_lambda_off = mean(lambda(idxOff));
    Winfo.mean_lambda_ew  = mean(lambda(idxEw));
end


% ================================================================
% Draw self-weight by role
% ================================================================
function s = draw_self_weight_by_role(roleCode, cfg)

    rOrd = cfg.role.code.ordinary;
    rOff = cfg.role.code.official;
    rEw  = cfg.role.code.ewom;

    switch lower(cfg.self.mode)
        case 'fixed_by_role'
            if roleCode == rOrd
                s = cfg.self.fixed.ordinary;
            elseif roleCode == rOff
                s = cfg.self.fixed.official;
            elseif roleCode == rEw
                s = cfg.self.fixed.ewom;
            else
                error('Unknown role code: %d', roleCode);
            end

        case 'beta_by_role'
            if roleCode == rOrd
                s = beta_sample_from_mean_kappa( ...
                    cfg.self.beta.ordinary.mean, ...
                    cfg.self.beta.ordinary.kappa);
            elseif roleCode == rOff
                s = beta_sample_from_mean_kappa( ...
                    cfg.self.beta.official.mean, ...
                    cfg.self.beta.official.kappa);
            elseif roleCode == rEw
                s = beta_sample_from_mean_kappa( ...
                    cfg.self.beta.ewom.mean, ...
                    cfg.self.beta.ewom.kappa);
            else
                error('Unknown role code: %d', roleCode);
            end

        otherwise
            error('Unknown cfg.self.mode: %s', cfg.self.mode);
    end
end


% ================================================================
% Sample from Dirichlet(alpha) using Gamma draws
% ================================================================
function p = dirichlet_sample(alpha)

    alpha = alpha(:)';
    if any(alpha <= 0)
        error('Dirichlet alpha must be strictly positive.');
    end

    g = randg(alpha);

    if sum(g) <= 0 || any(~isfinite(g))
        % fallback to normalized alpha
        p = alpha / sum(alpha);
    else
        p = g / sum(g);
    end
end


% ================================================================
% Beta sample from mean + kappa using Gamma trick
% ================================================================
function x = beta_sample_from_mean_kappa(mu, kappa)

    if mu <= 0 || mu >= 1
        error('Beta mean must lie in (0,1).');
    end
    if kappa <= 0
        error('Beta kappa must be > 0.');
    end

    a = mu * kappa;
    b = (1 - mu) * kappa;

    g1 = randg(a);
    g2 = randg(b);

    if (g1 + g2) <= 0 || ~isfinite(g1 + g2)
        x = mu;
    else
        x = g1 / (g1 + g2);
    end
end