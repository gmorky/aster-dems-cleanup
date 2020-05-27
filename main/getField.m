function cOutput = getField(strDir,strFile,strObj,strField)
    
% Read the metadata text file
cFile = getFiles(strDir,strFile);
fID = fopen(cFile{1});
cData = textscan(fID,'%s','delimiter',';');
cData = cData{1};
fclose(fID);

% Get fields for current band
lStart = find(strcmp(['OBJECT=' strObj],cData));
lEnd = find(strcmp(['END_OBJECT=' strObj],cData));
cData = cData(lStart:lEnd);

% Get field value
cData = cData(strncmp(strField,cData,length(strField)));
cData{1} = strrep(cData{1},'(','{');
cData{1} = strrep(cData{1},')','}');
cData{1} = strrep(cData{1},'"','''');
cData{1} = strrep(cData{1},'"','''');
cData{1} = strrep(cData{1},'N/A','NaN');
cData{1} = strrep(cData{1},strField,'cOutput');
eval([cData{1} ';'])
