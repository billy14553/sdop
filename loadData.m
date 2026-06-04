load nir_data.mat;
spec1X =spec1(:,1:301);
spec1Y = conc(:,1);
spec2Y = spec1Y;
spec2X = spec2(:,1:301);
load corn.mat;
mp5Y = propvals.data(:,3);
mp5X = mp5spec.data;
m5X = m5spec.data;
m5Y = mp5Y;
mp6X = mp6spec.data;
mp6Y = mp5Y;
% load raman.mat
% 
% portmanX = Xs;
% portmanY = Ys;
% horibaX = Xt;
% horibaY = Yt;
% 
% portmanX = imresize(Xs, 0.2, 'nearest');
% portmanY = imresize(Ys, 0.2, 'nearest');
% horibaX = imresize(Xt, 0.2, 'nearest');
% horibaY = imresize(Yt, 0.2, 'nearest');