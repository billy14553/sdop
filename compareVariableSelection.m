%% compareVariableSelection.m
% 功能：对比不同变量选择方法选择的特征差异
% 使用scripts6_comparison.m中的可视化函数进行展示
% 作者：CodeBuddy
% 日期：2026-06-02
% 
% 修改日志：
% 2026-06-02 - 初始版本：加载SelectedVariables.mat，使用plotVariableSelectionComparison、
%              plotAllMethodsVariableSelection等函数进行可视化对比

clc; clear; close all;

%% ==================== 配置参数 ====================
matFilePath = 'mp6tomp5_SelectedVariables.mat';
outputDir = './comparison_results/';
strFileName = 'mp6tomp5';

% 创建输出目录
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% ==================== 加载数据 ====================
fprintf('正在加载 %s ...\n', matFilePath);
if ~exist(matFilePath, 'file')
    error('文件不存在: %s', matFilePath);
end

loadedData = load(matFilePath);
selectedVars = loadedData.selectedVariables;

% 提取数据
wavelength = selectedVars.wavelength;
lassoVars = selectedVars.LASSO;
covselVars = selectedVars.CovSel;
carsVars = selectedVars.CARS;
sdopVars = selectedVars.SDOP;

% 获取变量总数
nTotalVars = length(wavelength);

fprintf('变量总数: %d\n', nTotalVars);
fprintf('波长范围: %.2f - %.2f nm\n', min(wavelength), max(wavelength));
fprintf('各方法选择变量数:\n');
fprintf('  LASSO:  %d (%.1f%%)\n', length(lassoVars), length(lassoVars)/nTotalVars*100);
fprintf('  CovSel: %d (%.1f%%)\n', length(covselVars), length(covselVars)/nTotalVars*100);
fprintf('  CARS:   %d (%.1f%%)\n', length(carsVars), length(carsVars)/nTotalVars*100);
fprintf('  SDOP:   %d (%.1f%%)\n', length(sdopVars), length(sdopVars)/nTotalVars*100);

%% ==================== 调用可视化函数 ====================
fprintf('\n========== 生成可视化对比图 ==========\n');

% 图1: 使用 plotAllMethodsVariableSelection - 所有方法变量位置对比
fprintf('\n1. 生成所有方法变量位置对比图...\n');
plotAllMethodsVariableSelection(wavelength, selectedVars, fullfile(outputDir, strFileName));

% 图2: 使用 plotVariableSelectionComparison - 变量选择特征对比（4个子图）
fprintf('\n2. 生成变量选择特征对比图（4个子图）...\n');
plotVariableSelectionComparison(wavelength, selectedVars, fullfile(outputDir, strFileName));

% 图3: 回归系数对比（如果有系数数据）
if isfield(selectedVars, 'LASSO_Coef') || isfield(selectedVars, 'Coefficients')
    fprintf('\n3. 生成回归系数对比图...\n');
    plotCoefficientsComparison(wavelength, selectedVars, fullfile(outputDir, strFileName));
end

% 图3: 交集分析热图
%fprintf('\n3. 生成交集分析热图...\n');
%plotIntersectionHeatmap(wavelength, selectedVars, fullfile(outputDir, strFileName));

% 图4: 连续性分析
%fprintf('\n4. 生成连续性分析图...\n');
%plotContinuityAnalysis(wavelength, selectedVars, fullfile(outputDir, strFileName));

%fprintf('\n========== 分析完成 ==========\n');
%fprintf('所有图片已保存至: %s\n', outputDir);

%% ==================== 可视化函数定义 ====================

function plotAllMethodsVariableSelection(wavelength, selectedVars, strFileName)
% 功能：在同一图中显示所有方法的变量选择位置（散点图形式）
% 参数：
%   wavelength - 波长向量
%   selectedVars - 包含各方法选择变量的结构体
%   strFileName - 输出文件名前缀

% 创建图形窗口
fig = figure('Name', sprintf('All Methods Variable Selection - %s', strFileName), ...
    'Position', [100 100 1200 500]);

hold on;

% 定义方法和颜色 - 使用MATLAB默认颜色
methods = {'LASSO', 'CovSel', 'CARS', 'SDOP'};
colors = lines(4);

% Y轴位置（每个方法一条水平线，整数坐标便于Y轴显示）
y_positions = [1, 2, 3, 4];

% 绘制每个方法选中的变量（散点图）
for m = 1:length(methods)
    method = methods{m};
    if isfield(selectedVars, method)
        vars = selectedVars.(method);
        y_pos = y_positions(m);
        
        % 获取选中变量对应的波长
        selectedWavelengths = wavelength(vars(vars <= length(wavelength)));
        
        % 创建与选中变量数量相同的Y坐标（全部等于该方法的y_pos）
        y_coords = ones(size(selectedWavelengths)) * y_pos;
        
        % 绘制散点（使用 '|' 标记表示竖线样式的点，或 'o' 表示圆点）
        scatter(selectedWavelengths, y_coords, 50, colors(m, :), '|', ...
            'LineWidth', 2, 'DisplayName', method);
    end
end

% 设置图形属性 - 统一横坐标范围
xlim([1100 2500]);
ylim([0.5 4.5]);
xlabel('Wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('');
title(sprintf('Variable Selection Comparison - All Methods\nSelected Variable Positions'), ...
    'FontSize', 14, 'FontWeight', 'bold');

% 设置Y轴显示方法名称
set(gca, 'YTick', y_positions, 'YTickLabel', methods);
set(gca, 'YTickLabelRotation', 0);
box on;
grid on;

% 保存图形
saveas(fig, sprintf('%s_AllMethods_VariableSelection.png', strFileName));
fprintf('  Saved: %s_AllMethods_VariableSelection.png\n', strFileName);
close(fig);
end

function plotVariableSelectionComparison(wavelength, selectedVars, strFileName)
% 功能：展示四种算法的变量选择特征对比（4个子图）
% 参数：
%   wavelength - 波长向量
%   selectedVars - 包含各方法选择变量的结构体
%   strFileName - 输出文件名前缀

% 创建图形窗口
fig = figure('Name', sprintf('Variable Selection Comparison - %s', strFileName), ...
    'Position', [100 100 1000 800]);

% 定义颜色 - 使用MATLAB默认颜色（lines函数）
colors = lines(4);
color_lasso = colors(1, :);   % LASSO
color_covsel = colors(2, :);  % CovSel
color_cars = colors(3, :);    % CARS
color_sdop = colors(4, :);    % SDOP

% 统一横坐标范围
xlim_range = [1100 2500];

% ===== Subplot 1: LASSO =====
subplot(4, 1, 1);
hold on;
if isfield(selectedVars, 'LASSO')
    selected_vars = selectedVars.LASSO;
    % 绘制细竖线，添加DisplayName用于legend
    for j = 1:length(selected_vars)
        idx = selected_vars(j);
        if idx <= length(wavelength)
            if j == 1
                plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                    'Color', color_lasso, 'LineWidth', 0.5, 'DisplayName', 'LASSO');
            else
                plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                    'Color', color_lasso, 'LineWidth', 0.5);
            end
        end
    end
end
xlim(xlim_range);
ylim([0 1]);
title(sprintf('Variable Selection Comparison - %s', strFileName), 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best');
set(gca, 'YTick', []);
set(gca, 'XTickLabel', []);
box on;

% ===== Subplot 2: CovSel =====
subplot(4, 1, 2);
hold on;
if isfield(selectedVars, 'CovSel')
    selected_vars = selectedVars.CovSel;
    % 绘制细竖线，添加DisplayName用于legend
    for j = 1:length(selected_vars)
        idx = selected_vars(j);
        if idx <= length(wavelength)
            if j == 1
                plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                    'Color', color_covsel, 'LineWidth', 0.5, 'DisplayName', 'CovSel');
            else
                plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                    'Color', color_covsel, 'LineWidth', 0.5);
            end
        end
    end
end
xlim(xlim_range);
ylim([0 1]);
legend('Location', 'best');
set(gca, 'YTick', []);
set(gca, 'XTickLabel', []);
box on;

% ===== Subplot 3: CARS =====
subplot(4, 1, 3);
hold on;
if isfield(selectedVars, 'CARS')
    selected_vars = selectedVars.CARS;
    % 绘制选中的变量（稍粗的竖线），添加DisplayName用于legend
    for j = 1:length(selected_vars)
        idx = selected_vars(j);
        if idx <= length(wavelength)
            if j == 1
                plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                    'Color', color_cars, 'LineWidth', 1.5, 'DisplayName', 'CARS');
            else
                plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                    'Color', color_cars, 'LineWidth', 1.5);
            end
        end
    end
end
xlim(xlim_range);
ylim([0 1]);
legend('Location', 'best');
set(gca, 'YTick', []);
set(gca, 'XTickLabel', []);
box on;

% ===== Subplot 4: SDOP =====
% 显示连续色块
subplot(4, 1, 4);
hold on;
if isfield(selectedVars, 'SDOP')
    selected_vars = selectedVars.SDOP;
    % 使用单一蓝色显示SDOP选择
    for j = 1:length(selected_vars)
        idx = selected_vars(j);
        if idx <= length(wavelength)
            if j == 1
                plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                    'Color', color_sdop, 'LineWidth', 2, 'DisplayName', 'SDOP');
            else
                plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                    'Color', color_sdop, 'LineWidth', 2);
            end
        end
    end
end
xlim(xlim_range);
ylim([0 1]);
legend('Location', 'best');
xlabel('Wavelength (nm)', 'FontSize', 12);
set(gca, 'YTick', []);
box on;

% 保存图形
saveas(fig, sprintf('%s_VariableSelection_Comparison.png', strFileName));
fprintf('  Saved: %s_VariableSelection_Comparison.png\n', strFileName);
close(fig);
end

function plotIntersectionHeatmap(wavelength, selectedVars, strFileName)
% 功能：绘制方法间交集分析热图
% 参数：
%   wavelength - 波长向量
%   selectedVars - 包含各方法选择变量的结构体
%   strFileName - 输出文件名前缀

methods = {'LASSO', 'CovSel', 'CARS', 'SDOP'};
nMethods = length(methods);

% 创建逻辑矩阵
nTotalVars = length(wavelength);
selectionMatrix = false(nTotalVars, nMethods);
for i = 1:nMethods
    if isfield(selectedVars, methods{i})
        selectionMatrix(selectedVars.(methods{i}), i) = true;
    end
end

% 计算交集矩阵
intersectionMatrix = zeros(nMethods, nMethods);
jaccardMatrix = zeros(nMethods, nMethods);

for i = 1:nMethods
    for j = 1:nMethods
        set1 = selectedVars.(methods{i});
        set2 = selectedVars.(methods{j});
        intersection = intersect(set1, set2);
        union = unique([set1; set2]);
        intersectionMatrix(i,j) = length(intersection);
        jaccardMatrix(i,j) = length(intersection) / length(union);
    end
end

% 图1: 变量选择热图
fig1 = figure('Name', 'Selection Heatmap', 'Position', [100 100 900 400]);
imagesc(selectionMatrix');
colormap([0.95 0.95 0.95; 0.2 0.5 0.8]);
set(gca, 'YTick', 1:nMethods, 'YTickLabel', methods);
xlabel('Variable Index');
title('Variable Selection Pattern (Blue = Selected)');
% 添加网格线
hold on;
for i = 0.5:1:nMethods+0.5
    plot([0.5 nTotalVars+0.5], [i i], 'k-', 'LineWidth', 0.3);
end
for i = 0.5:100:nTotalVars+0.5
    plot([i i], [0.5 nMethods+0.5], 'k-', 'LineWidth', 0.1);
end
hold off;
saveas(fig1, sprintf('%s_Selection_Heatmap.png', strFileName));
fprintf('  Saved: %s_Selection_Heatmap.png\n', strFileName);
close(fig1);

% 图2: Jaccard相似度热图
fig2 = figure('Name', 'Jaccard Similarity', 'Position', [150 150 600 500]);
imagesc(jaccardMatrix);
colormap('parula');
colorbar;
caxis([0 1]);
set(gca, 'XTick', 1:nMethods, 'XTickLabel', methods, 'XTickLabelRotation', 45);
set(gca, 'YTick', 1:nMethods, 'YTickLabel', methods);
title('Jaccard Similarity Between Methods');
% 添加数值标注
for i = 1:nMethods
    for j = 1:nMethods
        text(j, i, sprintf('%.3f', jaccardMatrix(i,j)), ...
            'HorizontalAlignment', 'center', ...
            'Color', 'white', 'FontWeight', 'bold', 'FontSize', 11);
    end
end
saveas(fig2, sprintf('%s_Jaccard_Similarity.png', strFileName));
fprintf('  Saved: %s_Jaccard_Similarity.png\n', strFileName);
close(fig2);

% 打印统计结果
fprintf('\n方法间交集数量矩阵:\n');
intersectionTable = array2table(intersectionMatrix, 'VariableNames', methods, 'RowNames', methods);
disp(intersectionTable);

fprintf('\nJaccard相似度矩阵:\n');
jaccardTable = array2table(jaccardMatrix, 'VariableNames', methods, 'RowNames', methods);
disp(jaccardTable);
end

function plotContinuityAnalysis(wavelength, selectedVars, strFileName)
% 功能：分析并可视化变量选择的连续性
% 参数：
%   wavelength - 波长向量
%   selectedVars - 包含各方法选择变量的结构体
%   strFileName - 输出文件名前缀

methods = {'LASSO', 'CovSel', 'CARS', 'SDOP'};
nMethods = length(methods);
colors = [0.2 0.2 0.2; 0.5 0.5 0.5; 0.8 0.2 0.2; 0.2 0.5 0.8];

% 计算连续性统计
continuityStats = table('Size', [nMethods, 5], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Method', 'NSegments', 'AvgSegmentLength', 'MaxSegmentLength', 'CoveragePercent'});

for i = 1:nMethods
    vars = selectedVars.(methods{i});
    
    % 找出连续段
    if isempty(vars)
        nSegments = 0;
        avgLength = 0;
        maxLength = 0;
    else
        diffs = diff(vars);
        segmentBreaks = find(diffs > 1);
        nSegments = length(segmentBreaks) + 1;
        
        % 计算每段长度
        segmentLengths = zeros(nSegments, 1);
        startIdx = 1;
        for j = 1:length(segmentBreaks)
            segmentLengths(j) = segmentBreaks(j) - startIdx + 1;
            startIdx = segmentBreaks(j) + 1;
        end
        segmentLengths(end) = length(vars) - startIdx + 1;
        
        avgLength = mean(segmentLengths);
        maxLength = max(segmentLengths);
    end
    
    continuityStats.Method(i) = methods{i};
    continuityStats.NSegments(i) = nSegments;
    continuityStats.AvgSegmentLength(i) = avgLength;
    continuityStats.MaxSegmentLength(i) = maxLength;
    continuityStats.CoveragePercent(i) = length(vars) / length(wavelength) * 100;
end

% 显示统计结果
disp(continuityStats);

% 绘制连续性对比图
fig = figure('Name', 'Continuity Analysis', 'Position', [200 200 1200 400]);

% Subplot 1: 连续段数量
subplot(1, 3, 1);
bar(continuityStats.NSegments, 'FaceColor', 'flat');
for i = 1:nMethods
    fig.Children(1).Children(i).CData = colors(i, :);
end
set(gca, 'XTickLabel', methods);
ylabel('Number of Segments');
title('Continuity: Number of Segments\n(Lower = More Continuous)');
for i = 1:nMethods
    text(i, continuityStats.NSegments(i) + max(continuityStats.NSegments)*0.02, ...
        num2str(continuityStats.NSegments(i)), 'HorizontalAlignment', 'center', 'FontSize', 10);
end

% Subplot 2: 平均段长度
subplot(1, 3, 2);
bar(continuityStats.AvgSegmentLength, 'FaceColor', 'flat');
for i = 1:nMethods
    fig.Children(1).Children(i).CData = colors(i, :);
end
set(gca, 'XTickLabel', methods);
ylabel('Average Segment Length');
title('Continuity: Average Segment Length\n(Higher = More Continuous)');
for i = 1:nMethods
    text(i, continuityStats.AvgSegmentLength(i) + max(continuityStats.AvgSegmentLength)*0.02, ...
        sprintf('%.1f', continuityStats.AvgSegmentLength(i)), 'HorizontalAlignment', 'center', 'FontSize', 10);
end

% Subplot 3: 变量选择覆盖率
subplot(1, 3, 3);
bar(continuityStats.CoveragePercent, 'FaceColor', 'flat');
for i = 1:nMethods
    fig.Children(1).Children(i).CData = colors(i, :);
end
set(gca, 'XTickLabel', methods);
ylabel('Percentage (%)');
title('Variable Selection Coverage');
for i = 1:nMethods
    text(i, continuityStats.CoveragePercent(i) + max(continuityStats.CoveragePercent)*0.02, ...
        sprintf('%.1f%%', continuityStats.CoveragePercent(i)), 'HorizontalAlignment', 'center', 'FontSize', 10);
end

saveas(fig, sprintf('%s_Continuity_Analysis.png', strFileName));
fprintf('  Saved: %s_Continuity_Analysis.png\n', strFileName);
close(fig);
end

function plotCoefficientsComparison(wavelength, selectedVars, strFileName)
% 功能：绘制各变量选择方法的回归系数对比（不含DOP原始方法）
% 参数：
%   wavelength - 波长向量
%   selectedVars - 包含各方法选择变量和系数的结构体
%   strFileName - 输出文件名前缀

% 创建图形窗口
fig = figure('Name', sprintf('Coefficients Comparison - %s', strFileName), ...
    'Position', [100 100 1200 600]);

hold on;

% 定义方法和颜色（不含DOP，只包含变量选择方法）- 使用MATLAB默认颜色
methods = {'LASSO', 'CovSel', 'CARS', 'SDOP'};
colors = lines(4);

% 绘制每个方法的系数
for i = 1:length(methods)
    method = methods{i};
    coefField = [method '_Coef'];
    
    if isfield(selectedVars, coefField)
        beta = selectedVars.(coefField);
        
        % 确保系数长度与波长一致
        if length(beta) > length(wavelength)
            beta = beta(1:length(wavelength));
        elseif length(beta) < length(wavelength)
            beta = [beta; zeros(length(wavelength) - length(beta), 1)];
        end
        
        plot(wavelength, beta, 'Color', colors(i,:), 'LineWidth', 1.5, ...
            'DisplayName', method);
    elseif isfield(selectedVars, 'Coefficients') && isfield(selectedVars.Coefficients, method)
        % 备选：从Coefficients子结构体中获取
        beta = selectedVars.Coefficients.(method);
        
        if length(beta) > length(wavelength)
            beta = beta(1:length(wavelength));
        elseif length(beta) < length(wavelength)
            beta = [beta; zeros(length(wavelength) - length(beta), 1)];
        end
        
        plot(wavelength, beta, 'Color', colors(i,:), 'LineWidth', 1.5, ...
            'DisplayName', method);
    end
end

% 设置图形属性
xlabel('Wavelength (nm)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('\beta', 'Interpreter', 'tex', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Regression Coefficients Comparison - %s\n(Variable Selection Methods Only)', strFileName), ...
    'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 11);
grid on;
box on;

% 保存图形
saveas(fig, sprintf('%s_Coefficients_Comparison.png', strFileName));
fprintf('  Saved: %s_Coefficients_Comparison.png\n', strFileName);
close(fig);
end
