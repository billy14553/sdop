function vip_scores = calculatePLS_VIP(W, X, y)
    % 计算PLS模型的VIP值
    % 输入:
    %   W - PLS权值矩阵 (p x H), p为变量数，H为主成分数
    %   X - 原始数据矩阵 (n x p), n为样本数
    %   y - 响应变量 (n x 1)
    % 输出:
    %   vip_scores - 各变量的VIP值 (p x 1)

    [n, p] = size(X);
    H = size(W, 2); % 获取主成分数
    
    % 计算每个主成分的解释方差R²
    R2 = zeros(1, H);
    X_centered = X - mean(X);
    y_centered = y - mean(y);
    T = X_centered * W; % 得分矩阵
    
    for h = 1:H
        % 计算每个主成分对y的解释方差
        y_pred = T(:,1:h) * (T(:,1:h) \ y_centered);
        SS_residual = sum((y_centered - y_pred).^2);
        SS_total = sum(y_centered.^2);
        R2(h) = 1 - (SS_residual / SS_total);
    end
    
    % 计算VIP值
    sum_R2 = sum(R2);
    vip_scores = sqrt(p * sum((W.^2 .* R2), 2) / sum_R2);
end