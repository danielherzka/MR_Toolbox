load('C:\Users\herzkad\Dropbox\Herzka - MATLAB\Test DAta\VTA_Pig_G083_8_Weeks_post_MI_WIP_Hi-INAV-PSIR_SENSE_37_1.mat')

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

colororder = 'rgb';
markerorder = '+^o';
theta = linspace(0,2*pi,50);
patchcolor = repmat(linspace(0,1, nframes)', 1,3);



objStruct = struct([]);

for r = 1:nframes
    i=0;
    i=i+1;
    objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)/2;
    objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)/2;
    objStruct(i,r).Type = 'Line';  % line  point patch
    objStruct(i,r).Color = 'w';
    objStruct(i,r).Marker ='^';
    objStruct(i,r).Name = 'WhiteLine';
    hold on;
    %plot(hAllAxes(i) = objStruct{r,i}.x, objStruct{r,i}.y, 'Color', objStruct{r,i}.color, 'Marker', objStruct{r,i}.marker) ;
    hold on;
    
    i=i+1;
    objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)*5/8;
    objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)/4;
    objStruct(i,r).Type = 'Points';  % line  point patch
    objStruct(i,r).Color = [0 0 1];
    objStruct(i,r).Marker = 'x';
    objStruct(i,r).Name = 'BluePointsX';
    hold on;
    %plot(hAllAxes(i) = objStruct{r,i}.x, objStruct{r,i}.y, 'Color', objStruct{r,i}.color, 'Marker', objStruct{r,i}.marker) ;
    hold on;
   
    i=i+1;
    objStruct(i,r).XData = rad(r)*cos(theta)- dx(r) + size(Ims,1)/4;
    objStruct(i,r).YData = rad(r)*sin(theta)+ dx(r) + size(Ims,2)/4;
    objStruct(i,r).Type = 'Points';  % line  point patch
    objStruct(i,r).Color = 'r';
    objStruct(i,r).Marker = 'o';
    objStruct(i,r).Name = 'RedPointsO';
    hold on;
    %plot(hAllAxes(i) = objStruct{r,i}.x, objStruct{r,i}.y, 'Color', objStruct{r,i}.color, 'Marker', objStruct{r,i}.marker) ;
    hold on;
    
    i=i+1;
    objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)*1/8;
    objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)*3/8;
    objStruct(i,r).Type = 'Points';  % line  point patch
    objStruct(i,r).Color = 'g';
    objStruct(i,r).Marker = '+';
    objStruct(i,r).Name = 'GreenPoints+';
    hold on;
    %plot(hAllAxes(i) = objStruct{r,i}.x, objStruct{r,i}.y, 'Color', objStruct{r,i}.color, 'Marker', objStruct{r,i}.marker) ;
    hold on;
    
    
    i=i+1;
    objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)*3/4;
    objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)*3/4;
    objStruct(i,r).Type = 'Patch';  % line  point patch
    objStruct(i,r).Color = patchcolor(r,:);
    objStruct(i,r).Name = 'BlackPatch';
    objStruct(i,r).Other.FaceAlpha = 0.5;
    objStruct(i,r).Other.EdgeColor = [0 0 0];
    objStruct(i,r).Other.EdgeAlpha = 1;

    hold on;
    %plot(hAllAxes(i) = objStruct{r,i}.x, objStruct{r,i}.y, 'Color', objStruct{r,i}.color, 'Marker', objStruct{r,i}.marker) ;
    hold on;
    
    
    
    
    
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


