dop_R2 = [];
sdop_R2 = [];
xtk = 10:10:90
%change splite_percent and record the results as follows:
% dop_R2(1) = 0.91;
% sdop_R2(1) = 0.95;
% dop_R2(2) = 0.92;
% sdop_R2(2) = 0.94;
% dop_R2(3) = 0.93;
% sdop_R2(3) = 0.93;
% dop_R2(4) = 0.93;
% sdop_R2(4) = 0.92;
% dop_R2(5) = 0.93;
% sdop_R2(5) = 0.91;
% dop_R2(6) = 0.92;
% sdop_R2(6) = 0.91;
% dop_R2(7) = 0.92;
% sdop_R2(7) = 0.90;
% dop_R2(8) = 0.90;
% sdop_R2(8) = 0.90;
% dop_R2(9) = 0.86;
% sdop_R2(9) = 0.86;



%//mp6tomp5
dop_R2 = [0.91,0.92,0.93,0.93,0.93,0.92,0.92,0.90,0.85];
sdop_R2 = [0.94,0.94,0.92,0.93,0.95,0.91,0.92,0.92,0.88];
 fileName = "mp6tomp5_splite";
fig = figure('name',fileName);
plot(xtk,dop_R2,'-o',LineWidth=1.5);
hold on;
plot(xtk,sdop_R2,'-s',LineWidth=1.5);
legend(["DOP","SDOP"]);
ylabel("R^2_p");
xlabel("Test Set Proportion (%) For Target Domain");
ylim([0.7 1.0]);
SCIPlot;
MySaveFig(fig,fileName);
dop_R2 = [];
sdop_R2 = [];
%change splite_percent and record the results as follows:
% dop_R2(1) = 0.95;
% sdop_R2(1) = 0.95;
% 
% dop_R2(2) = 0.92;
% sdop_R2(2) = 0.93;
% 
% dop_R2(3) = 0.96;
% sdop_R2(3) = 0.95;
% 
% dop_R2(4) = 0.88;
% sdop_R2(4) = 0.87;
% 
% dop_R2(5) = 0.92;
% sdop_R2(5) = 0.89;
% 
% dop_R2(6) = 0.95;
% sdop_R2(6) = 0.88;
% 
% dop_R2(7) = 0.93;
% sdop_R2(7) = 0.89;
% dop_R2(8) = 0.83;
% sdop_R2(8) = 0.86;
% dop_R2(9) = 0.53;
% sdop_R2(9) = 0.47;
%//sepc2tospec1
dop_R2 = [0.99,0.99,0.99,0.99,0.99,0.98,0.97,0.80,0.80];
sdop_R2 = [0.99,0.98,0.98,0.99,0.99,0.98,0.98,0.79,0.75];

 
fileName = "spec2tospec1_splite";
fig = figure('name',fileName);
plot(xtk,dop_R2,'-o',LineWidth=1.5);
hold on;
plot(xtk,sdop_R2,'-s',LineWidth=1.5);
legend(["DOP","SDOP"]);
ylabel("R^2_p");
xlabel("Test Set Proportion (%) For Target Domain");
%ylim([0.5 1.0]);
SCIPlot;

MySaveFig(fig,fileName);