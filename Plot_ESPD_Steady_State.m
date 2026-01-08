function Plot_ESPD_Steady_State(varargin)
% Plot_ESPD_Steady_State: 动力学区间实体填充分析
% 优化：标题居中加粗，路径自动补全，坐标轴字体加粗，高分辨率导出

%% 1. 初始化参数解析
Para = inputParser;
addOptional(Para, 'points_eta', 2);  
addOptional(Para, 'points_d', 2);
addOptional(Para, 'max_iter', 15);   
addOptional(Para, 'dig', 32);         
addOptional(Para, 'eta0_range', [0.1, 0.99]);
addOptional(Para, 'd0_range', [-9, -2]); 
addOptional(Para, 'n', 5);
addOptional(Para, 'k', 2);
addOptional(Para, 'Save_path', ""); % 默认为空字符串，代表当前目录
parse(Para, varargin{:});

n_eta = Para.Results.points_eta; n_d = Para.Results.points_d;
max_it = Para.Results.max_iter; dig_val = Para.Results.dig;
n = Para.Results.n; k = Para.Results.k;
eta0_range = Para.Results.eta0_range; d0_range = Para.Results.d0_range;
save_path = Para.Results.Save_path;

% 路径处理逻辑："" 表示当前文件夹
if save_path == ""
    save_path = pwd; 
end

digits(dig_val);

% 建立网格
eta_vec = linspace(eta0_range(1), eta0_range(2), n_eta);
d0_log_vec = linspace(d0_range(1), d0_range(2), n_d);
[ETA0, D0_LOG] = meshgrid(eta_vec, d0_log_vec);
D0_ACTUAL = 10.^D0_LOG;

Steady_Eta_Max = zeros(n_d, n_eta); Steady_Eta_Min = zeros(n_d, n_eta);
Steady_D_Max   = zeros(n_d, n_eta); Steady_D_Min   = zeros(n_d, n_eta);

fprintf('\n%-10s | %-10s | %-22s | %-22s\n', 'eta0', 'd0', 'Steady_Eta_Range', 'Steady_d_Range');
fprintf('--------------------------------------------------------------------------------\n');

%% 2. 迭代计算
for i = 1:n_d
    for j = 1:n_eta
        curr_eta = vpa(ETA0(i,j));
        curr_d   = vpa(10^D0_LOG(i,j));
        tail_size = 10;
        eta_tail = vpa(zeros(tail_size, 1));
        d_tail = vpa(zeros(tail_size, 1));
        
        for step = 1:max_it
            prev_eta = curr_eta; prev_d = curr_d;
            [curr_eta, curr_d] = ESPD('eta', curr_eta, 'd', curr_d, 'n', n, 'k', k, 'dig', dig_val);
            idx = mod(step-1, tail_size) + 1;
            eta_tail(idx) = curr_eta; d_tail(idx) = curr_d;
            
            min_val_d = min(curr_d, prev_d) + vpa('1e-45');
            if (abs(curr_eta - prev_eta) < vpa('0.01')) && (abs(curr_d - prev_d)/min_val_d < vpa('0.01'))
                eta_tail(:) = curr_eta; d_tail(:) = curr_d;
                break;
            end
        end
        Steady_Eta_Max(i,j) = double(max(eta_tail));
        Steady_Eta_Min(i,j) = double(min(eta_tail));
        Steady_D_Max(i,j)   = double(max(d_tail));
        Steady_D_Min(i,j)   = double(min(d_tail));
        
        fprintf('%-10.2f%%| %-10.1e | [%.2f%%, %.2f%%] | [%.1e, %.1e]\n', ...
            double(ETA0(i,j))*100, double(D0_ACTUAL(i,j)), ...
            Steady_Eta_Min(i,j)*100, Steady_Eta_Max(i,j)*100, ...
            Steady_D_Min(i,j), Steady_D_Max(i,j));
    end
end

%% 3. 绘图处理
view_angle = [-35, 30]; 
xtick_pos = linspace(eta0_range(1), eta0_range(2), 4);
xtick_lab = arrayfun(@(x) sprintf('%.2f%%', x*100), xtick_pos, 'UniformOutput', false);

% --- 图 1: 效率震荡图 ---
fig_eta = figure('Color', 'w', 'Name', 'Efficiency Map');
hold on; grid on;
for i = 1:n_d-1
    for j = 1:n_eta-1
        X = [ETA0(i,j) ETA0(i+1,j) ETA0(i+1,j+1) ETA0(i,j+1)];
        Y = [D0_ACTUAL(i,j) D0_ACTUAL(i+1,j) D0_ACTUAL(i+1,j+1) D0_ACTUAL(i,j+1)];
        Z_m1 = [Steady_Eta_Min(i,j) Steady_Eta_Min(i+1,j) Steady_Eta_Min(i+1,j+1) Steady_Eta_Min(i,j+1)];
        Z_m2 = [Steady_Eta_Max(i,j) Steady_Eta_Max(i+1,j) Steady_Eta_Max(i+1,j+1) Steady_Eta_Max(i,j+1)];
        fill3([X, fliplr(X)], [Y, fliplr(Y)], [Z_m1, fliplr(Z_m2)], [0.3 0.7 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    end
end
surf(ETA0, D0_ACTUAL, Steady_Eta_Max, 'FaceColor', 'interp', 'FaceAlpha', 0.8, 'EdgeColor', 'none');
surf(ETA0, D0_ACTUAL, Steady_Eta_Min, 'FaceColor', 'interp', 'FaceAlpha', 0.8, 'EdgeColor', 'none');

% 设置 Z 轴
z_min_limit = max(0, min(Steady_Eta_Min(:)) - 0.01);
z_max_limit = min(1, max(Steady_Eta_Max(:)) + 0.01);
if z_max_limit <= z_min_limit, z_max_limit = z_min_limit + 0.05; end
set(gca, 'ZLim', [z_min_limit z_max_limit], 'YScale', 'log');

% 坐标轴与刻度（加粗）
set(gca, 'XTick', xtick_pos, 'XTickLabel', xtick_lab, 'FontWeight', 'bold');
zt = unique(round(get(gca, 'ZTick'), 4));
set(gca, 'ZTick', zt, 'ZTickLabel', arrayfun(@(x) sprintf('%.2f%%', x*100), zt, 'UniformOutput', false));

% 标题：正上方居中加粗
title(sprintf('Steady-state DE Map (n=%d, k=%d)', n, k), 'FontWeight', 'bold', 'FontSize', 12);

cb1 = colorbar; drawnow;
set(cb1, 'TickLabels', arrayfun(@(x) sprintf('%.2f%%', x*100), get(cb1, 'Ticks'), 'UniformOutput', false), 'FontWeight', 'bold');

xlabel('\eta_0', 'FontWeight', 'bold'); ylabel('d_0', 'FontWeight', 'bold'); zlabel('\eta_{\infty}', 'FontWeight', 'bold');
view(view_angle); colormap jet; set(gca, 'XDir', 'normal', 'YDir', 'normal');

% --- 图 2: DCR 震荡图 ---
fig_d = figure('Color', 'w', 'Name', 'DCR Map');
hold on; grid on;
Z_L_Max = log10(max(Steady_D_Max, 1e-65));
Z_L_Min = log10(max(Steady_D_Min, 1e-65));
for i = 1:n_d-1
    for j = 1:n_eta-1
        X = [ETA0(i,j) ETA0(i+1,j) ETA0(i+1,j+1) ETA0(i,j+1)];
        Y = [D0_ACTUAL(i,j) D0_ACTUAL(i+1,j) D0_ACTUAL(i+1,j+1) D0_ACTUAL(i,j+1)];
        Z_v1 = [Z_L_Min(i,j) Z_L_Min(i+1,j) Z_L_Min(i+1,j+1) Z_L_Min(i,j+1)];
        Z_v2 = [Z_L_Max(i,j) Z_L_Max(i+1,j) Z_L_Max(i+1,j+1) Z_L_Max(i,j+1)];
        fill3([X, fliplr(X)], [Y, fliplr(Y)], [Z_v1, fliplr(Z_v2)], [0.9 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    end
end
surf(ETA0, D0_ACTUAL, Z_L_Max, 'FaceColor', 'r', 'FaceAlpha', 0.6, 'EdgeColor', 'none');
surf(ETA0, D0_ACTUAL, Z_L_Min, 'FaceColor', 'b', 'FaceAlpha', 0.6, 'EdgeColor', 'none');

set(gca, 'YScale', 'log', 'ZLim', [min(Z_L_Min(:))-1, max(Z_L_Max(:))+1], 'FontWeight', 'bold');
set(gca, 'XTick', xtick_pos, 'XTickLabel', xtick_lab);

zt_d = unique(round(get(gca, 'ZTick')));
set(gca, 'ZTick', zt_d, 'ZTickLabel', arrayfun(@(x) sprintf('10^{%.0f}', x), zt_d, 'UniformOutput', false));

% 标题：正上方居中加粗
title(sprintf('Steady-state DCR Map (n=%d, k=%d)', n, k), 'FontWeight', 'bold', 'FontSize', 12);

cb2 = colorbar; drawnow;
set(cb2, 'TickLabels', arrayfun(@(x) sprintf('10^{%.0f}', x), get(cb2, 'Ticks'), 'UniformOutput', false), 'FontWeight', 'bold');

xlabel('\eta_0', 'FontWeight', 'bold'); ylabel('d_0', 'FontWeight', 'bold'); zlabel('d_{\infty}', 'FontWeight', 'bold');
view(view_angle); set(gca, 'XDir', 'normal', 'YDir', 'normal'); 

%% 4. 保存图片逻辑
% 构建文件名
name_eta = sprintf('Stable_n%d_k%d_eta.eps', n, k);
name_d   = sprintf('Stable_n%d_k%d_d.eps', n, k);

% 确保路径存在
if ~exist(save_path, 'dir') && save_path ~= ""
    mkdir(save_path);
end

full_path_eta = fullfile(save_path, name_eta);
full_path_d   = fullfile(save_path, name_d);

fprintf('正在保存图片至: %s\n', full_path_eta);
exportgraphics(fig_eta, full_path_eta, 'ContentType', 'vector');
exportgraphics(fig_d, full_path_d, 'ContentType', 'vector');

end
