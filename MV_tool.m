function MV_tool(varargin)
% function MV_tool(varargin)
% Movie viewing tool for displaying 3D or 4D sets of data. Use with
% imagescn. Can export to avi.
% Usage: MV_tool;
%
% Author: Daniel Herzka  daniel.herzka@nih.gov 
% Laboratory of Cardiac Energetics 
% National Heart, Lung and Blood Institute, NIH, DHHS
% Bethesda, MD 20892
% and 
% Medical Imaging Laboratory
% Department of Biomedical Engineering
% Johns Hopkins University Schoold of Medicine
% Baltimore, MD 21205
%
% Updated: Daniel Herzka, 2017-02 -> .v0
% Cardiovascular Intervention Program
% National Heart, Lung and Blood Institute, NIH, DHHS
% Bethesda, MD 20892

% Set or clear global debug flag
dispDebug('Entry');
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

% Check for time-dimension data. If none, deactivate tool.
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

% Delete Objects which are redrawn every time tool is activated
if ~isempty(aD.objectStruct)
    for i = 1:size(aD.objectStruct)
        hCurrObjs = aD.objectStruct(i).handles;
        hCurrObjs = hCurrObjs(ishghandle(hCurrObjs));
        delete(hCurrObjs  ); 
    end
    aD.hObjects = [];
end;
delete(aD.hFrameNumbers); % redrawn every call

aD.hUtils.deactivateButton(aD);
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
    updateAllObjectsOneAxes(aD, hAxesOfInterest(i),currentFrame );
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
    updateAllObjectsOneAxes(aD, hAxesOfInterest(i),currentFrame );
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
    updateAllObjectsOneAxes(aD, hAxesOfInterest(i),currentFrame );

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

origEnable = aD.hUtils.disableGUIObjects(aD.hGUI, 'Stop_pushbutton');
		
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
        updateAllObjectsOneAxes(aD, hAxesOfInterest(i),currentFrame{i} );

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
    aD.hUtils.restoreGUIObjects(aD.hGUI, origEnable);
    
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

origEnable = aD.hUtils.disableGUIObjects(aD.hGUI);

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
        updateAllObjectsOneAxes(aD, hAxesOfInterest(i),currentFrame{i} );
        
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
aD.hUtils.restoreGUIObjects(aD.hGUI, origEnable);
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

hCurrentAxes_idx = aD.hAllAxes==aD.hCurrentAxes;

if ~isempty(aD.objectStruct(hCurrentAxes_idx))
    % Update popupmenu string to reflect current axes
    aD.hGUI.Object_List_popupmenu.String = ...
        aD.objectPopupString{hCurrentAxes_idx};
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
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% START FUNCTIONS RELATED TO OBJECT DISPLAY %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  Toggle_All_Objects(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function toggle the display of all objects based on checkbox

dispDebug;
aD = getAD(hFig);

if ~isempty(aD.objectStruct)
    % Objects exist (they have already been drawn)
    aD.hGUI.Show_Objects_checkbox.Enable = 'On';
    show = aD.hGUI.Show_Objects_checkbox.Value;
   
    % make the PopupMenu (already filled) visible
    if show
        aD.hGUI.Object_List_popupmenu.Visible ='On';
    else
        aD.hGUI.Object_List_popupmenu.Visible ='Off';
    end    
    
    for i = 1:size(aD.objectStruct,1)
        hObj = aD.objectStruct(i).handles;
        if show
            [hObj(isgraphics(hObj)).Visible] = deal('On');
        else
            [hObj(isgraphics(hObj)).Visible] = deal('Off');
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
function  Toggle_Object(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to toggle display of an object in a given axes or all 
%  axes in response to a selection on the popupmenu
dispDebug;
aD =getAD(hFig);

toggleVal       = aD.hGUI.Object_List_popupmenu.Value;
toggleString    = aD.hGUI.Object_List_popupmenu.String(toggleVal,:);
popupmenuString = aD.hGUI.Object_List_popupmenu.String;

% Specify single or all axes
hAxesOfInterest = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);

Hide = strncmp('Hide', toggleString, length('Hide'));

if ~Hide , newString = 'Hide'; oldString = 'Show'; visibility = 'on';
else       newString = 'Show'; oldString = 'Hide'; visibility = 'off';
end;

for i = 1:length(hAxesOfInterest)
    
    hCurrObjects = aD.objectStruct( aD.hAllAxes == hAxesOfInterest(i)).handles;
    
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
    aD.objectPopupString{ aD.hAllAxes == hAxesOfInterest(i)} = popupmenuString;    
end;

storeAD(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  updateAllObjectsOneAxes(aD, hAx, frame ) 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to update the relevant properties for each type of object 
%  typically called when the frame changes. Called to update all objects
%  within a single axes.
dispDebug;

if ~isempty(aD.objectStruct)
    objStruct = aD.objectStruct(aD.hAllAxes == hAx,1);
    
    for j = 1:size(objStruct.handles,1)
        
        if isgraphics(objStruct.handles(j))
            
            if strcmpi(objStruct.data(j,frame).Type, 'Line') ||  strcmpi( objStruct.data(j,frame).Type, 'Points')
                objStruct.handles(j).XData = objStruct.data(j,frame).XData(:);
                objStruct.handles(j).YData = objStruct.data(j,frame).YData(:);
                
                if ~isempty(objStruct.data(j,frame).XData(:))
                    % empty object; do not update other properties
                    objStruct.handles(j).Color = objStruct.data(j,frame).Color;
                    updateOtherObjectProps(objStruct.handles(j), objStruct.data(j,frame) )
                end
                
            elseif strcmpi(objStruct.handles(j).Type, 'Patch')
                objStruct.handles(j).XData = objStruct.data(j,frame).XData(:);
                objStruct.handles(j).YData = objStruct.data(j,frame).YData(:);
                if ~isempty(objStruct.data(j,frame).XData(:))  % empty object
                    % empty object; do not update other properties
                    updateOtherObjectProps(objStruct.handles(j), objStruct.data(j,frame) )
                end
            else
                dispDebug('Unrecognized Object!');
            end
            
        end
        
    end
    
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function aD = drawAllObjects(aD)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to draw a series of graphics objects per axis; 
% Objects change with temporal dimension
% Object info is stored in a cell array (# rows = # axes; # cols = 3 with
%  1) data; 2) handles, 3) object names, 4) popupstring ready to be loaded into popupmenu 
% Only axes with 'Objects' appdata are used. Other axes are ignored.

dispDebug;

oStruct = struct('data', [], 'handles', [],'names', []);
oPopupString = cell(length(aD.hAllAxes),1);
%hObjects = cell(length(aD.hAllAxes),3);



drewObjectsFlag = 0;
for i = 1:length(aD.hAllAxes)

    if isappdata(aD.hAllAxes(i), 'Objects')

        oStruct(i,1).data    = getappdata(aD.hAllAxes(i),'Objects');
        oStruct(i,1).names   = makeObjectNameList(oStruct(i).data);
        oStruct(i,1).handles = drawAllObjectsOneAxes(oStruct(i).data , aD.hAllAxes(i)) ;
        oPopupString{i}      = [repmat('Hide ', size(oStruct(i).names ,1),1), oStruct(i).names ];

        drewObjectsFlag = 1;

        % load the current axes object list into popupmenu
        if(aD.hAllAxes(i)==aD.hCurrentAxes)
            aD.hGUI.Object_List_popupmenu.String = oPopupString{i};
        end
    else
        % make sure that the object structure has the right size 
        %  (#axis=#rows)
        oStruct(i,1).data = [];        
    end;

end;

if drewObjectsFlag
    aD.hGUI.Object_List_popupmenu.Visible = 'On';
    aD.objectStruct = oStruct;
    aD.objectPopupString = oPopupString;
else
    aD.hGUI.Object_List_popupmenu.Visible = 'Off';
    aD.objectStruct = [];
    aD.objectPopupString = [];
end
storeAD(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function hObjects = drawAllObjectsOneAxes(objDataStruct, hAxes)
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

hObjects = gobjects(size(objDataStruct,1),1);

% Empty objects in objDataStruct sent in by user are allowed but at least
%  one object has to exist in a time series. If any row was empty, remove
%  it was removed before entering this function. FIX BUG: if first object in a
%  time series is empty, no object in the series will draw.

% Draw each object in the list of objects for this axes;
for i = 1:size(objDataStruct,1)
    
    objType = objDataStruct(i,CurrImage).Type;    
    % Assume at least one time point has an object to draw; 
    
    if ~isempty(objType)
        if strcmpi(objType, 'Line') % min props: xdata,ydata, color, name
            hObjects(i,1) = plot(hAxes, ...
                objDataStruct(i,CurrImage).XData(:), ...
                objDataStruct(i,CurrImage).YData(:),...
                'color', objDataStruct(i,CurrImage).Color );
            hObjects(i,1).LineStyle = '-';
            hObjects(i,1).Marker    = 'none';
            hObjects(i,1).UserData  = objDataStruct(i,CurrImage).Name;
            
            updateOtherObjectProps( hObjects(i,1), objDataStruct(i,CurrImage) ) ;
            
        elseif strcmpi(objType, 'Points') % min props: xdata,ydata, color, marker, name
            hObjects(i,1) = plot(hAxes, ...
                objDataStruct(i,CurrImage).XData(:), ....
                objDataStruct(i,CurrImage).YData(:),...
                'color', objDataStruct(i,CurrImage).Color );
            hObjects(i,1).LineStyle = 'none';
            hObjects(i,1).Marker    =  objDataStruct(i,CurrImage).Marker;
            hObjects(i,1).UserData  = objDataStruct(i,CurrImage).Name;
            
            updateOtherObjectProps( hObjects(i,1), objDataStruct(i,CurrImage) ) ;
            
        elseif strcmpi(objType, 'Patch') % min props: xdata,ydata, color, name
            hObjects(i,1) = patch(hAxes, ...
                objDataStruct(i,CurrImage).XData(:), ...
                objDataStruct(i,CurrImage).YData(:),...
                objDataStruct(i,CurrImage).Color ) ;
            hObjects(i,1).UserData      = objDataStruct(i,CurrImage).Name;
            
            updateOtherObjectProps( hObjects(i,1), objDataStruct(i,CurrImage) ) ;            
        
        else
            dispDebug('Unknown object Type!');
        end       
    end
        
end
hAxes.NextPlot =  origNextPlot;
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

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function objectNames = makeObjectNameList(objDataStruct)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make object name list for one axes
objectNames = [];
for i = 1:size(objDataStruct,1)
    name = cell(1, size(objDataStruct,2));
    for j = 1:size(objDataStruct,2)
        name{j} = objDataStruct(i,j).Name;
    end
    name = unique(name(~cellfun(@isempty, name)));
    if isempty(name)
        name = {'<Empty>'};
    end
    if isempty(objectNames)
        objectNames = name{1};
    else
        objectNames = char(objectNames, name{1});
    end
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% START SUPPORT FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%
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
aD.hAllImages   = aD.hUtils.findAxesChildIm(aD.hAllAxes);
aD.hFig.CurrentAxes = aD.hAllAxes(1);

% Set current figure and axis
aD = aD.hUtils.updateHCurrentFigAxes(aD);

% Store the figure's old info within the fig's own userdata
aD.origProperties      = aD.hUtils.retrieveOrigData(aD.hFig);
aD.origAxesProperties  = aD.hUtils.retrieveOrigData(aD.hAllAxes , ...
    {'ButtonDownFcn', 'XLimMode', 'YLimMode', 'SortMethod'});
aD.origImageProperties = aD.hUtils.retrieveOrigData(aD.hAllImages , {'ButtonDownFcn'});

% Find and close the old tool figure to avoid conflicts
hToolFigOld = aD.hUtils.findHiddenObj(aD.hRoot.Children, 'Tag', aD.objectNames.figTag);
if ~isempty(hToolFigOld), delete(hToolFigOld);end
pause(0.5);

% Make it easy to find this button (tack on 'On') after old fig is closed
aD.hButton.Tag   = [aD.hButton.Tag,'_On'];
aD.hMenuPZ.Tag   = [aD.hMenu.Tag, '_On'];

% Set figure close callback
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

if ismac, aD.hUtils.adjustGUIForMAC(aD.hGUI, 0.1); end

aD.hUtils.adjustGUIPositionMiddle(aD.hFig, aD.hToolFig);

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

aD.hToolFig.Visible = 'On';
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
drawAllObjects(aD);
Toggle_All_Objects([],[],aD.hFig);
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






 

    

