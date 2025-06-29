function [model,r2, pctvar] = sparseplscv(X, Y, nlv, nvarX, cv)
% Sparse Partial Least Squares with Cross-Validation
%
% Inputs:
%   X        = Independent data.
%   Y        = Dependent data.
%   nlv      = Number of latent variables to model.
%   nvarX    = Row vector indicating number of independent variables kept per latent variable modeled.
%   nvarY    = Row vector indicating number of dependent variables kept per latent variable modeled.
%   maxiter  = Maximum number of iterations.
%   tol      = Convergence criterion.
%   mode     = Use regression (1) or canonical (2) mode for modeling.
%   mc       = Option for performing mean-centering (1) or not (0).
%   cv       = Number of folds for cross-validation (optional).
%
% Outputs:
%   model    = Data structure containing the sparsity PLS model.
%   mse      = Mean squared error for each number of latent variables.
%   pctvar   = Percentage of variance explained for each number of latent variables.

% Default values
 
maxiter = 500;
tol = 0.000001;
mode = 1;
mc = 1;
nvarY = 1; 
% Validation of input
% ... (existing validation code)

% Cross-validation setup
if cv > 0
    pctvar = zeros(1, nlv);
    r2 = pctvar;
    cvindices = crossvalind('Kfold', size(X, 1), cv);
    Yhat = Y;

    for lv = 1:nlv
        Yhat = zeros(length(Y),1);
        for fold = 1:cv
            test = (cvindices == fold);
            train = ~test;
            Xtrain = X(train, :);
            Ytrain = Y(train, :);
            Xtest = X(test, :);
            Ytest = Y(test, :);

            % Train model
            %model_fold = sparsepls2(Xtrain, Ytrain, lv, nvarX*ones(1, lv), nvarY*ones(1, lv), maxiter, tol, mode, mc);
            model_fold = sparsepls1(Xtrain, Ytrain, lv, nvarX);
            Ypred = Xtest * model_fold.B + model_fold.B0;
           % plot(model_fold.B );
           % hold on;
            Yhat(test) = Ypred;
        end
      %  figure;
       % plot(Yhat,Y,'o');
        [~,r2(lv)] = calculate_metrics(Y,Yhat);
        pctvar(lv) = r2(lv);
        if lv >1
            pctvar(lv) = r2(lv) -r2(lv-1);
        end
    end


    model = model_fold;


else
    % No cross-validation
    model = sparsepls1(X, Y, nlv, nvarX);
    r2 = [];
    pctvar = [];
end


end

function r2 = calculate_r2(y, yhat)
% 计算观测值的均值
y_mean = mean(y);

% 计算残差平方和 SS_res
SS_res = sum((y - yhat).^2);

% 计算总平方和 SS_tot
SS_tot = sum((y - y_mean).^2);

% 计算决定系数 R^2
r2 = 1 - (SS_res / SS_tot);
end
