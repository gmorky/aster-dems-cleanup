function mGrid = resample(mGrid,cFileInput,cFileTarget)
    
% Get spatial referencing vectors
sInfo = geotiffinfo(cFileInput{1});
[vLonI,vLatI] = makeSpatialRefVecs(sInfo.SpatialRef,'full');
sInfo = geotiffinfo(cFileTarget{1});
[vLonN,vLatN] = makeSpatialRefVecs(sInfo.SpatialRef,'full');

% Make spatial referencing matrices
[mLonI,mLatI] = meshgrid(vLonI,vLatI);
[mLonN,mLatN] = meshgrid(vLonN,vLatN);

% Resample
mGrid = interp2(mLonI,mLatI,mGrid,mLonN,mLatN);
