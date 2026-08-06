function [integrated3D, spectrumUsed] = buildIntegratedVolumeFromSpectrum(spectrum4D, idxRange, meta, valueMode)
%BUILDINTEGRATEDVOLUMEFROMSPECTRUM Apply saved phase and integrate a range.

if nargin < 4 || isempty(valueMode)
    valueMode = getSpectralValueMode(meta);
end

spectrumUsed = applyStoredPhaseCorrection(spectrum4D, meta);

integrated3D = integrateSpectralRange(spectrumUsed, idxRange, valueMode);
end
