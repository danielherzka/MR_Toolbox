function RT_tool(varargin)
% function RT_tool(varargin);
% Function for rotations and flips of images
%
% Usage: RT_tool;
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

global DB; DB = 1;
dispDebug('Lobby');
Create_New_Objects;

% 
% if isempty(varargin) 
%    Action = 'New';
% else
%    Action = varargin{1};  
% end
% 
% %(['RT Tool: Current Action: ', Action]);
% 
% switch Action
% case 'New'
%     Create_New_Button;
% 
% case 'Activate_Rotate_Tool'
%     Activate_Rotate_Tool;
%     
% case 'Deactivate_Rotate_Tool's
%     Deactivate_Rotate_Tool(varargin{2:end});
%         
% case 'Set_Current_Axes'
% 	Set_Current_Axes(varargin{2:end});
% 	
% case 'Rotate_CW'
% 	Rotate_Images(0);
% 
% case 'Rotate_CCW'
% 	Rotate_Images(1);
% 	
% case 'Flip_Horizontal'
% 	Flip_Images(0);
% 
% case 'Flip_Vertical' 
% 	Flip_Images(1);
% 
% case 'Menu_Rotate_Tool'
%     Menu_Rotate_Tool;
%     
% case 'Close_Parent_Figure'
%     Close_Parent_Figure;
%     
% otherwise
%     disp(['Unimplemented Functionality: ', Action]);
%    
% end;
     

% aD.hGUI.Rotate_CW_pushbutton.Callback  = {@Rotate_Images, aD.hFig, 0};
% aD.hGUI.Rotate_CCW_pushbutton.Callback = {@Rotate_Images, aD.hFig, 1};
% aD.hGUI.Flip_Hor_pushbutton.Callback   = {@Flip_Images, aD.hFig, 0};
% aD.hGUI.Flip_Ver_pushbutton.Callback   = {@Flip_Images, aD.hFig, 1};

%% %%%%%%%%%%%%%%%%%%%%%%%% 
%
function Create_New_Objects
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

hUtils = MR_utilities;

hFig = gcf;

objNames = retrieveNames;


[hButton, hToolbar] = hUtils.createButtonObject(hFig, ...
    makeButtonImage, ...
    {@Activate_RT,hFig}, ...
    {@Deactivate_RT,hFig},...
    objNames.buttonTag, ...
    objNames.buttonToolTipString);


hMenu  = hUtils.createMenuObject(hFig, ...
    objNames.menuTag, ...
    objNames.menuLabel, ...
    @Menu_RT);

aD.Name        = objNames.Name;
aD.hUtils      = hUtils;
aD.hRoot       = groot;
aD.hFig        = hFig;
aD.hButton     = hButton;
aD.hMenu       = hMenu;
aD.hToolbar    = hToolbar;
aD.objectNames = objNames;
aD.cMapData = [];

% store app data structure in tool-specific field
setappdata(aD.hFig, aD.Name, aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%% 
%
function Activate_RT(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = configActiveFigure(hFig);
aD = configGUI(aD);
aD = configOther(aD);

storeAD(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 
% % Deactivate zoom and rotate buttons
% % will work even if there are no toolbars found
% % Deactivate zoom and rotate buttons
% hToolbar = findall(fig, 'type', 'uitoolbar');
% hToolbar = findobj(hToolbar, 'Tag', 'FigureToolBar');
% 
% if ~isempty(hToolbar)
% 	hToolbar_Children = get(hToolbar, 'Children');
% 	
% 	% disable MATLAB's own tools
% 	Rot3D = findobj(hToolbar_Children,'Tag', 'figToolRotate3D');
% 	ZoomO = findobj(hToolbar_Children,'Tag', 'figToolZoomOut');
% 	ZoomI = findobj(hToolbar_Children,'Tag', 'figToolZoomIn');
% 
% 	% try to disable other tools buttons - if they exist
% 	WL = findobj(hToolbar_Children, 'Tag', 'figWindowLevel');
% 	PZ = findobj(hToolbar_Children, 'Tag', 'figPanZoom');
% 	RT = findobj(hToolbar_Children, 'Tag', 'figROITool');
% 	MV = findobj(hToolbar_Children, 'Tag', 'figViewImages');
% 	PM = findobj(hToolbar_Children,'Tag', 'figPointTool');
% 	RotT = findobj(hToolbar_Children, 'Tag', 'figRotateTool');
% 	Prof = findobj(hToolbar_Children, 'Tag', 'figProfileTool');
% 	
% 	old_ToolHandles  =     cat(1,Rot3D, ZoomO, ZoomI,WL,PZ,RT,MV,PM,Prof);
% 	old_ToolEnables  = get(cat(1,Rot3D, ZoomO, ZoomI,WL,PZ,RT,MV,PM,Prof), 'Enable');
% 	old_ToolStates   = get(cat(1,Rot3D, ZoomO, ZoomI,WL,PZ,RT,MV,PM,Prof), 'State');
% 	
% 	for i = 1:length(old_ToolHandles)
% 		if strcmp(old_ToolStates(i) , 'on')			
% 			set(old_ToolHandles(i), 'State', 'Off');
% 		end;
% 		set(old_ToolHandles(i), 'Enable', 'Off');
% 	end;
%         %LFG
%         %enable save_prefs tool button
%         SP = findobj(hToolbar_Children, 'Tag', 'figSavePrefsTool');
%         set(SP,'Enable','On');
% end;
% 
% 
% 
% 
% % check for square images:
% % if not square, then turn of image rotation (for now)
% Im = get(findobj(handlesRT.CurrentAxes, 'Type', 'Image'), 'CData');
% if(size(Im,1) ~= size(Im,2)), 
% 	set([handlesRT.Rotate_CCW_pushbutton, handlesRT.Rotate_CW_pushbutton], 'Enable', 'off');
% end;
% 
% guidata(fig2,handlesRT);
% Set_Current_Axes(h_axes);
% 
% %h_axes = h_all_axes(end);
% set(fig, 'CurrentAxes', h_axes);
% set(fig, 'WindowButtonDownFcn',  ['RT_tool(''Set_Current_Axes'')']);


%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%% 
%
function Deactivate_RT(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%disp('RT_tool:Deactivate_Point_Tool');

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

% Reactivate other buttons
aD.hUtils.enableToolbarButtons(aD)

% Close Tool figure
delete(aD.hToolFig);

% Store aD in tool-specific apdata for next Activate call
setappdata(aD.hFig, aD.Name, aD);
rmappdata(aD.hFig, 'AD');

if ~isempty(aD.hSP) %?ishghandle?
    aD.SP.Enable = 'Off';
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%% 
%
function Flip_Images(~,~, hFig, direction)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

hCurrentAxes = getApplyToAxes(aD,aD.hGUI.Apply_checkbox);

for i = 1:length(hCurrentAxes)
    % Flip CData of the current image
    % if a 4-D array, flip all the other data stored in appdata  
    if isappdata(hCurrentAxes(i), 'CurrentImage'), extraDimData = 1;
    else                                           extraDimData = 0;
    end
    
    if extraDimData
        currentImage = getappdata(hCurrentAxes(i), 'CurrentImage');
        imageData = getappdata(hCurrentAxes(i), 'ImageData');
    else
        currentImage = 1;
        imageData =  aD.hAllImages(hCurrentAxes(i)==aD.hAllAxes).CData;
    end;
    
    % Change the xlims and ylims depending on the call
    imSize  = [size(imageData,1), size(imageData,2)];
    xlims = hCurrentAxes(i).XLim;
    ylims = hCurrentAxes(i).YLim;
    
	if direction  
		dispDebug('Flip Vertical')
		for j =1:size(imageData,3)
			imageData(:,:,j) = flipud(imageData(:,:,j));
		end
		ylims = [ (imSize(1) ) - (ylims(2)-0.5) , imSize(1)  - (ylims(1)-0.5)] + 0.5;
	else 
		dispDebug('Flip Horizontal')	
		for j =1:size(imageData,3)
			imageData(:,:,j) = fliplr(imageData(:,:,j));
		end
		xlims = [ (imSize(2) ) - (xlims(2)-0.5), (imSize(2) ) - (xlims(1)-0.5)] + 0.5;		
	end;
    
    if extraDimData
        setappdata(hCurrentAxes(i), 'ImageData', imageData);
    end;
    
	hCurrentAxes(i).XLim =  xlims;
    hCurrentAxes(i).YLim =  ylims;
    aD.hAllImages(hCurrentAxes(i)==aD.hAllAxes).CData = squeeze(imageData(:,:,currentImage));

end;

figure(aD.hToolFig);
figure(aD.hFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%		
		
%% %%%%%%%%%%%%%%%%%%%%%%%% 
%
function Rotate_Images(~,~, hFig, direction)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

hCurrentAxes = getApplyToAxes(aD,aD.hGUI.Apply_checkbox);

for i = 1:length(hCurrentAxes)
    % Rotate CData of the current image,
    % If a 4-D array, rotate all the other data stored in appdata
    if isappdata(hCurrentAxes(i), 'CurrentImage');
        currentImage = getappdata(hCurrentAxes(i), 'CurrentImage');
        imageData = getappdata(hCurrentAxes(i), 'ImageData');
        dim4 = 1;
    else
        currentImage = 1;
        imageData =  aD.hAllImages(hCurrentAxes(i)==aD.hAllAxes).CData;
        dim4 = 0;
    end;
    
    % Change the xlims and ylims depending on the call
    imSize  = size(imageData,1); % image is square
	xlims = hCurrentAxes(i).XLim  - imSize;
	ylims = hCurrentAxes(i).YLim  - imSize;
	temp = xlims;

    %newXLims =  sort(-1*hCurrentAxes(i).YLim) + imSize;
    %newYLims =  sort(-1*hCurrentAxes(i).XLim) + imSize;
    
    if direction  % Rotate CCW
        for j =1:size(imageData,3)
            imageData(:,:,j) = flipud(permute(imageData(:,:,j), [ 2 1]));
        end
		xlims =        ylims  + imSize;
		ylims =  sort(-1*temp + imSize);		
    else % Rotate CW
        for j =1:size(imageData,3)
            imageData(:,:,j) = fliplr(permute(imageData(:,:,j), [ 2 1]));
        end
		xlims = sort(-1*ylims + imSize);
		ylims =         temp  + imSize;
    end;
    
    if dim4,
        setappdata(hCurrentAxes(i), 'ImageData', imageData);
    end;
    
    hCurrentAxes(i).XLim = xlims;
    hCurrentAxes(i).YLim = ylims;
    aD.hAllImages(hCurrentAxes(i)==aD.hAllAxes).CData = squeeze(imageData(:,:,currentImage));
    
end;

figure(aD.hToolFig);
figure(aD.hFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%% 
%
function Set_Current_Axes(~,~,hFig, hCurrentAxes)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
if (nargin == 3), hCurrentAxes = gca; end;
if isempty(hCurrentAxes), hCurrentAxes=gca; end;

aD = getAD(hFig);
aD.hCurrentAxes = hCurrentAxes;
storeAD(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%% 
%
function Menu_RT
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
aD = getAD(hFig);
aD.hUtils.menuToggle(aD.hMenu,aD.hButton);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%START LOCAL SUPPORT FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = configActiveFigure(hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PART I - Environment
dispDebug;
objNames = retrieveNames;
aD = getappdata(hFig, objNames.Name); 
aD.hFig.Tag  = aD.objectNames.activeFigureName; % ActiveFigure

% Check the menu object
if ~isempty(aD.hMenu), aD.hMenu.Checked = 'on'; end

% Find toolbar and deactivate other buttons
aD = aD.hUtils.disableToolbarButtons(aD,  aD.objectNames.buttonTag);

% Store initial state of all axes in current figure for reset
aD.hAllAxes = flipud(findobj(aD.hFig,'Type','Axes'));
aD.hFig.CurrentAxes = aD.hAllAxes(1);
aD.hAllImages   = aD.hUtils.findAxesChildIm(aD.hAllAxes);

% Set current figure and axis
aD = aD.hUtils.updateHCurrentFigAxes(aD);

% Store the figure's old infor within the fig's own userdata
aD.origProperties = aD.hUtils.retrieveOrigData(aD.hFig);
aD.origAxesProperties  = aD.hUtils.retrieveOrigData(aD.hAllAxes , {'ButtonDownFcn'});


% Find and close the old WL figure to avoid conflicts
hToolFigOld = aD.hUtils.findHiddenObj(aD.hRoot.Children, 'Tag', aD.objectNames.figTag);
if ~isempty(hToolFigOld), close(hToolFigOld);end;
pause(0.5);

% Make it easy to find this button (tack on 'On')
% Wait until after old fig is closed.
aD.hButton.Tag = [aD.hButton.Tag,'_On'];
aD.hMenu.Tag   = [aD.hMenu.Tag, '_On'];

% Set callbacks
aD.hFig.WindowButtonDownFcn   = {@Set_Current_Axes, aD.hFig};
aD.hFig.CloseRequestFcn       = {aD.hUtils.closeParentFigure, aD.objectNames.figTag};

% Draw faster and without flashes
aD.hFig.Renderer = 'zbuffer';
[aD.hAllAxes.SortMethod] = deal('Depth');
[aD.hAllAxes.ButtonDownFcn] = deal(''); 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = configGUI(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PART II Create GUI Figure
dispDebug;
aD.hToolFig = openfig(aD.objectNames.figFilename,'reuse');

% Enable save_prefs tool button
if ~isempty(aD.hToolbar)
    aD.hSP = findobj(aD.hToolbarChildren, 'Tag', 'figButtonSP');
    aD.hSP.Enable = 'On';
    optionalUIControls = {'Apply_checkbox', 'Value'};
    aD.hSP.UserData = {aD.hToolFig, aD.objectNames.figFilename, optionalUIControls};
end

% Generate a structure of handles to pass to callbacks and store it.
aD.hGUI = guihandles(aD.hToolFig);

if ismac, aD.hUtils.adjustGUIForMAC(aD.hGUI, 0.0); end

aD.hToolFig.Name = aD.objectNames.figName;
aD.hToolFig.CloseRequestFcn = {aD.hUtils.closeRequestCallback, aD.hUtils.limitAD(aD)};

% Set Object callbacks; return hFig for speed
aD.hGUI.Rotate_CW_pushbutton.Callback  = {@Rotate_Images, aD.hFig, 0};
aD.hGUI.Rotate_CCW_pushbutton.Callback = {@Rotate_Images, aD.hFig, 1};
aD.hGUI.Flip_Hor_pushbutton.Callback   = {@Flip_Images, aD.hFig, 0};
aD.hGUI.Flip_Ver_pushbutton.Callback   = {@Flip_Images, aD.hFig, 1};
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = configOther(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  PART III - Finish setup for other objects
dispDebug;
% Allow rotations only if images are square
if(size(aD.hAllImages(1).CData,1) ~= size(aD.hAllImages(1).CData,2)), 
	aD.hGUI.CCW_pushbutton.Enable = 'Off';
    aD.hGUI.CW_pushbutton.Enable= 'Off';
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function structNames = retrieveNames
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
structNames.Name              = 'RT';
structNames.toolName            = 'RT_tool';
structNames.buttonTag           = 'figButtonRT';
structNames.buttonToolTipString = 'Image Rotation Tool';
structNames.menuTag             = 'menuRT';
structNames.menuLabel           = 'Rotate and Flip';
structNames.figFilename         = 'RT_tool_figure.fig';
structNames.figName             = 'RT Tool';
structNames.figTag              = 'RT_figure';
structNames.activeFigureName    = 'ActiveFigure';
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

f = [...
    24    38    39    52    53    54    65    68    69    71    79    84    87   108   118   123   133,...
    138   148   169   172   177   185   187   188   191   202   203   204   217   218   232 ...
    ];
   
buttonImage(f) = 0;
buttonImage = repmat(buttonImage, [1,1,3]);
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
function hAxes = getApplyToAxes(aD, Apply_checkbox)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
applyAll = Apply_checkbox.Value;
if applyAll
    hAxes = aD.hAllAxes;
else
    hAxes = aD.hCurrentAxes;
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    if length(x) > 4
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
