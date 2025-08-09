clear;
close all;

% 鍙傛暟璁剧疆
var_threshold_array = [0.80, 0.90, 0.95, 0.99, 0.999];
sparity_array = [10, 20, 50, 100, 150, 200];
nMaxLV = 10;
splite_percent1 = 0.3;
splite_percent2 = 0.3; %for test set of target domain
which_data = 1;
nVarX = 20;
epsilon = 1;

SrcArray   = ["mp5","mp5","m5","m5","mp6","mp6","spec1","spec2"];
DestArray = ["m5","mp6","mp6","mp5","m5","mp5","spec2","spec1"];
%skiplist = [0,0,0,0,0,0,0,0];
skiplist = [1,1,1,1,1,0,1,1];


loadData;

for i = 1:1:length(skiplist)
    strFileName = SrcArray(i)+"to"+DestArray(i);
    if skiplist(i)==1
        continue;
    end
    fprintf("Conduct %s to %s \n",SrcArray(i),DestArray(i));
    str = sprintf("Xs = %sX;ys = %sY;Xt = %sX;yt = %sY;",SrcArray(i),SrcArray(i),DestArray(i),DestArray(i));
    eval(str);
    
    for j = 1:1:9
        [TrainXs, TrainYs, TestXs, TestYs] = preprocess_data(Xs,  ys, splite_percent1);
        splite_percent2 = j/10;
        if splite_percent2<=0.5
            [TrainXt, TrainYt, TestXt, TestYt] = preprocess_data(Xt,  yt, splite_percent2);
        else
            [TestXt, TestYt,TrainXt, TrainYt ] = preprocess_data(Xt,  yt, 1-splite_percent2);
        end
        epsilon = 1/size(TrainXs,1);
    end
    %RMSECV = zeros(length(var_threshold_array),nMaxLV);
    %R2= zeros(length(var_threshold_array),nMaxLV);
    %for j = 1:1:length(var_threshold_array)
    %  [RMSECV(j,:),R2(j,:)] = CrossValidate_DOP(TrainXs, TrainYs, TrainXt, TrainYt,nMaxLV,epsilon,var_threshold_array(j));
    % end
    %save(SrcArray(i)+"to"+DestArray(i)+"_DOP");
end

selectedVd =[0.99,0.950 ,0.950,0.95,0.99,0.95,0.99,0.99];
selectedLV_DOP = [5,5,6,5,5,5,3,3];
selectedLV_PLS = [6,6,6,6,6,6,3,3];

%skiplist1 = [1,1,1,1,1,1,1,0];
%skiplist1 = [1,0,0,0,1,1,1,1];
skiplist1 = [0,0,0,0,0,0,0,0];
sparity = [5,10,20,50, 100];
%sparity = [700,700,700,700, 700];
for k = 1:1:length(skiplist1)
    if skiplist1(k)==1
        continue;
    end
    load(SrcArray(k)+"to"+DestArray(k)+"_DOP");
    E = dop2(TrainXs, TrainYs, TrainXt, TrainYt, epsilon, selectedVd(k));
    XCorrected = TrainXs * E;
    [xl, yl, xs, ys, beta, pctvar1, mse] = plsregress(XCorrected, TrainYs, selectedLV_DOP(k), 'CV', size(XCorrected, 1));
    disp("<<===============================================================>>");
    disp("Evaluate "+ SrcArray(k)+"to"+DestArray(k));
    evaluate_model(TrainXs, TrainYs, TrainXt, TrainYt, TestXt, TestYt, E, beta);
    BETA = [];
    R2_SDOP = [];
    for s = 1:1:length(sparity)
        [model, r, pctvar] = sparseplscv(XCorrected, TrainYs, nMaxLV,sparity(s),size(XCorrected,1));
        BETA = [BETA model.B];
        R2_SDOP = [R2_SDOP;r];
        % nLv = 6;
        % Yhat = TrainYs;
        % figure;
        % for t = 1:1:size(XCorrected,1)
        %    XX = XCorrected;
        %    YY = TrainYs;
        %    testXX = XX(t,:);
        %    testYY = YY(t);
        %    XX(t,:) = [];
        %    YY(t) = [];
        %    model = sparsepls2(XX, YY, nLv, sparity(s) * ones(1, nLv), ones(1, nLv), 500, 0.001, 1, 1);
        %    Yhat(t) = testXX*model.B+model.B0;
        %    plot(model.B);
        %    hold on;
        % end
        %[rmse,rr2] = calculate_metrics(TrainYs,Yhat);
        %Yhat2 = XCorrected*model.B+model.B0;
        %rr2
        %[rmse,rr2] = calculate_metrics(TrainYs,Yhat2);
        %rr2
        %figure;
        %plot(Yhat,'-*');
        %hold on;plot(Yhat2,'-o');
        %plot(TrainYs,'-s');
        %legend(["Yhat","Yhat2","TrainYs"]);
        %evaluate_sparse_model(TrainXs, TrainYs, TrainXt, TrainYt, TestXt, TestYt, E, model);
    end
    
    save(SrcArray(k)+"to"+DestArray(k)+"_SDOP");
end

%column_norms = sqrt(sum(BETA.^2, 1));

% 归一化每一列
%BETA_norm = BETA ./ column_norms;
%imagesc(abs(BETA_norm)');
%nLv = 4;
%model = sparsepls2(XCorrected, TrainYs, nLv, 5 * ones(1, nLv), ones(1, nLv), 500, 0.001, 1, 1);
%evaluate_sparse_model(TrainXs, TrainYs, TrainXt, TrainYt, TestXt, TestYt, E, model);

%evaluate_dataset(TestXs, TestYs, E, model, 'SparseDOP TestXs from Source Domain');
%figure;
%plot(model.B);
%skiplist2 = [0,1,1,1,1,1,1,1];
skiplist2 = [1,1,1,1,1,1,1,0];
%skiplist2 = [0,0,0,0,0,0,0,0];
LV_PLS = [7,7,7,7,7,7,5,5];
LV_DOP = [5,6,6,5,5,5,3,3];
LV_SDOP = [5,6,6,7,5,7,3,4];
%nVarX_SDOP = [10,10,10,10,10,10,10,10,10,10];
%nVarX_SDOP = [10,10,10,10,10,10,10,10];
nVarX_SDOP = [10,10,10,10,10,10,5,5];

%Decide which v is best for DOP and SDOP
for z = 1:1:length(skiplist2)
    fileName = SrcArray(z)+"to"+DestArray(z)+"_SDOP";
    preStr = "Select_v";
    load(fileName);
    if skiplist2(z)==1
        continue;
    end
    figure('Name',strFileName+preStr);
    style = ["-*","-o","-s","-^","-v"];
    for j = 1:1:length(var_threshold_array)
        plot(R2(j,:),style(j),'LineWidth',1.0);
        hold on;
    end
    xlabel("Number of Latent Variables");
    ylabel("R_{cv}");
    legend(["v = 80.0%", "v = 90.0%", "v = 95.0%", "v = 99.0%", "v = 99.9%"],'Location','southeast');
    SCIPlot;
    pause(0.5);
    disp("<<===============================================================>>");
    disp("Evaluate Source domain:"+ SrcArray(z)+" to Target domain:"+DestArray(z));
    
    [xl, yl, xs, ys, beta_PLS, pctvar1, mse_PLS] = plsregress(TrainXs, TrainYs, selectedLV_PLS(k), 'CV', size(XCorrected, 1));
    evaluate_dataset(TestXt, TestYt, eye(size(E,1)), beta_PLS, 'PLS: Testset from Target Domain');
    [xl, yl, xs, ys, beta, pctvar1, mse] = plsregress(XCorrected, TrainYs, selectedLV_DOP(k), 'CV', size(XCorrected, 1));
    evaluate_dataset(TestXt, TestYt, E, beta, 'DOP: Testset from Target Domain');
    
    nvarX = nVarX_SDOP(z);
    %model = sparsepls2(XCorrected, TrainYs, LV_SDOP(z), nvarX*ones(1, LV_SDOP(z)), 1*ones(1, LV_SDOP(z)), 500, 0.000001, 1, 1);
    model = sparsepls1(XCorrected, TrainYs, LV_SDOP(z), nvarX);
    evaluate_dataset(TestXt, TestYt, E, model, 'SDOP: Testset from Target Domain');
    %figure;
    %plot(model.B);
    preStr = "Select_nVarX";
    if z>6
        wavelength = 800:2:1400;
    else
        wavelength = 1100:2:2498;
    end
    figure('Name',strFileName+preStr);
    
    for j = 1:1:length(sparity)
        plot(R2_SDOP(j,:),style(j),'LineWidth',1.0);
        hold on;
    end
    xlabel("Number of Latent Variables");
    ylabel("R_{cv}");
    legend(["nVarX = 5", "nVarX = 10", "nVarX = 20", "nVarX = 50","nVarX = 100"],'Location','southeast');
    SCIPlot;
    preStr = "_nVarX_compare";
    figure('Name',strFileName+preStr);
    for j = 1:1:4
        nvarX = sparity(j);
        %model = sparsepls2(XCorrected, TrainYs, LV_SDOP(z), nvarX*ones(1, LV_SDOP(z)), 1*ones(1, LV_SDOP(z)), 500, 0.000001, 1, 1);
        model = sparsepls1(XCorrected, TrainYs, LV_SDOP(z), nvarX);
        %    vip = pls_vip(XCorrected,TrainYs,model.U,model.P, LV_SDOP(z));
        Yhat = TestXt*E*model.B+model.B0;
        [RMSEP,R] = calculate_metrics(TestYt,Yhat);
        subplot(2,2,j);
        plot(wavelength,model.B,'LineWidth',1.5);
        sp = length(find(model.B==0))/length(model.B);
        
        % Add annotation with metrics
        text(0.1, 0.75, sprintf('nVarX = %d \nRMSEP = %.2f\nR_p = %.2f\nsparity = %.2f', nvarX,RMSEP, R,sp), ...
            'Units', 'normalized', 'FontSize', 16, 'FontWeight', 'bold');
        xlabel("WaveLength (nm)");
        ylabel("$\beta_{SDOP}$",Interpreter="latex");
        
        SCIPlot;
    end
    preStr = "_nMean_compare";
    figure('Name',strFileName+preStr);
    subplot(2,1,1);
    plot(wavelength,mean(TrainXs),'LineWidth',1.5);
    hold on;
    plot(wavelength,mean(TrainXt),'LineWidth',1.5);
    legend(["$\mu_{X_s}$","$\mu_{X_t}$"],Location="northwest",Interpreter="latex");
    xlabel("WaveLength (nm)");
    ylabel("Intensity (a.u.)");
    SCIPlot;
    subplot(2,1,2);
    plot(wavelength,mean(TrainXs)*E,'LineWidth',1.5);
    hold on;
    plot(wavelength,mean(TrainXt)*E,'--','LineWidth',1.5);
    legend(["$\mu_{X^*_s}$","$\mu_{X^*_t}$"],Location="northwest",Interpreter="latex");
    xlabel("WaveLength (nm)");
    ylabel("Intensity (a.u.)");
    SCIPlot;
    %h = findobj(gcf, 'Type', 'axes'); % 获取所有坐标轴句柄
    %set(h(2), 'Position', [0.13, 0.55, 0.775, 0.35]); % 调整上方子图位置
    %set(h(1), 'Position', [0.13, 0.11, 0.775, 0.35]); % 调整下方子图位置
    nvarX = nVarX_SDOP(z);
    %model = sparsepls2(XCorrected, TrainYs, LV_SDOP(z), nvarX*ones(1, LV_SDOP(z)), 1*ones(1, LV_SDOP(z)), 500, 0.000001, 1, 1);
    model = sparsepls1(XCorrected, TrainYs, LV_SDOP(z), nvarX);
    preStr = "_nBeta_compare";
    figure('Name',strFileName+preStr);
    
    plot(wavelength,beta(2:end),'LineWidth',1.5);
    hold on;
    plot(wavelength,model.B,'--','LineWidth',1.5);
    legend(["$\beta_{DOP}$","$\beta_{SDOP}$"],Interpreter="latex");
    xlabel("WaveLength (nm)");
    ylabel("Regression Coefficient");
    SCIPlot;
    
    
    preStr = "_nBeta_compare2";
    figure('Name',strFileName+preStr);
    
    plot(wavelength,beta(2:end)'*(eye(size(E,1))-E),'LineWidth',1.5);
    hold on;
    plot(wavelength,model.B'*(eye(size(E,1))-E),'--','LineWidth',1.5);
    legend(["$\beta_{DOP}*PP^\top$","$\beta_{SDOP}*PP^\top$"],Interpreter="latex");
    SCIPlot;
    xlabel("WaveLength (nm)");
    ylabel("Projected Regression Coefficient");
    %fprintf("Finish %s to %s \n",SrcArray(i),DestArray(i));
end

%selectedVd
%Decide which v is best for DOP and SDOP
% for z = 1:1:length(skiplist2)
%     load(SrcArray(z)+"to"+DestArray(z)+"_SDOP");
%     if skiplist2(z)==1
%         continue;
%     end
%     figure('Name',strFileName);
%     style = ["-*","-o","-s","-^","-v"];
%     for j = 1:1:length(var_threshold_array)
%         plot(R2(j,:),style(j),'LineWidth',1.0);
%         hold on;
%     end
%     xlabel("Number of Latent Variables");
%     ylabel("R_{cv}");
%     legend(["v = 80.0%", "v = 90.0%", "v = 95.0%", "v = 99.0%", "v = 99.9%"],'Location','southeast');
%     SCIPlot;
%     pause(0.5);
%     fprintf("Finish %s to %s \n",SrcArray(i),DestArray(i));
% end

return;



% PLS 鍥炲綊


nLv = 5;
%while pctvar1(2,nLv+1)>0.01
%   nLv = nLv + 1;
%end
%fprintf("DOP selected %d LVs \n",nLv);
[xl, yl, xs, ys, beta, ~, mse] = plsregress(XCorrected, TrainYs, nLv);

% 妯″瀷璇勪及


% Sparse DOP 鏍″噯

% [model, mse, pctvar] = sparseplscv(XCorrected, TrainYs, nMaxLV, nVarX, 1, 500, 0.001, 1, 1,size(XCorrected,1));
% nLv = 1;
% while pctvar(nLv+1)>0.01
%     nLv = nLv + 1;
% end
% fprintf("SDOP selected %d LVs \n",nLv);
nLv =7;
%model = sparsepls2(XCorrected, TrainYs, nLv, nVarX * ones(1, nLv), ones(1, nLv), 500, 0.001, 1, 1);
model = sparsepls1(XCorrected, TrainYs, nLv, nVarX );
%yhat = XCorrected*model.B+model.B0;
%figure("name","yhat_sdop_LV1");
%plot(yhat,TrainYs,'o');
%[~,r2 ] = calculate_metrics(yhat,TrainYs)

% Yhat = TrainXs * E * model.B + model.B0;
% [~,r2 ] = calculate_metrics(TrainYs,Yhat)

evaluate_sparse_model(TrainXs, TrainYs, TrainXt, TrainYt, TestXt, TestYt, E, model);
evaluate_dataset(TrainXs, TrainYs, E, model, 'SparseDOP TestXs from Source Domain');

% 缁樺浘
%plot_results(beta, model.B);

function [TrainX, TrainY, TestX, TestY] = preprocess_data(X, y, splite_percent)
% 鏁版嵁棰勫鐞?
X = apply_savgol(X);
[model_s, test_s] = duplex(X, round(splite_percent * size(X, 1)));
%[model_s, test_s] = kennardStone(X, round(splite_percent * size(X, 1)));

TrainX = X(model_s, :);
TrainY = y(model_s);
TestX = X(test_s, :);
TestY = y(test_s);
end

function X = apply_savgol(X)
% 搴旂敤 Savitzky-Golay 婊ゆ尝
%X = snv2(X);
for i = 1:size(X, 1)
    X(i, :) = savgol(X(i, :), 15, 2, 0);
end
end


function evaluate_model(TrainXs, TrainYs, TrainXt, TrainYt, TestXt, TestYt, E, beta)
% 璇勪及 DOP 妯″瀷
evaluate_dataset(TrainXs, TrainYs, E, beta, 'DOP Trainset from Source Domain');
evaluate_dataset(TrainXt, TrainYt, E, beta, 'DOP Trainset from Target Domain');
evaluate_dataset(TestXt, TestYt, E, beta, 'DOP Testset from Target Domain');
end

function evaluate_sparse_model(TrainXs, TrainYs, TrainXt, TrainYt, TestXt, TestYt, E, model)
% 璇勪及 Sparse DOP 妯″瀷
evaluate_dataset(TrainXs, TrainYs, E, model, 'SparseDOP Trainset from Source Domain');
evaluate_dataset(TrainXt, TrainYt, E, model, 'SparseDOP Trainset from Target Domain');
evaluate_dataset(TestXt, TestYt, E, model, 'SparseDOP Testset from Target Domain');
end

function evaluate_dataset(X, Y, E, model, label)
% 璇勪及鏁版嵁闆?
if isstruct(model)
    Yhat = X * E * model.B + model.B0;
else
    Yhat = [ones(size(X, 1), 1), X * E] * model;
end
[rmse, r2] = calculate_metrics(Y, Yhat);
fprintf("%s: RMSEP: %.2f, R2: %.2f\n", label, rmse, r2);
end

function plot_results(beta_dop, beta_sparse)
% 缁樺埗缁撴灉
figure;
subplot(2, 1, 1);
plot(beta_dop(2:end), 'linewidth', 1.5);
title("$\beta_{DOP}$", "Interpreter", "latex");
SCIPlot;
subplot(2, 1, 2);
plot(beta_sparse, 'linewidth', 1.5);
title("$\beta_{SparseDOP}$", "Interpreter", "latex");
SCIPlot;
end