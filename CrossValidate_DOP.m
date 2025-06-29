function [RMSECV,R] = CrossValidate_DOP(Xs,Ys,Xt,Yt,maxLV,sigma,Vd)
[m,n] = size(Xs);
RMSECV = zeros(maxLV,1);
R = zeros(maxLV,1);
Yhat   = zeros(m,1);
for LV = 1:1:maxLV
    for i = 1:1:m
        TrainXs = Xs;
        TrainYs = Ys;
        XVal =  TrainXs(i,:);
        YVal = TrainYs(i);
        E = dop2(TrainXs, TrainYs, Xt, Yt, sigma,Vd);
        XCorrected = TrainXs * E;
        [xl, yl, xs, ys, beta, pctvar1, mse] = plsregress(XCorrected, TrainYs, LV);
        XVal   = XVal * E;
        Yhat(i) = [1 XVal]*beta;
    end
    [RMSECV(LV),R(LV)] = calculate_metrics(Ys,Yhat);

end
end