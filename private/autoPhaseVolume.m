function [phaseMaps, summary] = autoPhaseVolume( ...
    spectrum4D, algorithm, initialParams, progressCallback)
%AUTOPHASEVOLUME Estimate individual phase parameters for every voxel.

if nargin < 4
    progressCallback = [];
end

nX = size(spectrum4D, 2);
nY = size(spectrum4D, 3);
nZ = size(spectrum4D, 4);
spatialSize = [nX, nY, nZ];
totalVoxels = prod(spatialSize);

phaseMaps = struct( ...
    'ph0Deg', repmat(double(initialParams.ph0Deg), spatialSize), ...
    'ph1Deg', repmat(double(initialParams.ph1Deg), spatialSize), ...
    'pivotIndex', repmat(double(initialParams.pivotIndex), spatialSize), ...
    'successMask', false(spatialSize), ...
    'algorithm', normalizeVolumeAlgorithm(algorithm));

summary = struct( ...
    'algorithm', phaseMaps.algorithm, ...
    'totalVoxels', totalVoxels, ...
    'successCount', 0, ...
    'fallbackCount', 0);

notifyProgress(progressCallback, 0, totalVoxels);
for linearIndex = 1:totalVoxels
    [voxelX, voxelY, voxelZ] = ind2sub(spatialSize, linearIndex);
    spectrum = spectrum4D(:, voxelX, voxelY, voxelZ);
    [params, info] = autoPhaseSpectrum(spectrum, phaseMaps.algorithm, initialParams);

    if info.success
        phaseMaps.ph0Deg(voxelX, voxelY, voxelZ) = params.ph0Deg;
        phaseMaps.ph1Deg(voxelX, voxelY, voxelZ) = params.ph1Deg;
        phaseMaps.pivotIndex(voxelX, voxelY, voxelZ) = params.pivotIndex;
        phaseMaps.successMask(voxelX, voxelY, voxelZ) = true;
        summary.successCount = summary.successCount + 1;
    else
        summary.fallbackCount = summary.fallbackCount + 1;
    end

    notifyProgress(progressCallback, linearIndex, totalVoxels);
end
end

function notifyProgress(callback, completedCount, totalCount)
if isempty(callback)
    return;
end
callback(completedCount, totalCount);
end

function algorithm = normalizeVolumeAlgorithm(value)
algorithm = lower(strtrim(char(string(value))));
algorithm = strrep(algorithm, ' ', '_');
switch algorithm
    case 'acme'
        algorithm = 'acme';
    case {'peak_minima', 'peakminima'}
        algorithm = 'peak_minima';
    otherwise
        error('Automatic phase algorithm must be ACME or Peak minima.');
end
end
