function hFcn = MR_utilities(varargin)
% Create cell-list of available functions. Functions stored alphabetically.
% Author: Daniel Herzka, daniel.herzka@nih.gov 
% 2017-02 -> .v0
% Cardiovascular Intervention Program
% National Heart, Lung and Blood Institute, NIH, DHHS
% Bethesda, MD 20892

fs={...
    'adjustGUIForMAC';...
    'adjustGUIPositionBottom';...
    'adjustGUIPositionMiddle';...
    'adjustGUIPositionTop';...
    'closeParentFigure';...
    'closeRequestCallback';...
    'createButtonObject';...
    'createMenuObject';...
    'deactivateButton';...
    'defaultButtonTags';...
    'disableToolbarButtons';...
    'disableGUIObjects';...
    'enableToolbarButtons';...
    'enableGUIObjects';...
    'findAxesChildIm';...
    'findHiddenObj';...
    'findHiddenObjRegexp';...
    'getAD';...
    'getADBlind';...
    'limitAD';...
    'menuToggle';...
    'restoreOrigData';...
    'retrieveNames';...
    'retrieveOrigData'; ...
    'storeAD';...
    'updateHCurrentFigAxes';...
    };

% Convert each name into a function handle reachable from outside this file
for i=1:length(fs)
    hFcn.(fs{i}) = str2func(fs{i});
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%START MULTI-TOOL SUPPORT FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Utility functions are sorted in alphabetical order since they are called
%  from within individual tools.

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function activateToolExternal(hFig, objNames)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
hFig = isAppropriateFigureHandle(hFig); 
if hFig==0
    disp('Input to activate tool must be a figure handle');
    return;
end;

hButton = findHiddenObj(hFig, 'Tag', objNames.figTag);

if ~isempty(hButton)
hButton.State = 'On'; % Triggers callbacks for button press
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function deactivateToolExternal(hFig, objNames)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
hButton = findHiddenObj(hFig, 'Tag', objNames.figTag);
if ~isempty(hButton)
    hButton.State = 'Off'; % Triggers callbacks for button press
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  flag  = isAppropriateFigureHandle(h)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
flag = 1;
if ~isgraphics(h), flag = 0; return; end
if ~strcmpi(h.Type, 'Figure'), flag = 0; end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function adjustGUIForMAC(hGUI, scaling) %#ok<*DEFNU>>
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adjust fontsize and figure size for OSX
dispDebug;

if nargin==1, scaling = 0; end

fSize = 12; % font size
scaleFact = 1 + scaling; % figure size scaling factor
objs = fieldnames(hGUI);
xDelta = 1 + scaling/2;  % relative hor shift after scaling 
yDelta = 1 + scaling/2;  % relative ver shift after scaling 
 
% Scale in size
for i = 1:length(objs)
    if strcmpi(hGUI.(objs{i}).Type, 'UIControl') && isprop(hGUI.(objs{i}), 'FontSize')
                hGUI.(objs{i}).FontSize = fSize;
    end   
    if isprop(hGUI.(objs{i}), 'Position')
       % pos = hGUI.(objs{i}).Position
        %hGUI.(objs{i}).Position = [pos(1:2), scaleFact * pos(3:4)];
    end
end

% Calculate horizontal and vertical UIControl shift
% for i = 1:length(objs)
%     if strcmpi(hGUI.(objs{i}).Type, 'Figure')
%         figPos = hGUI.(objs{i}).Position;
%         xDelta = xDelta * figPos(3) / 2
%         yDelta = yDelta * figPos(4) / 2
%         break
%     end
% end

% Apply deltas
% for i = 1:length(objs)
%     if strcmpi(hGUI.(objs{i}).Type, 'UIControl') && isprop(hGUI.(objs{i}), 'Position')
%         pos = hGUI.(objs{i}).Position 
%         hGUI.(objs{i}).Position = [ pos(1) + xDelta, pos(2)+yDelta, pos(3), pos(4)];
%     end   
% end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function adjustGUIPositionMiddle(hFig, hToolFig) 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

figPos = hFig.Position;
hToolFig.Units = hFig.Units;
guiPos = hToolFig.Position;
guiVPos = figPos(2) + figPos(4)/2 - guiPos(4)/2;
guiHPos = figPos(1) - guiPos(3)*1.1;
hToolFig.Position = [guiHPos, guiVPos, guiPos(3:4)];
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function adjustGUIPositionTop(hFig, hToolFig) 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
figPos = hFig.Position;
hToolFig.Units = hFig.Units;
guiPos = hToolFig.Position;
guiVPos = figPos(2) + figPos(4) - guiPos(4);
guiHPos = figPos(1) - guiPos(3)*1.1;
hToolFig.Position = [guiHPos, guiVPos, guiPos(3:4)];
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function adjustGUIPositionBottom(hFig, hToolFig) 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
figPos = hFig.Position;
hToolFig.Units = hFig.Units;
guiPos = hToolFig.Position;
guiVPos = figPos(2) + guiPos(4);
guiHPos = figPos(1) - guiPos(3)*1.1;
hToolFig.Position = [guiHPos, guiVPos, guiPos(3:4)];
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
delete(hFig);
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

delete(gcf)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function  [hButton, hToolbar] = createButtonObject(hFig, buttonImage, ...
    callbackOn, callbackOff, buttonTag, buttonToolTipString)
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
function deactivateButton(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

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
aD.hUtils.enableToolbarButtons(aD);

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
function tags = defaultButtonTags 
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
function origEnable = disableGUIObjects(hGUI, list)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to disable uicontrol objcects in a GUI. The exclusion list
%  allows for specific objects to be ignored.
dispDebug;
if nargin==1
    list = cell;
end

h = fieldnames(hGUI);

for i = 1:length(h)
    
    if strcmpi('uicontrol', hGUI.(h{i}).Type)
        if any(strcmpi (h{i}, list))
            dispDebug(['disable->', h{i}])  
            hGUI.(h{i}).Enable = 'Off';
        end
    end
end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function enableGUIObjects(hGUI, list)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to enable uicontrol objcects in a GUI. The exclusion list
% (optional) allows for specific objects to be ignored. Assume that the input
%  origEnables object list (optional) has the original Enable states. If
%  the origEnables does not have an equivalent object name (as a field)
%  the uicontrol is Enabled as a default.

dispDebug;
if nargin==1
    list = {};
end
    
h = fieldnames(hGUI);

for i = 1:length(h)

    if strcmpi('uicontrol', hGUI.(h{i}).Type)
        
        if strcmpi(h{i}, list)
        
            hGUI.(h{i}).Enable = 'On';
        
        end            
            
    end
    
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %% %%%%%%%%%%%%%%%%%%%%%%%%
% %
% function inStruct = removeFields(inStruct, List)
% %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%
% dispDebug;
% inStruct = rmfield(inStruct, List);

% Use this version if rmfield causes problems 
% with fields that somehow do not exist in inStruct
%
% for i=1:length(List)
%     
%     if isfield(inStruct, List{i})
%     
%         inStruct = rmfield(inStruct, List{i});
%     end
%         
% end
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
function restoreGUIObjects(hGUI, origEnable)
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
function structNames = retrieveNames
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
structNames.toolName            = '<Utils>';
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
function  storeAD(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
setappdata(aD.hFig, aD.Name, aD);
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
    if nargin>0
        for i = 1:length(varargin)
            str = varargin{i};
            fprintf(': %s | ', str);
        end
    end
    fprintf('\n');    
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%




