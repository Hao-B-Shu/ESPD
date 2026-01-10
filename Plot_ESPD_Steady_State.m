function Plot_ESPD_Steady_State(varargin)
% Plot_ESPD_Steady_State: 采用硬截断(Clamp)逻辑的稳定版本
%% 1. 参数解析
Para = inputParser;
addOptional(Para, 'points_eta', 99);  
addOptional(Para, 'points_d', 71);
addOptional(Para, 'max_iter', 15);   
addOptional(Para, 'dig', 32);         
addOptional(Para, 'eta0_range', [0.01, 0.99]);
addOptional(Para, 'd0_range', [-9, -2]); 
addOptional(Para, 'n', 8);
addOptional(Para, 'k', 4);
addOptional(Para, 'Save_path', ""); 
parse(Para, varargin{:});

n_eta = Para.Results.points_eta; n_d = Para.Results.points_d;
max_it = Para.Results.max_iter; dig_val = Para.Results.dig;
n = Para.Results.n; k = Para.Results.k;
eta0_range = Para.Results.eta0_range; d0_range = Para.Results.d0_range;
save_path = Para.Results.Save_path;
if save_path == "" || save_path == string(""), save_path = pwd; end

gcp(); 
eta_vec = linspace(eta0_range(1), eta0_range(2), n_eta);
d0_log_vec = linspace(d0_range(1), d0_range(2), n_d);
[ETA0, D0_LOG] = meshgrid(eta_vec, d0_log_vec);
D0_ACTUAL = 10.^D0_LOG;

Steady_Eta_Max = zeros(n_d, n_eta); Steady_Eta_Min = zeros(n_d, n_eta);
Steady_D_Max   = zeros(n_d, n_eta); Steady_D_Min   = zeros(n_d, n_eta);
Iter_Count     = zeros(n_d, n_eta);

%% 2. 并行迭代计算
fprintf('Start parallel calculation... \n');
tic; 
parfor i = 1:n_d
    local_eta_max = zeros(1, n_eta); local_eta_min = zeros(1, n_eta);
    local_d_max = zeros(1, n_eta); local_d_min = zeros(1, n_eta);
    local_iter = zeros(1, n_eta);
    for j = 1:n_eta
        curr_eta = vpa(ETA0(i,j), dig_val); curr_d = vpa(D0_ACTUAL(i,j), dig_val);
        tail_size = 10; eta_tail = vpa(zeros(tail_size, 1)); d_tail = vpa(zeros(tail_size, 1));
        final_step = max_it;
        for step = 1:max_it
            prev_eta = curr_eta; prev_d = curr_d;
            [curr_eta, curr_d] = ESPD('eta', curr_eta, 'd', curr_d, 'n', n, 'k', k, 'dig', dig_val);
            idx = mod(step-1, tail_size) + 1;
            eta_tail(idx) = curr_eta; d_tail(idx) = curr_d;
            min_val_d = min(curr_d, prev_d) + vpa('1e-45');
            if (abs(curr_eta - prev_eta) < vpa('0.01')) && (abs(curr_d - prev_d)/min_val_d < vpa('0.01'))
                eta_tail(:) = curr_eta; d_tail(:) = curr_d;
                final_step = step; break;
            end
        end
        local_eta_max(j) = double(max(eta_tail)); local_eta_min(j) = double(min(eta_tail));
        local_d_max(j) = double(max(d_tail)); local_d_min(j) = double(min(d_tail));
        local_iter(j) = final_step;
    end
    Steady_Eta_Max(i,:) = local_eta_max; Steady_Eta_Min(i,:) = local_eta_min;
    Steady_D_Max(i,:) = local_d_max; Steady_D_Min(i,:) = local_d_min;
    Iter_Count(i,:) = local_iter;
end
fprintf('Cost: %.2f s. \n', toc);

%% 3. 绘图处理
view_angle = [-35, 30]; 
xtick_pos = linspace(eta0_range(1), eta0_range(2), 4);
xtick_lab = arrayfun(@(x) sprintf('$%.0f\\%%$', x*100), xtick_pos, 'UniformOutput', false);
ytick_pos = 10.^linspace(d0_range(1), d0_range(2), 4);
ytick_lab = arrayfun(@(x) sprintf('$10^{%.0f}$', log10(x)), ytick_pos, 'UniformOutput', false);

% --- 图 1: DE图 ---
fig_eta = figure('Color', 'w'); ax1 = axes(fig_eta); hold(ax1, 'on'); grid(ax1, 'on');

% 效率硬截断并设置范围
E_Max_Plot = min(Steady_Eta_Max, 1); E_Min_Plot = max(Steady_Eta_Min, 0);
z_lims_e = [min(E_Min_Plot(:)), max(E_Max_Plot(:))];
if z_lims_e(1) >= z_lims_e(2), z_lims_e(2) = z_lims_e(1) + 0.05; end

surf(ax1, ETA0, D0_ACTUAL, E_Max_Plot, 'FaceColor', 'interp', 'EdgeColor', 'none');
surf(ax1, ETA0, D0_ACTUAL, E_Min_Plot, 'FaceColor', 'interp', 'EdgeColor', 'none');

set(ax1, 'YScale', 'log', 'FontWeight', 'bold', 'TickLabelInterpreter', 'latex');
set(ax1, 'XTick', xtick_pos, 'XTickLabel', xtick_lab, 'YTick', ytick_pos, 'YTickLabel', ytick_lab);
set(ax1, 'ZLim', z_lims_e); clim(ax1, z_lims_e);
ztick_pos_e = linspace(z_lims_e(1), z_lims_e(2), 4);
set(ax1, 'ZTick', ztick_pos_e, 'ZTickLabel', arrayfun(@(x) sprintf('$%.0f\\%%$', x*100), ztick_pos_e, 'UniformOutput', false));
xlabel(ax1, '$\eta_0$', 'Interpreter', 'latex'); ylabel(ax1, '$d_0$', 'Interpreter', 'latex'); zlabel(ax1, '$\eta_{\infty}$', 'Interpreter', 'latex');
view(ax1, view_angle); colormap(ax1, jet); cb1 = colorbar(ax1); 
set(cb1, 'TickLabelInterpreter', 'latex'); drawnow;
cb1.TickLabels = arrayfun(@(x) sprintf('$%.0f\\%%$', x*100), cb1.Ticks, 'UniformOutput', false);

% --- 图 2: DCR 图 ---
fig_d = figure('Color', 'w'); ax2 = axes(fig_d); hold(ax2, 'on'); grid(ax2, 'on');

% 物理截断最小值 10^-20
D_Max_Clamp = max(Steady_D_Max, 1e-20);
D_Min_Clamp = max(Steady_D_Min, 1e-20);

% 取对数
Z_L_Max = log10(D_Max_Clamp);
Z_L_Min = log10(D_Min_Clamp);

% 设置范围
z_d_min = -20;
z_d_max = max(Z_L_Max(:));
if z_d_max <= z_d_min, z_d_max = z_d_min + 5; end
z_d_lims = [z_d_min, z_d_max];

surf(ax2, ETA0, D0_ACTUAL, Z_L_Max, 'FaceColor', 'interp', 'EdgeColor', 'none');
surf(ax2, ETA0, D0_ACTUAL, Z_L_Min, 'FaceColor', 'interp', 'EdgeColor', 'none');

set(ax2, 'YScale', 'log', 'FontWeight', 'bold', 'TickLabelInterpreter', 'latex');
set(ax2, 'XTick', xtick_pos, 'XTickLabel', xtick_lab, 'YTick', ytick_pos, 'YTickLabel', ytick_lab);
set(ax2, 'ZLim', z_d_lims); clim(ax2, z_d_lims);

ztick_d_pos = linspace(z_d_lims(1), z_d_lims(2), 4);
set(ax2, 'ZTick', ztick_d_pos, 'ZTickLabel', arrayfun(@(x) sprintf('$10^{%.0f}$', x), ztick_d_pos, 'UniformOutput', false));

xlabel(ax2, '$\eta_0$', 'Interpreter', 'latex'); ylabel(ax2, '$d_0$', 'Interpreter', 'latex'); zlabel(ax2, '$d_{\infty}$', 'Interpreter', 'latex');
view(ax2, view_angle); colormap(ax2, jet); cb2 = colorbar(ax2); 
set(cb2, 'TickLabelInterpreter', 'latex'); drawnow;
cb2.TickLabels = arrayfun(@(x) sprintf('$10^{%.0f}$', x), cb2.Ticks, 'UniformOutput', false);

%% 4. 导出
set(fig_eta, 'Renderer', 'Painters'); set(fig_d, 'Renderer', 'Painters');
exportgraphics(fig_eta, fullfile(save_path, sprintf('Stable_n%d_k%d_eta.eps', n, k)), 'ContentType', 'vector');
exportgraphics(fig_d, fullfile(save_path, sprintf('Stable_n%d_k%d_d.eps', n, k)), 'ContentType', 'vector');
end