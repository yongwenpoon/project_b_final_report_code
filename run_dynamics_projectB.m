function [Xhist, dynInfo] = run_dynamics_projectB(Xinit, W, lambda, C, roles, cfg)
%RUN_DYNAMICS_PROJECTB
% Run multi-topic belief-system dynamics for Project B.
%
% Update rule:
%   X(t+1) = (I-Lambda) * Xinit + Lambda * W * X(t) * C'
%
% Inputs:
%   Xinit  : n x m scenario-specific initial state
%   W      : n x n influence matrix
%   lambda : n x 1 susceptibility vector
%   C      : m x m belief-system matrix
%   roles  : n x 1 role codes
%   cfg    : config struct
%
% Outputs:
%   Xhist   : n x m x (Tmax+1) trajectory tensor
%   dynInfo : diagnostics and summary trajectories

    [n, m] = size(Xinit);

    if size(W,1) ~= n || size(W,2) ~= n
        error('W must be n x n.');
    end
    if numel(lambda) ~= n
        error('lambda length must equal n.');
    end
    if size(C,1) ~= m || size(C,2) ~= m
        error('C must be m x m, matching Xinit columns.');
    end
    if numel(roles) ~= n
        error('roles length must equal n.');
    end

    lambda = lambda(:);
    roles  = roles(:);

    Tmax = cfg.sim.Tmax;

    Xhist = zeros(n, m, Tmax + 1);
    Xhist(:,:,1) = Xinit;

    stepMaxAbs = zeros(Tmax, 1);
    stepMeanAbs = zeros(Tmax, 1);

    for t = 1:Tmax
        Xcur = Xhist(:,:,t);

        social_term  = W * Xcur;          % n x m
        coupled_term = social_term * C';  % n x m

        Xnext = bsxfun(@times, (1 - lambda), Xinit) + ...
                bsxfun(@times, lambda, coupled_term);

        if cfg.sim.clip_each_step
            Xnext = min(max(Xnext, cfg.scale.xmin), cfg.scale.xmax);
        end

        Xhist(:,:,t+1) = Xnext;

        delta = Xnext - Xcur;
        stepMaxAbs(t) = max(abs(delta(:)));
        stepMeanAbs(t) = mean(abs(delta(:)));
    end

    % ------------------------------------------------------------
    % Diagnostics
    % ------------------------------------------------------------
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
    dynInfo.Tmax = Tmax;
    dynInfo.stepMaxAbs = stepMaxAbs;
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