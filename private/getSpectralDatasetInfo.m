function info = getSpectralDatasetInfo(varName)
%GETSPECTRALDATASETINFO Return spectral metadata and arrays for a loaded dataset.

metaVarName = [varName '__meta'];
existsMeta = evalin('base', sprintf('exist(''%s'', ''var'')', metaVarName));
if ~existsMeta
    info = struct('isSpectral', false, 'reason', 'Metadata is missing.');
    return;
end

meta = evalin('base', metaVarName);
if ~isstruct(meta) || ~isfield(meta, 'sourceKind') || ~strcmp(meta.sourceKind, 'spectral4d')
    info = struct('isSpectral', false, 'reason', 'Selected dataset is not spectral.');
    return;
end

if isfield(meta, 'spectrumVarName')
    spectrumVarName = meta.spectrumVarName;
else
    spectrumVarName = [varName '__spectrum4d'];
end

existsSpectrum = evalin('base', sprintf('exist(''%s'', ''var'')', spectrumVarName));
if ~existsSpectrum
    info = struct('isSpectral', false, 'reason', '4D spectrum variable is missing.');
    return;
end

info = struct( ...
    'isSpectral', true, ...
    'varName', varName, ...
    'metaVarName', metaVarName, ...
    'spectrumVarName', spectrumVarName, ...
    'volume3D', evalin('base', varName), ...
    'spectrum4D', evalin('base', spectrumVarName), ...
    'meta', meta);
end
