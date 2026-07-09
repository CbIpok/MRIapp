function axisSettings = getSpectralAxisSettings(meta, nSpec)
%GETSPECTRALAXISSETTINGS Read spectral x-axis display settings from metadata.

if nargin < 2 || isempty(nSpec)
    nSpec = 1;
end

axisSettings = struct( ...
    'usePpm', false, ...
    'swPpm', defaultSpectralWidth(nSpec), ...
    'o1Ppm', 0);

if ~isstruct(meta)
    return;
end

axisSettings.usePpm = getOptionalLogical(meta, 'spectralAxisUsePpm', axisSettings.usePpm);
axisSettings.swPpm = getOptionalNumeric(meta, 'spectralSWPpm', axisSettings.swPpm);
axisSettings.o1Ppm = getOptionalNumeric(meta, 'spectralO1Ppm', axisSettings.o1Ppm);

if ~isfinite(axisSettings.swPpm) || axisSettings.swPpm <= 0
    axisSettings.swPpm = defaultSpectralWidth(nSpec);
end

if ~isfinite(axisSettings.o1Ppm)
    axisSettings.o1Ppm = 0;
end
end

function value = defaultSpectralWidth(nSpec)
value = max(1, double(nSpec) - 1);
end

function value = getOptionalNumeric(src, fieldName, defaultValue)
if isfield(src, fieldName)
    value = double(src.(fieldName));
else
    value = defaultValue;
end
end

function value = getOptionalLogical(src, fieldName, defaultValue)
if isfield(src, fieldName)
    value = logical(src.(fieldName));
else
    value = defaultValue;
end
end
