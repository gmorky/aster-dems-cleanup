function [cOutput] = processFolder(cFun,cDir,sParams,iFolderIdx)
    
% Initialize
iFunCount = numel(cFun);
cOutput = cell(1,iFunCount);

% Loop through user-defined functions
for j = 1:iFunCount
    try

        % Call user-defined function for current ASTER scene
        cOutput{j} = cFun{j}(cDir{iFolderIdx},sParams);

    catch objExc

        cFolders = strsplit(cDir{iFolderIdx},'\');
        warning(objExc.message)
        warning(['An error occurred while processing images ' ...
            'in folder ' cFolders{end-1} '...'])

    end
end
