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
Ims = cat(4, I.A,flipud(I.A),fliplr(I.A));
%Ims = cat(5, Ims, flipud(Ims));
imagescn(Ims(:,:,:,:,:), [], [], 10 , 3);


hAllAxes = flipud(findobj(f, 'type', 'axes'));

% Object params
nframes = size(I.A,3);

rad = linspace (30,60, nframes);
dx = linspace(0,10, nframes);
colororder = 'rgb';
markerorder = '+^o';
theta = linspace(0,2*pi,50);
patchcolor = repmat(linspace(0,1, nframes)', 1,3);
patchalpha = linspace(1,0, nframes);

objStruct = struct;

% Object structure: row = object list; column should match in length to #
% of frames in temporal sequence. If less, those objects will be empty;

for f = 1:length(hAllAxes)-1
    
    for r = 1:nframes
        i=0;
        
        i=i+1;
        objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)/2;
        objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)/2;
        objStruct(i,r).Type = 'Line';  % line  point patch
        objStruct(i,r).Color = 'w';
        objStruct(i,r).Marker ='^';
        objStruct(i,r).Name = 'WhiteLine';
        objStruct(i,r).Other.LineWidth = mod(r,4)+1;
        hold on;
        
        i=i+1;
        objStruct(i,r).XData = (f*0.2)*rad(r)*cos(theta)+ dx(r) + size(Ims,1)*5/8;
        objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)/4;
        objStruct(i,r).Type = 'Points';  % line  point patch
        objStruct(i,r).Color = [0 0 1];
        objStruct(i,r).Marker = 'x';
        objStruct(i,r).Name = 'BluePointsX';
        
        i=i+1;
        objStruct(i,r).XData = (f*0.2)*rad(r)*cos(theta)- dx(r) + size(Ims,1)/4;
        objStruct(i,r).YData = (f*0.2)*rad(r)*sin(theta)+ dx(r) + size(Ims,2)/4;
        objStruct(i,r).Type = 'Points';  % line  point patch
        objStruct(i,r).Color = 'r';
        objStruct(i,r).Marker = 'o';
        objStruct(i,r).Name = 'RedPointsO';
        objStruct(i,r).Other.MarkerSize = mod(r,10)+1;
        
        i=i+1;
        if mod(r,1) % never / all empty      
            objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)*1/8;
            objStruct(i,r).YData = (f*0.2)*rad(r)*sin(theta) + size(Ims,2)*3/8;
            objStruct(i,r).Type = 'Points';  % line  point patch
            objStruct(i,r).Color = 'g';
            objStruct(i,r).Marker = '+';
            objStruct(i,r).Name = 'GreenPoints+';
            hold on;
        end
        
        i=i+1;
        if mod(r,4) % 3 out of 4     
            objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)*1/8;
            objStruct(i,r).YData = (f*0.2)*rad(r)*sin(theta) + size(Ims,2)*3/8;
            objStruct(i,r).Type = 'Points';  % line  point patch
            objStruct(i,r).Color = 'g';
            objStruct(i,r).Marker = '+';
            objStruct(i,r).Name = 'GreenPoints++';
            hold on;
        end
        
        i=i+1;
        if mod(r+1,2) % every other, first one on
            objStruct(i,r).XData = rad(r)*cos(theta)+ dx(r) + size(Ims,1)*3/4;
            objStruct(i,r).YData = rad(r)*sin(theta) + size(Ims,2)*3/4;
            objStruct(i,r).Type = 'Patch';  % line  point patch
            objStruct(i,r).Color = patchcolor(r,:);
            objStruct(i,r).Name = 'BlackPatch';
            objStruct(i,r).Other.FaceAlpha = patchalpha(r);
            objStruct(i,r).Other.EdgeColor = [0 1 1];
            objStruct(i,r).Other.EdgeAlpha = patchalpha(r);
        end
            
        i=i+1;
        if mod(r,2) % every other, first one off
            objStruct(i,r).XData = 0.5*rad(r)*cos(theta)+ dx(r) + size(Ims,1)*3/4;
            objStruct(i,r).YData = 0.5*rad(r)*sin(theta) + size(Ims,2)*3/4;
            objStruct(i,r).Type = 'Patch';  % line  point patch
            objStruct(i,r).Color = patchcolor(r,:);
            objStruct(i,r).Name = 'BlackPatchHole';
            objStruct(i,r).Other.FaceAlpha = patchalpha(nframes-r+1);
            objStruct(i,r).Other.EdgeColor = 'none';
        end        
        
    end
    
    setappdata(hAllAxes(f), 'Objects', objStruct)
end

shg


% Test single image array without time
% figure
% imagescn(I.A(:,:,7), [], [], 10);
shg

