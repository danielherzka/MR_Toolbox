function RT_tool(varargin)
% function RT_tool(varargin);
% Function for image rotation and reflection (flip). Use with imagescn.
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
%
% Updated: Daniel Herzka, 2017-02 -> .v0
% Cardiovascular Intervention Program
% National Heart, Lung and Blood Institute, NIH, DHHS
% Bethesda, MD 20892
dispDebug('Entry');
Create_New_Objects;

% Object callbacks; return hFig for speed
%  aD.hButton.OnCallback                   -> {@Activate_RT, hFig}
%  aD.hButton.OffCallback                  -> {@Deactivate_RT, hFig}
%  aD.hMenu.Callback                       -> {@Menu_RT, hFig}
%  aD.hFig.WindowButtonDownFcn              = {@Set_Current_Axes, aD.hFig};  
%  aD.hFig.CloseRequestFcn                 -> {aD.hUtils.closeParentFigure, figTag};
%  aD.hGUI.Rotate_CW_pushbutton.Callback    = {@Rotate_Images, aD.hFig, 0};
%  aD.hGUI.Rotate_CCW_pushbutton.Callback   = {@Rotate_Images, aD.hFig, 1};
%  aD.hGUI.Flip_Hor_pushbutton.Callback     = {@Flip_Images, aD.hFig, 0};
%  aD.hGUI.Flip_Ver_pushbutton.Callback     = {@Flip_Images, aD.hFig, 1};

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

%% %%%%%%%%%%%%%%%%%%%%%%%% 
%
function Deactivate_RT(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
aD = getAD(hFig);
aD.hUtils.deactivateButton(aD);
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
    if isappdata(hCurrentAxes(i), 'CurrentImage')
        currentImage = getappdata(hCurrentAxes(i), 'CurrentImage');
        imageData = getappdata(hCurrentAxes(i), 'ImageData');
        dim4Exists = 1;
    else
        currentImage = 1;
        imageData =  aD.hAllImages(hCurrentAxes(i)==aD.hAllAxes).CData;
        dim4Exists = 0;
    end;
    
    % Image is square and axes are one pixel wider than the image (half
    % pixel on each side)
    halfImSize  = (size(imageData,1)+1)/2;
    
	inXLims = hCurrentAxes(i).XLim ;
	inYLims = hCurrentAxes(i).YLim  ;

    % im_size = ( size(image_data,1) + 1)/2;
	%xlims = get(CurrentAxes(i), 'Xlim') - im_size;
	%ylims = get(CurrentAxes(i), 'Ylim') - im_size;
    %temp = xlims;

    % Change the xlims and ylims depending on the call
     if direction  % Rotate CW
        disp('CCW')
        for j =1:size(imageData,3)
            imageData(:,:,j) = flipud(permute(imageData(:,:,j), [ 2 1]));
        end
		outXLims =          inYLims;
		outYLims =  sort(-1*inXLims  + 2*halfImSize) ;
        %		xlims =        ylims  + im_size;
		%       ylims =  sort(-1*temp + im_size);	
    else % Rotate CCW
        disp('CW')
        for j =1:size(imageData,3)
            imageData(:,:,j) = fliplr(permute(imageData(:,:,j), [ 2 1]));
        end
        outXLims =  sort(-1*inYLims  + 2*halfImSize);
        outYLims =          inXLims;
        
        % 		xlims = sort(-1*ylims + im_size);
		%       ylims =         temp  + im_size;
    end
        
    aD.hAllImages(hCurrentAxes(i)==aD.hAllAxes).CData = squeeze(imageData(:,:,currentImage));

    hCurrentAxes(i).YLim = outYLims;
    hCurrentAxes(i).XLim = outXLims;

    if dim4Exists
        setappdata(hCurrentAxes(i), 'ImageData', imageData);
    end;

    
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
aD.hAllImages   = aD.hUtils.findAxesChildIm(aD.hAllAxes);
aD.hFig.CurrentAxes = aD.hAllAxes(1);

% Set current figure and axis
aD = aD.hUtils.updateHCurrentFigAxes(aD);

% Store the figure's old info within the fig's own userdata
aD.origProperties = aD.hUtils.retrieveOrigData(aD.hFig);
aD.origAxesProperties  = aD.hUtils.retrieveOrigData(aD.hAllAxes , {'ButtonDownFcn', 'XLimMode', 'YLimMode'});
aD.origImageProperties = aD.hUtils.retrieveOrigData(aD.hAllImages , {'ButtonDownFcn'});

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

if ismac, aD.hUtils.adjustGUIForMAC(aD.hGUI, 0.5); end

aD.hUtils.adjustGUIPosition(aD.hFig, aD.hToolFig);

aD.hToolFig.Name = aD.objectNames.figName;
aD.hToolFig.CloseRequestFcn = {aD.hUtils.closeRequestCallback, aD.hUtils.limitAD(aD)};

% Set Object callbacks; return hFig for speed
aD.hGUI.Rotate_CW_pushbutton.Callback  = {@Rotate_Images, aD.hFig, 0};
aD.hGUI.Rotate_CCW_pushbutton.Callback = {@Rotate_Images, aD.hFig, 1};
aD.hGUI.Flip_Hor_pushbutton.Callback   = {@Flip_Images, aD.hFig, 0};
aD.hGUI.Flip_Ver_pushbutton.Callback   = {@Flip_Images, aD.hFig, 1};

aD.hToolFig.Visible = 'On';
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
if(size(aD.hAllImages(1).CData,1) ~= size(aD.hAllImages(1).CData,2))
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
structNames.Name                = 'RT';
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
