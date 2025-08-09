function model = sparsepls1(X, Y, nlv, nvarX)
% Sparse Partial Least Squares (SPLS) regression
% X: Independent variables (n x p matrix)
% Y: Dependent variables (n x q vector or matrix)
% nlv: Number of latent variables to model
% nvarX: Scalar indicating number of X variables kept per latent variable

%This is a simiplied version for sparsepls2, which can ben found at github.com/josecamachop/MEDA-Toolbox


% Default parameter settings
maxiter = 500;         % Maximum iterations
tol = 1e-6;            % Convergence tolerance
mc = 1;                % Mean-centering enabled

% Validate input sizes
[n, p] = size(X);
if size(Y, 1) ~= n
    error('X and Y must have the same number of rows');
end
q = size(Y, 2);

% Expand scalar nvarX to vector for all latent variables
if isscalar(nvarX)
    nvarX = nvarX * ones(1, nlv);
end

% Validate nvarX values
if any(nvarX > p) || any(nvarX < 1)
    error('nvarX values must be between 1 and number of X variables');
end

% For Y variables, always keep all (no variable selection on Y)
nvarY = q * ones(1, nlv);  % Keep all Y variables

% Initialize parameters
meanY = mean(Y);
meanX = mean(X);

% Mean centering
if mc
    X = X - meanX;
end

% Initialize matrices
Xtemp = X;
Ytemp = Y;
tmatrix = zeros(n, nlv);
amatrix = zeros(p, nlv);
cmatrix = zeros(p, nlv);
dmatrix = zeros(q, nlv);

% Main SPLS loop
for h = 1:nlv
    % Get number of variables to keep for this component
    nkeepX = nvarX(h);
    
    % SVD initialization
    M = Xtemp' * Ytemp;
    [U, ~, V] = svd(M, 'econ');
    aold = U(:, 1);
    bold = V(:, 1);
    
    % Initialize scores
    t = Xtemp * aold;
    t = t / norm(t);
    
    u = Ytemp * bold;
    u = u / norm(u);
    
    % Iterative optimization
    iter = 0;
    converged = false;
    
    while ~converged && iter < maxiter
        iter = iter + 1;
        
        % Calculate weights
        a = Xtemp' * u;
        b = Ytemp' * t;
        
        % X variable selection
        if p > nkeepX
            [~, sidx] = sort(abs(a), 'descend');
            athreshold = abs(a(sidx(nkeepX))); % Threshold at nkeepX-th value
            
            % Apply soft thresholding
            sign_a = sign(a);
            abs_a = max(0, abs(a) - athreshold);
            a = sign_a .* abs_a;
        end
        
        % Normalize X weights
        a = a / norm(a);
        
        % Update scores
        t_new = Xtemp * a;
        t_new = t_new / norm(t_new);
        
        u_new = Ytemp * b;
        u_new = u_new / norm(u_new);
        
        % Check convergence
        da = norm(a - aold);
        dt = norm(t_new - t);
        
        if max(da, dt) < tol
            converged = true;
        end
        
        % Update for next iteration
        aold = a;
        t = t_new;
        u = u_new;
        
    end
  %  fprintf("iter:%d \n",iter);
    % Calculate loadings
    c = Xtemp' * t / (t' * t);
    d = Ytemp' * t / (t' * t);
    
    % Deflate matrices
    Xtemp = Xtemp - t * c';
    Ytemp = Ytemp - t * d';
    
    % Store results
    tmatrix(:, h) = t;
    amatrix(:, h) = a;
    cmatrix(:, h) = c;
    dmatrix(:, h) = d;
end

% Calculate regression coefficients
if nlv > 0
    R = amatrix / (cmatrix' * amatrix);
    B = R * dmatrix';
else
    B = zeros(p, q);
end

% Calculate intercept
B0 = meanY - meanX * B;

% Build output model
model = struct(...
    'P', cmatrix, ...             % X loadings
    'Q', dmatrix, ...             % Y loadings
    'T', tmatrix, ...             % X scores
    'B', B, ...                   % Regression coefficients
    'B0', B0, ...                 % Intercept
    'W', amatrix, ...             % X weights
    'meanX', meanX, ...
    'meanY', meanY, ...
    'params', struct(...
        'nlv', nlv, ...
        'nvarX', nvarX, ...
        'maxiter', maxiter, ...
        'tol', tol ...
    ) ...
);
end