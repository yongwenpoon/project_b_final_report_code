function [A, deg, roles, idx, netinfo] = generate_network_projectB(cfg)
%GENERATE_NETWORK_PROJECTB
% Build the BA network and assign Project B roles:
%   ordinary / official / ewom
%
% Usage:
%   cfg = get_cfg_projectB('main');
%   [A, deg, roles, idx, netinfo] = generate_network_projectB(cfg);

    rng(cfg.seed.network, 'twister');

    % ------------------------------------------------------------
    % 1) Read key parameters
    % ------------------------------------------------------------
    n    = cfg.population.n;
    nOff = cfg.population.nOff;
    nEw  = cfg.population.nEwom;

    roleOrd = cfg.role.code.ordinary;
    roleOff = cfg.role.code.official;
    roleEw  = cfg.role.code.ewom;

    if ~strcmpi(cfg.network.type, 'BA')
        error('Currently only BA network is implemented.');
    end

    mBA = cfg.network.mBA;

    % ------------------------------------------------------------
    % 2) Generate BA adjacency matrix
    % ------------------------------------------------------------
    A = generate_BA_adjacency(n, mBA);

    % Basic checks
    if ~isequal(A, A')
        error('Adjacency matrix A must be symmetric for undirected BA network.');
    end
    if any(diag(A) ~= 0)
        error('Adjacency matrix A should not contain self-loops.');
    end

    deg = sum(A, 2);

    % ------------------------------------------------------------
    % 3) Assign roles
    % ------------------------------------------------------------
    switch lower(cfg.network.role_assignment_mode)
        case 'highest_degree'
            [roles, idx, hub_order, off_nodes, ew_nodes] = ...
                assign_roles_highest_degree(deg, nOff, nEw, roleOrd, roleOff, roleEw);

        case 'random'
            [roles, idx, hub_order, off_nodes, ew_nodes] = ...
                assign_roles_random(n, nOff, nEw, roleOrd, roleOff, roleEw);

        otherwise
            error('Unknown role_assignment_mode: %s', cfg.network.role_assignment_mode);
    end

    % ------------------------------------------------------------
    % 4) Package network info
    % ------------------------------------------------------------
    netinfo = struct();
    netinfo.seed = cfg.seed.network;
    netinfo.hub_order = hub_order;
    netinfo.mean_degree = mean(deg);
    netinfo.max_degree = max(deg);
    netinfo.min_degree = min(deg);

    % connectivity check
    netinfo.is_connected = is_graph_connected(A);

    netinfo.assigned_official_nodes = off_nodes;
    netinfo.assigned_ewom_nodes     = ew_nodes;

    % final count checks
    if numel(idx.ordinary) ~= cfg.population.nOrd
        error('ordinary count mismatch.');
    end
    if numel(idx.official) ~= cfg.population.nOff
        error('official count mismatch.');
    end
    if numel(idx.ewom) ~= cfg.population.nEwom
        error('ewom count mismatch.');
    end
end


% ================================================================
% BA adjacency generator
% ================================================================
function A = generate_BA_adjacency(n, mBA)
% Pure MATLAB BA generator (undirected, no self-loops)
%
% Start with a fully connected core of size mBA+1,
% then add one node at a time with mBA preferential attachments.

    if n < (mBA + 1)
        error('n must be at least mBA + 1.');
    end
    if mBA < 1
        error('mBA must be >= 1.');
    end

    A = zeros(n, n);

    % initial complete core
    m0 = mBA + 1;
    A(1:m0, 1:m0) = ones(m0) - eye(m0);

    deg = sum(A, 2);

    % add nodes one by one
    for newNode = (m0 + 1):n
        existing = 1:(newNode - 1);
        weights = deg(existing);

        if sum(weights) <= 0
            weights = ones(size(existing));
        end

        targets = weighted_sample_without_replacement(existing, weights, mBA);

        A(newNode, targets) = 1;
        A(targets, newNode) = 1;

        deg(newNode) = numel(targets);
        deg(targets) = deg(targets) + 1;
    end

    if ~isequal(A, A')
        error('BA generator produced a non-symmetric adjacency matrix.');
    end
end

% ================================================================
% Weighted sample without replacement
% ================================================================
function picked = weighted_sample_without_replacement(candidates, weights, k)

    if numel(candidates) < k
        error('Not enough candidates to sample k items.');
    end

    picked = zeros(1, k);

    cand = candidates(:)';
    w    = weights(:)';

    for t = 1:k
        p = w / sum(w);
        u = rand();
        cdf = cumsum(p);
        j = find(u <= cdf, 1, 'first');

        picked(t) = cand(j);

        % remove chosen candidate
        cand(j) = [];
        w(j) = [];
    end
end


% ================================================================
% Role assignment: highest degree
% ================================================================
function [roles, idx, hub_order, off_nodes, ew_nodes] = assign_roles_highest_degree(deg, nOff, nEw, roleOrd, roleOff, roleEw)

    n = numel(deg);

    if (nOff + nEw) >= n
        error('Too many special-role agents for total n.');
    end

    % deterministic tie-breaker: degree desc, index asc
    M = [-deg(:), (1:n)'];
    [~, hub_order] = sortrows(M, [1 2]);

    off_nodes = hub_order(1:nOff);
    ew_nodes  = hub_order(nOff+1:nOff+nEw);

    roles = roleOrd * ones(n,1);
    roles(off_nodes) = roleOff;
    roles(ew_nodes)  = roleEw;

    idx = build_idx_struct(roles, roleOrd, roleOff, roleEw);
end


% ================================================================
% Role assignment: random
% ================================================================
function [roles, idx, order, off_nodes, ew_nodes] = assign_roles_random(n, nOff, nEw, roleOrd, roleOff, roleEw)

    if (nOff + nEw) >= n
        error('Too many special-role agents for total n.');
    end

    order = randperm(n);

    off_nodes = order(1:nOff);
    ew_nodes  = order(nOff+1:nOff+nEw);

    roles = roleOrd * ones(n,1);
    roles(off_nodes) = roleOff;
    roles(ew_nodes)  = roleEw;

    idx = build_idx_struct(roles, roleOrd, roleOff, roleEw);
end


% ================================================================
% Build idx struct
% ================================================================
function idx = build_idx_struct(roles, roleOrd, roleOff, roleEw)

    idx = struct();
    idx.ordinary = find(roles == roleOrd);
    idx.official = find(roles == roleOff);
    idx.ewom     = find(roles == roleEw);
end


% ================================================================
% Connectivity check
% ================================================================
function tf = is_graph_connected(A)

    n = size(A,1);
    visited = false(n,1);
    stack = 1;
    visited(1) = true;

    while ~isempty(stack)
        v = stack(end);
        stack(end) = [];

        nbrs = find(A(v,:) > 0);
        new_nodes = nbrs(~visited(nbrs));
        visited(new_nodes) = true;
        stack = [stack, new_nodes]; %#ok<AGROW>
    end

    tf = all(visited);
end