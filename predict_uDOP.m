function Yhat = predict_uDOP(Xs, Ys, Xt, E, LV)
    % Predict using uDOP (unified Dynamic Orthogonal Projection)
    %
    % Parameters:
    %   Xs: Source domain spectral data (N, K)
    %   Ys: Source domain reference values (N, 1)
    %   Xt: Target domain spectral data (N_t, K)
    %   E: Orthogonalization matrix (K, K)
    %   LV: Number of latent variables (PLS components)
    %
    % Returns:
    %   Yhat: Predicted values in the target domain (N_t, 1)

    % Apply orthogonalization to source domain data
    Xs_e = Xs * E;

    % Compute mean values
    x_mean_e = mean(Xs_e, 1); % Row vector
    y_mean = mean(Ys, 1); % Row vector

    % Fit PLS model
    pls_model = plsregress(Xs_e, Ys, LV);

    % Extract PLS coefficients
    B = pls_model{2}; % PLS regression coefficients

    % Compute offset beta
    beta = y_mean - (x_mean_e * B); % Model: y = Xs_e * B + beta

    % Predict target domain values
    Yhat = (Xt * B) + beta;

end