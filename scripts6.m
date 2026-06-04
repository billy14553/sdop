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
skiplist = [0,0,0,0,0,0,0,0];

% Predefined optimal parameters (8 elements, matching SrcArray)
selectedVd =  [0.99, 0.95, 0.95, 0.95, 0.99, 0.95, 0.99, 0.99];
LV_PLS =      [6,    6,     6,     6,    6,    6,    3,    3   ];
LV_DOP =      [5,    5,     6,     5,    5,    5,    3,    3   ];
LV_SDOP =     [5,    7,     7,     7,    5,    7,    3,    4   ];
nVarX_SDOP =  [10,   10,    10,    10,   10,   10,   5,    5   ];
sparity =     [5,    10,    20,    50,   100];

loadData;

for i = 1:1:length(skiplist)
    close all;
    strFileName = SrcArray(i)+"to"+DestArray(i);
    if skiplist(i)==1
        continue;
    end
    fprintf("Conduct %s to %s \n",SrcArray(i),DestArray(i));
    str = sprintf("Xs = %sX;ys = %sY;Xt = %sX;yt = %sY;",SrcArray(i),SrcArray(i),DestArray(i),DestArray(i));
    eval(str);
    [TrainXs, TrainYs, TestXs, TestYs] = preprocess_data(Xs,  ys, splite_percent1);
    if splite_percent2<=0.5
        [TrainXt, TrainYt, TestXt, TestYt] = preprocess_data(Xt,  yt, splite_percent2);
    else
        [TestXt, TestYt,TrainXt, TrainYt ] = preprocess_data(Xt,  yt, 1-splite_percent2);
    end
    epsilon = 1/size(TrainXs,1);
    RMSECV = zeros(length(var_threshold_array),nMaxLV);
    R2= zeros(length(var_threshold_array),nMaxLV);
    nFolds = size(TrainXs,1);
    for j = 1:1:length(var_threshold_array)
        [RMSECV(j,:),R2(j,:)] = CrossValidate_DOP(TrainXs, TrainYs, TrainXt, TrainYt, ...
            nMaxLV, epsilon, var_threshold_array(j), nFolds);
    end
    E = dop2(TrainXs, TrainYs, TrainXt, TrainYt, epsilon, selectedVd(i));
    XCorrected = TrainXs * E;
    [xl, yl, xs, ys, beta, pctvar1, mse] = plsregress(XCorrected, TrainYs, LV_DOP(i), 'CV', size(XCorrected, 1));
    %disp("<<===============================================================>>");
    %disp("Evaluate "+ SrcArray(i)+" to "+DestArray(i));
    evaluate_model(TrainXs, TrainYs, TrainXt, TrainYt, TestXt, TestYt, E, beta);
    BETA = [];
    R2_SDOP = [];
    n_samples = size(XCorrected, 1);
    for s = 1:1:length(sparity)
        %n_samples = 10;
        [model, r, pctvar] = sparseplscv(XCorrected, TrainYs, nMaxLV,sparity(s),n_samples);
        BETA = [BETA model.B];
        R2_SDOP = [R2_SDOP;r];
    end
    % Visualization and evaluation
    preStr = "Select_v";
    fig= figure('Name',strFileName+preStr);
    style = ["-*","-o","-s","-^","-v"];
    for j = 1:1:length(var_threshold_array)
        plot(R2(j,:),style(j),'LineWidth',1.0);
        hold on;
    end
    xlabel("Number of Latent Variables");
    ylabel("R^2_{cv}");
    legend(["v = 80.0%", "v = 90.0%", "v = 95.0%", "v = 99.0%", "v = 99.9%"],'Location','southeast');
    SCIPlot;
    %MySaveFig(fig,strFileName+preStr);
    pause(0.5);
    disp("<<===============================================================>>");
    disp("Evaluate Source domain:"+ SrcArray(i)+" to Target domain:"+DestArray(i));
    % 评估所有方法并收集结果
    results = struct();
    % 1. PLS
    [~, ~, ~, ~, beta_PLS, ~, ~] = plsregress(TrainXs, TrainYs, LV_PLS(i), 'CV', size(XCorrected, 1));
    [results.PLS.RMSEP, results.PLS.R2] = evaluate_dataset(TestXt, TestYt, eye(size(E,1)), beta_PLS);
    results.PLS.LV = LV_PLS(i);
    results.PLS.sparsity = sum(beta_PLS(2:end)==0) / length(beta_PLS(2:end));
    % 2. DOP
    [~, ~, ~, ~, beta, ~, ~] = plsregress(XCorrected, TrainYs, LV_DOP(i), 'CV', size(XCorrected, 1));
    [results.DOP.RMSEP, results.DOP.R2] = evaluate_dataset(TestXt, TestYt, E, beta);
    results.DOP.LV = LV_DOP(i);
    results.DOP.sparsity = sum(beta(2:end)==0) / length(beta(2:end));
    % 3. SDOP
    nvarX = nVarX_SDOP(i);
    model = sparsepls1(XCorrected, TrainYs, LV_SDOP(i), nvarX);
    [results.SDOP.RMSEP, results.SDOP.R2] = evaluate_dataset(TestXt, TestYt, E, model);
    results.SDOP.LV = LV_SDOP(i);
    results.SDOP.sparsity = sum(model.B==0) / length(model.B);
    % 打印结果表格
    printResultsTable(results, SrcArray(i), DestArray(i));
    %figure;
    %plot(model.B);
    preStr = "Select_nVarX";
    if i>8
        wavelength = 1:1:size(XCorrected,2);
    elseif i>6
        wavelength = 800:2:1400;
    else
        wavelength = 1100:2:2498;
    end
    fig = figure('Name',strFileName+preStr);
    for j = 1:1:length(sparity)
        plot(R2_SDOP(j,:),style(j),'LineWidth',1.0);
        hold on;
    end
    xlabel("Number of Latent Variables");
    ylabel("R^2_{cv}");
    legend(["nVarX = 5", "nVarX = 10", "nVarX = 20", "nVarX = 50","nVarX = 100"],'Location','southeast');
    SCIPlot;
    % MySaveFig(fig,strFileName+preStr);
    preStr = "_nVarX_compare";
    %figure('Name',strFileName+preStr);
    for j = 1:1:4
        nvarX = sparity(j);
        model = sparsepls1(XCorrected, TrainYs, LV_SDOP(i), nvarX);
        Yhat = TestXt*E*model.B+model.B0;
        [RMSEP,R] = calculate_metrics(TestYt,Yhat);
        %fig = subplot(2,2,j);
        fig = figure('Name',strFileName+preStr+num2str(j));
        plot(wavelength,model.B,'LineWidth',1.5);
        sp = length(find(model.B==0))/length(model.B);
        % Add annotation with metrics
        text(0.1, 0.75, sprintf('nVarX = %d \nRMSEP = %.2f\nR^2_p = %.2f\nsparity = %.2f', nvarX,RMSEP, R,sp), ...
            'Units', 'normalized', 'FontSize', 16, 'FontWeight', 'bold');
        xlabel("Wavelength (nm)");
        ylabel("$\beta_{SDOP}$","Interpreter" , "latex");
        SCIPlot;
        %MySaveFig(fig,strFileName+preStr+num2str(j));
    end
    preStr = "_nMean_compare";
    %figure('Name',strFileName+preStr);
    %fig = subplot(2,1,1);
    fig = figure('Name',strFileName+preStr+"1");
    plot(wavelength,mean(TrainXs),'LineWidth',1.5);
    hold on;
    plot(wavelength,mean(TrainXt),'--','LineWidth',1.5);
    legend(["$\mu_{X_s}$","$\mu_{X_t}$"],"Location",'northwest', "Interpreter","latex");
    xlabel("Wavelength (nm)");
    ylabel("Intensity (a.u.)");
    SCIPlot;
    %MySaveFig(fig,strFileName+preStr+"1");
    %fig = subplot(2,1,2);
    fig = figure('Name',strFileName+preStr+"2");
    plot(wavelength,mean(TrainXs)*E,'LineWidth',1.5);
    hold on;
    plot(wavelength,mean(TrainXt)*E,'--','LineWidth',1.5);
    legend(["$\mu_{X^*_s}$","$\mu_{X^*_t}$"],"Location","northwest","Interpreter","latex");
    xlabel("Wavelength (nm)");
    ylabel("Intensity (a.u.)");
    SCIPlot;
    %MySaveFig(fig,strFileName+preStr+"2");
    nvarX = nVarX_SDOP(i);
    model = sparsepls1(XCorrected, TrainYs, LV_SDOP(i), nvarX);
    preStr = "_nBeta_compare";
    fig = figure('Name',strFileName+preStr);
    plot(wavelength,beta(2:end),'LineWidth',1.5);
    hold on;
    plot(wavelength,model.B,'--','LineWidth',1.5);
    legend(["$\beta_{DOP}$","$\beta_{SDOP}$"],"Location","northwest","Interpreter","latex");
    xlabel("Wavelength (nm)");
    ylabel("$\beta$","Interpreter","latex");
    SCIPlot;
    %MySaveFig(fig,strFileName+preStr);
    preStr = "_nBeta_compare2";
    fig = figure('Name',strFileName+preStr);
    plot(wavelength,beta(2:end)'*(eye(size(E,1))-E),'LineWidth',1.5);
    hold on;
    plot(wavelength,model.B'*(eye(size(E,1))-E),'--','LineWidth',1.5);
    legend(["$\beta_{DOP}*VV^\top$","$\beta_{SDOP}*VV^\top$"],"Location","northwest",Interpreter="latex");
    SCIPlot;
    xlabel("Wavelength (nm)");
    ylabel("Projected $\beta$",Interpreter="latex");
    %MySaveFig(fig,strFileName+preStr);
    %fprintf("Finish %s to %s \n",SrcArray(i),DestArray(i));
end

%% 数据预处理函数
% 使用 Duplex 算法划分训练集和测试集，确保样本空间均匀覆盖
% 输入参数:
%   X              - 原始光谱数据矩阵 (n_samples × n_features)
%   y              - 目标变量向量 (n_samples × 1)
%   splite_percent - 划分比例，测试集占总样本的比例 (0~0.5)
% 输出参数:
%   TrainX, TrainY - 训练集特征和标签
%   TestX, TestY   - 测试集特征和标签
function [TrainX, TrainY, TestX, TestY] = preprocess_data(X, y, splite_percent)
% 鏁版嵁棰勫鐞?
X = apply_savgol(X);
[model_s, test_s] = duplex(X, round(splite_percent * size(X, 1)));
%[model_s, test_s] = kennardStone(X, round(splite_percent * size(X, 1)));

TrainX = X(model_s, :);
TrainY = y(model_s);
TestX = X(test_s, :);
TestY = y(test_s);
end

%% Savitzky-Golay 平滑滤波
% 对光谱数据进行 Savitzky-Golay 平滑预处理，去除高频噪声
% 输入参数:
%   X - 光谱数据矩阵 (n_samples × n_features)，逐行处理
% 输出参数:
%   X - 平滑处理后的光谱数据
function X = apply_savgol(X)
% 应用 Savitzky-Golay 滤波
%X = snv2(X);
for i = 1:size(X, 1)
    X(i, :) = savgol(X(i, :), 15, 2, 0);
end
end


%% 评估 DOP 模型性能
% 在源域和目标域的训练集/测试集上评估 DOP 迁移学习模型
% 输入参数:
%   TrainXs, TrainYs - 源域训练集特征和标签
%   TrainXt, TrainYt - 目标域训练集特征和标签
%   TestXt, TestYt   - 目标域测试集特征和标签
%   E                - DOP 投影矩阵
%   beta             - PLS 回归系数向量
function evaluate_model(TrainXs, TrainYs, TrainXt, TrainYt, TestXt, TestYt, E, beta)
% 评估 DOP 模型
[rmse1, r2_1] = evaluate_dataset(TrainXs, TrainYs, E, beta);
[rmse2, r2_2] = evaluate_dataset(TrainXt, TrainYt, E, beta);
[rmse3, r2_3] = evaluate_dataset(TestXt, TestYt, E, beta);
%fprintf('DOP Trainset from Source Domain: RMSEP: %.2f, R2: %.2f\n', rmse1, r2_1);
%fprintf('DOP Trainset from Target Domain: RMSEP: %.2f, R2: %.2f\n', rmse2, r2_2);
%fprintf('DOP Testset from Target Domain: RMSEP: %.2f, R2: %.2f\n', rmse3, r2_3);
end

%% 评估 Sparse DOP 模型性能
% 在源域和目标域的训练集/测试集上评估稀疏 DOP 模型
% 输入参数:
%   TrainXs, TrainYs - 源域训练集特征和标签
%   TrainXt, TrainYt - 目标域训练集特征和标签
%   TestXt, TestYt   - 目标域测试集特征和标签
%   E                - DOP 投影矩阵
%   model            - 稀疏 PLS 模型结构体（包含 B 和 B0）
function evaluate_sparse_model(TrainXs, TrainYs, TrainXt, TrainYt, TestXt, TestYt, E, model)
% 评估 Sparse DOP 模型
[rmse1, r2_1] = evaluate_dataset(TrainXs, TrainYs, E, model);
[rmse2, r2_2] = evaluate_dataset(TrainXt, TrainYt, E, model);
[rmse3, r2_3] = evaluate_dataset(TestXt, TestYt, E, model);
fprintf('SparseDOP Trainset from Source Domain: RMSEP: %.2f, R2: %.2f\n', rmse1, r2_1);
fprintf('SparseDOP Trainset from Target Domain: RMSEP: %.2f, R2: %.2f\n', rmse2, r2_2);
fprintf('SparseDOP Testset from Target Domain: RMSEP: %.2f, R2: %.2f\n', rmse3, r2_3);
end

%% 评估数据集预测性能
% 计算模型在指定数据集上的预测RMSE和R²指标
% 输入参数:
%   X      - 输入特征矩阵
%   Y      - 真实标签向量
%   E      - DOP 投影矩阵
%   model  - 回归模型（结构体或向量）
% 输出参数:
%   rmsep  - 预测均方根误差
%   r2     - 决定系数R²
function [rmsep, r2] = evaluate_dataset(X, Y, E, model)
% 评估数据集
if isstruct(model)
    Yhat = X * E * model.B + model.B0;
else
    Yhat = [ones(size(X, 1), 1), X * E] * model;
end
[rmsep, r2] = calculate_metrics(Y, Yhat);
end

%% 打印结果表格
% 以表格形式输出各方法的性能对比
% 输入参数:
%   results - 包含PLS、DOP、SDOP结果的结构体
%   source  - 源域名称
%   target  - 目标域名称
function printResultsTable(results, source, target)
fprintf('\n');
fprintf('========== Results Summary ==========\n');
fprintf('%-10s %-10s %-8s %-6s %-10s %-8s %-10s\n', 'Source', 'Target', 'Method', 'LV', 'RMSEP', 'R²p', 'Sparsity');
fprintf('%s\n', repmat('-', 1, 70));
fprintf('%-10s %-10s %-8s %-6d %-10.2f %-8.2f %-10.2f\n', ...
    char(source), char(target), 'PLS', results.PLS.LV, results.PLS.RMSEP, results.PLS.R2, results.PLS.sparsity);
fprintf('%-10s %-10s %-8s %-6d %-10.2f %-8.2f %-10.2f\n', ...
    char(source), char(target), 'DOP', results.DOP.LV, results.DOP.RMSEP, results.DOP.R2, results.DOP.sparsity);
fprintf('%-10s %-10s %-8s %-6d %-10.2f %-8.2f %-10.2f\n', ...
    char(source), char(target), 'SDOP', results.SDOP.LV, results.SDOP.RMSEP, results.SDOP.R2, results.SDOP.sparsity);
fprintf('%s\n', repmat('=', 1, 70));
fprintf('\n');
end

%% 绘制回归系数对比图
% 可视化 DOP 和 Sparse DOP 模型的回归系数
% 输入参数:
%   beta_dop   - DOP 模型的回归系数向量
%   beta_sparse - Sparse DOP 模型的回归系数向量
% 输出参数: 无（生成对比子图）
function plot_results(beta_dop, beta_sparse)
% 绘制结果
figure;
subplot(2, 1, 1);
plot(beta_dop(2:end), 'linewidth', 1.5);
title("$\beta_{DOP}$", "Interpreter", "latex");
SCIPlot;
subplot(2, 1, 2);
plot(beta_sparse, 'linewidth', 1.5);
title("$\beta_{SparseDOP}$", "Interpreter", "latex");
SCIPlot;
end