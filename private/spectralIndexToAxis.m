function axisValue = spectralIndexToAxis(indexValue, axisSettings, nSpec)
%SPECTRALINDEXTOAXIS Convert spectral point indices to current x-axis units.

if ~isstruct(axisSettings) || ~isfield(axisSettings, 'usePpm') || ~axisSettings.usePpm
    axisValue = indexValue;
    return;
end

swPpm = double(axisSettings.swPpm);
o1Ppm = double(axisSettings.o1Ppm);

if nSpec <= 1
    axisValue = o1Ppm + zeros(size(indexValue));
    return;
end

stepPpm = swPpm / double(nSpec - 1);
axisValue = o1Ppm + (double(indexValue) - double(nSpec + 1) / 2) .* stepPpm;
end
