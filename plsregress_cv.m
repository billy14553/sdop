function [rmse_cv, r2_cv, pls_model] = plsregress_cv(X, y, ncomp, nfolds)
    % PLSREGRESS_CV 使用偏最小二乘回归 (PLS) 进行交叉验证
    %
    % 输入参数：
    %   X - 自变量矩阵 (n x p)，n 为样本数，p 为变量数
    %   y - 因变量向量 (n x 1)
    %   ncomp - PLS 成分数量
    %   nfolds - 交叉验证的折数
    %
    % 输出参数：
    %   rmse_cv - 交叉验证的均方根误差
    %   r2_cv - 交叉验证的决定系数
    %   pls_model - PLS 模型参数

    % 检查输入参数
    if nargin < 4
        error('需要提供 X, y, ncomp 和 nfolds 参数');
    end

    % 获取样本数量
    n = size(X, 1);

    % 初始化均方误差和决定系数
    mse_cv = 0;
    r2_cv = 0;

    % 生成交叉验证索引
    cv = cvpartition(n, 'KFold', nfolds);

    % 循环进行交叉验证
    for i = 1:nfolds
        % 获取训练集和测试集索引
        trainIdx = training(cv, i);
        testIdx = test(cv, i);

        % 提取训练集和测试集数据
        X_train = X(trainIdx, :);
        y_train = y(trainIdx, :);
        X_test = X(testIdx, :);
        y_test = y(testIdx, :);

        % 使用训练集拟合 PLS 模型
        [XL, YL, Xs, Ys, beta, ~] = plsregress(X_train, y_train, ncomp);

        % 预测测试集
        y_pred = [ones(size(X_test, 1), 1), X_test] * beta;

        % 计算均方误差
        mse_cv = mse_cv + sum((y_test - y_pred).^2) / length(y_test);

        % 计算决定系数 R^2
        y_mean = mean(y_test);
        ss_tot = sum((y_test - y_mean).^2);
        ss_res = sum((y_test - y_pred).^2);
        r2_cv = r2_cv + (1 - ss_res / ss_tot);
    end

    % 计算平均均方误差和平均决定系数
    mse_cv = mse_cv / nfolds;
    rmse_cv = sqrt(mse_cv);
    r2_cv = r2_cv / nfolds;
    pls_model = struct('XL', XL, 'YL', YL, 'Xs', Xs, 'Ys', Ys, 'beta', beta);