function sMetadata = cleanupDem(strDir,sParams,sUserParams)

% Parse
strRef = sUserParams.referenceDemFile;
strShpDir = sUserParams.unstableTerrainDir;
dElevThresh = sUserParams.elevationThreshold;
strSaveDir = sUserParams.saveDir;

% Make sure path ends with backslash
if ~strcmp(strShpDir(end),'\')
    strShpDir = [strShpDir '\'];
end
if ~strcmp(strSaveDir(end),'\')
    strSaveDir = [strSaveDir '\'];
end

% ASTER DEM filename
cFile = getFiles(strDir,[sParams.dem '.tif']);

% Read the ASTER spatial referencing and DEM
sInfo = geotiffinfo(cFile{1});
sR = sInfo.SpatialRef;
[vLon,vLat] = makeSpatialRefVecs(sR,'full');
[mLon,mLat] = meshgrid(vLon,vLat);
mDem = double(geotiffread(cFile{1}));

% Masks
lNull = nullMask(mDem);
lSat = satMask(strDir,cFile,sParams.raster{3});

% Optional elevation difference threshold mask
if dElevThresh > 0
    [lDiff,mDemRef] = diffMask(strRef,mLon,mLat,mDem,dElevThresh);
else
    lDiff = false(size(mDem));
end

% Apply masks
mDem(lNull | lDiff | lSat) = NaN;

% Shift or optimize orientation of ASTER DEM to match reference DEM
switch sUserParams.alignmentMethod
    case 'shift'
        [mDem,sRefFinal] = shift(strRef,strShpDir,mLon,mLat,mDem,sR);
    case 'optimize'
        mDem = optimize(strRef,strShpDir,mLon,mLat,mDem);
        sRefFinal = sR;
    case 'none'
        sRefFinal = sR;
    otherwise
        error('Invalid parameter.')
end

% Set nodata value of -32768, convert to int16
mDem(isnan(mDem)) = -32768;
mDem = int16(mDem);

% Write geotiff files for shifted DEM
cFolders = strsplit(strDir,'\');
geotiffwrite([strSaveDir 'dem_' cFolders{end-1} '.tif'],mDem,sRefFinal);

% Output metadata
sMetadata.id = cFolders{end-1};
sMetadata.acquisitionDate = acquisitionDate(strDir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lNull = nullMask(mDem)

% Null pixels mask
lNull = mDem < -500 | mDem > 9000;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lSat = satMask(strDir,cFile,strRas)

% Read band 3N image (this along with band 3B were used to make the DEM)
cFileB3 = getFiles(strDir,[strRas '.tif']);
mB3 = double(geotiffread(cFileB3{1}));

% Find saturated pixels
lSat = mB3 == 0 | mB3 == 255;

% Resample to match the DEM
lSat = resample(double(lSat),cFileB3,cFile) > 0;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [lDiff,varargout] = diffMask(strRef,mLon,mLat,mDem,dElevThresh)
    
% Read the reference DEM
mBnd = [min(mLon(:)) min(mLat(:)); max(mLon(:)) max(mLat(:))];
[mDemR,vLonR,vLatR] = readGeotiffRegion(mBnd,strRef,10);
mDemR = double(mDemR);

% Remove null values
mDemR(mDemR > 9000 | mDemR < -500) = NaN;

% Interpolate to match resolution of the ASTER DEM
[mLonR,mLatR] = meshgrid(vLonR,vLatR);
mDemR = interp2(mLonR,mLatR,mDemR,mLon,mLat);

% Find elevations greater than user-specified value
lDiff = abs(mDem - mDemR) > dElevThresh;

% Slight morphological dilation
lDiff = imdilate(lDiff,strel('disk',7));

% Optional reference DEM optional output
varargout{1} = mDemR;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [mDem,sR] = shift(strRef,strShpDir,mLon,mLat,mDem,sR)

% Make spatial referencing vectors at ~90 m resolution
dRes = 90;
vLonR = mLon(1,:); vLatR = mLat(:,1);
[vC,iZ,strH] = ll2utm([mean(vLonR) mean(vLatR)],[],[]);
dRes = mean(abs(diff(utm2ll([vC;vC+dRes],iZ,strH))));
vLonR = vLonR(1):dRes:vLonR(end);
vLatR = vLatR(1):-dRes:vLatR(end);
    
% Read and resample reference DEM
sParamsR.nullVal = 'dem';
mDemR = grid2grid(strRef,vLonR,vLatR,sParamsR);

% Skip image if reference DEM does not overlap
if all(isnan(mDemR(:)))
    error('No overlap with reference DEM. Skipping...')
end

% Make unstable terrain mask
lM = imdilate(polygons2grid(strShpDir,vLonR,vLatR),strel('disk',3));

% Compute geographic >> projected scale factors
vC = [mean(vLonR) mean(vLatR)];
vScale = diff(ll2utm([vC;vC+dRes],[],[])) / dRes;

% Compute shift vector to align with reference DEM
vShift = shiftDem([mLon(:) mLat(:) mDem(:)]',mDemR,lM,vLonR,vLatR,vScale);
    
% Apply shift
sR.Lonlim = sR.Lonlim + vShift(1);      
sR.Latlim = sR.Latlim + vShift(2);    
mDem = mDem + vShift(3);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mDem = optimize(strRef,strShpDir,mLon,mLat,mDem)

% Prepare data for optimization
[mPts,mDemR,lM,vX,vY,iZ,strH] = prepareData(strRef,strShpDir, ...
    mLon,mLat,mDem);

% Parameters for nonlinear optimization
sOpt.rotation = [5 5 5];
sOpt.translation = [1E3 1E3 1E3];
sOpt.scale = [NaN NaN NaN];
sOpt.globalScale = 1;
sOpt.maxIterations = 200;
sOpt.visualize = false;
sOpt.polySurf = false;

% Optimize orientation of ASTER points to match reference DEM
sOutput = optimizeDem(mPts,mDemR,lM,vX,vY,sOpt);

% Apply transformation to all ASTER points
lIn = ~isnan(mDem);
mPts = ll2utm([mLon(lIn) mLat(lIn) mDem(lIn)],iZ,strH)';
mPts = [mPts; ones(1,size(mPts,2))];
mPts = transformUsingSolverVar(mPts,sOutput);  
mPts = utm2ll(mPts',iZ,strH)'; 

% Interpolation parameters
sP.blockSize = 500;
sP.null = -9999;
sP.connectedPixels = 0;
sP.radius = 0;

% Interpolate to make raster DEM
mDem = points2grid(mPts,mLon(1,:),mLat(:,1)','interp',sP);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [mPts,mDemR,lM,vX,vY,iZ,strH] = prepareData(strRef,strShpDir, ...
        mLon,mLat,mDem)

% Convert ASTER DEM to points in UTM coordinate system
lIn = ~isnan(mDem);
[mPts,iZ,strH] = ll2utm([mLon(lIn) mLat(lIn) mDem(lIn)],[],[]); 
mPts = mPts';

% Choose random sample of points (to conserve memory)
vIdx = randperm(length(mPts),min([1E6 length(mPts)]));
mPts = mPts(:,vIdx);
mPts = [mPts; ones(1,size(mPts,2))];

% Read the reference DEM
mBnd = utm2ll([min(mPts(1:2,:),[],2) max(mPts(1:2,:),[],2)]',iZ,strH);
[mDemR,vLonR,vLatR] = readGeotiffRegion(mBnd,strRef,10);
mDemR = double(mDemR);
mDemR(nullMask(mDemR)) = NaN;

% Convert reference DEM to points in UTM coordinate system
[mLonR,mLatR] = meshgrid(vLonR,vLatR);
mPtsR = ll2utm([mLonR(:) mLatR(:) mDemR(:)],iZ,strH)';
clear mDemR

% Make reference DEM grid in UTM coordinate system
dX = 90; dY = 90;
vX = floor(min(mPtsR(1,:)))-dX:dX:ceil(max(mPtsR(1,:))+dX);
vY = fliplr(floor(min(mPtsR(2,:)))-dY:dY:ceil(max(mPtsR(2,:))+dY));
mDemR = points2grid(mPtsR,vX,vY,'sparse');

% Make unstable terrain grid in UTM coordinate system
lM = polygons2grid(strShpDir,mLonR(1,:),mLatR(:,1)'); clear mLonR mLatR
lM = points2grid([mPtsR(1:2,:);double(lM(:)')],vX,vY,'sparse') > 0;
lM = imdilate(lM,strel('disk',3));

end
end
