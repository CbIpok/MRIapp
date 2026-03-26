function [resultValue, details] = evaluateSpectralConversionValue(spectrumVector, definitions, meta)
%EVALUATESPECTRALCONVERSIONVALUE Evaluate the configured conversion for one voxel spectrum.

if nargin < 3
    meta = struct();
end

if ~isvector(spectrumVector)
    error('Spectrum input must be a vector for single-voxel evaluation.');
end

spectrumVector = reshape(spectrumVector, [], 1);
volume4D = reshape(spectrumVector, [numel(spectrumVector), 1, 1, 1]);
[resultVolume, volumeDetails] = buildSpectralConversionVolume(volume4D, definitions, meta);

resultValue = resultVolume(1, 1, 1);
details = volumeDetails;
details.variableValues = zeros(numel(details.variableVolumes), 1);

for iDef = 1:numel(details.variableVolumes)
    details.variableValues(iDef, 1) = details.variableVolumes{iDef}(1, 1, 1);
end
details.numeratorValue = details.numerator(1, 1, 1);
details.denominatorValue = details.denominator(1, 1, 1);
details.resultValue = resultValue;
end
