function cOutput = asterLoop(strTopDir,cFun,lParallel)

% Make sure top directory ends with backslash
if ~strcmp(strTopDir(end),'\')
    strTopDir = [strTopDir '\'];
end

% Get all folders contained in the top directory
cChildren = dir(strTopDir);
cChildren = cChildren([cChildren.isdir]);
cDir = {cChildren.name};
cDir(strcmp(cDir,'.')) = [];
cDir(strcmp(cDir,'..')) = [];
cDir = cellfun(@(x) [strTopDir x '\'],cDir,'Uni',0);

% Parameters for ASTER spectral bands and elevation model
sParamsA = parameters();

% Initialize
cOutput = cell(numel(cDir),numel(cFun));

% Normal or parallel processing
if lParallel
    
    % Loop through folders
    parfor i = 1:numel(cDir)
        
        % Update command window
        cFolders = strsplit(cDir{i},'\');
        disp(['processing folder ' cFolders{end-1} '...'])
        
        % Process folder
        cOutput(i,:) = processFolder(cFun,cDir,sParamsA,i);
        
    end
    
else
    
    % Loop through folders
    for i = 1:numel(cDir)
        
        % Update command window
        cFolders = strsplit(cDir{i},'\');
        disp(['processing folder ' cFolders{end-1} '...'])
        
        % Process folder
        cOutput(i,:) = processFolder(cFun,cDir,sParamsA,i);
        
    end
    
end