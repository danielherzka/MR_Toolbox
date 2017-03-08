function WL_tool(varargin)
% function WL_tool(varargin);
% Window - Level tool for adjusting contrast of a set of images
% interactively. Use with imagesc or imagescn.
%
% Usage: WL_tool;
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

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
% Lobby Function

if isempty(varargin)
    Action = 'New';
else
    Action = varargin{1};
end;

% Set or clear global debug flag
global DB; DB = 1;
dispDebug('Lobby');



% List of Actions responding to GUI 
switch Action
    case 'New', 	                       Create_New_Objects;
%     case 'Activate_WL',		           Activate_WL(varargin{:});
%     case 'Deactivate_WL',                Deactivate_WL(varargin{2:end});
%     case 'Adjust_On', 		           Adjust_On;         % Entry
%     case 'Adjust_WL', 	 	           Adjust_WL;         % Cycle
%     case 'Adjust_WL_For_All',            Adjust_WL_For_All; % Exit
%     case 'Edit_Adjust',                  Edit_Adjust;
%     case 'Set_Colormap',                 Set_Colormap;
%     case 'Menu_WL',                      Menu_WL;
%     case 'WL_Reset',                     WL_Reset;
%     case 'Auto_WL_Reset',                Auto_WL_Reset;
%     case 'Key_Press_CopyPaste',          Key_Press_CopyPaste(varargin{2:end});
%     case 'Close_Request_Callback',       Close_Request_Callback;
%     case 'Close_Parent_Figure',    	     Close_Parent_Figure;
    otherwise
        disp(['Unimplemented Functionality: ', Action]);
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Create_New_Objects
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

hUtils = MR_Toolbox_Utilities;

hFig = gcf;

objNames = retrieveNames;

%Create Button
[hButton, hToolbar] = hUtils.createButtonObject(hFig, ...
    makeButtonImage, ...
    {@Activate_WL,hFig}, ...
    {@Deactivate_WL,hFig},...
    objNames.buttonTag, ...
    objNames.buttonToolTipString);

hMenu  = hUtils.createMenuObject(hFig, ...
    objNames.menuTag, ...
    objNames.menuLabel, ...
    @Menu_WL);

if ~isempty(hButton)
    aD.Name        = 'WL';
    aD.hUtils      = hUtils;
    aD.hRoot       = groot;
    aD.hFig        = hFig;
    aD.hButton     = hButton;
    aD.hMenu       = hMenu;
    aD.hToolbar    = hToolbar;
    aD.objectNames = objNames;
    aD.cMapData = [];

    % store app data structure
    storeAD(aD);
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Activate_WL(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

%% PART I - Environment
aD = getAD(hFig);

% Check the menu object
if ~isempty(aD.hMenu), aD.hMenu.Checked = 'on'; end

% Deactivate other toolbar buttons to avoid callback conflicts
aD.hToolbar = findall(aD.hFig, 'type', 'uitoolbar');
aD.hToolbar = findobj(aD.hToolbar, 'Tag', 'FigureToolBar');

if ~isempty(aD.hToolbar)
    [aD.hToolbarChildren, aD.origToolEnables, aD.origToolStates ] = ...
        aD.hUtils.disableToolbarButtons(aD.hToolbar,  aD.objectNames.buttonTag);
end;

% Store initial state of all axes in current figure for reset
aD.hAllAxes = flipud(findobj(aD.hFig,'Type','Axes'));
aD.allClims = zeros(length(aD.hAllAxes),2);
for i = 1:length(aD.hAllAxes)
    aD.allClims(i,:) = aD.hAllAxes(i).CLim;
end;

aD.hRoot.CurrentFigure = aD.hFig;
aD.hCurrentAxes = aD.hFig.CurrentAxes;
if isempty(aD.hCurrentAxes)
    aD.hCurrentAxes = aD.hAllAxes(1);
    aD.hFig.CurrentAxes = aD.hCurrentAxes;
end;

% Store the figure's old infor within the fig's own userdata
aD.origProperties = retreiveOrigData(aD.hFig);

% Find and close the old WL figure to avoid conflicts
hToolFigOld = findHiddenObj(aD.hRoot.Children, 'Tag', aD.objectNames.figTag);
if ~isempty(hToolFigOld), close(hToolFigOld);end;
pause(0.5);

% Make it easy to find this button (tack on 'On')
% Wait until after old fig is closed.
aD.hButton.Tag = [aD.hButton.Tag,'_On'];
aD.hMenu.Tag   = [aD.hMenu.Tag, '_On'];
aD.hFig.Tag      = aD.objectNames.activeFigureName; % ActiveFigure

% Set callbacks
aD.hFig.WindowButtonDownFcn   = {@Adjust_On, aD.hFig};
aD.hFig.WindowButtonUpFcn     = {@Adjust_WL_For_All, aD.hFig};
aD.hFig.WindowButtonMotionFcn = '';
aD.hFig.WindowKeyPressFcn     = @Key_Press_CopyPaste;

% Draw faster and without flashes
aD.hFig.CloseRequestFcn       = @Close_Parent_Figure;
aD.hFig.Renderer = 'zbuffer';
aD.hRoot.CurrentFigure = aD.hFig;
[aD.hAllAxes.SortMethod] = deal('Depth');

%% PART II Create GUI Figure
aD.hToolFig = openfig(aD.objectNames.figFilename,'reuse');

% Enable save_prefs tool button
if ~isempty(aD.hToolbar)
    aD.hSP = findobj(aD.hToolbarChildren, 'Tag', 'figSavePrefsTool');
    aD.hSP.Enable = 'On';
    optionalUIControls = {'Apply_to_popupmenu', 'Value'};
    aD.hSP.UserData = {aD.hToolFig, aD.objectNames.figFilename, optionalUIControls};
end

% Generate a structure of handles to pass to callbacks and store it.
aD.hGUI = guihandles(aD.hToolFig);

aD.hToolFig.Name = aD.objectNames.figName;
aD.hToolFig.CloseRequestFcn = {@Close_Request_Callback, aD.hFig};

% Set Object callbacks; return hFig for speed
aD.hGUI.Colormap_popupmenu.Callback = {@Set_Colormap, aD.hFig};
aD.hGUI.Window_value_edit.Callback  = {@Edit_Adjust, aD.hFig};
aD.hGUI.Level_value_edit.Callback   = {@Edit_Adjust, aD.hFig};
aD.hGUI.Auto_pushbutton.Callback    = {@Auto_WL_Reset, aD.hFig};
aD.hGUI.Reset_pushbutton.Callback   = {@WL_Reset, aD.hFig};

%%  PART III - Finish setup for other objects

% Store the figure's old info
aD.origData = retreiveOrigData(aD.hFig);
aD.copy.CLim       = [];
aD.copy.CMapValue  = [];
aD.copy.CMap       = [];

% Update colormap information
if isempty(aD.cMapData)

    dispDebug;('First Call');
    % If first call,determine current figure's colormap and
    % distribute it to all axes
    cmapNames = aD.hGUI.Colormap_popupmenu.String;
    aD.cMapData.allCmapValues = findColormap(aD.hFig.Colormap,cmapNames(1:end-1));
    aD.cMapData.allCmapValues = repmat(aD.cMapData.allCmapValues, size(aD.hAllAxes));

    aD.cMapData.allColormaps = cell(size(aD.hAllAxes));
    [aD.cMapData.allColormaps{:}] = deal(aD.hFig.Colormap);

    for i=1:length(aD.hAllAxes)
        colormap(aD.hAllAxes(i), aD.hFig.Colormap);
    end

    storeAD(aD);
    updateColormapPopupmenu
    Set_Colormap([], [], aD.hFig); %(aD.hGUI.Colormap_popupmenu);

else
    dispDebug('Return Call');
    % If return call, restore old string; since first axes is active, put its
    %  colormap as the value
    storeAD(aD);
    restoreColormap;

end
aD.hGUI.Reset_pushbutton.Enable   = 'Off';
aD.hGUI.Window_value_edit.Enable  = 'Off';
aD.hGUI.Level_value_edit.Enable   = 'Off';
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Deactivate_WL(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

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

% Reactivate other buttons
aD.hUtils.enableToolbarButtons(aD.hToolbarChildren, aD.origToolEnables, aD.origToolStates )

% Store tool state for recovery on next button press in the appdata
setappdata(aD.hButton, 'cMapData',...
    {aD.cMapData.allColormaps, ...               % colormaps-per-axes
     aD.cMapData.allCmapValues, ...               % value-per-axes
     aD.hGUI.Colormap_popupmenu.String, ...      % current colormap names
     aD.hGUI.Apply_to_popupmenu.Value});         % apply to current value

% Close WL figure
delete(aD.hToolFig);

%Disable save_prefs tool button
if ishghandle(aD.hSP)
    aD.hSP.Enable = 'Off';
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Adjust_On(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Execute once at the beggining of a drag cycle
dispDebug;

aD = getAD(hFig);

aD.hFig.WindowButtonMotionFcn = {@Adjust_WL, aD.hFig};
aD.hCurrentAxes = gca;


point = aD.hCurrentAxes.CurrentPoint;
% Store reference point and the refereonce CLim
aD.refPoint = [point(1,1) point(1,2)];
aD.refCLim  = aD.hCurrentAxes.CLim;
%hButton.UserData = [point(1,1) point(1,2), Clim];
storeAD(aD);
updateColormapPopupmenu;
Adjust_WL([],[],aD.hFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Adjust_WL(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

aD.hCurrentAxes = gca;
point = aD.hCurrentAxes.CurrentPoint;

%ref_coor = hButton.UserData;

clim= aD.refCLim;
xlim= aD.hCurrentAxes.XLim;
ylim= aD.hCurrentAxes.YLim;

window = (clim(2) - clim(1) )  ;
level =  (clim(2) + clim(1) )/2;

% Use fraction  i.e. relative to position to the originally clicked point
% to determine the change in window and level
deltas = point(1,1:2) - aD.refPoint;

% To change WL sensitivity to position, change exponento to bigger/ smaller odd number
sensitivity_factor = 3;
new_level =   level  + level  * (deltas(2) / diff(ylim))^sensitivity_factor;
new_window =  window + window * (deltas(1) / diff(xlim))^sensitivity_factor;

% make sure clims stay ascending
if (new_window < 0), new_window = 0.1; end;
aD.hCurrentAxes.CLim = [new_level - new_window/2 , new_level + new_window/2];

storeAD(aD); % Need hCurrentAxes to be perm? If not, don't need store
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Adjust_WL_For_All(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Execute once after window/level is done
% Check to see if all images in slice should be rescaled
dispDebug;

aD = getAD(hFig);

aD.hFig.WindowButtonMotionFcn = ' ';

apply_all = aD.hGUI.Apply_to_popupmenu.Value;
hCurrentAxes_index = find(aD.hAllAxes==aD.hFig.CurrentAxes);
%
% new_level = new_level{1};
% new_window = new_level(2);
% new_level = new_level(1);
newClim = aD.hCurrentAxes.CLim;
newWin = (newClim(2) - newClim(1) )  ;
newLev = (newClim(2) + newClim(1) )/2;

if apply_all == 1
    % do _nothing
elseif apply_all == 2
    % All
    [aD.hAllAxes(:).CLim] = deal(newClim);
elseif apply_all == 3
    % odd
    if (mod(hCurrentAxes_index,2))
        [aD.hAllAxes(1:2:end).CLim] = deal(newClim);
    else
        [aD.hAllAxes(2:2:end).CLim] = deal(newClim);
    end;
elseif apply_all == 4
    % 1:current
    [aD.hAllAxes(1:hCurrentAxes_index).CLim] = deal(newClim);
elseif apply_all == 5
    % current:end
    [aD.hAllAxes(hCurrentAxes_index:end).CLim] = deal(newClim);
end;

aD.hGUI.Reset_pushbutton.Enable   = 'On';
aD.hGUI.Window_value_edit.Enable  = 'On';
aD.hGUI.Level_value_edit.Enable   = 'On';

storeAD(aD);

% Update editable text boxes
Update_Window_Level(newWin, newLev);

Set_Colormap([], [], aD.hFig);

figure(aD.hToolFig);
figure(aD.hFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Update_Window_Level(win, lev)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
aD = getAD;
aD.hGUI.Window_value_edit.String = num2str(win,5);
aD.hGUI.Level_value_edit.String  = num2str(lev,5) ;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Set_Colormap(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Change the colormap to the one specified by the popupmenu
% Use the same size of the original colormap as stored in
% the popupmenu's userdata = { fig , cmaps , old_values}.
% Take advantage of colormap-per-axes functionality.
dispDebug;

aD = getAD(hFig);

inCmapValue = aD.hGUI.Colormap_popupmenu.Value;
inCmapNames = aD.hGUI.Colormap_popupmenu.String;
inCmapName  = inCmapNames{inCmapValue}; % may not have an actual cmap name

%storageData     = hColormap_popupmenu.UserData;

outCmaps     = aD.cMapData.allColormaps ;
outCmapValues= aD.cMapData.allCmapValues;

sizeCmap     = size(outCmaps{1},1);

apply_all    = aD.hGUI.Apply_to_popupmenu.Value;

aD.hCurrentAxes     = aD.hFig.CurrentAxes;
hCurrentAxes_index  = find(aD.hAllAxes==aD.hCurrentAxes);

defaultCmapNames = defineColormaps; % base names

% use the previous pmenu value to put the old string back on top...
newMapFlag = 0;
switch inCmapName

    case 'More...'
        % Increase the number of colormap options to include all
        %  possibilities. Should not require changing anythign in the axes
        %  but have to make sure that the right value is displayed in the
        %  popupmenu.
        dispDebug('More');
        outCmapNames = [defaultCmapNames; 'Less...'];
        %newCmapName = inCmapName;
        %outCmapValue = find(strncmp(newCmapName, newCmapNames, 3));


        % Update value for cmaps that have changed position
        %  (1(P)->1, 2(G)->2, Other goes to a new number}
        for i = 1:length(aD.hAllAxes)
            outCmapValues(i) = findColormap(outCmaps{i}, outCmapNames);
        end

        %outCmapName = outCmapNames{outCmapValues(h_axes_index)};

        outCmapValue = outCmapValues(hCurrentAxes_index);

    case 'Less...'
        dispDebug('Less');

        % If current cmap is not parula(1) or gray(2), keep name on string.
        % Check and add all Cmaps being used in all the axes
        
        outCmapNames  = cell(length(aD.hAllAxes),1);
        for i = 1:length(aD.hAllAxes)
            outCmapNames(i) = defaultCmapNames(findColormap(outCmaps{i}, defaultCmapNames));
        end

        outCmapNames = [ unique([defaultCmapNames(1:2);outCmapNames], 'stable'); 'More...'];

        for i = 1:length(aD.hAllAxes)
            outCmapValues(i) = findColormap(outCmaps{i}, outCmapNames);
        end

        outCmapValue = outCmapValues(hCurrentAxes_index);
        % When you do this, the 'values' may need to be updated (i.e. if
        % the position of a name changes in the list, then value needs to
        % be updated;

    otherwise
 
        for i=1:length(defaultCmapNames)

            if strcmpi(inCmapName, defaultCmapNames{i})
                cmapFcn = str2func(lower(inCmapName));
                cmap= cmapFcn(sizeCmap);
                newMapFlag = 1;
            end
          
        end
        
        if ~newMapFlag
            % didn't find a matching colormap; do nothing;
            %outCmaps     = aD.cMapData.allColormaps ;
            %outCmapValues= aD.cMapData.allCmapValues;
            outCmapValue  = inCmapValue ;
            outCmapNames  = inCmapNames;
        end
end

if newMapFlag
    % Set indiviudal Axes colormaps depending on current apply settings
    if apply_all == 1,                   idxs = hCurrentAxes_index;                      % Single
    elseif apply_all == 2,               idxs = 1:length(aD.hAllAxes);                   % All
    elseif apply_all == 3
        if (mod(hCurrentAxes_index,2)) , idxs =  1:2:length(aD.hAllAxes);                % odd
        else                             idxs =  2:2:length(aD.hAllAxes);                % even
        end;
    elseif apply_all == 4,               idxs =  1:hCurrentAxes_index;                   % 1:current
    elseif apply_all == 5,               idxs =  hCurrentAxes_index:length(aD.hAllAxes); % current:end
    end;

    for i = idxs
        colormap(aD.hAllAxes(i),cmap);
        outCmaps{i} = cmap;
        outCmapValues(i) = findColormap(cmap,inCmapNames);
    end

else
    % Update Popupmenu
    aD.hGUI.Colormap_popupmenu.String  = outCmapNames;    % update popupmenu string
    aD.hGUI.Colormap_popupmenu.Value  = outCmapValue;    % update popupmenu value
end

aD.cMapData.allCmapValues = outCmapValues;
aD.cMapData.allColormaps  = outCmaps;

storeAD(aD);

figure(aD.hToolFig);
figure(aD.hFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function WL_Reset(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

apply_all = aD.hGUI.Apply_to_popupmenu.Value;
clims = aD.allClims;

hCurrentAxes = aD.hFig.CurrentAxes;
hCurrentAxes_index = find(aD.hAllAxes==hCurrentAxes);

if apply_all == 1
    hAxesInterest = hCurrentAxes;
    indexes = hCurrentAxes_index;
elseif apply_all == 2
    hAxesInterest = aD.hAllAxes;
    indexes = 1:length(aD.hAllAxes);
elseif apply_all == 3
    if (mod(hCurrentAxes_index,2))
        hAxesInterest = aD.hAllAxes(1:2:end);
        indexes = 1:2:length(aD.hAllAxes);
    else
        hAxesInterest = aD.hAllAxes(2:2:end);
        indexes = 2:2:length(aD.hAllAxes);
    end;
elseif apply_all == 4
    hAxesInterest = aD.hAllAxes(1:hCurrentAxes_index);
    indexes = 1:length(aD.hAllAxes);
elseif apply_all == 5
    hAxesInterest = aD.hAllAxes(hCurrentAxes_index:end);
    indexes = find(hAxesInterest(1)==aD.hAllAxes):length(aD.hAllAxes);
end

for i = 1:length(hAxesInterest)
    hAxesInterest(i).CLim = clims(indexes(i),:);
end;

% now update sliders
win = (clims(hCurrentAxes_index,2)-clims(hCurrentAxes_index,1));
lev =  (clims(hCurrentAxes_index,2)+clims(hCurrentAxes_index,1))/2;
aD.hGUI.Reset_pushbutton.Enable   = 'Off';
Update_Window_Level(win, lev);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Auto_WL_Reset(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

apply_all = aD.hGUI.Apply_to_popupmenu.Value;
clims = aD.allClims;
hCurrentAxes_index = find(aD.hCurrentAxes==aD.hAllAxes);

if apply_all == 1,                  hAxesInterest = aD.hCurrentAxes;
elseif apply_all == 2,              hAxesInterest = aD.hAllAxes;
elseif apply_all == 3,
    if (mod(hCurrentAxes_index,2)), hAxesInterest = aD.hAllAxes(1:2:end);
    else                            hAxesInterest = aD.hAllAxes(2:2:end);
    end;
elseif apply_all == 4,              hAxesInterest = aD.hAllAxes(1:hCurrentAxes_index);
elseif apply_all == 5,              hAxesInterest = aD.hAllAxes(hCurrentAxes_index:end);
end

for i = 1:length(hAxesInterest)
    xlim = hAxesInterest(i).XLim;
    ylim = hAxesInterest(i).YLim;
    x1 = ceil(xlim(1)); x2 = floor(xlim(2));
    y1 = ceil(ylim(1)); y2 = floor(ylim(2));
    hImage = findobj(hAxesInterest(i),'type','image');
    c = hImage.CData;
    cmin = min(min(c(y1:y2,x1:x2)));
    cmax = max(max(c(y1:y2,x1:x2)));
    hAxesInterest(i).CLim = [cmin cmax];
end;

% Update sliders
win= (clims(hCurrentAxes_index,2)-clims(hCurrentAxes_index,1));
lev =  (clims(hCurrentAxes_index,2)+clims(hCurrentAxes_index,1))/2;
aD.hGUI.Reset_pushbutton.Enable   = 'On';
Update_Window_Level(win, lev);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Edit_Adjust(~,~,hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD(hFig);

apply_all      = aD.hGUI.Apply_to_popupmenu.Value;
hCurrentAxes_index = find(aD.hAllAxes==aD.hCurrentAxes);

win = str2double(aD.hGUI.Window_value_edit.String);
lev = str2double(aD.hGUI.Level_value_edit.String);

if isnumeric(win) && isnumeric(lev)
    % update the current graph or all the graphs...

    if apply_all == 1,                  hAxesInterest = aD.hCurrentAxes;
    elseif apply_all == 2,              hAxesInterest = aD.hAllAxes;
    elseif apply_all == 3
        if (mod(hCurrentAxes_index,2)), hAxesInterest = aD.hAllAxes(1:2:end);
        else                            hAxesInterest = aD.hAllAxes(2:2:end);
        end;
    elseif apply_all == 4,              hAxesInterest = aD.hAllAxes(1:hCurrentAxes_index);
    elseif apply_all == 5,              hAxesInterest = aD.hAllAxes(hCurrentAxes_index:end);
    end

    for i = 1:length(hAxesInterest)
        hAxesInterest(i).CLim = [lev-win/2, lev+win/2];
    end;

end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Key_Press_CopyPaste(~, data)
dispDebug;

aD = getAD;

switch data.Key
    case 'c' %copy
        aD.copy.CLim = aD.hCurrentAxes.CLim;
        hCurrentAxes_idx = find(aD.hCurrentAxes==aD.hAllAxes);
        aD.copy.CMapValue = aD.cMapData.allCmapValues(hCurrentAxes_idx);
        aD.copy.CMap      = aD.cMapData.allColormaps{hCurrentAxes_idx};
        storeAD(aD);
    case {'p','v'} %paste
        apply_all = aD.hGUI.Apply_to_popupmenu.Value;

        if     apply_all == 1,                hAxesInterest = aD.hCurrentAxes;
        elseif apply_all == 2,                hAxesInterest = aD.hAllAxes;
        elseif apply_all == 3,
            if (mod(hCurrentAxes_index,2)),   hAxesInterest = aD.hAllAxes(1:2:end);
            else                              hAxesInterest = aD.hAllAxes(2:2:end);
            end;
        elseif apply_all == 4,                hAxesInterest = aD.hAllAxes(1:hCurrentAxes_index);
        elseif apply_all == 5,                hAxesInterest = aD.hAllAxes(hCurrentAxes_index:end);
        end

        aD.copy

        if ~isempty(aD.copy.CLim)
            % XXX what happens if there is a change in CMap_PUP String and
            % Value is not longer suitable/correct?
            for i = 1:length(hAxesInterest)
                hAxesInterest(i).CLim = aD.copy.CLim;
                aD.cMapData.allColormaps{hAxesInterest(i)==aD.hAllAxes} = aD.copy.CMap;
                aD.cMapData.allCMapValues(hAxesInterest(i)==aD.hAllAxes) = aD.copy.CMapValue;
                colormap(hAxesInterest(i), aD.copy.CMap);
                aD.hGUI.Colormap_popupmenu.Value = aD.copy.CMapValue;
            end;
        end
        Set_Colormap([], [], aD.hFig)
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Menu_WL(~,~)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;

aD = getAD;

checked = aD.hMenu.Checked;

% Changing button state engages button callback
if strcmpi(checked,'on')
    % turn off button ->Deactivate_WL
    dispDebug(' Deactivate');
    aD.hMenu.Checked = 'off';
    aD.hButton.State = 'off';
else
    % turn on button -> Activate_WL
    dispDebug(' Activate');
    aD.hMenu.Checked = 'on';
    aD.hButton.State = 'on';
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Close_Request_Callback(~,~,hFig)
%
dispDebug;

aD = getAD(hFig);

old_SHH = aD.hRoot.ShowHiddenHandles;
aD.hRoot.ShowHiddenHandles = 'On';

%call->WL_tool('Deactivate_WL');
aD.hButton.State = 'off';

aD.hRoot.ShowHiddenHandles= old_SHH;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Close_Parent_Figure(hFig,~)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to make sure that if parent figure is closed,
% the ROI info and ROI Tool are closed too.
dispDebug;

aD = getAD;
if ~isempty(aD)
    hToolFig = aD.hToolFig;
else
    % Parent Figure is already closed and aD is gone (shouldn't happen!)
    dispDebug('ParFig closed!');
    objNames = retrieveNames;
    hToolFig = findobj(groot, 'Tag', objNames.figTag);
end
delete(hToolFig);
hFig.CloseRequestFcn = 'closereq';
close(hFig);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%START LOCAL SUPPORT FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function Cmap_Value = findColormap(Current_Cmap, CmapListCellString)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the current figure's colormap by comparing it with
% the established colormaps of the same size
dispDebug;

Cmap_Value = 1; % default

for i=1:length(CmapListCellString)
    cmapFcn = str2func(lower(CmapListCellString{i}));
    testCmap= cmapFcn(size(Current_Cmap,1));
    
    if isempty(find(testCmap - Current_Cmap, 1))
        Cmap_Value = i;
        return;
    end;
end
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
buttonImage = repmat(linspace(0,1,buttonSize_x), [ 15 1 3]);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function updateColormapPopupmenu
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Change the colormap to the one specified by the popupmenu
dispDebug;

aD = getAD;

if isempty(aD.hFig.CurrentAxes)
    aD.hFig.CurrentAxes = aD.hAllAxes(1);
end
hCurrentAxes_index = (aD.hAllAxes==aD.hFig.CurrentAxes);

currCmapNames   = aD.hGUI.Colormap_popupmenu.String;
currCmapValue   = findColormap(aD.cMapData.allColormaps{hCurrentAxes_index}, currCmapNames);

aD.hGUI.Colormap_popupmenu.Value = currCmapValue;

storeAD(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function restoreColormap
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Restore state during second call to WL_tool after i.e. closing and
% reopening. Only difference could be the CurrentAxes is different
dispDebug;

aD = getAD;

storageData = getappdata(aD.hButton, 'cMapData');

outCmaps     = storageData{1};
outCmapValues= storageData{2};
outCmapNames = storageData{3};
applyToValue = storageData{4};

aD.hCurrentAxes = aD.hFig.CurrentAxes;
hCurrentAxes_index = aD.hAllAxes==aD.hCurrentAxes;

aD.hGUI.Apply_to_popupmenu.Value = applyToValue;

aD.hGUI.Colormap_popupmenu.String = outCmapNames;
aD.hGUI.Colormap_popupmenu.Value  = outCmapValues(hCurrentAxes_index);
aD.cMapData.allCmapValues = outCmapValues;
aD.cMapData.allColormaps  = outCmaps;

storeAD(aD);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function cmap_cell = defineColormaps
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
cmap_cell = {...
    'Parula';'Gray'  ;'Jet'    ;...
    'Hsv'   ;'Hot'   ;'Bone'   ;...
    'Copper';'Pink'  ;'White'  ;...
    'Flag'  ;'Lines' ;'Colorcube';...
    'Prism' ;'Cool'  ;'Autumn' ;...
    'Spring';'Winter';'Summer' ;...
    'ecg_cmap'; 't1_cmap'; 'perfusion_cmap';...
    };  %add new colormaps at the end of the list;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function structNames = retrieveNames
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
structNames.toolName            = 'WL_tool';
structNames.buttonTag           = 'figButtonWL';
structNames.buttonToolTipString = 'Set Image Window Level';
structNames.menuTag             = 'menuWindowLevel';
structNames.menuLabel           = 'Window and Level';
structNames.figFilename         = 'WL_tool_figure.fig';
structNames.figName             = 'WL Tool';
structNames.figTag              = 'WL_figure';
structNames.activeFigureName    = 'ActiveFigure';
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
function  storeAD(aD)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
dispDebug;
setappdata(aD.hFig, aD.Name, aD);
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

aDName=dbstack;
aDName=aDName(end).file(1:2);

if nargin==0
    % Search the children of groot
    hFig = findobj(groot, 'Tag', 'ActiveFigure', '-depth', 1); 
    if isempty(hFig)
        % hFig hasn't been found (likely first call) during Activate
        obj = findobj('-regexp', 'Tag', ['\w*Button', aDName,'\w*']);
        hFig = obj(1).Parent.Parent;
    end
end

if isappdata(hFig, aDName)
    aD = getappdata(hFig, aDName);
else
    aD = [];
end

dispDebug(['end (',num2str(toc),')']); %dbg
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
function propList = retreiveOrigData(hFig)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Retrive previous settings for storage
dispDebug;

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

for i = 1:size(propList,1)
    propList{i,2} = hFig.(propList{i,1});
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
