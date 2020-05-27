# ASTER DEMs Cleanup

This repository contains MATLAB code for processing ASTER digital elevation models (DEMs) to prepare them for geomorphic change computations as described by Maurer et al. (2019). Only individual ASTER scenes downloaded from the METI AIST Data Archive System (MADAS) maintained by the National Institute of Advanced Industrial Science and Technology (AIST) and Geological Survey of Japan (https://gbank.gsj.jp/madas/map/index.html) are compatible as input. Using a user-specified reference DEM as ground-truth, the majority of erroneous elevation pixels (primarily caused by poor image contrast and clouds) are removed. Each ASTER DEM is then spatially aligned to the reference DEM using optimization routines.

## Requirements

* MATLAB version 2018a or newer

* MATLAB image processing, mapping, statistics, and optimization toolboxes. Enter `ver` in the MATLAB command window to see if you have them installed.

* The HEXIMAP "shared" [library](https://github.com/gmorky/heximap/tree/master/main/shared)

## Tips

* Any external data used as input must be georeferenced in the WGS84 geographic coordinate system, with elevations specified in meters.

* Only ASTER scenes and metadata downloaded from the MADAS website are compatible as input.

## Installation

After downloading the repository, add it to your MATLAB path including all subdirectories as `addpath(genpath('/path/to/asterDemsCleanup'))`. Also add the required HEXIMAP shared library as `addpath('/path/to/heximap/main/shared')`.

## Usage

*Any external data input must be georeferenced in the WGS84 geographic coordinate system, with elevations specified in meters.* The ASTER data must first be downloaded from [MADAS](https://gbank.gsj.jp/madas/map/index.html). This can be done using the standard search portal on the MADAS website. Alternatively, the javascript file *downloadFromMadas.js* (included in this repository) can be used for more efficient downloading if a large number of scenes are required. Instructions for using the javascript code in a web browser are included in the comments within the *downloadFromMadas.js* file.

This repository includes an example dataset in the Bhutanese Himalayas to illustrate a workflow for computing glacier ice loss trends (using the [geomorphic-change](https://github.com/gmorky/geomorphic-change) repository as the next step). The example dataset contains an ALOS reference DEM (geotiff format), polygons representing glacier boundaries (ESRI shapefile format), and several ASTER scenes.

The *cleanupAsterDems.m* script demonstrates the general workflow, with inputs for the two primary functions as follows:

* `cleanupDem(params);`

	* `params.referenceDemFile` (char): Path to the reference DEM geotiff file.

	* `params.unstableTerrainDir` (char): Path to the directory containing shapefile(s) with polygons enclosing terrain known to be unstable through time. In the example dataset, polygons representing approximate glacier boundaries are used.

	* `params.elevationThreshold` (1x1 double): The elevation threshold (absolute difference between ASTER DEMs and the reference DEM) which determines whether any given ASTER DEM pixel is considered erroneous. ASTER DEM pixels with absolute elevation differences greater than this value are removed. Units: meters.

	* `params.alignmentMethod` (char): Can be specified as `'shift'`, `'optimize'`, or `'none'`. The `'shift'` option allows for horizontal and vertical translations only (no rotation or scaling) when aligning ASTER DEMs to the reference DEM. The `'optimize'` option allows for translation, rotation, and scaling, but runs slower. In most cases using the `'shift'` option is sufficient.

	* `params.saveDir` (char): Directory to save the final processed ASTER DEMs.

* `asterLoop(asterScenesDir,functionHandles,parallel);`

	* `asterScenesDir` (char): Path to the directory containing ASTER scenes to be processed. Individual images and metadata files belonging to each ASTER scene should be kept within seperate subdirectories (see example dataset).

	* `functionHandles` (1xN cell): Array of function handles to be called for each ASTER scene. Custom user-defined functions can be specified here if desired.

	* `parallel` (1x1 logical): Flag specifying whether to execute for-loop iterations in parallel (requires the parallel computing toolbox).

## References

* Maurer, J. M., Schaefer, J. M., Rupper, S., & Corley, A. (2019). Acceleration of ice loss across the Himalayas over the past 40 years. Science advances, 5(6), eaav7266.