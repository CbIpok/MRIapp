function correctedSpectrum = applyStoredPhaseCorrection(spectrum4D, meta)
%APPLYSTOREDPHASECORRECTION Apply global or voxel-wise saved phase data.

correctedSpectrum = spectrum4D;
if nargin < 2 || ~isstruct(meta) || ~isfield(meta, 'phaseEnabled') || ~meta.phaseEnabled
    return;
end

phaseMode = 'global';
if isfield(meta, 'phaseMode') && ~isempty(meta.phaseMode)
    phaseMode = lower(strtrim(char(string(meta.phaseMode))));
end

if strcmp(phaseMode, 'voxelwise')
    if ~isfield(meta, 'phaseMaps') || ~isstruct(meta.phaseMaps)
        error('Voxel-wise phase mode is enabled, but phase maps are missing.');
    end

    maps = meta.phaseMaps;
    requiredFields = {'ph0Deg', 'ph1Deg', 'pivotIndex'};
    for iField = 1:numel(requiredFields)
        if ~isfield(maps, requiredFields{iField})
            error('Voxel-wise phase map "%s" is missing.', requiredFields{iField});
        end
    end

    correctedSpectrum = applyPhaseCorrection(spectrum4D, ...
        maps.ph0Deg, maps.ph1Deg, maps.pivotIndex);
    return;
end

if ~isfield(meta, 'phaseParams') || ~isstruct(meta.phaseParams)
    error('Global phase correction is enabled, but phase parameters are missing.');
end

params = meta.phaseParams;
correctedSpectrum = applyPhaseCorrection(spectrum4D, ...
    params.ph0Deg, params.ph1Deg, params.pivotIndex);
end
