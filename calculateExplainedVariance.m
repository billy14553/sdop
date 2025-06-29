function explainedVariance = calculateExplainedVariance(y, yhat)
    % 计算残差
    residuals = y - yhat;
    
    % 计算残差的方差
    varResiduals = var(residuals);
    
    % 计算因变量的方差
    varY = var(y);
    
    % 计算解释比例
    explainedVariance = 1 - varResiduals / varY;
end