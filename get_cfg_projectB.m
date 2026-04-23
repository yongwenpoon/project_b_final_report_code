function cfg = get_cfg_projectB(presetName)
%GET_CFG_PROJECTB  Unified configuration for Research Project B
%
% Usage:
%   cfg = get_cfg_projectB();        % default = 'main'
%   cfg = get_cfg_projectB('debug');
%   cfg = get_cfg_projectB('main');
%
% This configuration is the single source of truth for:
%   - population and roles
%   - topics
%   - network generation
%   - role assignment
%   - self-weight and lambda
%   - X0 generation
%   - baseline topic logic C
%   - Scenario S1 shock settings
%   - seeds and run controls
%
% Core usage in the repository:
%   [A, deg, roles, idx] = generate_network_projectB(cfg);
%   [W, lambda]          = build_W_lambda_projectB(A, deg, roles, cfg);
%   X0                   = generate_X0_projectB(roles, cfg);

    if nargin < 1 || isempty(presetName)
        presetName = 'main';
    end

    %% ------------------------------------------------------------
    % 0) Meta
    % -------------------------------------------------------------
    cfg.project_name = 'ResearchProjectB';
    cfg.preset       = lower(string(presetName));
    cfg.version      = 'final_report_cfg_v1';

    %% ------------------------------------------------------------
    % 1) Topics
    % -------------------------------------------------------------
    cfg.topic.names = {'BT','Q','OM'};
    cfg.topic.long_names = { ...
        'Brand Trust', ...
        'Quality', ...
        'Official Message'};
    cfg.topic.m = numel(cfg.topic.names);

    % fixed index map for convenience
    cfg.topic.idx.BT = 1;
    cfg.topic.idx.Q  = 2;
    cfg.topic.idx.OM = 3;

    %% ------------------------------------------------------------
    % 2) Scale
    % -------------------------------------------------------------
    % Internal simulation scale:
    %   'att'  => [-1,1]
    %   'prob' => [0,1]
    %
    % Current report configuration uses the attitude scale [-1,1].
    cfg.scale.internal = 'att';
    cfg.scale.xmin = -1;
    cfg.scale.xmax =  1;

    %% ------------------------------------------------------------
    % 3) Preset-dependent population size and special counts
    % -------------------------------------------------------------
    cfg.population.count_mode = 'absolute';
    % options:
    %   'absolute' : use nOff / nEwom directly
    %   'ratio'    : derive counts from ratioOff / ratioEwom with min constraints

    switch cfg.preset
        case "debug"
            cfg.population.n      = 200;
            cfg.population.nOff   = 1;
            cfg.population.nEwom  = 2;

        case "main"
            cfg.population.n      = 1000;
            cfg.population.nOff   = 2;
            cfg.population.nEwom  = 8;

        otherwise
            error('Unknown preset: %s. Use ''debug'' or ''main''.', cfg.preset);
    end

    % ratio inputs retained as optional settings
    cfg.population.ratioOff  = 0.002;   % 0.2%
    cfg.population.ratioEwom = 0.008;   % 0.8%
    cfg.population.minOff    = 1;
    cfg.population.minEwom   = 1;

    % resolve counts
    cfg.population = resolve_population_counts(cfg.population);

    %% ------------------------------------------------------------
    % 4) Role labels
    % -------------------------------------------------------------
    cfg.role.names = {'ordinary','official','ewom'};
    cfg.role.code.ordinary = 1;
    cfg.role.code.official = 2;
    cfg.role.code.ewom     = 3;

    %% ------------------------------------------------------------
    % 5) Network
    % -------------------------------------------------------------
    cfg.network.type = 'BA';
    cfg.network.mBA  = 4;     % average degree about 2*mBA ~ 8
    cfg.network.directed = false;

    % Role assignment over the generated graph
    cfg.network.role_assignment_mode = 'highest_degree';
    % optional values:
    %   'highest_degree'
    %   'random'

    %% ------------------------------------------------------------
    % 6) W / self-weight / lambda
    % -------------------------------------------------------------
    % Default setting:
    %   fixed self-weight by role
    % Optional alternative:
    %   beta_by_role
    cfg.self.mode = 'fixed_by_role';
    % options:
    %   'fixed_by_role'
    %   'beta_by_role'

    % ---- Default fixed self-weights
    cfg.self.fixed.ordinary = 0.20;
    cfg.self.fixed.official = 0.95;
    cfg.self.fixed.ewom     = 0.85;

    % ---- Optional beta-by-role settings
    % mean + kappa => Beta(alpha,beta)
    cfg.self.beta.ordinary.mean  = 0.60;
    cfg.self.beta.ordinary.kappa = 30;

    cfg.self.beta.official.mean  = 0.95;
    cfg.self.beta.official.kappa = 200;

    cfg.self.beta.ewom.mean      = 0.85;
    cfg.self.beta.ewom.kappa     = 80;

    % neighbour weight allocation after self-weight:
    % remaining mass is distributed across neighbours
    % using degree-biased Dirichlet
    cfg.W.neighbour_weight_mode = 'degree_biased_dirichlet';
    cfg.W.degree_bias_gamma = 1.0;   % 0 => uniform over neighbours
    cfg.W.dirichlet_scale_k = 25;    % larger => less random dispersion

    %% ------------------------------------------------------------
    % 7) X0 generation
    % -------------------------------------------------------------
    % ordinary: Beta on [0,1], then map to internal scale if needed
    cfg.X0.ordinary.mode = 'beta';

    cfg.X0.ordinary.mu    = [0.76, 0.78, 0.60];
    cfg.X0.ordinary.kappa = [15,   15,   12];

    % optional topic correlation for ordinary block
    cfg.X0.ordinary.corr = 0.0;

    % official: fixed on [0,1], then map if needed
    cfg.X0.official.mode = 'fixed';
    cfg.X0.official.fixed_prob = [0.92, 0.95, 1.00];

    % ewom: fixed on [0,1], then map if needed
    cfg.X0.ewom.mode = 'fixed';
    cfg.X0.ewom.fixed_prob = [0.70, 0.72, 0.50];

    % optional tiny noise on special-role fixed values, off by default
    cfg.X0.special_noise_std_prob = 0.00;

    %% ------------------------------------------------------------
    % 8) Baseline C
    % -------------------------------------------------------------
    cfg.C.mode = 'shared_baseline';

    cfg.C.base = [ ...
        0.30, 0.40, 0.30; ...
        0.00, 0.90, 0.10; ...
        0.00, 0.10, 0.90];

    %% ------------------------------------------------------------
    % 9) Scenario S1
    % -------------------------------------------------------------
    cfg.S1.name = 'quality_crisis';
    cfg.S1.direct_shock_topic = cfg.topic.idx.Q;

    % roles receiving direct Q shock
    cfg.S1.shock_ordinary = true;
    cfg.S1.shock_official = false;
    cfg.S1.shock_ewom     = true;

    % named shock levels
    cfg.S1.deltaQ_main    = -0.70;
    cfg.S1.deltaQ_extreme = -1.00;
    cfg.S1.deltaQ_weak    = -0.35;

    % default run list used by the backbone S0/S1 runner
    cfg.S1.deltaQ_list = [cfg.S1.deltaQ_main, cfg.S1.deltaQ_extreme];

    % partial exposure settings used in Section 4.4
    cfg.S1.ordinary_exposure_levels = [1.00, 0.50, 0.25];
    cfg.S1.keep_ewom_fully_exposed  = true;
    cfg.S1.exposure_seed            = 777;

    %% ------------------------------------------------------------
    % 10) Simulation run control
    % -------------------------------------------------------------
    cfg.sim.Tmax = 30;
    cfg.sim.store_full_trajectory = true;
    cfg.sim.clip_each_step = true;

    %% ------------------------------------------------------------
    % 11) Random seed
    % -------------------------------------------------------------
    cfg.seed.master = 42;

    % separate seeds can be added later if needed
    cfg.seed.network = cfg.seed.master;
    cfg.seed.X0      = cfg.seed.master;

    %% ------------------------------------------------------------
    % 12) Plot / export flags
    % -------------------------------------------------------------
    cfg.plot.show_X0_checks   = true;
    cfg.plot.show_W_checks    = true;
    cfg.plot.show_scenario_S1 = true;

    cfg.export.save_csv = false;
    cfg.export.save_fig = false;
    cfg.export.outdir   = 'outputs_projectB';

    %% ------------------------------------------------------------
    % 13) Validation
    % -------------------------------------------------------------
    cfg = validate_cfg(cfg);
end


% ================================================================
% Helper: resolve population counts
% ================================================================
function pop = resolve_population_counts(pop)

    switch lower(pop.count_mode)
        case 'absolute'
            % keep nOff / nEwom as given

        case 'ratio'
            pop.nOff  = max(pop.minOff,  round(pop.ratioOff  * pop.n));
            pop.nEwom = max(pop.minEwom, round(pop.ratioEwom * pop.n));

        otherwise
            error('Unknown population.count_mode: %s', pop.count_mode);
    end

    pop.nOrd = pop.n - pop.nOff - pop.nEwom;

    if pop.nOrd <= 0
        error('Invalid population counts: nOrd <= 0.');
    end
end


% ================================================================
% Helper: validate cfg
% ================================================================
function cfg = validate_cfg(cfg)

    % topic dimension
    if cfg.topic.m ~= 3
        error('Project B currently expects exactly 3 topics: BT, Q, OM.');
    end

    % C shape
    [rC, cC] = size(cfg.C.base);
    if rC ~= 3 || cC ~= 3
        error('cfg.C.base must be 3x3.');
    end

    % X0 shapes
    if numel(cfg.X0.ordinary.mu) ~= 3
        error('cfg.X0.ordinary.mu must have length 3.');
    end
    if numel(cfg.X0.ordinary.kappa) ~= 3
        error('cfg.X0.ordinary.kappa must have length 3.');
    end
    if numel(cfg.X0.official.fixed_prob) ~= 3
        error('cfg.X0.official.fixed_prob must have length 3.');
    end
    if numel(cfg.X0.ewom.fixed_prob) ~= 3
        error('cfg.X0.ewom.fixed_prob must have length 3.');
    end

    % count consistency
    if cfg.population.nOrd + cfg.population.nOff + cfg.population.nEwom ~= cfg.population.n
        error('Population counts do not sum to total n.');
    end

    % self-weight sanity
    switch lower(cfg.self.mode)
        case 'fixed_by_role'
            sw = [ ...
                cfg.self.fixed.ordinary, ...
                cfg.self.fixed.official, ...
                cfg.self.fixed.ewom];
            if any(sw <= 0) || any(sw >= 1)
                error('Fixed self-weights must lie strictly between 0 and 1.');
            end

        case 'beta_by_role'
            % means in (0,1), kappas > 0
            check_beta_role(cfg.self.beta.ordinary, 'ordinary');
            check_beta_role(cfg.self.beta.official, 'official');
            check_beta_role(cfg.self.beta.ewom,     'ewom');

        otherwise
            error('Unknown cfg.self.mode: %s', cfg.self.mode);
    end

    % shock list
    if ~isvector(cfg.S1.deltaQ_list) || isempty(cfg.S1.deltaQ_list)
        error('cfg.S1.deltaQ_list must be a non-empty vector.');
    end
end


% ================================================================
% Helper: beta-role validation
% ================================================================
function check_beta_role(s, roleName)
    if s.mean <= 0 || s.mean >= 1
        error('cfg.self.beta.%s.mean must be in (0,1).', roleName);
    end
    if s.kappa <= 0
        error('cfg.self.beta.%s.kappa must be > 0.', roleName);
    end
end