function [rmse, r2] = calculate_metrics(y_test, y_pred)
    % CALCULATE_METRICS 计算均方根误差 (RMSE) 和决定系数 (R^2)
    %
    % 输入参数：
    %   y_test - 真实值向量
    %   y_pred - 预测值向量
    %
    % 输出参数：
    %   rmse - 均方根误差
    %   r2 - 决定系数

    % 检查输入向量的长度是否一致
    if length(y_test) ~= length(y_pred)
        error('y_test 和 y_pred 的长度必须一致');
    end

    % 计算均方根误差 (RMSE)
    mse = mean((y_test - y_pred).^2);
    rmse = sqrt(mse);

    % 计算决定系数 (R^2)
    y_mean = mean(y_test);
    ss_tot = sum((y_test - y_mean).^2);
    ss_res = sum((y_test - y_pred).^2);
    r2 = 1 - (ss_res / ss_tot);

    % 输出结果
    %disp(['均方根误差 (RMSE): ', num2str(rmse)]);
    %disp(['决定系数 (R^2): ', num2str(r2)]);
end