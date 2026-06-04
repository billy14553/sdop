function [RMSECV,R] = CrossValidate_DOP(Xs,Ys,Xt,Yt,maxLV,sigma,Vd,nFolds)
% CrossValidate_DOP - K-fold cross-validation for DOP parameter optimization
% Inputs:
%   Xs, Ys - Source domain training data
%   Xt, Yt - Target domain data (for computing DOP projection)
%   maxLV  - Maximum number of latent variables for PLS
%   sigma  - Regularization parameter for DOP
%   Vd     - Variance threshold for DOP
%   nFolds - Number of folds for cross-validation (default: 10)

if nargin < 8 || isempty(nFolds)
    nFolds = 10;  % Default to 10-fold CV
end

[m,~] = size(Xs);
nFolds = min(nFolds, m);  % Cannot have more folds than samples

RMSECV = zeros(maxLV,1);
R = zeros(maxLV,1);

% Create fold indices using crossvalind
if exist('crossvalind', 'file')
    cvIndices = crossvalind('Kfold', m, nFolds);
else
    % Fallback: manual fold assignment
    cvIndices = mod(1:m, nFolds)' + 1;
end

for LV = 1:maxLV
    Yhat = zeros(m,1);
    
    for fold = 1:nFolds
        testIdx = (cvIndices == fold);
        trainIdx = ~testIdx;
        
        % Training data for this fold
        TrainXs = Xs(trainIdx,:);
        TrainYs = Ys(trainIdx);
        XVal = Xs(testIdx,:);
        YVal = Ys(testIdx);
        
        % Compute DOP projection using full target data
        E = dop2(TrainXs, TrainYs, Xt, Yt, sigma, Vd);
        XCorrected = TrainXs * E;
        
        % Train PLS model
        [~, ~, ~, ~, beta, ~, ~] = plsregress(XCorrected, TrainYs, LV);
        
        % Predict on validation set
        XValCorrected = XVal * E;
        Yhat(testIdx) = [ones(sum(testIdx),1), XValCorrected] * beta;
    end
    
    [RMSECV(LV),R(LV)] = calculate_metrics(Ys,Yhat);
end
end