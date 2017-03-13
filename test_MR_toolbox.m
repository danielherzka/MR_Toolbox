
%load('C:\Users\herzkad\Dropbox\Herzka - MATLAB\Test DAta\VTA_Pig_G083_8_Weeks_post_MI_WIP_Hi-INAV-PSIR_SENSE_37_1.mat')
load('/Users/danielherzka/Dropbox/Herzka - MATLAB/New Tools/20170310 In Progress EodD stop Wl PZ MV SP/VTA_Pig_G083_8_Weeks_post_MI_WIP_Hi-INAV-PSIR_SENSE_37_1.mat')

try
    close all
catch
    delete(gcf)
    delete(gcf)
end


% Test multiple images with time (MV)
% Test non-square images in PZ

% f=figure;
% Ims = cat(4, I.A,I.A,I.A);
% imagescn(Ims(end/4:end*3/4,:,:,:), [], [], 10 , 3);

% Test non-standard colormap in WL
% cmap = ecv_cmap(200);
% colormap(cmap(1:end/2,:))

%% Test object drawing in MV

f=figure;
Ims = cat(4, I.A,I.A,I.A);
imagescn(Ims(:,:,:,:), [], [], 10 , 3);


hAllAxes = flipud(findobj(f, 'type', 'axes'));

nframes = size(I.A,3);

rad = linspace (30,60, nframes);
dx = linspace(0,10, nframes);

colororder = 'rgbyc';
markerorder = '+^ox';
theta = linspace(0,2*pi,50);
patchcolor = linspace(0,1,nframes)';
patchcolor = repmat(patchcolor,  1, 3) ;

objStruct = struct([]);

for r = 1:nframes
i=0;
    i=i+1;
    objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)/2;
    objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)/2;
    objStruct(i,r).Type = 'line';  % line  point patch
    objStruct(i,r).Color = 'r';
    objStruct(i,r).Marker = markerorder(i);
    objStruct(i,r).Name = 'RedLine';
    hold on;

    i=i+1;
    objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)/4;
    objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)/8;
    objStruct(i,r).Type = 'points';  % line  point patch
    objStruct(i,r).Color = 'g';
    objStruct(i,r).Marker = markerorder(i);
    objStruct(i,r).Name = 'CaratGreenOs';

    i=i+1;
    %if mod(r,2)
    objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)*3/4;
    objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)*3/4;
    objStruct(i,r).Type = 'points';  % line  point patch
    objStruct(i,r).Color = 'b';
    objStruct(i,r).Marker = markerorder(i);
    objStruct(i,r).Name = 'BlueEven';
    %end
%     
%     
     i=i+1;
    %if mod(r+1,2)
    objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)*1/4;
    objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)*1/4;
    objStruct(i,r).Type = 'points';  % line  point patch
    objStruct(i,r).Color = 'c';
    objStruct(i,r).Marker = markerorder(i);
    objStruct(i,r).Name = 'LineCyanOdd';
    %end
%     
     i=i+1;
    objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)*1/4;
    objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)*1/4;
    objStruct(i,r).Color = patchcolor(r,:);
    objStruct(i,r).Type = 'patch';  % line  point patch
    objStruct(i,r).Name = 'BlackPatchOdd';
    objStruct(i,r).FaceAlpha = 0.25;
    
    
    
    
    
end

%xlim([0 size(Ims,1)])
%ylim([ 0, size(Ims,2)])


for i = 1:length(hAllAxes)
    setappdata(hAllAxes(i), 'Objects', objStruct)
end


 


% Test single image array without time
% figure
% imagescn(I.A(:,:,7), [], [], 10);
shg


