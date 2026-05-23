function [integrated3D, spectrumUsed] = buildIntegratedVolumeFromSpectrum(spectrum4D, idxRange, meta, valueMode)
%BUILDINTEGRATEDVOLUMEFROMSPECTRUM Apply saved phase and integrate a range.

if nargin < 4 || isempty(valueMode)
    valueMode = getSpectralValueMode(meta);
end

spectrumUsed = spectrum4D;

if nargin >= 3 && isstruct(meta) ...
        && isfield(meta, 'phaseEnabled') && meta.phaseEnabled ...
        && isfield(meta, 'phaseParams') && isstruct(meta.phaseParams)
    params = meta.phaseParams;
    spectrumUsed = applyPhaseCorrection( ...
        spectrum4D, params.ph0Deg, params.ph1Deg, params.pivotIndex);
end

integrated3D = integrateSpectralRange(spectrumUsed, idxRange, valueMode);
end
