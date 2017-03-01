function utilFcn = MR_Toolbox_Utilities

%  Creata cell-list of available functions
fs={'defaultButtonTags'};

% Convert each name into a function handle available from structure M
for i=1:length(fs),
	utilFcn.(fs{i}) = str2func(fs{i});
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%START MULTI-TOOL SUPPORT FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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