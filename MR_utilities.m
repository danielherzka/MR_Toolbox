function hFcn = MR_utilities(varargin)
% Create cell-list of available functions
fs={...
    'defaultButtonTags';...
    'retrieveNames';...
    'enableToolbarButtons';...
    'disableToolbarButtons';...
    'retrieveOrigData'; ...
    'restoreOrigData';...
    'updateHCurrentFigAxes';...
    'findHiddenObj';...
    'findHiddenObjRegexp';...
    'findAxesChildIm';...
    'createButtonObject';...
    'createMenuObject';...
    'menuToggle';...
    'closeRequestCallback';...
    'closeParentFigure';...
    'storeAD';...
    'limitAD';...
    'getAD';...
    'getADBlind';...
    };

% Convert each name into a function handle reachable from outside this file
for i=1:length(fs),
    hFcn.(fs{i}) = str2func(fs{i});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%START MULTI-TOOL SUPPORT FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function tags = defaultButtonTags %#ok<*DEFNU>>
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

tags = { ...
    'figWindowLevel',...
    'figPanZoom',...
    'figROITool',...
    'figViewImages',...
    'figPointTool',...
    'figRotateTool',...
    'figProfileTool'};
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function structNames = retrieveNames
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
structNames.toolName            = '<Utils>';
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = disableToolbarButtons(aD, currentToolName) 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deactivate other toolbar buttons to avoid callback conflicts
dispDebug;

aD.hToolbar = findall(aD.hFig, 'type', 'uitoolbar');
aD.hToolbar = findobj(aD.hToolbar, 'Tag', 'FigureToolBar');

if ~isempty(aD.hToolbar)
    old_SHH = aD.hRoot.ShowHiddenHandles;
    aD.hRoot.ShowHiddenHandles = 'on';
    
    aD.hToolbarChildren = aD.hToolbar.Children;
    
    aD.origToolEnables = cell(size(aD.hToolbarChildren));
    aD.origToolStates  = cell(size(aD.hToolbarChildren));
    
    for i = 1:length(aD.hToolbarChildren)
        if ~strcmpi(aD.hToolbarChildren(i).Tag, currentToolName)
            if isprop(aD.hToolbarChildren(i), 'Enable')
                aD.origToolEnables{i} =  aD.hToolbarChildren(i).Enable;
                aD.hToolbar_Children(i).Enable ='off';
            end
            if isprop(aD.hToolbarChildren(i), 'State')
                aD.origToolStates{i}  =  aD.hToolbarChildren(i).State;
                aD.hToolbarChildren(i).Enable ='off';
            end
        end
    end
    
    aD.hRoot.ShowHiddenHandles = old_SHH;
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function enableToolbarButtons(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

for i = 1:length(aD.hToolbarChildren)
    if isprop(aD.hToolbarChildren(i), 'Enable') && ~isempty(aD.origToolEnables{i})
        aD.hToolbarChildren(i).Enable = aD.origToolEnables{i};
    end
    if isprop(aD.hToolbarChildren(i), 'State') && ~isempty(aD.origToolStates{i})
        aD.hToolbarChildren(i).State = aD.origToolStates{i};
    end
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function propList = retrieveOrigData(hObjs,propList)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Retrive previous settings for storage
dispDebug;

if nargin==1
    % basic list - typically modified figure properties
    propList = {...
        'WindowButtonDownFcn'; ...
        'WindowButtonMotionFcn'; ...
        'WindowButtonUpFcn'; ...
        'WindowKeyPressFcn'; ...
        'UserData'; ...
        'CloseRequestFcn'; ...
        'Pointer'; ...
        'PointerShapeCData'; ...
        'Tag' ...
        };
end

propList = repmat(propList, [1 1 length(hObjs)]);

for j = 1:length(hObjs) % objects
    for i = 1:size(propList,1) % properties
        if isprop(hObjs(j), propList{i,1,j})
            propList{i,2,j} = hObjs(j).(propList{i,1,j});
        end
    end
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function restoreOrigData(hFig, propList)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Restore previous WBDF etc to restore state after WL is done.
dispDebug;
for j = 1:length(hFig)
    for i = 1:size(propList,1)
        hFig(j).(propList{i,1,j}) = propList{i,2,j};
    end
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function aD = updateHCurrentFigAxes(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
aD.hRoot.CurrentFigure = aD.hFig;
aD.hCurrentAxes=aD.hFig.CurrentAxes;
if isempty(aD.hCurrentAxes)
    aD.hCurrentAxes = aD.hAllAxes(1); 
    aD.hFig.CurrentAxes = aD.hCurrentAxes;
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function hIm = findAxesChildIm(hAllAxes)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

hIm = gobjects(size(hAllAxes));
for i = 1:length(hAllAxes)
    hIm(i) = findobj(hAllAxes(i), 'Type', 'Image');
end    
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  [hButton, hToolbar] = createButtonObject(...
    hFig, ...
    buttonImage, ...
    callbackOn, ...
    callbackOff,...
    buttonTag, ...
    buttonToolTipString)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
hToolbar = findall(hFig, 'type', 'uitoolbar', 'Tag','FigureToolBar' );

% If the toolbar exists and the button has not been previously created
if ~isempty(hToolbar) && isempty(findHiddenObj(hToolbar, 'Tag', buttonTag))
    
    hToolbar_Children = hToolbar.Children;
    buttonTags = defaultButtonTags();
    hButtons = cell(1,size(buttonTags,2));
    
    for i = 1:length(buttonTags)
        hButtons{i} = findobj(hToolbar_Children, 'Tag', buttonTags{i});
    end;
    
    separator = 'off';
    if isempty(hButtons)
        separator = 'on';
    end;
    
    hButton = uitoggletool(hToolbar);
    hButton.CData         = buttonImage;
    hButton.OnCallback    = callbackOn;
    hButton.OffCallback   = callbackOff;
    hButton.Tag           = buttonTag;
    hButton.TooltipString = buttonToolTipString;
    hButton.Separator     = separator;
    hButton.UserData      = hFig;
    hButton.Enable         = 'on';
else
    % Toolbar doesn't exist, or button already exists
    hButton = [];
end


%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  hMenu = createMenuObject(hFig, menuTag, menuLabel,callback)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
hToolMenu = findall(hFig, 'Label', '&Tools');

if ~isempty(hToolMenu) && isempty(findHiddenObj(hToolMenu,'Tag', menuTag))

    % If the menubar exists and the menu item has not been previously created
    hExistingMenus = findobj(hToolMenu, '-regexp', 'Tag', 'menu\w*');
    
    position = 9;
    separator = 'On';
    
    if ~isempty(hExistingMenus)
        position = position + length(hExistingMenus);
        separator = 'Off';
    end;
    
    hMenu = uimenu(hToolMenu,'Position', position);
    hMenu.Tag       = menuTag;
    hMenu.Label     = menuLabel;
    hMenu.Callback  = callback;
    hMenu.Separator = separator;
    hMenu.UserData  = hFig;
else
    hMenu = [];
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function menuToggle(hMenu, hButton)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

checked   = hMenu.Checked;
if strcmpi(checked,'on')
    % turn off button -> Deactivate
    hMenu.Checked = 'off';
    hButton.State = 'off';
else %hButton
    hMenu.Checked = 'on';
    hButton.State = 'on';
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function closeRequestCallback(~,~,uaD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
old_SHH = uaD.hRoot.ShowHiddenHandles;
uaD.hRoot.ShowHiddenHandles = 'On';

%calls deactivate
uaD.hButton.State = 'off';
uaD.hRoot.ShowHiddenHandles= old_SHH;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  storeAD(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
setappdata(aD.hFig, aD.Name, aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  uaD = limitAD(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Return micro aD
dispDebug;
uaD = struct;
uaD.hRoot    = aD.hRoot;
uaD.hFig     = aD.hFig;
uaD.hToolFig = aD.hToolFig;
uaD.hButton  = aD.hButton;
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
tic %dbg

if nargin==0
    % Search the children of groot
    hFig = findobj(groot, 'Tag', 'ActiveFigure', '-depth', 1); 
    if isempty(hFig)
        % hFig hasn't been found (likely first call) during Activate
        obj = findobj('-regexp', 'Tag', ['\w*Button', aDName,'\w*']);
        hFig = obj(1).Parent.Parent;
    end
end

% assume ewe require the Active AD, not the tool-specific ones
if isappdata(hFig, 'AD')
    aD = getappdata(hFig, 'AD');
else
    dispDebug('no aD!'); %dbg
    aD = [];
end

dispDebug(['end (',num2str(toc),')']); %dbg
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  aD = getADBlind
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Retrieve application data stored within Active Figure (aka image figure)
%  Appdata name depends on tool. Blind = do not know ActiveFigure handle
dispDebug;

tic %dbg

if nargin==0
    % Search the children of groot
    hFig = findHiddenObj(groot, 'Tag', 'ActiveFigure'); 
    if isempty(hFig)
        % hFig hasn't been found (may be first call) during Activate
        %  find button
        obj = findHiddenObjRegexp('Tag', ['\w*Button', objNames.Name,'\w*']);
        hFig = obj(1).Parent.Parent;
    end
end

if ishghandle(hFig) && isappdata(hFig, 'AD')
    aD = getappdata(hFig, 'AD');
else
    dispDebug('!No aD found!'); %dbg
    aD = [];
end

dispDebug(['end (',num2str(toc),')']); %dbg
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function closeParentFigure(hFig,~,figTag)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to make sure that if parent figure is closed,
% the ROI info and ROI Tool are closed too.
dispDebug;
aD = getAD(hFig);
if ~isempty(aD)
    hToolFig = aD.hToolFig;
else
    % Parent Figure is somehow already gone and there aD is no aD (shouldn't happen!)
    % Find tool figure directly via Tag
    dispDebug('ParFig closed!');
    hToolFig = findobj(groot, 'Tag', figTag);
end
delete(hToolFig);
%hFig.CloseRequestFcn = 'closereq';
delete(hFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%START LOCAL SUPPORT FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  dispDebug(varargin)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print a debug string if global debug flag is set
global DB;

if DB
    loc = [];
    objectNames = retrieveNames;
    x = dbstack;
    funcName = x(2).name;   
    if length(x)<3 %pad
        x = cat(1, x, repmat(x(end),3-length(x),1));
    end
    callFuncName = x(3).file(1:end-2);
    if strcmpi( x(3).file, x(2).file)
        loc = ['(loc)', repmat('|> ',1, sum(strcmp(x(1).file, {x.file})-1))] ;
    end
    fprintf([callFuncName,' ',objectNames.toolName, ':', loc , ' %s'], funcName);
    fprintf('\n');    
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function h = findHiddenObj(Handle, Property, Value)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

h_root = groot;
old_SHH = h_root.ShowHiddenHandles;
h_root.ShowHiddenHandles = 'On';
if nargin <3
    h = findobj(Handle, Property);
else
    h = findobj(Handle, Property, Value);
end;
h_root.ShowHiddenHandles = old_SHH;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function h = findHiddenObjRegexp(Handle, Property, Value)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

h_root = groot;
old_SHH = h_root.ShowHiddenHandles;
h_root.ShowHiddenHandles = 'On';
if nargin <3
    h = findobj('-regexp', Handle, Property);
else
    h = findobj(Handle, '-regexp', Property, Value);
end;
h_root.ShowHiddenHandles = old_SHH;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%


