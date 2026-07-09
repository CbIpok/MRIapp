function indexValue = spectralAxisToIndex(axisValue, axisSettings, nSpec)
%SPECTRALAXISTOINDEX Convert a plot x coordinate back to spectral point index.

if ~isstruct(axisSettings) || ~isfield(axisSettings, 'usePpm') || ~axisSettings.usePpm
    indexValue = axisValue;
    return;
end

swPpm = double(axisSettings.swPpm);
o1Ppm = double(axisSettings.o1Ppm);

if nSpec <= 1 || ~isfinite(swPpm) || swPpm == 0
    indexValue = ones(size(axisValue));
    return;
end

stepPpm = swPpm / double(nSpec - 1);
indexValue = (double(axisValue) - o1Ppm) ./ stepPpm + double(nSpec + 1) / 2;
end
