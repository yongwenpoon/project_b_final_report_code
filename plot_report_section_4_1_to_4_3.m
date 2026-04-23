function plot_report_section_4_1_to_4_3(results, cfg)
%PLOT_REPORT_SECTION_4_1_TO_4_3
% Final-report figures for Project B Sections 4.1-4.3.
%
% Figures produced:
%   1) Figure 4.1: S0 baseline, all-agent trajectories
%   2) Figure 4.2: S1 main quality shock, all-agent comparison with S0
%   3) Figure 4.3: BT trajectories by role under S0 and S1
%   4) Appendix Figure A1: role-specific trajectories across BT, Q, and OM
%
% This function is report-facing rather than presentation-facing.
% It uses final report titles, legends, and output filenames.

    tt = 0:cfg.sim.Tmax;

    bt = cfg.topic.idx.BT;
    q  = cfg.topic.idx.Q;
    om = cfg.topic.idx.OM;

    % Topic colours
    colBT = [0.0000, 0.4470, 0.7410];
    colQ  = [0.8500, 0.3250, 0.0980];
    colOM = [0.9290, 0.6940, 0.1250];

    % Role colours
    colOrd = [0.0000, 0.4470, 0.7410];
    colOff = [0.8500, 0.3250, 0.0980];
    colEw  = [0.9290, 0.6940, 0.1250];

    % Shared reference colours
    colS0   = [0.10 0.10 0.10];
    zeroCol = [0.75 0.75 0.75];

    % Main shock
    mainTag   = choose_main_shock_tag(results, cfg);
    deltaMain = results.S1.(mainTag).deltaQ;

    % All-agent trajectories
    Y0_all = results.S0.dyn.mean_all;
    Y1_all = results.S1.(mainTag).dyn.mean_all;

    % By-role trajectories
    Y0_ord = results.S0.dyn.mean_ord;
    Y0_off = results.S0.dyn.mean_off;
    Y0_ew  = results.S0.dyn.mean_ew;

    Y1_ord = results.S1.(mainTag).dyn.mean_ord;
    Y1_off = results.S1.(mainTag).dyn.mean_off;
    Y1_ew  = results.S1.(mainTag).dyn.mean_ew;

    outdir = cfg.export.outdir;
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end

    %% ============================================================
    % Figure 4.1: S0 baseline, all-agent mean trajectories
    % ============================================================
    f1 = figure('Name', 'Figure_4_1_S0_Baseline_AllAgents', ...
                'Color', 'w', ...
                'Position', [80 80 980 520]);

    hold on;
    hBT = plot(tt, Y0_all(:,bt), '-', 'Color', colBT, 'LineWidth', 2.8, 'DisplayName', 'BT');
    hQ  = plot(tt, Y0_all(:,q),  '-', 'Color', colQ,  'LineWidth', 2.8, 'DisplayName', 'Q');
    hOM = plot(tt, Y0_all(:,om), '-', 'Color', colOM, 'LineWidth', 2.8, 'DisplayName', 'OM');

    mark_start_end(tt, Y0_all(:,bt), colBT);
    mark_start_end(tt, Y0_all(:,q),  colQ);
    mark_start_end(tt, Y0_all(:,om), colOM);

    ylim_all_s0 = padded_limits(Y0_all(:), 0.08, 0.18);

    grid on;
    box on;
    xlabel('Time step', 'FontSize', 12);
    ylabel('Mean opinion', 'FontSize', 12);
    title('S0 baseline: all-agent mean trajectories', 'FontSize', 15, 'FontWeight', 'bold');
    legend([hBT,hQ,hOM], 'Location', 'southeast', 'FontSize', 11);
    ylim(ylim_all_s0);
    xlim([tt(1), tt(end)]);
    set(gca, 'FontSize', 11);
    ax = gca; ax.Toolbar.Visible = 'off';
    hold off;

    exportgraphics(f1, fullfile(outdir, 'Figure_4_1_S0_Baseline_AllAgents.png'), 'Resolution', 300);

    %% ============================================================
    % Figure 4.2: S1 main quality shock, all-agent comparison with S0
    % ============================================================
    f2 = figure('Name', 'Figure_4_2_S1_MainShock_AllAgents', ...
                'Color', 'w', ...
                'Position', [120 100 1080 860]);

    tl1 = tiledlayout(3,1, 'TileSpacing', 'compact', 'Padding', 'compact');

    ax1 = nexttile;
    [hS0_1, hS1_1] = plot_topic_compare_panel(ax1, tt, Y0_all(:,bt), Y1_all(:,bt), ...
        'BT trajectories', colBT, deltaMain, colS0, zeroCol);

    ax2 = nexttile;
    plot_topic_compare_panel(ax2, tt, Y0_all(:,q), Y1_all(:,q), ...
        'Q trajectories', colQ, deltaMain, colS0, zeroCol);

    ax3 = nexttile;
    plot_topic_compare_panel(ax3, tt, Y0_all(:,om), Y1_all(:,om), ...
        'OM trajectories', colOM, deltaMain, colS0, zeroCol);

    lgd2 = legend(ax1, [hS0_1, hS1_1], ...
        {'S0 reference', sprintf('S1 quality shock (\\DeltaQ = %.2f)', deltaMain)}, ...
        'Orientation', 'horizontal', 'FontSize', 11);
    lgd2.Layout.Tile = 'north';

    xlabel(tl1, 'Time step', 'FontSize', 12);
    ylabel(tl1, 'Mean opinion', 'FontSize', 12);
    title(tl1, sprintf('S1 main quality shock (\\DeltaQ = %.2f): all-agent mean trajectories compared with S0', deltaMain), ...
        'FontSize', 16, 'FontWeight', 'bold');

    exportgraphics(f2, fullfile(outdir, 'Figure_4_2_S1_MainShock_AllAgents.png'), 'Resolution', 300);

    %% ============================================================
    % Figure 4.3: BT trajectories by role under S0 and S1
    % ============================================================
    f3 = figure('Name', 'Figure_4_3_BT_ByRole_S0_vs_S1', ...
                'Color', 'w', ...
                'Position', [160 120 1180 700]);

    tl2 = tiledlayout(1,2, 'TileSpacing', 'compact', 'Padding', 'compact');

    btVals = [Y0_ord(:,bt); Y0_off(:,bt); Y0_ew(:,bt); Y1_ord(:,bt); Y1_off(:,bt); Y1_ew(:,bt)];
    ylim_bt_role = padded_limits(btVals, 0.06, 0.16);

    axL = nexttile;
    [hOrd, hOff, hEw] = plot_role_panel(axL, tt, Y0_ord(:,bt), Y0_off(:,bt), Y0_ew(:,bt), ...
        'S0 baseline', colOrd, colOff, colEw, zeroCol, ylim_bt_role, true);

    axR = nexttile;
    plot_role_panel(axR, tt, Y1_ord(:,bt), Y1_off(:,bt), Y1_ew(:,bt), ...
        'S1 quality shock', colOrd, colOff, colEw, zeroCol, ylim_bt_role, false);

    lgd3 = legend(axL, [hOrd, hOff, hEw], ...
        {'ordinary consumers', 'official agents', 'eWOM influencers'}, ...
        'Orientation', 'horizontal', 'FontSize', 11, 'Box', 'on');
    lgd3.Layout.Tile = 'north';

    xlabel(tl2, 'Time step', 'FontSize', 12);
    ylabel(tl2, 'Mean opinion', 'FontSize', 12);
    title(tl2, sprintf('BT trajectories by role under S0 and S1 (\\DeltaQ = %.2f)', deltaMain), ...
        'FontSize', 16, 'FontWeight', 'bold');

    exportgraphics(f3, fullfile(outdir, 'Figure_4_3_BT_ByRole_S0_vs_S1.png'), 'Resolution', 300);

    %% ============================================================
    % Appendix Figure A1: role-specific trajectories across BT, Q, and OM
    % ============================================================
    f4 = figure('Name', 'Appendix_A1_RoleSpecific_AllTopics', ...
                'Color', 'w', ...
                'Position', [180 120 1280 860]);

    tl3 = tiledlayout(2,3, 'TileSpacing', 'compact', 'Padding', 'compact');

    all_role_vals = [Y0_ord(:); Y0_off(:); Y0_ew(:); Y1_ord(:); Y1_off(:); Y1_ew(:)];
    ylim_role = padded_limits(all_role_vals, 0.06, 0.35);

    % ----- Row 1: S0 baseline -----
    ax11 = nexttile;
    [hOrd2, hOff2, hEw2] = plot_role_panel(ax11, tt, Y0_ord(:,bt), Y0_off(:,bt), Y0_ew(:,bt), ...
        'BT by role', colOrd, colOff, colEw, zeroCol, ylim_role, true);

    % Row label placed INSIDE first subplot to avoid left-side layout issues
    text(ax11, 0.03, 0.93, 'S0 baseline', ...
        'Units', 'normalized', ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top');

    ax12 = nexttile;
    plot_role_panel(ax12, tt, Y0_ord(:,q), Y0_off(:,q), Y0_ew(:,q), ...
        'Q by role', colOrd, colOff, colEw, zeroCol, ylim_role, false);

    ax13 = nexttile;
    plot_role_panel(ax13, tt, Y0_ord(:,om), Y0_off(:,om), Y0_ew(:,om), ...
        'OM by role', colOrd, colOff, colEw, zeroCol, ylim_role, false);

    % ----- Row 2: S1 main shock -----
    ax21 = nexttile;
    plot_role_panel(ax21, tt, Y1_ord(:,bt), Y1_off(:,bt), Y1_ew(:,bt), ...
        '', colOrd, colOff, colEw, zeroCol, ylim_role, true);

    % Row label placed INSIDE first subplot to avoid left-side layout issues
    text(ax21, 0.03, 0.93, 'S1 quality shock', ...
        'Units', 'normalized', ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top');

    ax22 = nexttile;
    plot_role_panel(ax22, tt, Y1_ord(:,q), Y1_off(:,q), Y1_ew(:,q), ...
        '', colOrd, colOff, colEw, zeroCol, ylim_role, false);

    ax23 = nexttile;
    plot_role_panel(ax23, tt, Y1_ord(:,om), Y1_off(:,om), Y1_ew(:,om), ...
        '', colOrd, colOff, colEw, zeroCol, ylim_role, false);

    lgd4 = legend(ax11, [hOrd2, hOff2, hEw2], ...
        {'ordinary consumers', 'official agents', 'eWOM influencers'}, ...
        'Orientation', 'horizontal', 'FontSize', 10, 'Box', 'on');
    lgd4.Layout.Tile = 'north';

    xlabel(tl3, 'Time step', 'FontSize', 12);
    ylabel(tl3, 'Mean opinion', 'FontSize', 12);
    title(tl3, sprintf('Role-specific mean trajectories across BT, Q, and OM under S0 and S1 (\\DeltaQ = %.2f)', deltaMain), ...
        'FontSize', 16, 'FontWeight', 'bold');

    exportgraphics(f4, fullfile(outdir, 'Appendix_A1_RoleSpecific_AllTopics.png'), 'Resolution', 300);
end

% ================================================================
% Helper: all-agent S0 vs S1 topic panel
% ================================================================
function [hS0, hS1] = plot_topic_compare_panel(ax, tt, Y0_topic, Y1_topic, panelTitle, topicColor, deltaQ, colS0, zeroCol)
    hold(ax, 'on');

    hS0 = plot(ax, tt, Y0_topic, '--', ...
        'Color', colS0, ...
        'LineWidth', 2.2, ...
        'DisplayName', 'S0 reference');

    hS1 = plot(ax, tt, Y1_topic, '-', ...
        'Color', topicColor, ...
        'LineWidth', 2.8, ...
        'DisplayName', sprintf('S1 quality shock (\\DeltaQ = %.2f)', deltaQ));

    plot(ax, tt(end), Y0_topic(end), 'o', ...
        'Color', colS0, 'MarkerFaceColor', colS0, ...
        'HandleVisibility', 'off');

    plot(ax, tt(end), Y1_topic(end), 'o', ...
        'Color', topicColor, 'MarkerFaceColor', topicColor, ...
        'HandleVisibility', 'off');

    yline(ax, 0, '--', 'Color', zeroCol, 'HandleVisibility', 'off');

    ylim_topic = padded_limits([Y0_topic(:); Y1_topic(:)], 0.10, 0.18);

    grid(ax, 'on');
    box(ax, 'on');
    title(ax, panelTitle, 'FontSize', 13, 'FontWeight', 'bold');
    ylim(ax, ylim_topic);
    xlim(ax, [tt(1), tt(end)]);
    set(ax, 'FontSize', 11);
    ax.Toolbar.Visible = 'off';

    hold(ax, 'off');
end

% ================================================================
% Helper: by-role panel
% ================================================================
function [hOrd, hOff, hEw] = plot_role_panel(ax, tt, Yord, Yoff, Yew, panelTitle, colOrd, colOff, colEw, zeroCol, ylim_role, showYTicks)
    hold(ax, 'on');

    hOrd = plot(ax, tt, Yord, '-', 'Color', colOrd, 'LineWidth', 2.6, 'DisplayName', 'ordinary consumers');
    hOff = plot(ax, tt, Yoff, '-', 'Color', colOff, 'LineWidth', 2.6, 'DisplayName', 'official agents');
    hEw  = plot(ax, tt, Yew,  '-', 'Color', colEw,  'LineWidth', 2.6, 'DisplayName', 'eWOM influencers');

    yline(ax, 0, '--', 'Color', zeroCol, 'HandleVisibility', 'off');

    grid(ax, 'on');
    box(ax, 'on');

    if ~isempty(panelTitle)
        title(ax, panelTitle, 'FontSize', 13, 'FontWeight', 'bold');
    end

    ylim(ax, ylim_role);
    xlim(ax, [tt(1), tt(end)]);
    set(ax, 'FontSize', 11);
    ax.Toolbar.Visible = 'off';

    if ~showYTicks
        set(ax, 'YTickLabel', []);
    end

    hold(ax, 'off');
end

% ================================================================
% Helper: mark start and end
% ================================================================
function mark_start_end(tt, yy, col)
    plot(tt(1),   yy(1),  'o', 'Color', col, 'MarkerFaceColor', col, 'HandleVisibility', 'off');
    plot(tt(end), yy(end),'o', 'Color', col, 'MarkerFaceColor', col, 'HandleVisibility', 'off');
end

% ================================================================
% Helper: choose main shock tag
% ================================================================
function mainTag = choose_main_shock_tag(results, cfg)
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

% ================================================================
% Helper: padded y-limits
% ================================================================
function ylim_out = padded_limits(y, padFrac, minSpan)
    y = y(~isnan(y));
    ymin = min(y);
    ymax = max(y);

    span = ymax - ymin;
    if span < minSpan
        mid = 0.5 * (ymin + ymax);
        ymin = mid - 0.5 * minSpan;
        ymax = mid + 0.5 * minSpan;
        span = ymax - ymin;
    end

    pad = padFrac * span;
    ylim_out = [ymin - pad, ymax + pad];
end