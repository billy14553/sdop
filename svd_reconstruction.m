function [D_reconstructed, num_retained] = svd_reconstruction(D, v1)
    % D: 需要进行SVD分解的矩阵
    % V: 保留的解释比率（0 < V < 1）

    % Step 1: SVD 分解
    [U, S, V] = svd(D, 'econ');

    % Step 2: 确定保留的奇异值数量
    total_singular_values = sum(diag(S));
    cumulative_sum = cumsum(diag(S));
    num_retained = find(cumulative_sum / total_singular_values >= v1, 1);

    % Step 3: 重构矩阵
    S_reduced = S(1:num_retained, 1:num_retained);
    U_reduced = U(:, 1:num_retained);
    V_reduced = V(:, 1:num_retained);
    D_reconstructed = U_reduced * S_reduced * V_reduced';
end