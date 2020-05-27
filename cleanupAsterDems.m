% Add dependencies paths
addpath(genpath('heximap\main\shared'))
addpath(genpath('asterDemsCleanup'))

% Directory containing downloaded ASTER scenes
strDir = 'asterDemsCleanup\asterScenes\';

% Parameters for DEM cleanup
sParams.referenceDemFile = 'asterDemsCleanup\alosRefDem.tif';
sParams.unstableTerrainDir = 'asterDemsCleanup\unstableTerrainMask\';
sParams.elevationThreshold = 150;
sParams.alignmentMethod = 'shift';
sParams.saveDir = 'asterDemsCleanup\cleanedDems\';

% Function handles
cFun = { ...
    @(x,y) cleanupDem(x,y,sParams)
};

% Use parallel processing?
lParallel = true;

% Process the ASTER scenes
cMetadata = asterLoop(strDir,cFun,lParallel);

% Save file containing ASTER scenes metadata (will use later when
% computing geomorphic change)
save([sParams.saveDir 'asterScenesMetadata.mat'],'cMetadata')
