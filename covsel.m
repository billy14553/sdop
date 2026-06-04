function [num,crbvar,xdef,ydef,crbcov] = covsel(x,y,lv,xscale,yscale)
% covsel       - Selection of variables from covariance maximisation
%  [num,crbvar,xdef,ydef,crbcov] = covsel(X,Y,lv,xscale,yscale)
%
%  Input arguments
% ================
%   X : Matrix n x p of the predictive variables
%   Y : Matrix n x q of the responses
%   lv : number of selected variables
%   xscale : 0: no scaling, 1: mean center, 2: autoscale (1 by default)
%   yscale : 0: no scaling, 1: mean center, 2: autoscale 
%           (1 by default if y is a vector, 2 if y is a matrix)
%
% Output arguments
% ================
%   num    : number of selected variables
%   crbvar : evolution of cumulated variance of X (first column) and Y (second one)
%   xdef, ydef : successive deflated x and y matrices (3D matrices)
%   crbcov : cov^2 curve at each step of the algorithm
%   
%
% Written by JM Roger, INRAE, Montpellier
%

[nx,px] = size(x);
[ny,py] = size(y);
if nx ~= ny
  error('Number of samples do not match')
end
if nx < 2
  error('Not enough samples')
end

% managing default args
if nargin < 5
    if py>1
        yscale = 2;
    else
        yscale = 1;
    end;
end;

if nargin < 4 
    xscale = 1;
end;

% upper limit
lv = min( lv, rank(x) );

% initializing outputs
num = zeros(1,lv);

if nargout>1
    crbvar=zeros(lv,2);
end

if nargout>2
    xdef = zeros(lv,nx,px);
end

if nargout>3
    ydef = zeros(lv,ny,py);
end

if nargout>4
    crbcov = zeros(lv,px);
end

% scaling
switch xscale
    case 1 
        z = x-repmat(mean(x),nx,1);
    case 2 
        z = (x-repmat(mean(x),nx,1)) ./ repmat(std(x),nx,1);
    otherwise
        z = x;
end;
switch yscale
    case 1 
        t = y-repmat(mean(y),ny,1);
    case 2 
        t = (y-repmat(mean(y),ny,1)) ./ repmat(std(y),ny,1);
    otherwise
        t = y;
end;

% total inertia
vartot=[sum(sum(z.*z)) sum(sum(t.*t))];

for i=1:lv
    
    % trace
    if nargout > 4
        crbcov(i,:) = diag(z'*t*t'*z);
    end
    
    % searching covariance max
    [~,num(i)] = max( sum( (z'*t).^2 ,2) );
    
    % selected column
    v = z(:,num(i));
    
    % deflation of x and y 
    z = z - v*v'*z/(v'*v);
    t = t - v*v'*t/(v'*v);

    % tracing
    if nargout > 1
        crbvar(i,1) = ( vartot(1)-  sum(sum(z.*z)) ) / vartot(1);
        crbvar(i,2) = ( vartot(2) - sum(sum(t.*t)) ) / vartot(2);
    end;
    if nargout > 2
        xdef(i,:,:) = z;
    end;
    if nargout > 3
        ydef(i,:,:) = t;
    end;
end;


