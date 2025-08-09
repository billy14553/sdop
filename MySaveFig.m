function [outputArg1,outputArg2] = MySaveFig(fig,name)
%return;
pause(0.72);
strPath = getSavePath();
saveas(fig,strPath+"\"+name,'fig');
pause(1);
saveas(fig,strPath+"\"+name,'epsc');
%pause(1);
%saveas(fig,strPath+"\"+name,'bmp');
end

