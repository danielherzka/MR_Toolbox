
load('C:\Users\herzkad\Dropbox\Herzka - MATLAB\Test DAta\VTA_Pig_G083_8_Weeks_post_MI_WIP_Hi-INAV-PSIR_SENSE_37_1.mat')

try
    close all
catch
    delete(gcf)
    delete(gcf)
end

%%
% multiple images; no time
figure
imagescn(I.A(end/4:end*3/4,:,1:9), [], [], 10);


% single image; no time
% figure
% imagescn(I.A(:,:,7), [], [], 10);

shg


%MR_toolbox


%%
% figure;
% imagesc(I.A(:,:,9))
% MR_toolbox
%   
% shg