function PM_tool(varargin)
% function PM_tool(varargin);
% Function for point measurements on a set of images.  
% Use with imagesc or imagescn.
%
% Usage: PM_tool;
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
%  aD.hFig.WindowButtonDownFcn              =  @Measure_Start;  
%  aD.hFig.CloseRequestFcn                 -> {aD.hUtils.closeParentFigure, figTag};
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    {@Activate_PM,hFig}, ...
    {@Deactivate_PM,hFig},...
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
function Activate_PM(~,~,hFig)
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
function Deactivate_PM(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
aD = getAD(hFig);
aD.hUtils.deactivateButton(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Measure_Start(hFig,~)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
setCurrentAxes([], [], hFig);
hFig.WindowButtonMotionFcn = {@Measure, hFig};
hFig.WindowButtonDownFcn   = {@Measure_End, hFig};
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Measure(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
aD = getAD(hFig);

measureAll = aD.hGUI.Measure_checkbox.Value;

currentAxes_XLim = aD.hCurrentAxes.XLim;
currentAxes_YLim = aD.hCurrentAxes.YLim;
currentPoint =  floor(aD.hCurrentAxes.CurrentPoint);

hAxesOfInterest = aD.hCurrentAxes;
if measureAll 
	hAxesOfInterest = aD.hAllAxes;
end;

% make sure that the current point is within the bounds of the current axis
if      currentPoint(1,1) >= currentAxes_XLim(1)  && ...
        currentPoint(1,1) <= currentAxes_XLim(2)  && ...
        currentPoint(1,2) >= currentAxes_YLim(1)  && ...
        currentPoint(1,2) <= currentAxes_YLim(2) % OR faster?
    s = [];
    for i = 1:length(hAxesOfInterest)
        imagedata = aD.hAllImages(aD.hAllAxes==hAxesOfInterest(i)).CData;
        s = char(s,  makeStringForTable(...
            num2str(find(hAxesOfInterest(i)==aD.hAllAxes)), ...`
            num2str(currentPoint(1,1), '%0.5g'), ...
            num2str(currentPoint(1,2), '%0.5g'), ...
            num2str( double(imagedata(floor(currentPoint(1,2)), floor(currentPoint(1,1)))), '%0.5g')));
        
    end
    
    aD.hGUI.Value_listbox.String =  s;
%    figure(aD.hToolFig);
%    figure(aD.hFig);    
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Measure_End(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
get(gca,'Userdata');
hFig.WindowButtonMotionFcn = '';
hFig.WindowButtonDownFcn =  @Measure_Start;
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
aD.hFig.WindowButtonDownFcn   =  @Measure_Start;
aD.hFig.CloseRequestFcn       = {aD.hUtils.closeParentFigure, aD.objectNames.figTag};

% Draw faster and without flashes
aD.hFig.Renderer = 'zbuffer';
aD.hFig.Pointer = 'crosshair'; %'cross'
[aD.hAllAxes.SortMethod] = deal('Depth');

storeAD(aD);

setCurrentAxes([],[], aD.hFig, aD.hCurrentAxes);
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
    optionalUIControls = {'Measure_checkbox', 'Value'};
    aD.hSP.UserData = {aD.hToolFig, aD.objectNames.figFilename, optionalUIControls};
end

% Generate a structure of handles to pass to callbacks and store it.
aD.hGUI = guihandles(aD.hToolFig);

if ismac, aD.hUtils.adjustGUIForMAC(aD.hGUI, 0.2); end

aD.hUtils.adjustGUIPosition(aD.hFig, aD.hToolFig);

aD.hToolFig.Name = aD.objectNames.figName;
aD.hToolFig.CloseRequestFcn = {aD.hUtils.closeRequestCallback, aD.hUtils.limitAD(aD)};
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = configOther(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  PART III - Finish setup for other objects
dispDebug;
% Nothing here
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
function buttonImage = makeButtonImage
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The default button size is 15 x 16 x 3.
dispDebug;

buttonSize_x= 16;
buttonImage = NaN* zeros(15,buttonSize_x);


f= [...
    8    23    38    53    68    81    82    83    84    85    96   100   106   107 , ...
    108   109   110   111   115   116   117   118   119   120   126   130   141   142 , ...
    143   144   145   158   173   188   203   218   233 ...
    ];

   
buttonImage(f) = 0;
buttonImage = repmat(buttonImage, [1,1,3]);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function outstr = makeStringForTable(str1, str2, str3, str4)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

min_size_1  = 4;
min_size_2  = 5;
min_size_3  = 5;
min_size_4  = 8;

outstr = [ ...
		blanks( min_size_1 - length(str1)), str1 ,...
		blanks( min_size_2 - length(str2)), str2 ,...
		blanks( min_size_3 - length(str3)), str3 ,...
		blanks( min_size_4 - length(str4)), str4 ,...
        ];
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function setCurrentAxes(~,~,hFig, hCurrentAxes)
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
function  storeAD(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
setappdata(aD.hFig, 'AD', aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function structNames = retrieveNames
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
structNames.Name                = 'PM';
structNames.toolName            = 'PM_tool';
structNames.buttonTag           = 'figButtonPM';
structNames.buttonToolTipString = 'Point Measurement Tool';
structNames.menuTag             = 'menuPM';
structNames.menuLabel           = 'Point Measurement';
structNames.figFilename         = 'PM_tool_figure.fig';
structNames.figName             = 'PM Tool';
structNames.figTag              = 'PM_figure';
structNames.activeFigureName    = 'ActiveFigure';
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%



