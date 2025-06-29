function vip = pls_vip(X, Y,YS,XL,ncomp)
 
    
    % 获取变量数量
    p = size(X, 2);
    
    % 初始化 VIP 值
    vip = zeros(p, 1);
    
    % 计算每个变量的 VIP 值
    for j = 1:p
        sum1 = 0;
        sum2 = 0;
        for a = 1:ncomp
            % 计算分子
            sum1 = sum1 + (YS(:, a)' * Y).^2 * XL(j, a)^2;
            % 计算分母
            for k = 1:p
                sum2 = sum2 + (YS(:, a)' * Y).^2 * XL(k, a)^2;
            end
        end
        vip(j) = sqrt(p * sum1 / sum2);
    end
end