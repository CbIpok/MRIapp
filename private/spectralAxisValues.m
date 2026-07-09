function [xValues, xLabel] = spectralAxisValues(axisSettings, nSpec)
%SPECTRALAXISVALUES Return x coordinates for spectral plots.

indices = (1:nSpec).';
if isstruct(axisSettings) && isfield(axisSettings, 'usePpm') && axisSettings.usePpm
    xValues = spectralIndexToAxis(indices, axisSettings, nSpec);
    xLabel = 'ppm';
else
    xValues = indices;
    xLabel = 'Spectral point';
end
end
