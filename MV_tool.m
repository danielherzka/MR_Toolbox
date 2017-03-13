function MV_tool(varargin)
% CHANGED 20170312 PM
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

dispDebug('Loggy');

% Set or clear global debug flag
global DB; DB = 1;
dispDebug('Lobby');
Create_New_Objects;

% % Set Object callbacks; return hFig for speed
% aD.hGUI.Reset_pushbutton.Callback        = {@Reset_Frame_Limit, aD.hFig};
% aD.hGUI.Min_Frame_edit.Callback          = {@Set_Frame_Limit, aD.hFig};
% aD.hGUI.Frame_Value_edit.Callback        = {@Set_Frame, aD.hFig};
% aD.hGUI.Max_Frame_edit.Callback          = {@Set_Frame_Limit, aD.hFig};
% aD.hGUI.Rewind_pushbutton.Callback       = {@Limit, aD.hFig, -1};
% aD.hGUI.Step_Rewind_pushbutton.Callback  = {@Step, aD.hFig, -1};
% aD.hGUI.Step_Forward_pushbutton.Callback = {@Step, aD.hFig, 1};
% aD.hGUI.Forward_pushbutton.Callback      = {@Limit, aD.hFig 1};
% aD.hGUI.Stop_pushbutton.Callback         = @Stop_Movie;
% aD.hGUI.Play_pushbutton.Callback         = {@Play_Movie, aD.hFig};
% aD.hGUI.Make_Movie_pushbutton.Callback   = {@Make_Movie, aD.hFig};
% aD.hGUI.Show_Frames_checkbox.Callback    = {@Show_Frame_Numbers, aD.hFig};
% aD.hGUI.Show_Objects_checkbox.Callback   = {@Show_Objects, aD.hFig};
% aD.hGUI.Object_List_popupmenu.Callback   = {@Toggle_Object, aD.hFig};
        
      
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
    @Menu_MV);

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

storeAD(aD);
Set_Current_Axes(aD.hFig, aD.hCurrentAxes);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Deactivate_MV(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

global GLOBAL_STOP_MOVIE
GLOBAL_STOP_MOVIE = 2;

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

hFig = varargin{3};
aD = getAD(hFig);
aD.hCurrentAxes = aD.hFig.CurrentAxes;

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

    if (aD.hCurrentAxes == hAxesOfInterest(i))
        % if doing the single current axes, update the
        aD.hGUI.Frame_Value_edit.String =  num2str(currentFrame);
        Set_Current_Axes(aD.hFig, hAxesOfInterest(i));
    end;

    if ~isempty(aD.hObjects)
        % Objects Exist- update the xdata/ydata for each object
        objectData   = getappdata(hAxesOfInterest(i), 'Objects');
        Update_Object(objectData, aD.hObjects{aD.hAllAxes == hAxesOfInterest(i),1},currentFrame);
    end;
    
end;

storeAD(aD);

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
           
    if ~isempty(aD.hObjects)
        object_data   = getappdata(hAxesOfInterest(i), 'Objects');
        Update_Object(object_data, aD.hObjects{aD.hAllAxes == hAxesOfInterest(i),1},currentFrame);
    end;
    
    
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

    % Objects Exist- update the xdata/ydata for each object
    if ~isempty(aD.hObjects)
        object_data   = getappdata(CurrentAxes(i), 'Objects');
        Update_Object(object_data, aD.hObjects{ hAxesOfInterest(i) == aD.hCurrentAxes,1},currentFrame);
    end;

end;
figure(aD.hFigMV);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Set_Frame_Limit(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

hAxesOfInterest = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);

ImageRangeAll = getappdata(hAxesOfInterest(aD.hAllAxes==aD.hCurrentAxes), 'ImageRangeAll');
minFrame  = str2double(aD.hGUI.Min_Frame_edit.String);
maxFrame  = str2double(aD.hGUI.Max_Frame_edit.String);
currFrame = str2double(aD.hGUI.Frame_Value_edit.String);

if minFrame < ImageRangeAll(1), minFrame = ImageRangeAll(1); end;
if minFrame > currFrame       , minFrame = currFrame; end;

if maxFrame > ImageRangeAll(2), maxFrame = ImageRangeAll(2); end;
if maxFrame < currFrame       , maxFrame = currFrame; end;


for i = 1:length(hAxesOfInterest)
	setappdata(hAxesOfInterest(i), 'ImageRange', [minFrame maxFrame]);
	aD.hGUI.Min_Frame_edit.String = minFrame;
	aD.hGUI.Max_Frame_edit.String = maxFrame;
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

applyAll = aD.hGUI.Apply_radiobutton.Value;
frameRate = str2double(aD.hGUI.Frame_Rate_edit.String);

origEnable = disableGUI(aD.hGUI);
aD.hGUI.Stop_pushbutton.Enable ='On';
		
% specify single or all axes
hAxesOfInterest = aD.hCurrentAxes;
if applyAll
	hAxesOfInterest = aD.hAllAxes;
end;

% Collect data needed for display (images, ranges, objects)
currentFrame = cell(size(hAxesOfInterest));
imageRange = cell(size(hAxesOfInterest));
imageData = cell(size(hAxesOfInterest));
objectData = cell(size(hAxesOfInterest));
for i = 1:length(hAxesOfInterest)
	currentFrame{i} = getappdata(hAxesOfInterest(i), 'CurrentImage');
	imageRange{i}   = getappdata(hAxesOfInterest(i), 'ImageRange');
	imageData{i}    = getappdata(hAxesOfInterest(i), 'ImageData');
    if ~isempty(aD.hObjects);
        objectData{i} = getappdata(hAxesOfInterest(i), 'Objects');
    end;    
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
%       %set(findobj(hAxesOfInterest(i), 'Type', 'image'), 'CData', imageData{i}(:,:,currentFrame{i}));
% 		set(handlesMV.hFrameNumbers(find(handlesMV.Axes == hAxesOfInterest(i))), 'String', num2str(currentFrame{i}));
        
        if ~isempty(aD.hObjects)
            % Objects Exist- update the xdata/ydata for each object for each axis
            for j = 1:size(aD.hObjects{i},1)
                Update_Object(objectData{i}, aD.hObjects{ hAxesOfInterest(i)==aD.hAllAxes }, currentFrame{i});
            end;                            
        end;
        
	end;
	drawnow;
	pause(t);
    estFrameRate = 1/toc;
	if estFrameRate > frameRate, t = t+0.01; end;	
end;

% Exit - update values for each of the axes in movie to correspond to last
% frame played

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
function Make_Movie
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

% fig2 = findobj('Tag', 'MV_figure');
% handlesMV = guidata(fig2);
% CurrentAxes = handlesMV.CurrentAxes;
% handle_for_movie = CurrentAxes;
% apply_all = get(handlesMV.Apply_radiobutton, 'Value');
% make_avi  = get(handlesMV.Make_Avi_checkbox, 'Value');
% make_mat  = get(handlesMV.Make_Mat_checkbox, 'Value');
% frame_rate = str2num(get(handlesMV.Frame_Rate_edit, 'String'));
% minFrame   = str2num(get(handlesMV.Min_Frame_edit, 'String'));
% maxFrame   = str2num(get(handlesMV.Max_Frame_edit, 'String'));
% 
% if make_avi || make_mat
%     if str2num(version('-release')) > 12.1        
%         [filename, pathname] = uiputfile( {'*.m;*.avi', 'Movie Files (*.m, *.avi)'}, ...
%             'Save Movie As', 'M');
%     else
%         [filename, pathname] = uiputfile( {'*.m;*.avi', 'Movie Files (*.m, *.avi)'}, ...
%             'Save Movie As');
%     end;
% 
% 	if isequal(filename,0) | isequal(pathname,0)
% 		% User hit cancel instead of ok
% 		return;
% 	end;
% 
%     filename = [pathname, filename];
% 	
% 	
% 	% Turn objects off while movie is made
% 	set([handlesMV.Reset_pushbutton, handlesMV.Min_Frame_edit, handlesMV.Max_Frame_edit, ...
% 		handlesMV.Frame_Value_edit, handlesMV.Rewind_pushbutton, handlesMV.Step_Rewind_pushbutton, ....
% 		handlesMV.Step_Forward_pushbutton, handlesMV.Forward_pushbutton, handlesMV.Play_pushbutton, ...
% 		handlesMV.Frame_Rate_edit, handlesMV.Make_Movie_pushbutton, handlesMV.Stop_pushbutton, ...
% 		handlesMV.Make_Avi_checkbox, handlesMV.Make_Mat_checkbox, handlesMV.Show_Frames_checkbox, ...
%         handlesMV.Show_Objects_checkbox, handlesMV.Object_List_popupmenu],...
% 	'Enable', 'Off');	
% else
% 	% do nothing!
% 	return;
% end;
% 	
% % if apply_all, make movie of the whole figure moving together.
% if apply_all 
% 	CurrentAxes = handlesMV.Axes;
% 	handle_for_movie = handlesMV.ParentFigure;
% end;
% 
% % collect info for each of the frames to be used.
% for i = 1:length(CurrentAxes)
% 	image_range{i}   = getappdata(CurrentAxes(i), 'ImageRange');
% 	image_data{i}    = getappdata(CurrentAxes(i), 'ImageData');
% 	current_frame{i} = image_range{i}(1);
% 	object_data{i}   = getappdata(CurrentAxes(i), 'Objects');
%     
% 	if CurrentAxes(i)==handlesMV.CurrentAxes
% 		endFrame = image_range{i}(2); 
% 		iRef   = i;
% 	end;
% end;
% 
% % play each frame; note that number of frames specified by the
% % editable text boxes (ie the current axes frame limits) are used 
% % to make movie - even if other windows have different number of 
% % frames though each axes will start at their own beginning frame
% stop_movie = 0;
% counter = 1;
% direction = 0;
% while ~stop_movie
% 	for i = 1:length(CurrentAxes)
% 		if     (current_frame{i} + direction) > image_range{i}(2), current_frame{i} = image_range{i}(1); 
% 		elseif (current_frame{i} + direction) < image_range{i}(1), current_frame{i} = image_range{i}(2); 
% 		else                                                       current_frame{i} = current_frame{i} + direction; end;	
% 		set(findobj(CurrentAxes(i), 'Type', 'image'), 'CData', image_data{i}(:,:,current_frame{i}));
% 		set(handlesMV.hFrameNumbers(find(handlesMV.Axes == CurrentAxes(i))), 'String', num2str(current_frame{i}));
%         
%         %%%CHUS%%%
%         if ~isempty(handlesMV.ObjectHandles)
%             for j = 1:size(handlesMV.ObjectHandles{i},1)
%                 Update_Object(object_data{i}, handlesMV.ObjectHandles{find(handlesMV.Axes==CurrentAxes(i))},current_frame{i});
%             end;
%         end;
%         %%%CHUS%%%
%         
% 	end;
% 	drawnow;
% 	M(counter) = getframe(handle_for_movie);
% 	counter = counter + 1;
% 	direction = 1;
% 	% now determine if the movie is over: have played the last frame 
% 	% of the reference axes (current)
% 	if current_frame{iRef} == endFrame
% 		stop_movie = 1;
% 	end	
% end;
% 
% if make_mat 
% 	f = [filename, '.mat'];
% 	save(f, 'M');
% end;
% 
% compression = 'CinePak';
% if isunix
% 	compression = 'None';
% end;
% 
% Q = 75;
% %%%CHUS%%%
% %if isempty(handlesMV.ObjectHandles), Q = 100; compression = 'None'; end;
% %%%CHUS%%%
% 
% compression
% 
% if make_avi
%     f = filename;
%     if isempty(strfind(f, '.avi')), f = [filename, '.avi']; end;
% 	try
% %		movie2avi(M, f, 'FPS', frame_rate, 'Compression', compression, 'Quality', Q);
% 	catch
% 		disp('Error within movie2avi function call');
% 		disp('  Movie was not created.');
% 	end;
% end;	
% 
% % Turn objects back on
% set([handlesMV.Reset_pushbutton, handlesMV.Min_Frame_edit, handlesMV.Max_Frame_edit, ...
% 		handlesMV.Frame_Value_edit, handlesMV.Rewind_pushbutton, handlesMV.Step_Rewind_pushbutton, ....
% 		handlesMV.Step_Forward_pushbutton, handlesMV.Forward_pushbutton, handlesMV.Play_pushbutton, ...
% 		handlesMV.Frame_Rate_edit, handlesMV.Make_Movie_pushbutton, handlesMV.Stop_pushbutton, ...
% 		handlesMV.Make_Avi_checkbox, handlesMV.Make_Mat_checkbox, handlesMV.Show_Frames_checkbox],...
% 	'Enable', 'On');
% 
% 
% %%%CHUS%%%
% if ~isempty(handlesMV.ObjectHandles)
%     set([handlesMV.Show_Objects_checkbox, handlesMV.Object_List_popupmenu], 'Enable', 'On');
% end; %%%CHUS%%%
dispDebug;
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
function Set_Current_Axes(varargin)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

if length(varargin)==2     % internal call
    hFig = varargin{1};
    currentAxes = varargin{2};
elseif length(varargin)==3 % allback on axes btdwnfcn
    currentAxes = varargin{1};
    hFig = varargin{3};
end

aD = getAD(hFig);
if isempty(currentAxes), currentAxes=gca; end;
aD.hCurrentAxes = currentAxes;

image_range = getappdata(aD.hCurrentAxes, 'ImageRange');
aD.handlesMV.Min_Frame_edit.String =  num2str(image_range(1));
aD.handlesMV.Max_Frame_edit.String =  num2str(image_range(2));

 if ~isempty(aD.hObjects)
     hCurrentAxes_idx = aD.hAllAxes==aD.hCurrentAxes;
     aD.handlesMV.Object_List_popupmenu.String = ...
         aD.hObjects{hCurrentAxes_idx,3};
 end;

storeAD(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Menu_MV(~,~)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
aD = getAD(hFig);
aD.hUtils.menuToggle(aD.hMenu,aD.hButton);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  Show_Objects(varargin)
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
            [h_obj(h_obj~=0).Visible] = deal('On');
        else
            [h_obj(h_obj~=0).Visible] = deal('Off');
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
function  Update_Object(ObjStruct, hObjects, frame)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to update the relevant properties for each type of object
dispDebug;

for j = 1:size(hObjects,1)
    switch ObjStruct(j).Type
        case 'Line'
            set(hObjects(j), ...
                'xdata', ObjStruct(j,frame).xdata(:), ...
                'ydata', ObjStruct(j,frame).ydata(:),...
                'Color', ObjStruct(j,frame).color);

        case 'Points'
            set(hObjects(j), ...
                'xdata', ObjStruct(j,frame).xdata(:), ...
                'ydata', ObjStruct(j,frame).ydata(:),...
                'Color', ObjStruct(j,frame).color);

        case 'Patch'
            set(hObjects(j), ...
                'xdata', ObjStruct(j,frame).xdata, ...
                'ydata', ObjStruct(j,frame).ydata,...
                'Facecolor', ObjStruct(j,frame).color, ...
                'FaceAlpha', ObjStruct(j,frame).facealpha ...
            );
    end
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  Toggle_Object(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to toggle display of an object(s)
dispDebug;
aD =getAD(hFig);

toggleVal    = aD.hGUI.Object_List_popupmenu.Value;
toggleString = aD.hGUI.Object_List_popupmenu.String(toggleVal,:);
popupmenuString = aD.hGUI.Object_List_popupmenu.String;

% Specify single or all axes
hAxesOfInterest = getApplyToAxes(aD,aD.hGUI.Apply_radiobutton);

%Hide = strmatch('Hide', toggleString);
Hide = strncmp('Hide', toggleString, length('Hide'))

if ~Hide , newString = 'Hide'; oldString = 'Show'; visibility = 'on';
else      newString = 'Show'; oldString = 'Hide'; visibility = 'off';
end;

for i = 1:length(hAxesOfInterest)
    
    hCurrObjects = aD.hObjects{ aD.hAllAxes == hAxesOfInterest(i), 1};
    
    popupmenuString(toggleVal,:) = strrep(toggleString,oldString,newString);
    
    for j = 1:size(hCurrObjects,1)        
        if strncmp(deblank(get(hCurrObjects(j),'Userdata')), deblank(toggleString(6:end)), length(deblank(toggleString(6:end))))
            set(hCurrObjects(j), 'Visible', visibility);
            aD.hGUI.Object_List_popupmenu.String =  popupmenuString;
        end;
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
aD.hCurrentAxes = aD.hAllAxes(1);
aD.hAllImages   = aD.hUtils.findAxesChildIm(aD.hAllAxes);

% Set current figure and axis
aD = aD.hUtils.updateHCurrentFigAxes(aD);

% Store the figure's old infor within the fig's own userdata
aD.origProperties      = aD.hUtils.retrieveOrigData(aD.hFig);
aD.origAxesProperties  = aD.hUtils.retrieveOrigData(aD.hAllAxes , {'ButtonDownFcn'});
aD.origImageProperties = aD.hUtils.retrieveOrigData(aD.hAllImages , {'ButtonDownFcn'});

% Find and close the old WL figure to avoid conflicts
hToolFigOld = aD.hUtils.findHiddenObj(aD.hRoot.Children, 'Tag', aD.objectNames.figTag);
if ~isempty(hToolFigOld), delete(hToolFigOld);end;
pause(0.5);

% Make it easy to find this button (tack on 'On') after old fig is closed
aD.hButton.Tag   = [aD.hButton.Tag,'_On'];
aD.hMenuPZ.Tag   = [aD.hMenu.Tag, '_On'];

% Set figure clsoe callback
aD.hFig.CloseRequestFcn = {aD.hUtils.closeParentFigure, aD.objectNames.figTag};

% Draw faster and without flashes
aD.hFig.Renderer = 'zbuffer';
[aD.hAllAxes.SortMethod] = deal('Depth');
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
        'Make_Mat_checkbox',     'Value'; ...
        'Show_Frames_checkbox',  'Value'; ...
        'Show_Objects_checkbox', 'Value';...
        };
    aD.hSP.UserData = {aD.hToolFig, aD.objectNames.figFilename, optionalUIControls};
end

% Generate a structure of handles to pass to callbacks, and store it. 
aD.hGUI = guihandles(aD.hToolFig);

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
aD.hGUI.Show_Objects_checkbox.Callback   = {@Show_Objects,       aD.hFig};
aD.hGUI.Object_List_popupmenu.Callback   = {@Toggle_Object,      aD.hFig};
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = configOther(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  PART III - Finish setup for other objects
[aD.hAllAxes(:).ButtonDownFcn] = deal({@Set_Current_Axes, aD.hFig});
aD.hRoot.CurrentFigure = aD.hFig;

% Add frame number to each axes
aD.hFrameNumbers = createFrameNumbers(aD.hFig, aD.hAllAxes, aD.hAllImages);
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
Show_Objects(aD.hFig);
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
function  storeAD(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
setappdata(aD.hFig, 'AD', aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = getAD(hFig)
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
function  hAxes = getApplyToAxes(aD,Apply_radiobutton)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
hAxes = aD.hCurrentAxes;
applyAll = Apply_radiobutton.Value;
if applyAll
    hAxes = aD.hAllAxes;
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
function hFrameNumbers = createFrameNumbers(hFig, hAllAxes, hIms)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calc text size
textFontSize = 20;
figUnits = hFig.Units;
hFig.Units = 'inches';
figSize = hFig.Position;
reffigSize = 8;   % 8 inch figure gets 20 pt font
textFontSize = textFontSize * figSize(3) / reffigSize;
hFig.Units = figUnits;

% Create text object per axes
hFrameNumbers = gobjects(size(hAllAxes));
for i = 1:length(hAllAxes)
	X = hAllAxes(i).XLim;
	Y = hAllAxes(i).YLim;
    str = num2str(getappdata(hAllAxes(i), 'CurrentImage')); 
 	hFrameNumbers(i) = text(hAllAxes(i), X(2)*0.98, Y(2), str);
end;
[hIms(:).ButtonDownFcn] = deal({@Step, hFig});
[hFrameNumbers(:).FontSize] = deal(textFontSize);
[hFrameNumbers(:).Color] = deal([ 1 0.95 0]);
[hFrameNumbers(:).VerticalAlignment] = deal('bottom');
[hFrameNumbers(:).HorizontalAlignment] = deal('right');
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
        [hObjects{i,1}, hObjects{i,2}] = drawObjectsPerAxes(objectData , aD.hAllAxes(i)) ;
        
        % load the current axes objets onto popupmenu
        %if(aD.hAllAxes(i)==aD.hCurrentAxes)
        popupstring = [repmat('Hide ', size(hObjects{i,2},1),1), hObjects{i,2}];
        aD.hGUI.Object_List_popupmenu.String = popupstring;
        hObjects{i,3} = popupstring;
        %else
        %    hObjects{i,3} = [];
        %end;
        drewObjectsFlag = 1;
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
function [hObject, objectNames] = drawObjectsPerAxes(objDataStruct, hAxes)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to cycle through drawing objects; 
%  Each object (data loaded into appdata 'Objects' for each axes, is
%  composed of structure that contains field type (line,point,patch), 
%  xdata ydata and color 
dispDebug;

CurrImage = getappdata(hAxes,'CurrentImage'); 
orignextplot = get(hAxes, 'NextPlot');
%origCurrentAxes = aD.hFig.CurrentAxes;

set(hAxes, 'NextPlot', 'add');

objectNames = [];

hObject = gobjects(size(objDataStruct,1),1);

% Draw each object in the list of objects for this axes
for i = 1:size(objDataStruct,1) 
    objType = objDataStruct(i,CurrImage).Type;
    
    if ~isempty(objType)
        if strcmpi(objType, 'Line')
            hObject(i,1) = plot(hAxes, ...
                objDataStruct(i,CurrImage).XData(:), ...
                objDataStruct(i,CurrImage).YData(:),...
                'color', objDataStruct(i,CurrImage).Color );
            linestyle = '-';
            marker = 'none';
            
        elseif strcmpi(objType, 'Points')
            hObject(i,1) = plot(hAxes, ...
                objDataStruct(i,CurrImage).XData(:), ....
                objDataStruct(i,CurrImage).YData(:),...
                'color', objDataStruct(i,CurrImage).Color );
            linestyle = 'none';
            marker = objDataStruct(i,CurrImage).Marker;
            
        elseif strcmpi(objType.type, 'Patch')
            hObject(i,1) = patch(hAxes, ...
                objDataStruct(i,CurrImage).xdata(:), ...
                objDataStruct(i,CurrImage).ydata(:),...
                objDataStruct(i,CurrImage).color);
            linestyle = 'none';
            marker = 'none';
        else
            disp('Unknown object type!');
        end;
        
        if isempty(objectNames)
            objectNames = objDataStruct(i,CurrImage).Name;
        else
            objectNames = char(objectNames, objDataStruct(i,CurrImage).Name);
        end
            
        % These apply to all objects (lines/points/patches)
        set(hObject(i,1),...
            'Marker',    marker,...
            'linestyle', linestyle,...
            'Userdata',  objDataStruct(i,CurrImage).Name);
    end

end

hAxes.NextPlot =  orignextplot;
%aD.hFig.CurrentAxes = origCurrentAxes;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%