function E = dop2(Xsou, Ysou, Xtar, Ytar, rho,Vd)
    % Ensure Ysou and Ytar are column vectors
    Ysou = Ysou(:);
    Ytar = Ytar(:);

    % Compute the Gaussian kernel matrix F
    %F = exp(-rho * pdist2(Ytar, Ysou, 'euclidean'));
    %denom = sum(F, 2);
    %F = bsxfun(@rdivide, F, denom);
    F = compute_aij(Ysou,Ytar,rho)';
    
    % Compute the virtual standard samples Xtar_hat
    Xtar_hat = F * Xsou;

    % Call epo_fit to compute the orthogonalization matrix E
    [E, ~] = epo_fit(Xtar_hat, Xtar,Vd);
end

function [E, a] = epo_fit(X_primary, X_secondary, Vd)
    % Compute the difference matrix D
    D = X_primary - X_secondary;

    % Perform SVD on D
    [U0, S, V0t] = svd(D);
    [~,epo_ncp] = svd_reconstruction(D,Vd);
    V = V0t(:, 1:epo_ncp);
    % Compute the orthogonalization matrix E
    E = eye(size(V, 1)) - V * V';
    % Compute the mean of X_primary
    a = mean(X_primary, 1);
end