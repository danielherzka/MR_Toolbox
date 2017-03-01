function utilFcn = MR_Toolbox_Utilities

%  Creata cell-list of available functions
fs={'defaultButtonTags' 'dispDebug'};

% Convert each name into a function handle available from structure M
for i=1:length(fs),
	utilFcn.(fs{i}) = str2func(fs{i});
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%START MULTI-TOOL SUPPORT FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%
%
function tags = defaultButtonTags %#ok<DEFNU>
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
utilDispDebug;

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

function  utilDispDebug(varargin)
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
%     if nargin>0
%         for i = 1:length(varargin)
%             str = varargin{i};
%             fprintf(': %s', str);
%         end
%     end
    fprintf('\n');
    
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
