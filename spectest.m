%% 绘制四条彩色波浪曲线（严格按描述）
clear; clc; close all;

% 设置参数
x = linspace(0, 10, 1000);  % 横坐标

% 定义四条曲线的颜色（严格按描述顺序）
colors = {[0, 0.2, 0.6],     % 深蓝色 (RGB: 0, 0.2, 0.6)
          [1, 0.5, 0],       % 橙色 (RGB: 1, 0.5, 0)
          [0, 0.6, 0.2],     % 绿色 (RGB: 0, 0.6, 0.2)
          [0, 0.4, 0.1]};    % 深绿色 (RGB: 0, 0.4, 0.1)

% 定义曲线名称
curve_names = {'深蓝色曲线', '橙色曲线', '绿色曲线', '深绿色曲线'};

% 基础波形函数（双峰"M"形，但顶部平缓）
base_y = zeros(size(x));

% 生成第一个平缓波峰
peak1_center = 3;
peak1_height = 1.8;
peak1_width = 1.5;  % 较宽使顶部平缓
peak1 = peak1_height * exp(-((x - peak1_center) / peak1_width).^2);

% 生成第二个平缓波峰
peak2_center = 6.5;
peak2_height = 1.4;
peak2_width = 1.6;  % 较宽使顶部平缓
peak2 = peak2_height * exp(-((x - peak2_center) / peak2_width).^2);

% 合成基础波形
base_y = peak1 + peak2;

% 添加整体趋势：从左向右下倾斜
downward_slope = -0.12 * x;  % 向下倾斜
base_y = base_y + downward_slope;

% 添加起始和结束的平滑
base_y = base_y + 0.2 * exp(-((x - 1) / 0.8).^2);  % 起始
base_y = base_y + 0.1 * exp(-((x - 9) / 2).^2);   % 结束

% 生成四条平行等距的曲线
y_curves = zeros(length(x), 4);
vertical_offsets = [0, -0.8, -1.6, -2.4];  % 等距向下偏移

for i = 1:4
    y_curves(:, i) = base_y + vertical_offsets(i);
end

% 添加轻微的形状变化使每条曲线略有不同
% 但保持基本波形一致
shape_variations = {0.05*sin(0.5*x),      % 深蓝色
                    0.03*sin(0.7*x+0.5),  % 橙色
                    0.04*sin(0.6*x+1),    % 绿色
                    0.02*sin(0.8*x+1.5)}; % 深绿色

for i = 1:4
%    y_curves(:, i) = y_curves(:, i) + shape_variations{i};
end

% 平滑处理
for i = 1:4
    y_curves(:, i) = smoothdata(y_curves(:, i), 'gaussian', 30);
end

% 绘制
figure('Position', [100, 100, 900, 600]);

% 绘制四条曲线
hold on;
for i = 1:4
    plot(x, y_curves(:, i), '-', 'LineWidth', 3, 'Color', colors{i});
end

% 设置图形属性
grid on;
box on;
xlabel('X轴', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Y轴', 'FontSize', 12, 'FontWeight', 'bold');
title('四条彩色波浪曲线（严格按描述）', 'FontSize', 14, 'FontWeight', 'bold');

% 设置坐标范围
xlim([0, 10]);
ylim([-3, 2.5]);

% 纯白背景
set(gca, 'FontSize', 11, 'FontWeight', 'bold');
set(gcf, 'Color', 'w');

% 添加"M"标记
text(0.5, 2.2, 'M', 'FontSize', 20, 'FontWeight', 'bold', 'Color', [0.3, 0.3, 0.3]);

% 添加图例
legend(curve_names, 'Location', 'southwest', 'FontSize', 10);

% 确保最终汇聚在右下角（最后一点接近同一条水平线）
% 调整最后部分使四条曲线在x=9-10区间内趋于平行
for i = 1:4
    end_idx = length(x) - 50:length(x);
    y_curves(end_idx, i) = linspace(y_curves(end_idx(1), i), vertical_offsets(i)-2.2, length(end_idx));
end

% 重新绘制调整后的部分
for i = 1:4
    plot(x, y_curves(:, i), '-', 'LineWidth', 3, 'Color', colors{i});
end

hold off;

%% 添加特征标注
figure('Position', [100, 100, 1000, 400]);

% 子图1：单独显示每条曲线
subplot(1, 2, 1);
hold on;
for i = 1:4
    plot(x, y_curves(:, i), '-', 'LineWidth', 2.5, 'Color', colors{i});
end
grid on; box on;
xlabel('X轴', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Y轴', 'FontSize', 11, 'FontWeight', 'bold');
title('四条曲线整体视图', 'FontSize', 12, 'FontWeight', 'bold');
legend(curve_names, 'Location', 'southwest', 'FontSize', 9);
xlim([0, 10]); ylim([-3, 2.5]);
set(gcf, 'Color', 'w');

% 子图2：放大显示波形细节
subplot(1, 2, 2);
hold on;
for i = 1:4
    % 归一化显示，便于观察波形形状
    y_normalized = y_curves(:, i) - min(y_curves(:, i));
    y_normalized = y_normalized / max(y_normalized) + (4-i)*0.5;
    plot(x, y_normalized, '-', 'LineWidth', 2, 'Color', colors{i});
end
grid on; box on;
xlabel('X轴', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('归一化幅值', 'FontSize', 11, 'FontWeight', 'bold');
title('波形形状对比（归一化）', 'FontSize', 12, 'FontWeight', 'bold');
xlim([2, 8]);  % 放大显示双峰区域
set(gcf, 'Color', 'w');