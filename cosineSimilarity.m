function similarity = cosineSimilarity(A, B)
% COSINESIMILARITY 计算两个向量的余弦相似度
%
% 输入参数：
%   A - 第一个向量（行向量或列向量）
%   B - 第二个向量（必须与A维度相同）
%
% 输出参数：
%   similarity - 余弦相似度值，范围[-1, 1]

    % 验证输入维度
    if ~isvector(A) || ~isvector(B)
        error('输入必须是向量');
    end
    
    A = A(:); % 转换为列向量
    B = B(:); % 转换为列向量
    
    if length(A) ~= length(B)
        error('向量维度必须相同');
    end
    
    % 计算点积
    dot_product = dot(A, B);
    
    % 计算模长
    norm_A = norm(A);
    norm_B = norm(B);
    
    % 避免除以零
    if norm_A == 0 || norm_B == 0
        warning('零向量输入，相似度定义为0');
        similarity = 0;
    else
        % 计算余弦相似度
        similarity = dot_product / (norm_A * norm_B);
    end
    similarity = norm(B-A);
end