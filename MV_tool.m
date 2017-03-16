function MV_tool(varargin)
% function MV_tool(varargin)
% Movie viewing tool for displaying 3D or 4D sets of data. Use with
% imagescn. Can export to avi.
% Usage: MV_tool;
%
% Author: Daniel Herzka  herzkad@nih.gov
% Laboratory of Cardiac Energetics 
% National Heart, Lung and Blood Institute, NIH, DHHS
% Bethesda, MD 20892
% and 
% Medical Imaging Laboratory
% Department of Biomedical Engineering
% Johns Hopkins University Schoold of Medicine
% Baltimore, MD 21205

% Updated: Daniel Herzka, 2017-02 -> .v0
% Cardiovascular Intervention Program
% National Heart, Lung and Blood Institute, NIH, DHHS
% Bethesda, MD 20892

% Set or clear global debug flag
global DB; DB = 1;
dispDebug('Lobby');
Create_New_Objects;

%  Object callbacks; return hFig for speed
% aD.hButton.OnCallback                   -> {@Activate_MV, hFig}
% aD.hButton.OffCallback                  -> {@Deactivate_MV, hFig}
% aD.hMenu.Callback                       -> {@Menu_MV, hFig}
% aD.hFig.CloseRequestFcn                  = {@localCloseParentFigure, figTag};
% aD.hAllImages(:).ButtonDownFcn]          = {@Step, aD.hFig}
% aD.hGUI.Reset_pushbutton.Callback        = {@Reset_Frame_Limit, aD.hFig};
% aD.hGUI.Min_Frame_edit.Callback          = {@Set_Frame_Limit, aD.hFig};
% aD.hGUI.Frame_Value_edit.Callback        = {@Set_Frame, aD.hFig};
% aD.hGUI.Max_Frame_edit.Callback          = {@Set_Frame_Limit, aD.hFig};
% aD.hGUI.Rewind_pushbutton.Callback       = {@Limit, aD.hFig, -1};
% aD.hGUI.Step_Rewind_pushbutton.Callback  = {@Step, aD.hFig, -1};
% aD.hGUI.Step_Forward_pushbutton.Callback = {@Step, aD.hFig, 1};
% aD.hGUI.Forward_pushbutton.Callback      = {@Limit, aD.hFig 1};
% aD.hGUI.Stop_pushbutton.Callback         =  @Stop_Movie;
% aD.hGUI.Play_pushbutton.Callback         = {@Play_Movie, aD.hFig};
% aD.hGUI.Make_Movie_pushbutton.Callback   = {@Make_Movie, aD.hFig};
% aD.hGUI.Show_Frames_checkbox.Callback    = {@Show_Frame_Numbers, aD.hFig};
% aD.hGUI.Show_Objects_checkbox.Callback   = {@Toggle_All_Objects, aD.hFig};
% aD.hGUI.Object_List_popupmenu.Callback   = {@Toggle_Object, aD.hFig};

%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Create_New_Objects
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

hUtils = MR_utilities;

hFig = gcf;

objNames = retrieveNames;

%Create Button
[hButton, hToolbar] = hUtils.createButtonObject(hFig, ...
    makeButtonImage, ...
    {@Activate_MV, hFig}, ...
    {@Deactivate_MV, hFig},...
    objNames.buttonTag, ...
    objNames.buttonToolTipString);

    
hMenu  = hUtils.createMenuObject(hFig,...
    objNames.menuTag, ...
    objNames.menuLabel, ...
    {@Menu_MV, hFig});

aD.Name        = 'MV';
aD.hUtils      =  hUtils;
aD.hRoot       =  groot;
aD.hFig        =  hFig;
aD.hButton     =  hButton;
aD.hMenu       =  hMenu;
aD.hToolbar    =  hToolbar;
aD.objectNames =  objNames;

% store app data structure in tool-specific field
setappdata(aD.hFig, aD.Name, aD);

hAllAxes = findobj(aD.hFig, 'Type', 'Axes');

if isempty(getappdata(hAllAxes(1), 'CurrentImage'))
    % Current images do not have hidden dimension data
    % Assume if one axis has hidden dimension, all do.
    hButton.Enable=  'off';
    if ~isempty(hMenu), hMenu.Enable= 'Off'; end
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%	

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Activate_MV(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = configActiveFigure(hFig);

aD = configGUI(aD);

aD = configOther(aD);

aD = Set_Current_Axes(aD.hFig, aD.hCurrentAxes);

storeAD(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Deactivate_MV(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

Abort_Movie;

aD = getAD(hFig);

if ~isempty(aD.hButton)
    aD.hButton.Tag = aD.hButton.Tag(1:end-3);
end

if ~isempty(aD.hMenu)
    aD.hMenu.Checked = 'off';
    aD.hMenu.Tag = aD.hMenu.Tag(1:end-3);
end

% Restore old figure settings
aD.hUtils.restoreOrigData(aD.hFig, aD.origProperties);
aD.hUtils.restoreOrigData(aD.hAllAxes, aD.origAxesProperties);
aD.hUtils.restoreOrigData(aD.hAllImages, aD.origImageProperties);

% Reactivate other buttons
aD.hUtils.enableToolbarButtons(aD)

delete(aD.hFrameNumbers); % redrawn every call

% Close MV figure
delete(aD.hToolFig);

% Store aD in tool-specific apdata for next Activate call
setappdata(aD.hFig, aD.Name, aD);
rmappdata(aD.hFig, 'AD');

if ~isempty(aD.hObjects)
    for i = 1:size(aD.hObjects,1)
        hCurrObjs = aD.hObjects{i,1};
        hCurrObjs = hCurrObjs(ishghandle(hCurrObjs));
        delete(hCurrObjs  ); % redrawn every call
    end
    aD.hObjects = [];
end;

if ~isempty(aD.hSP) %?ishghandle?
    aD.SP.Enable = 'Off';
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Step(varargin)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

global GLOBAL_STOP_MOVIE;

if ~GLOBAL_STOP_MOVIE
	Stop_Movie;
end
%hIm  = varargin{1};

hFig = varargin{3};
aD = getAD(hFig);
aD.hCurrentAxes = aD.hFig.CurrentAxes;  % hFig.CurrentAxes; %gca

if nargin==4
    % Button call (direction defined by which button was pressed)
    direction = varargin{4};
elseif nargin==3 
    % axis/image click callback (direction define by type of click)
    selectionType = aD.hFig.SelectionType;
    
    switch selectionType
        case 'normal'
            direction = 1;
        case 'alt'
            direction = -1;
        case 'open'
            Play_Movie(hFig);
            return;
    end
end

storeAD(aD);

% Specify single or all axes
hAxesOfInterest = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);

for i = 1:length(hAxesOfInterest)
    currentFrame = getappdata(hAxesOfInterest(i), 'CurrentImage');
    imageRange   = getappdata(hAxesOfInterest(i), 'ImageRange');
    imageData    = getappdata(hAxesOfInterest(i), 'ImageData');
    
    if     (currentFrame + direction) > imageRange(2), currentFrame = imageRange(1);
    elseif (currentFrame + direction) < imageRange(1), currentFrame = imageRange(2);
    else                                               currentFrame = currentFrame + direction;
    end;
    
    setappdata(hAxesOfInterest(i), 'CurrentImage', currentFrame);
	aD.hFrameNumbers(aD.hAllAxes == hAxesOfInterest(i)).String = num2str(currentFrame);
	aD.hAllImages(aD.hAllAxes == hAxesOfInterest(i)).CData = squeeze(imageData(:,:,currentFrame));

    if isequal(aD.hCurrentAxes, hAxesOfInterest(i))
        % if doing the single current axes, update the
        aD.hGUI.Frame_Value_edit.String =  num2str(currentFrame);
        Set_Current_Axes(aD.hFig, hAxesOfInterest(i));
    end;

    % Update overlay objects if they exist 
    updateAllObjectsSingleAxes(aD, hAxesOfInterest(i),currentFrame );
%     if ~isempty(aD.hObjects)
%         objectData   = getappdata(hAxesOfInterest(i), 'Objects');
%         Update_Objects(objectData, aD.hObjects{aD.hAllAxes == hAxesOfInterest(i),1},currentFrame);
%     end;
%     
end;

figure(aD.hToolFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Limit(~,~,hFig, direction)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

% Specify single or all axes
hAxesOfInterest = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);

for i = 1:length(hAxesOfInterest)
	imageRange   = getappdata(hAxesOfInterest(i), 'ImageRange');
	imageData    = getappdata(hAxesOfInterest(i), 'ImageData');
	
	if direction == 1
		currentFrame = imageRange(2);
	elseif direction == -1
		currentFrame = imageRange(1);
	end;
	
	setappdata( hAxesOfInterest(i), 'CurrentImage', currentFrame);
	aD.hFrameNumbers(aD.hAllAxes == hAxesOfInterest(i)).String = num2str(currentFrame);
	aD.hAllImages(aD.hAllAxes == hAxesOfInterest(i)).CData =  squeeze(imageData(:,:,currentFrame));
   
    % if doing the single current axes, update frame numbers        
    if (aD.hCurrentAxes == hAxesOfInterest(i))
        aD.hGUI.Frame_Value_edit.String =  num2str(currentFrame);
        Set_Current_Axes(aD.hFig, hAxesOfInterest(i));
    end;
           
    % Update overlay objects if they exist
    updateAllObjectsSingleAxes(aD, hAxesOfInterest(i),currentFrame );
%     if ~isempty(aD.hObjects)
%         object_data   = getappdata(hAxesOfInterest(i), 'Objects');
%         Update_Objects(object_data, aD.hObjects{aD.hAllAxes == hAxesOfInterest(i),1},currentFrame);
%     end;
    
    
end;
figure(aD.hToolFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Set_Frame(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

currentFrame = str2double(aD.hGUI.Frame_Value_edit.String);

% specify single or all axes
% Specify single or all axes
hAxesOfInterest = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);


for i = 1:length(hAxesOfInterest)
	imageRange   = getappdata(hAxesOfInterest(i), 'ImageRange');
	imageData    = getappdata(hAxesOfInterest(i), 'ImageData');
	
	% Error check
	if currentFrame > imageRange(2), currentFrame = imageRange(2); end;
	if currentFrame < imageRange(1), currentFrame = imageRange(1); end;
	
	setappdata( hAxesOfInterest(i), 'CurrentImage', currentFrame);
    
    aD.hFrameNumbers( hAxesOfInterest(i) == aD.hAllAxes ).String = num2str(currentFrame);
	aD.hAllImages( hAxesOfInterest(i) == aD.hAllAxes ).CData = squeeze(imageData(:,:,currentFrame));
    
    if ( hAxesOfInterest(i) == aD.hCurrentAxes)
        aD.hGUI.Frame_Value_edit.String = num2str(currentFrame);
        Set_Current_Axes(aD.hFig, hAxesOfInterest(i));
    end;

    % Update overlay objects if they exist
    updateAllObjectsSingleAxes(aD, hAxesOfInterest(i),currentFrame );

end;
figure(aD.hFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Set_Frame_Limit(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);
aD.hCurrentAxes = gca;

%aD = Set_Current_Axes(hFig, aD.hCurrentAxes);

hAxesOfInterest = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);

% Get current limits from current axes
ImageRangeAll = getappdata(aD.hCurrentAxes, 'ImageRangeAll');
minFrame  = str2double(aD.hGUI.Min_Frame_edit.String);
maxFrame  = str2double(aD.hGUI.Max_Frame_edit.String);
currFrame = str2double(aD.hGUI.Frame_Value_edit.String);

if minFrame < ImageRangeAll(1), minFrame = ImageRangeAll(1); end;
if minFrame > currFrame       , minFrame = currFrame; end;

if maxFrame > ImageRangeAll(2), maxFrame = ImageRangeAll(2); end;
if maxFrame < currFrame       , maxFrame = currFrame; end;


for i = 1:length(hAxesOfInterest)
	setappdata(hAxesOfInterest(i), 'ImageRange', [minFrame maxFrame]);
	%aD.hGUI.Min_Frame_edit.String = minFrame;
	%aD.hGUI.Max_Frame_edit.String = maxFrame;
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Reset_Frame_Limit
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

hCurrentAxes = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);

for i = 1:length(hCurrentAxes)
	ImageRangeAll = getappdata(hCurrentAxes(i), 'ImageRangeAll');
	setappdata(hCurrentAxes(i), 'ImageRange',ImageRangeAll );
	aD.hGUI.Min_Frame_edit.String =  num2str(ImageRangeAll(1)) ;
	aD.hGUI.Max_Frame_edit.String =  num2str(ImageRangeAll(2)) ;
end;

Set_Current_Axes(aD.hFig, aD.hCurrentAxes);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Play_Movie(varargin)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

global GLOBAL_STOP_MOVIE

if nargin==1
    hFig = varargin{1}; % Internal call
elseif nargin==3
    hFig = varargin{3}; % Button Call
end
aD = getAD(hFig);

frameRate = str2double(aD.hGUI.Frame_Rate_edit.String);

origEnable = disableGUI(aD.hGUI);
aD.hGUI.Stop_pushbutton.Enable ='On';
		
hAxesOfInterest = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);

% Collect data needed for display (images, ranges, objects)
currentFrame = cell(size(hAxesOfInterest));
imageRange   = cell(size(hAxesOfInterest));
imageData    = cell(size(hAxesOfInterest));
for i = 1:length(hAxesOfInterest)
	currentFrame{i} = getappdata(hAxesOfInterest(i), 'CurrentImage');
	imageRange{i}   = getappdata(hAxesOfInterest(i), 'ImageRange');
	imageData{i}    = getappdata(hAxesOfInterest(i), 'ImageData');
end;

GLOBAL_STOP_MOVIE = 0;
t = 0;

while ~GLOBAL_STOP_MOVIE
	tic
	for i = 1:length(hAxesOfInterest)
		direction = 1;
        if     (currentFrame{i} + direction) > imageRange{i}(2), currentFrame{i} = imageRange{i}(1);
        elseif (currentFrame{i} + direction) < imageRange{i}(1), currentFrame{i} = imageRange{i}(2);
        else                                                     currentFrame{i} = currentFrame{i} + direction;
        end
        
        % Update image and frame number (go faster?)
        aD.hAllImages(hAxesOfInterest(i)==aD.hAllAxes).CData = imageData{i}(:,:,currentFrame{i});
        aD.hFrameNumbers(hAxesOfInterest(i)==aD.hAllAxes).String =  num2str(currentFrame{i});
        
        if (aD.hCurrentAxes == hAxesOfInterest(i))
            aD.hGUI.Frame_Value_edit.String = num2str(currentFrame{i});
        end
        
        % Update objects
        updateAllObjectsSingleAxes(aD, hAxesOfInterest(i),currentFrame{i} );

	end;
	drawnow;
	pause(t);
    estFrameRate = 1/toc;
	if estFrameRate > frameRate, t = t+0.01; end;	
end;

% Exit - update values for each of the axes in movie to correspond to last
% frame played; Do this if Deactivate nor CloseParentFigure has been
% called.

if (GLOBAL_STOP_MOVIE ~= 2)
    for i = 1:length(hAxesOfInterest)
        setappdata( hAxesOfInterest(i), 'CurrentImage', currentFrame{i});
        aD.hFrameNumbers(hAxesOfInterest(i)==aD.hAllAxes).String =  num2str(currentFrame{i});
        aD.hAllIms(hAxesOfInterest(i)==aD.hAllAxes).CData = imageData{i}(:,:,currentFrame{i});
        %set(findobj(hAxesOfInterest(i), 'Type', 'image'), 'CData', imageData{i}(:,:,currentFrame{i}));
        drawnow;
        
        if (aD.hCurrentAxes==hAxesOfInterest(i))
            % if doing the single current axes
            aD.hGUI.Frame_Value_edit.String = num2str(currentFrame{i});
            Set_Current_Axes(aD.hFig, hAxesOfInterest(i));
        end;
    end;
	
    % Turn objects back on
    enableGUI(aD.hGUI, origEnable);
    
    figure(aD.hToolFig);
    figure(aD.hFig);
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Make_Movie(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

makeAVI    = aD.hGUI.Make_Avi_checkbox.Value;
makeUAVI   = aD.hGUI.Make_UAvi_checkbox.Value; % uncompressed
makeMAT    = aD.hGUI.Make_Mat_checkbox.Value;
makeMP4    = aD.hGUI.Make_MP4_checkbox.Value;

if ~(makeAVI || makeMAT || makeMP4 || makeUAVI)
    return
end

frameRate = str2double(aD.hGUI.Frame_Rate_edit.String);

videoFormatStr = [];
if makeAVI || makeUAVI, videoFormatStr = [videoFormatStr,'*.avi;']; end
if makeMP4, videoFormatStr = [videoFormatStr,'*.mp4;']; end
if makeMAT, videoFormatStr = [videoFormatStr,'*.mat;']; end

[filename, pathname] = uiputfile( {videoFormatStr, ['Movie Files (',videoFormatStr,')']}, ...
    'Save Movie As', 'NewMovie');

if isequal(filename,0) || isequal(pathname,0)
    % User hit cancel instead of ok
    return;
end;
    
filename = [pathname, filename];

M = struct('cdata', [], 'colormap', []);

origEnable = disableGUI(aD.hGUI);

% Determine axis to be captured
hAxesOfInterest = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);
if length(hAxesOfInterest)>1
    hForGetFrame = aD.hFig;         % movie of Figure (all axes)
else
    hForGetFrame = aD.hCurrentAxes; % movie of single axes
end

% collect info for each of the frames to be used.
imageRange   = cell(size(hAxesOfInterest));
imageData    = cell(size(hAxesOfInterest));
currentFrame = cell(size(hAxesOfInterest));

for i = 1:length(hAxesOfInterest)
    imageRange{i}   = getappdata(hAxesOfInterest(i), 'ImageRange');
    imageData{i}    = getappdata(hAxesOfInterest(i), 'ImageData');
    currentFrame{i} = getappdata(hAxesOfInterest(i), 'CurrentImage'); %imageRange{i}(1);
    
    if hAxesOfInterest(i)==aD.hCurrentAxes
        endFrame   = currentFrame{i}-1;
        if     endFrame > imageRange{i}(2), endFrame = imageRange{i}(1);
        elseif endFrame < imageRange{i}(1), endFrame = imageRange{i}(2);
        end
        refAxes   = i;
    end
end;

% Play each frame;  that number of frames specified by the
%  editable text boxes (i.e. the current axes frame limits) even if other
%  axes have different numbers of frames. However, each axes will start
%  at its own beginning frame
stopMovie = 0;
counter = 1;
direction = 0;

% Capture movie frames, cycle once through using the CurrentAxes limits
% and frame numbers as guide.
while ~stopMovie
    for i = 1:length(hAxesOfInterest)
       
        if  (currentFrame{i} + direction) > imageRange{i}(2)
            currentFrame{i} = imageRange{i}(1);
        elseif (currentFrame{i} + direction) < imageRange{i}(1)
            currentFrame{i} = imageRange{i}(2);
        else
            currentFrame{i} = currentFrame{i} + direction;
        end;
        
        % Update image and frame number (go faster?)
        aD.hAllImages(hAxesOfInterest(i)==aD.hAllAxes).CData = imageData{i}(:,:,currentFrame{i});
        aD.hFrameNumbers(hAxesOfInterest(i)==aD.hAllAxes).String =  num2str(currentFrame{i});
        
        % Update objects
        updateAllObjectsSingleAxes(aD, hAxesOfInterest(i),currentFrame{i} );
        
    end
    
    drawnow;
    
    M(counter) = getframe(hForGetFrame);
    
    counter = counter + 1;
    direction = 1; % movie always forward
    
    % Determine if the movie is over: played the last frame
    % of the reference axes (current)
    if isequal(currentFrame{refAxes},endFrame), stopMovie = 1; end

end

filename = filename(1:end-4); % remove suffix

if makeAVI 
    Mov = VideoWriter(filename, 'Motion JPEG AVI'); 
    Mov.FrameRate = frameRate;
    Mov.Quality = 100;
    open(Mov)
    writeVideo(Mov,M);
    close(Mov);
end;

if makeUAVI 
    Mov = VideoWriter([filename, '_uncomp'], 'Uncompressed AVI'); 
    Mov.FrameRate = frameRate;
    open(Mov)
    writeVideo(Mov,M);
    close(Mov);
end;

if makeMP4
    Mov = VideoWriter(filename, 'MPEG-4');
    Mov.FrameRate = frameRate;
    Mov.Quality = 100;
    open(Mov)
    writeVideo(Mov,M);
    close(Mov);
end

if makeMAT % save movie object
    save([filename,'.mat'], 'M');
end


% Turn objects back on
enableGUI(aD.hGUI, origEnable);
dispDebug('End');
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Stop_Movie(varargin)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

global GLOBAL_STOP_MOVIE
GLOBAL_STOP_MOVIE = 1;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Abort_Movie(varargin)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

global GLOBAL_STOP_MOVIE
GLOBAL_STOP_MOVIE = 2;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Show_Frame_Numbers(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
aD = getAD(hFig);

visibility = aD.hGUI.Show_Frames_checkbox.Value;
if visibility, visibility = 'On' ;
else           visibility = 'Off'; end
[aD.hFrameNumbers(:).Visible] = deal(visibility);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function aD = Set_Current_Axes(hFig, hCurrentAxes)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

aD.hCurrentAxes= hCurrentAxes;
aD.hFig.CurrentAxes = hCurrentAxes;

image_range = getappdata(hCurrentAxes, 'ImageRange');
aD.hGUI.Min_Frame_edit.String =  num2str(image_range(1));
aD.hGUI.Max_Frame_edit.String =  num2str(image_range(2));

 if ~isempty(aD.hObjects)
     % Update popupmenu string to reflect current axes
     hCurrentAxes_idx = aD.hAllAxes==aD.hCurrentAxes;
     aD.hGUI.Object_List_popupmenu.String = ...
         aD.hObjects{hCurrentAxes_idx,3};
 end;

storeAD(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Menu_MV(~,~, hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
aD = getAD(hFig);
aD.hUtils.menuToggle(aD.hMenu,aD.hButton);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  Toggle_All_Objects(varargin)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function toggle the display of the objects

dispDebug;
hFig = varargin{end}; %1 if internal; 3 if external call
aD = getAD(hFig);

if ~isempty(aD.hObjects)
    % Objects exist (they have already been drawn)
    aD.hGUI.Show_Objects_checkbox.Enable = 'On';
    show = aD.hGUI.Show_Objects_checkbox.Value;
   
    % make the PopupMenu (already filled) visible
    if show
        aD.hGUI.Object_List_popupmenu.Visible ='On';
    else
        aD.hGUI.Object_List_popupmenu.Visible ='Off';
    end    
    
    for i = 1:size(aD.hObjects,1)
        h_obj = aD.hObjects{i,1};
        if show
            [h_obj(isgraphics(h_obj)).Visible] = deal('On');
        else
            [h_obj(isgraphics(h_obj)).Visible] = deal('Off');
        end
    end    
else
    % There are no objects
    aD.hGUI.Show_Objects_checkbox.Enable = 'Off';
    aD.hGUI.Object_List_popupmenu.Visible= 'Off';
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  Update_All_Objects(objStruct, hObjects, frame)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to update the relevant properties for each type of object
dispDebug;

for j = 1:size(hObjects,1)
    if isgraphics(hObjects(j))
        if strcmpi(hObjects(j).Type, 'Line') ||  strcmpi( hObjects(j).Type, 'Points')
            hObjects(j).XData = objStruct(j,frame).XData(:);
            hObjects(j).YData = objStruct(j,frame).YData(:);
            
            if ~isempty(objStruct(j,frame).XData(:))
                % empty object; do not update other properties
                hObjects(j).Color = objStruct(j,frame).Color;
                updateOtherObjectProps(hObjects(j), objStruct(j,frame) )
            end
        elseif strcmpi(hObjects(j).Type, 'Patch')
            hObjects(j).XData = objStruct(j,frame).XData(:);
            hObjects(j).YData = objStruct(j,frame).YData(:);
            if ~isempty(objStruct(j,frame).XData(:))  % empty object
                % empty object; do not update other properties
                updateOtherObjectProps(hObjects(j), objStruct(j,frame) )
            end
        end
    end
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  Toggle_Object(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to toggle display of an object in a given axes or all 
%  axes
dispDebug;
aD =getAD(hFig);

toggleVal    = aD.hGUI.Object_List_popupmenu.Value;
toggleString = aD.hGUI.Object_List_popupmenu.String(toggleVal,:);
popupmenuString = aD.hGUI.Object_List_popupmenu.String;

% Specify single or all axes
hAxesOfInterest = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);

Hide = strncmp('Hide', toggleString, length('Hide'));

if ~Hide , newString = 'Hide'; oldString = 'Show'; visibility = 'on';
else       newString = 'Show'; oldString = 'Hide'; visibility = 'off';
end;

for i = 1:length(hAxesOfInterest)
    
    hCurrObjects = aD.hObjects{ aD.hAllAxes == hAxesOfInterest(i), 1};
    
    popupmenuString(toggleVal,:) = strrep(toggleString,oldString,newString);
    
    for j = 1:size(hCurrObjects,1)    
        % Current Object list could have empty graphics placeholders. 
        %  if so, skip the update of the string because there is no
        %  popupstring stored in the Userdata to modify.
        if isgraphics(hCurrObjects(j))
            if strncmp(deblank(get(hCurrObjects(j),'Userdata')), deblank(toggleString(6:end)), length(deblank(toggleString(6:end))))
                hCurrObjects(j).Visible =  visibility;
                aD.hGUI.Object_List_popupmenu.String =  popupmenuString;
            end;
        end
    end;
    aD.hObjects{ aD.hAllAxes == hAxesOfInterest(i),3} = popupmenuString;    
end;

storeAD(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%START SUPPORT FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  dispDebug(varargin)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print a debug string if global debug flag is set
global DB;

if DB
    objectNames = retrieveNames;
    x = dbstack;
    func_name = x(2).name;    loc = [];
    if length(x) > 3
        loc = [' (loc) ', repmat('|> ',1, length(x)-3)] ;
    end
    fprintf([objectNames.toolName, ':',loc , ' %s'], func_name);
    if nargin>0
        for i = 1:length(varargin)
            str = varargin{i};
            fprintf(': %s', str);
        end
    end
    fprintf('\n');
    
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = configActiveFigure(hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PART I - Environment
dispDebug;
objNames = retrieveNames;
aD = getappdata(hFig, objNames.Name); 
aD.hFig.Tag      = aD.objectNames.activeFigureName; % ActiveFigure

% Check the menu object
if ~isempty(aD.hMenu), aD.hMenu.Checked = 'on'; end

% Find toolbar and deactivate other buttons
aD= aD.hUtils.disableToolbarButtons(aD,aD.objectNames.buttonTag);

% Store initial state of all axes in current figure for reset
aD.hAllAxes = flipud(findobj(aD.hFig,'Type','Axes'));
aD.hFig.CurrentAxes = aD.hAllAxes(1);
aD.hAllImages   = aD.hUtils.findAxesChildIm(aD.hAllAxes);

% Set current figure and axis
aD = aD.hUtils.updateHCurrentFigAxes(aD);

% Store the figure's old infor within the fig's own userdata
aD.origProperties      = aD.hUtils.retrieveOrigData(aD.hFig);
aD.origAxesProperties  = aD.hUtils.retrieveOrigData(aD.hAllAxes , {'ButtonDownFcn', 'XLimMode', 'YLimMode'});
aD.origImageProperties = aD.hUtils.retrieveOrigData(aD.hAllImages , {'ButtonDownFcn'});

% Find and close the old WL figure to avoid conflicts
hToolFigOld = aD.hUtils.findHiddenObj(aD.hRoot.Children, 'Tag', aD.objectNames.figTag);
if ~isempty(hToolFigOld), delete(hToolFigOld);end
pause(0.5);

% Make it easy to find this button (tack on 'On') after old fig is closed
aD.hButton.Tag   = [aD.hButton.Tag,'_On'];
aD.hMenuPZ.Tag   = [aD.hMenu.Tag, '_On'];

% Set figure clsoe callback
aD.hFig.CloseRequestFcn = {@localCloseParentFigure, aD.objectNames.figTag};

% Draw faster and without flashes
aD.hFig.Renderer = 'zbuffer';
[aD.hAllAxes.SortMethod] = deal('Depth');
[aD.hAllAxes.XLimMode]   = deal('manual');
[aD.hAllAxes.YLimMode]   = deal('manual');
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = configGUI(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD.hToolFig = openfig(aD.objectNames.figFilename,'reuse');

% Enable save_prefs tool button
if ~isempty(aD.hToolbar)
    aD.hSP = findobj(aD.hToolbarChildren, 'Tag', 'figButtonSP');
    aD.hSP.Enable = 'On';
    optionalUIControls = { ...
        'Apply_radiobutton',     'Value'; ...
        'Frame_Rate_edit',       'String'; ...
        'Make_Avi_checkbox',     'Value'; ...
        'Make_UAvi_checkbox',    'Value'; ...
        'Make_MP4_checkbox',     'Value'; ...   
        'Make_Mat_checkbox',     'Value'; ...
        'Show_Frames_checkbox',  'Value'; ...
        'Show_Objects_checkbox', 'Value';...
        };
    aD.hSP.UserData = {aD.hToolFig, aD.objectNames.figFilename, optionalUIControls};
end

% Generate a structure of handles to pass to callbacks, and store it. 
aD.hGUI = guihandles(aD.hToolFig);

if ismac, aD.hUtils.adjustGUIForMAC(aD.hGUI); end

aD.hToolFig.Name = aD.objectNames.figName;
aD.hToolFig.CloseRequestFcn = {aD.hUtils.closeRequestCallback, aD.hUtils.limitAD(aD)};

% Set Object callbacks; return hFig for speed
aD.hGUI.Reset_pushbutton.Callback        = {@Reset_Frame_Limit,  aD.hFig};
aD.hGUI.Min_Frame_edit.Callback          = {@Set_Frame_Limit,    aD.hFig};
aD.hGUI.Frame_Value_edit.Callback        = {@Set_Frame,          aD.hFig};
aD.hGUI.Max_Frame_edit.Callback          = {@Set_Frame_Limit,    aD.hFig};
aD.hGUI.Rewind_pushbutton.Callback       = {@Limit,              aD.hFig, -1};
aD.hGUI.Step_Rewind_pushbutton.Callback  = {@Step,               aD.hFig, -1};
aD.hGUI.Step_Forward_pushbutton.Callback = {@Step,               aD.hFig, +1};
aD.hGUI.Forward_pushbutton.Callback      = {@Limit,              aD.hFig, +1};
aD.hGUI.Stop_pushbutton.Callback         =  @Stop_Movie;
aD.hGUI.Play_pushbutton.Callback         = {@Play_Movie,         aD.hFig};
aD.hGUI.Make_Movie_pushbutton.Callback   = {@Make_Movie,         aD.hFig};
aD.hGUI.Show_Frames_checkbox.Callback    = {@Show_Frame_Numbers, aD.hFig};
aD.hGUI.Show_Objects_checkbox.Callback   = {@Toggle_All_Objects, aD.hFig};
aD.hGUI.Object_List_popupmenu.Callback   = {@Toggle_Object,      aD.hFig};
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = configOther(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  PART III - Finish setup for other objects
%[aD.hAllAxes(:).ButtonDownFcn] = deal({@Set_Current_Axes, aD.hFig, 'x', 'x'});
[aD.hAllImages(:).ButtonDownFcn] = deal({@Step, aD.hFig});
aD.hRoot.CurrentFigure = aD.hFig;

% Add frame number to each axes
aD.hFrameNumbers = createFrameNumbers(aD.hFig, aD.hAllAxes);
textVisibility = aD.hGUI.Show_Frames_checkbox.Value;
if textVisibility, textVisibility = 'On' ;
else               textVisibility = 'Off'; end;
[aD.hFrameNumbers(:).Visible] = deal(textVisibility);

aD.hFig.CurrentAxes = aD.hCurrentAxes;
aD.hRoot.CurrentFigure = aD.hToolFig;

aD.hGUI.Frame_Value_edit.String = num2str(getappdata(aD.hCurrentAxes,'CurrentImage'));	
imageRangeAll = getappdata(aD.hCurrentAxes,'ImageRangeAll');
aD.hGUI.Max_Frame_edit.String = num2str(imageRangeAll(2));	
aD.hGUI.Min_Frame_edit.String = num2str(imageRangeAll(1));	

% Display pre-loaded Objects (additional graphics overlaid on image)
aD.hObjects = []; 
aD = drawAllObjects(aD);
Toggle_All_Objects(aD.hFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function buttonImage = makeButtonImage
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The default button size is 15 x 16 x 3.
dispDebug;

buttonSize_x= 16;
buttonImage = NaN* zeros(15,buttonSize_x);

f= [...
    9    10    11    12    13    14    15    24    30    39    45    50    51    52    53    54    60, ...
    65    69    75    80    84    90    91    92    93    94    95    99   100   101   102   103   104, ...
    105   106   110   116   121   125   131   135   136   140   141   142   143   144   145   146   149, ...
    151   157   163   166   172   177   181   182   183   184   185   186   187   189   191   204   205, ...
    219   220   221 ...
    ];

buttonImage(f) = 0;
buttonImage = repmat(buttonImage, [1,1,3]);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function structNames = retrieveNames
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
structNames.Name                = 'MV';
structNames.toolName            = 'MV_tool';
structNames.buttonTag           = 'figButtonMV';
structNames.buttonToolTipString = 'View Images & Make Movies';
structNames.menuTag             = 'menuViewImages';
structNames.menuLabel           = 'Movie Tool';
structNames.figFilename         = 'MV_tool_figure.fig';
structNames.figName             = 'MV Tool';
structNames.figTag              = 'MV_figure';
structNames.activeFigureName    = 'ActiveFigure';
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function storeAD(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
setappdata(aD.hFig, 'AD', aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function aD = getAD(hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Retrieve application data stored within Active Figure (aka image figure)
%  Appdata name depends on tool. 
dispDebug;
aD = getappdata(hFig, 'AD');
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function hAxes = getApplyToAxes(aD, Apply_radiobutton)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
applyAll = Apply_radiobutton.Value;
if applyAll
    hAxes = aD.hAllAxes;
else
    hAxes = aD.hCurrentAxes;
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function origEnable = disableGUI(hGUI)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

h = fieldnames(hGUI);
origEnable = cell(size(h));
for i = 1:length(h)
    if strcmpi('uicontrol', hGUI.(h{i}).Type)
        origEnable{i} = hGUI.(h{i}).Enable;
        hGUI.(h{i}).Enable = 'Off';
    end
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function enableGUI(hGUI, origEnable)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
h = fieldnames(hGUI);
for i =1:length(h)
    if strcmpi('uicontrol', hGUI.(h{i}).Type)
        hGUI.(h{i}).Enable = origEnable{i};
    end
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function hFrameNumbers = createFrameNumbers(hFig, hAllAxes)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calc text size
reftextFontSize = 20;
reffigSize = 8;   % 8 inch wide figure gets 20 pt font

figUnits = hFig.Units;
hFig.Units = 'inches';
figSize = hFig.Position;
textFontSize = reftextFontSize * figSize(3) / reffigSize;
hFig.Units = figUnits;

% Create text object per axes
hFrameNumbers = gobjects(size(hAllAxes));
for i = 1:length(hAllAxes)
	X = hAllAxes(i).XLim;
	Y = hAllAxes(i).YLim;
    str = num2str(getappdata(hAllAxes(i), 'CurrentImage')); 
 	hFrameNumbers(i) = text(hAllAxes(i), X(2)*0.98, Y(2), str);
end;

%[hIms(:).ButtonDownFcn] = deal({@Step, hFig});
[hFrameNumbers(:).FontSize] = deal(textFontSize);
[hFrameNumbers(:).Color] = deal([ 1 0.95 0]);
[hFrameNumbers(:).VerticalAlignment] = deal('bottom');
[hFrameNumbers(:).HorizontalAlignment] = deal('right');
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function localCloseParentFigure(hFig, ~, figTag)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
Abort_Movie;
aD = getAD(hFig);
aD.hUtils.closeParentFigure(hFig,[], figTag);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function aD = drawAllObjects(aD)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to draw a series of pre-drawn objects per axis; 
%  Objects change with temporal dimension draw temporal objects, if found
dispDebug;
hObjects = cell(length(aD.hAllAxes),3);

drewObjectsFlag = 0;
for i = 1:length(aD.hAllAxes)

    if isappdata(aD.hAllAxes(i), 'Objects')
        % Objects exist, Draw them
        objectData =  getappdata(aD.hAllAxes(i),'Objects');
        [hObjects{i,1}, hObjects{i,2}] = drawAllObjectsPerAxes(objectData , aD.hAllAxes(i)) ;
        
        % load the current axes objets onto popupmenu
        %if(aD.hAllAxes(i)==aD.hCurrentAxes)
        popupstring = [repmat('Hide ', size(hObjects{i,2},1),1), hObjects{i,2}];
        aD.hGUI.Object_List_popupmenu.String = popupstring;
        hObjects{i,3} = popupstring;
        drewObjectsFlag = 1;

        % load the current axes object list into popupmenu
        if(aD.hAllAxes(i)==aD.hCurrentAxes)
            aD.hGUI.Object_List_popupmenu.String = popupstring;
        end
    end;

end;

if drewObjectsFlag
    %     aD.hGUI.Show_Objects_checkbox.Enable = 'On';
    aD.hGUI.Object_List_popupmenu.Visible = 'On';
    aD.hObjects = hObjects;
else
    %     aD.hGUI.Show_Objects_checkbox.Enable = 'Off';
    aD.hGUI.Object_List_popupmenu.Visible = 'Off';
    aD.hObjects = [];
end
storeAD(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function [hObject, objectNames] = drawAllObjectsPerAxes(objDataStruct, hAxes)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to cycle through drawing objects; 
%  Each object (data loaded into appdata 'Objects' for each axes, is
%  composed of structure that contains field type (line,point,patch), 
%  xdata ydata and color 
dispDebug;

CurrImage = getappdata(hAxes,'CurrentImage'); 
origNextPlot = get(hAxes, 'NextPlot');
hAxes.NextPlot = 'Add'; % overlay


hObject = gobjects(size(objDataStruct,1),1);

% Empty objects in objDataStruct sent in by user are allowed but at least
%  one object has to exist in a time series. If any row is empty, remove
%  it;

% Make name list (overcomes first object of a kind being empty)
objectNames = [];
for i = 1:size(objDataStruct,1)
    name = cell(1, size(objDataStruct,2));
    for j = 1:size(objDataStruct,2)
        
        name{j} = objDataStruct(i,j).Name;
    end    
    name = unique(name(~cellfun(@isempty, name)));
    if isempty(objectNames)
        objectNames = name{1};
    else
        objectNames = char(objectNames, name{1});
    end
end

% Draw each object in the list of objects for this axes;
for i = 1:size(objDataStruct,1)
    
    objType = objDataStruct(i,CurrImage).Type;
    
    %if ~isempty(objType)
    
    % Assume at least one time point has an object to draw; 
    
    if strcmpi(objType, 'Line') % min props: xdata,ydata, color, name
        hObject(i,1) = plot(hAxes, ...
            objDataStruct(i,CurrImage).XData(:), ...
            objDataStruct(i,CurrImage).YData(:),...
            'color', objDataStruct(i,CurrImage).Color );
        hObject(i,1).LineStyle = '-';
        hObject(i,1).Marker    = 'none';
        
        updateOtherObjectProps( hObject(i,1), objDataStruct(i,CurrImage) ) ;
        
    elseif strcmpi(objType, 'Points') % min props: xdata,ydata, color, marker, name
        hObject(i,1) = plot(hAxes, ...
            objDataStruct(i,CurrImage).XData(:), ....
            objDataStruct(i,CurrImage).YData(:),...
            'color', objDataStruct(i,CurrImage).Color );
        hObject(i,1).LineStyle = 'none';
        hObject(i,1).Marker    =  objDataStruct(i,CurrImage).Marker;
        
        updateOtherObjectProps( hObject(i,1), objDataStruct(i,CurrImage) ) ;
        
    elseif strcmpi(objType, 'Patch') % min props: xdata,ydata, color, name
        hObject(i,1) = patch(hAxes, ...
            objDataStruct(i,CurrImage).XData(:), ...
            objDataStruct(i,CurrImage).YData(:),...
            objDataStruct(i,CurrImage).Color ) ;
        
        updateOtherObjectProps( hObject(i,1), objDataStruct(i,CurrImage) ) ;
        
    else
        disp('Unknown object type!');
    end;
        
    if ~isempty(objType)
        hObject(i,1).UserData      = objDataStruct(i,CurrImage).Name; 
    end
        
    %outName = objDataStruct(i,CurrImage).Name;
% 
%         
%     % Add name to list
%     if isempty( objectNames)
%         objectNames = outName;
%     else
%         objectNames = char(objectNames, outName);
%     end

end
hAxes.NextPlot =  origNextPlot;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function updateAllObjectsSingleAxes(aD, hAx, frame ) 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
if ~isempty(aD.hObjects)
    objectData   = getappdata(hAx, 'Objects');
    Update_All_Objects(objectData, aD.hObjects{aD.hAllAxes == hAx,1},frame);
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function updateOtherObjectProps( hObject, objDataStruct ) 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
if isfield(objDataStruct, 'Other') && ~isempty(objDataStruct.Other)
    props = fieldnames(objDataStruct.Other);
    for idx = 1:length(props)
        if isprop(hObject, props{idx})
            hObject.(props{idx}) = objDataStruct.Other.(props{idx});
        end
    end
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%




