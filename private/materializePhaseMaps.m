function phaseMaps = materializePhaseMaps(meta, spatialSize, nSpec)
%MATERIALIZEPHASEMAPS Expand the current saved phase state to spatial maps.

spatialSize = round(double(spatialSize(:)'));
if numel(spatialSize) ~= 3 || any(spatialSize < 1)
    error('Spatial size for phase maps must contain three positive dimensions.');
end

defaultParams = struct( ...
    'ph0Deg', 0, ...
    'ph1Deg', 0, ...
    'pivotIndex', max(1, round(nSpec / 2)));

phaseIsEnabled = isstruct(meta) && isfield(meta, 'phaseEnabled') && meta.phaseEnabled;
if phaseIsEnabled && isfield(meta, 'phaseParams') && isstruct(meta.phaseParams)
    defaultParams = normalizeGlobalParams(meta.phaseParams, defaultParams, nSpec);
end

phaseMaps = struct( ...
    'ph0Deg', repmat(defaultParams.ph0Deg, spatialSize), ...
    'ph1Deg', repmat(defaultParams.ph1Deg, spatialSize), ...
    'pivotIndex', repmat(defaultParams.pivotIndex, spatialSize), ...
    'successMask', false(spatialSize), ...
    'algorithm', 'manual');

isVoxelwise = phaseIsEnabled && isfield(meta, 'phaseMode') ...
    && strcmpi(string(meta.phaseMode), "voxelwise") ...
    && isfield(meta, 'phaseMaps') && isstruct(meta.phaseMaps);
if ~isVoxelwise
    return;
end

savedMaps = meta.phaseMaps;
requiredFields = {'ph0Deg', 'ph1Deg', 'pivotIndex'};
voxelCount = prod(spatialSize);
for iField = 1:numel(requiredFields)
    fieldName = requiredFields{iField};
    if ~isfield(savedMaps, fieldName)
        return;
    end
    values = double(savedMaps.(fieldName));
    if numel(values) ~= voxelCount || any(~isfinite(values(:)))
        return;
    end
    phaseMaps.(fieldName) = reshape(values, spatialSize);
end

phaseMaps.pivotIndex = max(1, min(nSpec, round(phaseMaps.pivotIndex)));
if isfield(savedMaps, 'successMask') && numel(savedMaps.successMask) == voxelCount
    phaseMaps.successMask = reshape(logical(savedMaps.successMask), spatialSize);
end
if isfield(savedMaps, 'algorithm') && ~isempty(savedMaps.algorithm)
    phaseMaps.algorithm = char(string(savedMaps.algorithm));
end
end

function params = normalizeGlobalParams(source, defaults, nSpec)
params = defaults;
fieldNames = {'ph0Deg', 'ph1Deg', 'pivotIndex'};
for iField = 1:numel(fieldNames)
    fieldName = fieldNames{iField};
    if isfield(source, fieldName)
        value = double(source.(fieldName));
        if isscalar(value) && isfinite(value)
            params.(fieldName) = value;
        end
    end
end
params.pivotIndex = max(1, min(nSpec, round(params.pivotIndex)));
end
