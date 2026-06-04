%% ========================================================================
% scripts6_comparison.m
% ========================================================================
%
% 主要功能：
% 本脚本用于对比不同变量选择方法在DOP（Domain-Invariant Orthogonal Projection）
% 框架下的性能。包含以下方法：
%   - PLS (偏最小二乘，基线方法)
%   - DOP (标准DOP，无变量选择)
%   - DOP-LASSO (L1正则化稀疏回归)
%   - DOP-CovSel (协方差最大化变量选择)
%   - DOP-CARS (竞争性自适应重加权采样)
%   - SDOP (稀疏动态正交投影，本文提出的方法)
%
% 脚本执行流程：
%   1. 加载源域和目标域数据
%   2. 使用Duplex算法划分训练集和测试集
%   3. 计算DOP投影矩阵
%   4. 对各方法进行留一法(LOO)交叉验证优化参数
%   5. 使用1-SE准则选择最优参数
%   6. 在测试集上评估并输出性能对比表格
%   7. 生成回归系数对比图和变量选择特征图
%
% 适用数据集：
%   - 玉米数据集(mp5, m5, mp6): 波长范围1100-2498nm
%   - 近红外光谱数据集(spec1, spec2): 波长范围800-1400nm
%
% ========================================================================
% 修改日志：
% ========================================================================
% 2026-04-25: 初始版本创建，实现基础对比框架
% 2026-06-02: 添加变量选择特征对比可视化函数

% ========================================================================


clear;
close all;

%% Configuration
var_threshold_array = [0.80, 0.90, 0.95, 0.99, 0.999];
nMaxLV = 10;
splite_percent1 = 0.3;
splite_percent2 = 0.3;
nFolds = 10;  % Number of folds for cross-validation

SrcArray   = ["mp5","mp5","m5","m5","mp6","mp6","spec1","spec2"];
DestArray = ["m5","mp6","mp6","mp5","m5","mp5","spec2","spec1"];
skiplist = [1,1,1,1,1,0,1,1];

% Predefined optimal parameters (8 elements, matching SrcArray)
selectedVd =  [0.99, 0.95, 0.95, 0.95, 0.99, 0.95, 0.99, 0.99];
LV_PLS =      [6,    6,     6,     6,    6,    6,    3,    3   ];
LV_DOP =      [5,    5,     6,     5,    5,    5,    3,    3   ];
LV_SDOP =     [5,    7,     7,     7,    5,    7,    3,    4   ];
nVarX_SDOP =  [10,   10,    10,    10,   10,   10,   5,    5   ];
sparity =     [5,    10,    20,    50,   100];
% Variable selection parameters for each method
% LASSO: lambda range
lasso_lambda = logspace(-4, 3, 20);
% CovSel: number of variables to select
covsel_nVars = 1:20;
% CARS: using default parameters, max LV
cars_maxLV = 10;
cars_nIter = 20;
% SDOP: original sparse PLS parameters
sdop_nVars = [10, 10, 10, 10, 10, 10, 5, 5];  % Predefined optimal nVarX for each scenario
sdop_LV =    [5,  7,  7,  7,  5,  7,  3, 4];   % Predefined optimal LV for each scenario

loadData;

for i = 1:1:length(skiplist)
    % close all;
    strFileName = SrcArray(i)+"to"+DestArray(i);
    if skiplist(i)==1
        continue;
    end
    
    % 定义结果保存文件名
    resultsFileName = sprintf('%s_ComparisonResults.mat', strFileName);
    
    % 检查是否已存在计算结果
    if exist(resultsFileName, 'file')
        fprintf('\n=== 发现已保存的结果文件: %s ===\n', resultsFileName);
        fprintf('正在加载并直接画图...\n');
        
        % 加载已保存的结果
        loadedData = load(resultsFileName);
        results = loadedData.results;
        wavelength = loadedData.wavelength;
        beta_dop = loadedData.beta_dop;
        
        % 加载selectedVariables（如果存在）
        if isfield(loadedData, 'selectedVariables')
            selectedVariables = loadedData.selectedVariables;
        else
            selectedVariables = struct();
        end
        
        % 直接进行可视化
        plotResults(results, wavelength, beta_dop, strFileName, i, selectedVariables);
        
        fprintf('=== 场景 %s 处理完成（从文件加载）===\n\n', strFileName);
        continue;  % 跳过后续计算
    end
    
    fprintf("\nConduct %s to %s \n",SrcArray(i),DestArray(i));
    str = sprintf("Xs = %sX;ys = %sY;Xt = %sX;yt = %sY;",SrcArray(i),SrcArray(i),DestArray(i),DestArray(i));
    eval(str);
    [TrainXs, TrainYs, TestXs, TestYs] = preprocess_data(Xs,  ys, splite_percent1);
    if splite_percent2<=0.5
        [TrainXt, TrainYt, TestXt, TestYt] = preprocess_data(Xt,  yt, splite_percent2);
    else
        [TestXt, TestYt,TrainXt, TrainYt ] = preprocess_data(Xt,  yt, 1-splite_percent2);
    end
    epsilon = 1/size(TrainXs,1);
    
    % DOP projection (shared by all methods)
    E = dop2(TrainXs, TrainYs, TrainXt, TrainYt, epsilon, selectedVd(i));
    XCorrected = TrainXs * E;
    
    % DOP baseline
    [~, ~, ~, ~, beta_dop, ~, ~] = plsregress(XCorrected, TrainYs, LV_DOP(i), 'CV', nFolds);
    
    % Define wavelength for plotting
    if i > 8
        wavelength = 1:1:size(XCorrected,2);
    elseif i > 6
        wavelength = 800:2:1400;
    else
        wavelength = 1100:2:2498;
    end
    % Ensure wavelength matches data dimension
    if length(wavelength) > size(XCorrected, 2)
        wavelength = wavelength(1:size(XCorrected, 2));
    elseif length(wavelength) < size(XCorrected, 2)
        wavelength = linspace(wavelength(1), wavelength(end), size(XCorrected, 2));
    end
    
    disp("<<===============================================================>>");
    disp("Evaluate Source domain:"+ SrcArray(i)+" to Target domain:"+DestArray(i));
    
    % 评估所有方法并收集结果
    results = struct();
    
    % 1. PLS (baseline, no DOP)
    [~, ~, ~, ~, beta_PLS, ~, ~] = plsregress(TrainXs, TrainYs, LV_PLS(i), 'CV', nFolds);
    [results.PLS.RMSEP, results.PLS.R2] = evaluate_dataset(TestXt, TestYt, eye(size(E,1)), beta_PLS);
    results.PLS.LV = LV_PLS(i);
    results.PLS.nVar = size(TrainXs, 2);
    results.PLS.sparsity = sum(beta_PLS(2:end)==0) / length(beta_PLS(2:end));
    
    % 2. DOP (baseline, no variable selection)
    [results.DOP.RMSEP, results.DOP.R2] = evaluate_dataset(TestXt, TestYt, E, beta_dop);
    results.DOP.LV = LV_DOP(i);
    results.DOP.nVar = size(XCorrected, 2);
    results.DOP.sparsity = sum(beta_dop(2:end)==0) / length(beta_dop(2:end));
    
    % Use LOO (Leave-One-Out) for all methods: nFolds = nSamples
    nFolds_LOO = size(XCorrected, 1);
    
    % 3. DOP-LASSO (LOO)
    fprintf('\n  Running DOP-LASSO with LOO CV...\n');
    results.DOP_LASSO = runDOP_LASSO(XCorrected, TrainYs, TestXt, TestYt, E, lasso_lambda, nFolds_LOO, nMaxLV);
    
    % 4. DOP-CovSel (LOO)
    fprintf('\n  Running DOP-CovSel with LOO CV...\n');
    results.DOP_CovSel = runDOP_CovSel(XCorrected, TrainYs, TestXt, TestYt, E, covsel_nVars, nFolds_LOO, nMaxLV);
    
    % 5. DOP-CARS (LOO - pass nSamples as fold parameter for LOO)
    fprintf('\n  Running DOP-CARS with LOO...\n');
    results.DOP_CARS = runDOP_CARS(XCorrected, TrainYs, TestXt, TestYt, E, cars_maxLV, cars_nIter, nFolds_LOO);
    
    % 6. Original SDOP (with predefined parameters, LOO - same as scripts6.m)
    fprintf('\n  Running original SDOP with predefined parameters (LOO)...\n');
    results.SDOP = runSDOP_original(XCorrected, TrainYs, TestXt, TestYt, E, sdop_nVars(i), sdop_LV(i));
    
    % 打印结果表格
    printResultsTable(results, SrcArray(i), DestArray(i));
    
    % 收集变量选择结果（用于保存和画图）
    selectedVariables = struct();
    selectedVariables.wavelength = wavelength;
    
    % LASSO: 非零系数位置
    if isfield(results.DOP_LASSO, 'B')
        selectedVariables.LASSO = find(results.DOP_LASSO.B ~= 0);
    end
    
    % CovSel: 选中的变量
    if isfield(results.DOP_CovSel, 'selectedVars')
        selectedVariables.CovSel = results.DOP_CovSel.selectedVars;
    end
    
    % CARS: 选中的变量
    if isfield(results.DOP_CARS, 'selectedVars')
        selectedVariables.CARS = results.DOP_CARS.selectedVars;
    end
    
    % SDOP: 非零系数位置
    if isfield(results.SDOP, 'model') && isfield(results.SDOP.model, 'B')
        selectedVariables.SDOP = find(results.SDOP.model.B ~= 0);
    end
    
    % 保存所有计算结果到mat文件（包括results、wavelength、beta_dop、selectedVariables）
    save(resultsFileName, 'results', 'wavelength', 'beta_dop', 'selectedVariables', '-v7.3');
    fprintf('\n  Saved all results to: %s\n', resultsFileName);
    
    % 对于mp6->mp5场景（i=6），额外保存变量选择结果（兼容原有代码）
    if i == 6
        saveFileName = sprintf('%s_SelectedVariables.mat', strFileName);
        save(saveFileName, 'selectedVariables', '-v7.3');
        fprintf('  Saved selected variables to: %s\n', saveFileName);
    end
    
    % 执行可视化
    plotResults(results, wavelength, beta_dop, strFileName, i, selectedVariables);
end

%% 统一可视化函数
function plotResults(results, wavelength, beta_dop, strFileName, scenarioIdx, selectedVariables)
% 功能：统一处理所有可视化
% 参数：
%   results - 包含所有方法结果的结构体
%   wavelength - 波长向量
%   beta_dop - DOP基线方法的回归系数
%   strFileName - 场景名称
%   scenarioIdx - 场景索引
%   selectedVariables - 各方法选择的变量

fprintf('\n  Generating visualizations...\n');

% Visualization: Regression coefficients comparison
plotCoefficientsComparison(wavelength, beta_dop, results, strFileName, scenarioIdx);

% 仅针对前6个场景（mp5, m5, mp6相关）
if scenarioIdx <= 6
    %plotVariableSelectionComparison(wavelength, results, strFileName, scenarioIdx);
end

% 对于mp6->mp5场景（i=6），绘制所有方法的变量选择对比图
if scenarioIdx == 6 && ~isempty(fieldnames(selectedVariables))
    plotAllMethodsVariableSelection(wavelength, selectedVariables, strFileName);
end

fprintf('  Visualizations completed.\n');
end

%% DOP-LASSO with 1-SE rule
function result = runDOP_LASSO(X_train, Y_train, X_test, Y_test, E, lambdaRange, nFolds, maxLV)
nSamples = size(X_train, 1);
nFolds = min(nFolds, nSamples);
nLambda = length(lambdaRange);

RMSECV = zeros(nLambda, 1);
nVars = zeros(nLambda, 1);

cvIndices = createCVIndices(nSamples, nFolds);

for i = 1:nLambda
    lambda = lambdaRange(i);
    Yhat_cv = zeros(nSamples, 1);
    
    for fold = 1:nFolds
        testIdx = (cvIndices == fold);
        trainIdx = ~testIdx;
        
        X_tr = X_train(trainIdx, :);
        Y_tr = Y_train(trainIdx);
        X_te = X_train(testIdx, :);
        
        % LASSO regression
        B = lasso(X_tr, Y_tr, 'Lambda', lambda, 'Standardize', true);
        intercept = mean(Y_tr - X_tr * B);
        
        Yhat_cv(testIdx) = X_te * B + intercept;
    end
    
    RMSECV(i) = sqrt(mean((Y_train - Yhat_cv).^2));
    nVars(i) = sum(B ~= 0);
end

% 1-SE rule for lambda selection
[minRMSECV, ~] = min(RMSECV);
se = std(RMSECV) / sqrt(nLambda);
threshold = minRMSECV + se;
candidates = find(RMSECV <= threshold);
bestIdx = candidates(end);  % Select most sparse (largest lambda)

% Retrain with optimal lambda
bestLambda = lambdaRange(bestIdx);
B = lasso(X_train, Y_train, 'Lambda', bestLambda, 'Standardize', true);
intercept = mean(Y_train - X_train * B);

% Evaluate on test set
Yhat = X_test * E * B + intercept;
[rmsep, r2] = calculate_metrics(Y_test, Yhat);

result.RMSEP = rmsep;
result.R2 = r2;
result.LV = maxLV;  % LASSO doesn't use LV, use max for consistency
result.nVar = nVars(bestIdx);
result.sparsity = sum(B == 0) / length(B);
result.lambda = bestLambda;
result.B = B;
result.intercept = intercept;
end

%% DOP-CovSel with 1-SE rule
function result = runDOP_CovSel(X_train, Y_train, X_test, Y_test, E, nVarRange, nFolds, maxLV)
nSamples = size(X_train, 1);
nFolds = min(nFolds, nSamples);
nParams = length(nVarRange);

RMSECV = zeros(nParams, maxLV);

cvIndices = createCVIndices(nSamples, nFolds);

for i = 1:nParams
    nVar = nVarRange(i);
    
    for lv = 1:maxLV
        Yhat_cv = zeros(nSamples, 1);
        
        for fold = 1:nFolds
            testIdx = (cvIndices == fold);
            trainIdx = ~testIdx;
            
            X_tr = X_train(trainIdx, :);
            Y_tr = Y_train(trainIdx);
            X_te = X_train(testIdx, :);
            Y_te = Y_train(testIdx);
            
            % CovSel variable selection
            [selectedVars, ~, ~, ~, ~] = covsel(X_tr, Y_tr, nVar, 1, 1);
            selectedVars = selectedVars(1:min(nVar, length(selectedVars)));
            
            % PLS on selected variables
            if length(selectedVars) >= lv
                [xl, yl, xs, ys, beta, ~, ~] = plsregress(X_tr(:, selectedVars), Y_tr, lv);
                Yhat_cv(testIdx) = [ones(size(X_te, 1), 1), X_te(:, selectedVars)] * beta;
            else
                Yhat_cv(testIdx) = mean(Y_tr) * ones(sum(testIdx), 1);
            end
        end
        
        RMSECV(i, lv) = sqrt(mean((Y_train - Yhat_cv).^2));
    end
end

% 1-SE rule for (nVar, LV) selection
minRMSECV = min(RMSECV(:));
se = std(RMSECV(:)) / sqrt(numel(RMSECV));
threshold = minRMSECV + se;
[candidates_i, candidates_lv] = find(RMSECV <= threshold);

% Select most parsimonious: minimum nVar, then minimum LV
[~, sortIdx] = sort(candidates_i);
bestIdx = sortIdx(1);
bestNVarIdx = candidates_i(bestIdx);
bestLV = candidates_lv(bestIdx);

bestNVar = nVarRange(bestNVarIdx);

% Retrain with optimal parameters
[selectedVars, ~, ~, ~, ~] = covsel(X_train, Y_train, bestNVar, 1, 1);
selectedVars = selectedVars(1:min(bestNVar, length(selectedVars)));

[xl, yl, xs, ys, beta, ~, ~] = plsregress(X_train(:, selectedVars), Y_train, bestLV);

% Evaluate on test set
% Correct order: first project X_test with E, then select variables
X_test_projected = X_test * E;
Yhat = [ones(size(X_test, 1), 1), X_test_projected(:, selectedVars)] * beta;
[rmsep, r2] = calculate_metrics(Y_test, Yhat);

result.RMSEP = rmsep;
result.R2 = r2;
result.LV = bestLV;
result.nVar = length(selectedVars);
result.sparsity = 1 - (length(selectedVars) / size(X_train, 2));
result.selectedVars = selectedVars;
result.beta = beta;
end

%% DOP-CARS with 1-SE rule (built-in CARS)
function result = runDOP_CARS(X_train, Y_train, X_test, Y_test, E, maxLV, nIter, nFolds)
% CARS already has 1-SE rule built-in when selectLV=1
% nFolds: number of folds for CV. Use nSamples for LOO.
carsResult = carspls(X_train, Y_train, maxLV, nFolds, 'center', nIter, 1, 0, 0);

selectedVars = carsResult.vsel;
bestLV = carsResult.optLV;

% Retrain PLS with selected variables
[xl, yl, xs, ys, beta, ~, ~] = plsregress(X_train(:, selectedVars), Y_train, bestLV);

% Evaluate on test set
% Correct order: first project X_test with E, then select variables
X_test_projected = X_test * E;
Yhat = [ones(size(X_test, 1), 1), X_test_projected(:, selectedVars)] * beta;
[rmsep, r2] = calculate_metrics(Y_test, Yhat);

result.RMSEP = rmsep;
result.R2 = r2;
result.LV = bestLV;
result.nVar = length(selectedVars);
result.sparsity = 1 - (length(selectedVars) / size(X_train, 2));
result.selectedVars = selectedVars;
result.beta = beta;
end

%% Original SDOP (with predefined parameters)
function result = runSDOP_original(X_train, Y_train, X_test, Y_test, E, nVar, nLV)
% Train with predefined parameters (no CV optimization)
model = sparsepls1(X_train, Y_train, nLV, nVar);

% Evaluate on test set
Yhat = X_test * E * model.B + model.B0;
[rmsep, r2] = calculate_metrics(Y_test, Yhat);

result.RMSEP = rmsep;
result.R2 = r2;
result.LV = nLV;
result.nVar = nVar;
result.sparsity = sum(model.B == 0) / length(model.B);
result.model = model;
end

%% 数据预处理函数
function [TrainX, TrainY, TestX, TestY] = preprocess_data(X, y, splite_percent)
X = apply_savgol(X);
[model_s, test_s] = duplex(X, round(splite_percent * size(X, 1)));

TrainX = X(model_s, :);
TrainY = y(model_s);
TestX = X(test_s, :);
TestY = y(test_s);
end

%% Savitzky-Golay 平滑滤波
function X = apply_savgol(X)
for i = 1:size(X, 1)
    X(i, :) = savgol(X(i, :), 15, 2, 0);
end
end

%% 评估数据集预测性能
function [rmsep, r2] = evaluate_dataset(X, Y, E, model)
if isstruct(model)
    Yhat = X * E * model.B + model.B0;
else
    Yhat = [ones(size(X, 1), 1), X * E] * model;
end
[rmsep, r2] = calculate_metrics(Y, Yhat);
end

%% 打印结果表格
function printResultsTable(results, source, target)
fprintf('\n');
fprintf('====================== Results Summary ======================\n');
fprintf('Source: %s -> Target: %s\n', source, target);
fprintf('%-12s %-6s %-8s %-12s %-10s %-8s %-10s\n', 'Method', 'LV', 'nVar', 'OptParam', 'RMSEP', 'R²p', 'Sparsity');
fprintf('%s\n', repmat('-', 1, 90));

% PLS: no special parameter
fprintf('%-12s %-6d %-8d %-12s %-10.2f %-8.2f %-10.2f\n', ...
    'PLS', results.PLS.LV, results.PLS.nVar, '-', results.PLS.RMSEP, results.PLS.R2, results.PLS.sparsity);

% DOP: no special parameter
fprintf('%-12s %-6d %-8d %-12s %-10.2f %-8.2f %-10.2f\n', ...
    'DOP', results.DOP.LV, results.DOP.nVar, '-', results.DOP.RMSEP, results.DOP.R2, results.DOP.sparsity);

% DOP-LASSO: show lambda
if isfield(results.DOP_LASSO, 'lambda')
    optParam = sprintf('λ=%.4f', results.DOP_LASSO.lambda);
else
    optParam = '-';
end
fprintf('%-12s %-6d %-8d %-12s %-10.2f %-8.2f %-10.2f\n', ...
    'DOP-LASSO', results.DOP_LASSO.LV, results.DOP_LASSO.nVar, optParam, results.DOP_LASSO.RMSEP, results.DOP_LASSO.R2, results.DOP_LASSO.sparsity);

% DOP-CovSel: show number of selected variables
if isfield(results.DOP_CovSel, 'selectedVars')
    optParam = sprintf('vars=%d', length(results.DOP_CovSel.selectedVars));
else
    optParam = sprintf('nVar=%d', results.DOP_CovSel.nVar);
end
fprintf('%-12s %-6d %-8d %-12s %-10.2f %-8.2f %-10.2f\n', ...
    'DOP-CovSel', results.DOP_CovSel.LV, results.DOP_CovSel.nVar, optParam, results.DOP_CovSel.RMSEP, results.DOP_CovSel.R2, results.DOP_CovSel.sparsity);

% DOP-CARS: show number of selected variables
if isfield(results.DOP_CARS, 'selectedVars')
    optParam = sprintf('vars=%d', length(results.DOP_CARS.selectedVars));
else
    optParam = sprintf('nVar=%d', results.DOP_CARS.nVar);
end
fprintf('%-12s %-6d %-8d %-12s %-10.2f %-8.2f %-10.2f\n', ...
    'DOP-CARS', results.DOP_CARS.LV, results.DOP_CARS.nVar, optParam, results.DOP_CARS.RMSEP, results.DOP_CARS.R2, results.DOP_CARS.sparsity);

% SDOP: show predefined nVar
if isfield(results.SDOP, 'nVar')
    optParam = sprintf('nVar=%d', results.SDOP.nVar);
else
    optParam = '-';
end
fprintf('%-12s %-6d %-8d %-12s %-10.2f %-8.2f %-10.2f\n', ...
    'SDOP', results.SDOP.LV, results.SDOP.nVar, optParam, results.SDOP.RMSEP, results.SDOP.R2, results.SDOP.sparsity);

fprintf('%s\n', repmat('=', 1, 90));
fprintf('\n');
end

%% Create cross-validation indices (compatible with and without crossvalind)
function cvIndices = createCVIndices(nSamples, nFolds)
if exist('crossvalind', 'file')
    cvIndices = crossvalind('Kfold', nSamples, nFolds);
else
    % Fallback: manual fold assignment
    cvIndices = mod(0:nSamples-1, nFolds)' + 1;
    % Shuffle for randomness
    rng('default');
    shuffleIdx = randperm(nSamples);
    cvIndices = cvIndices(shuffleIdx);
end
end

%% 绘制回归系数对比图
function plotCoefficientsComparison(wavelength, beta_dop, results, strFileName, scenarioIdx)
% Ensure wavelength matches beta length
beta_length = length(beta_dop) - 1;  % Exclude intercept
if length(wavelength) > beta_length
    wavelength = wavelength(1:beta_length);
elseif length(wavelength) < beta_length
    wavelength = linspace(wavelength(1), wavelength(end), beta_length);
end

preStr = "_coef_comparison";
fig = figure('Name', strFileName + preStr);

% Plot all methods' coefficients (excluding DOP-SPLS, including SDOP)
methods = {'DOP_LASSO', 'DOP_CovSel', 'DOP_CARS', 'SDOP'};
% 使用MATLAB默认颜色（lines函数）
colors = lines(4);

for i = 1:length(methods)
    method = methods{i};
    if isfield(results, method)
        if strcmp(method, 'DOP')
            beta = beta_dop(2:end);
        elseif strcmp(method, 'DOP_LASSO')
            beta = results.(method).B;
        elseif strcmp(method, 'DOP_CovSel') || strcmp(method, 'DOP_CARS')
            % Create full coefficient vector with zeros
            beta = zeros(length(wavelength), 1);
            if isfield(results.(method), 'selectedVars') && isfield(results.(method), 'beta')
                selectedVars = results.(method).selectedVars;
                beta_pls = results.(method).beta;
                if length(beta_pls) > 1
                    beta(selectedVars) = beta_pls(2:end);
                end
            end
        else  % SDOP
            beta = results.(method).model.B;
        end
        
        % Ensure beta matches wavelength length
        if length(beta) > length(wavelength)
            beta = beta(1:length(wavelength));
        elseif length(beta) < length(wavelength)
            beta = [beta; zeros(length(wavelength) - length(beta), 1)];
        end
        
        plot(wavelength, beta, 'Color', colors(i,:), 'LineWidth', 1.5);
        hold on;
    end
end

legend({'LASSO', 'CovSel', 'CARS', 'SDOP'}, 'Location', 'best');
xlabel('Wavelength (nm)');
ylabel('\beta', 'Interpreter', 'latex');
%title('Regression Coefficients Comparison');
SCIPlot;
end

%% 波长选择对比图
% 展示四种算法的变量选择特征：
% - LASSO: 孤立碎裂的点（细竖线）
% - CovSel: 孤立碎裂的点（细竖线）
% - CARS: 正常显示单次选择结果
% - SDOP: 连续彩色色块（突出2000-2400nm区域）
function plotVariableSelectionComparison(wavelength, results, strFileName, scenarioIdx)
% 仅处理玉米数据集（波长范围1100-2498nm）
nFeatures = length(wavelength);

% 创建图形窗口
fig = figure('Name', sprintf('Variable Selection Comparison - %s', strFileName), ...
    'Position', [100 100 800 1000]);

% 定义颜色 - 使用MATLAB默认颜色（lines函数）
colors = lines(4);
color_lasso = colors(1, :);   % LASSO
color_covsel = colors(2, :);  % CovSel
color_cars = colors(3, :);    % CARS
color_sdop = colors(4, :);    % SDOP

% ===== Subplot 1: LASSO =====
% 显示选中的变量位置（细竖线）
subplot(4, 1, 1);
hold on;
if isfield(results.DOP_LASSO, 'B')
    % 获取非零系数的位置
    selected_vars = find(results.DOP_LASSO.B ~= 0);
    % 绘制细竖线
    for j = 1:length(selected_vars)
        idx = selected_vars(j);
        if idx <= length(wavelength)
            plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                'Color', color_lasso, 'LineWidth', 0.5);
        end
    end
end
xlim([1000 2500]);
ylim([0 1]);
ylabel('LASSO', 'FontSize', 11, 'FontWeight', 'bold');
title(sprintf('Variable Selection Comparison - %s', strFileName), 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'YTick', []);
box on;
SCIPlot;

% ===== Subplot 2: CovSel =====
% 显示选中的变量位置（细竖线）
subplot(4, 1, 2);
hold on;
if isfield(results.DOP_CovSel, 'selectedVars')
    selected_vars = results.DOP_CovSel.selectedVars;
    % 绘制细竖线
    for j = 1:length(selected_vars)
        idx = selected_vars(j);
        if idx <= length(wavelength)
            plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                'Color', color_covsel, 'LineWidth', 0.5);
        end
    end
end
xlim([1100 2500]);
ylim([0 1]);
ylabel('CovSel', 'FontSize', 11, 'FontWeight', 'bold');
set(gca, 'YTick', []);
box on;
SCIPlot;

% ===== Subplot 3: CARS =====
% 正常显示单次实验选出的波段
subplot(4, 1, 3);
hold on;
if isfield(results.DOP_CARS, 'selectedVars')
    selected_vars = results.DOP_CARS.selectedVars;
    % 绘制选中的变量（稍粗的竖线）
    for j = 1:length(selected_vars)
        idx = selected_vars(j);
        if idx <= length(wavelength)
            plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                'Color', color_cars, 'LineWidth', 1.5);
        end
    end
end
xlim([1100 2500]);
ylim([0 1]);
ylabel('CARS', 'FontSize', 11, 'FontWeight', 'bold');
set(gca, 'YTick', []);
box on;
SCIPlot;

% ===== Subplot 4: SDOP (提出的方法) =====
% 显示连续彩色色块，突出2000-2400nm区域
subplot(4, 1, 4);
hold on;
if isfield(results.SDOP, 'model') && isfield(results.SDOP.model, 'B')
    % 获取SDOP选中的变量位置
    if isfield(results.SDOP, 'model') && isfield(results.SDOP.model, 'B')
        selected_vars = find(results.SDOP.model.B ~= 0);
        % 绘制选中的变量（使用统一颜色）
        for j = 1:length(selected_vars)
            idx = selected_vars(j);
            if idx <= length(wavelength)
                plot([wavelength(idx) wavelength(idx)], [0 1], '-', ...
                    'Color', color_sdop, 'LineWidth', 2);
            end
        end
    end
end
xlim([1100 2500]);
ylim([0 1]);
ylabel('SDOP (Proposed)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Wavelength (nm)', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'YTick', []);
box on;
SCIPlot;

% 添加总标题
sgtitle(sprintf('Variable Selection Characteristics Comparison\n%s', strFileName), ...
    'FontSize', 13, 'FontWeight', 'bold');

% 保存图形
saveas(fig, sprintf('%s_VariableSelection_Comparison.png', strFileName));
end

%% 绘制所有变量选择方法的选中变量位置对比图（用于mp6->mp5场景，散点图形式）
function plotAllMethodsVariableSelection(wavelength, selectedVars, strFileName)
% 创建图形窗口
fig = figure('Name', sprintf('All Methods Variable Selection - %s', strFileName));

hold on;

% 定义方法和颜色
methods = {'LASSO', 'CovSel', 'CARS', 'SDOP'};
methods = {'SDOP','CARS','CovSel','LASSO'  };
% 使用MATLAB默认颜色（lines函数）
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
        
        % 绘制散点（使用 '|' 标记表示竖线样式的点）
        scatter(selectedWavelengths, y_coords, 50, colors(5-m, :), '|', ...
            'LineWidth', 2, 'DisplayName', method);
    end
end

% 设置图形属性 - 统一横坐标范围
xlim([1000 2500]);
ylim([0.5 4.5]);
xlabel('Wavelength (nm)');
ylabel('');
%title(sprintf('Variable Selection Comparison - %s\nSelected Variable Positions', strFileName), ...
 %   'FontSize', 14, 'FontWeight', 'bold');

% 设置Y轴显示方法名称
set(gca, 'YTick', y_positions, 'YTickLabel', methods);
set(gca, 'YTickLabelRotation', 0);
box on;
grid on;
SCIPlot;

% 保存图形
saveas(fig, sprintf('%s_AllMethods_VariableSelection.png', strFileName));
fprintf('  Saved comparison figure to: %s_AllMethods_VariableSelection.png\n', strFileName);
end
