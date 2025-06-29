function aij = compute_aij(y0, yt, sigma)
    % y0: 校准数据库中的属性值，列向量
    % yt: 在线测量的参考值，列向量
    % sigma: 高斯核函数的带宽参数
    % aij: 计算得到的权重矩阵

    % 确保输入是列向量
    
    y0 = y0(:);
    yt = yt(:);

    % 计算yt和y0之间的所有组合的差异
    [n_yt, ~] = size(yt);
    [n_y0, ~] = size(y0);
    Y0 = repmat(y0, 1, n_yt);
    YT = repmat(yt', n_y0, 1);

    % 计算高斯核函数
    differences = Y0 - YT;
    exponent = -differences.^2 / (2 * sigma^2)/std(y0)/std(y0);
    gaussian_kernel = exp(exponent) / (sigma * sqrt(2 * pi));

    % 确保每一列的和为1（归一化）
    aij = gaussian_kernel ./ repmat(sum(gaussian_kernel, 1), n_y0, 1);
    
end