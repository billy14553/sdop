function Yhat = predict_DOP(Xs, Ys, Xt, E, LV)
    % Orthogonalize the source data
    Xs_e = Xs * E;

    % Compute the mean of the orthogonalized source data
    x_mean_e = mean(Xs_e, 1);

    % Compute the mean of the source reference values
    y_mean = mean(Ys);

    % Train a PLSR model on the orthogonalized source data
    [xl,yl,xs,ys,beta,pctvar,mse]  = plsregress(Xs_e, Ys, LV);

    Yhat = [ones(size(Xt,1),1) Xt]*beta;
end