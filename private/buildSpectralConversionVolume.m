function [resultVolume, details] = buildSpectralConversionVolume(spectrum4D, definitions, meta)
%BUILDSPECTRALCONVERSIONVOLUME Build a derived 3D volume from named spectral integrals.

defs = normalizeConversionDefinitions(definitions, size(spectrum4D, 1));
if isempty(defs)
    error('Conversion definitions are empty.');
end

[~, spectrumUsed] = buildIntegratedVolumeFromSpectrum(spectrum4D, 1:size(spectrum4D, 1), meta);
resultSize = [size(spectrumUsed, 2), size(spectrumUsed, 3), size(spectrumUsed, 4)];

numerator = zeros(resultSize);
denominator = zeros(resultSize);
variableVolumes = cell(numel(defs), 1);
variableNames = cell(numel(defs), 1);

hasNumerator = false;
hasDenominator = false;

for iDef = 1:numel(defs)
    idxRange = defs(iDef).startIndex:defs(iDef).endIndex;
    currentVolume = integrateSpectralRange(spectrumUsed, idxRange);
    variableVolumes{iDef} = currentVolume;
    variableNames{iDef} = defs(iDef).name;
    weightedVolume = currentVolume ./ defs(iDef).divisor;

    if defs(iDef).useNumerator
        numerator = numerator + weightedVolume;
        hasNumerator = true;
    end

    if defs(iDef).useDenominator
        denominator = denominator + weightedVolume;
        hasDenominator = true;
    end
end

if ~hasNumerator
    error('At least one variable must be included in the numerator.');
end

if ~hasDenominator
    error('At least one variable must be included in the denominator.');
end

resultVolume = numerator ./ denominator;
resultVolume(denominator == 0) = NaN;

details = struct( ...
    'definitions', defs, ...
    'numerator', numerator, ...
    'denominator', denominator, ...
    'variableNames', {variableNames}, ...
    'variableVolumes', {variableVolumes});
end

function defs = normalizeConversionDefinitions(definitions, nSpec)
if isempty(definitions)
    defs = repmat(makeEmptyDefinition(), 0, 1);
    return;
end

if istable(definitions)
    definitions = table2struct(definitions);
end

if ~isstruct(definitions)
    error('Conversion definitions must be a struct array or table.');
end

defs = repmat(makeEmptyDefinition(), numel(definitions), 1);
usedNames = strings(numel(definitions), 1);

for iDef = 1:numel(definitions)
    src = definitions(iDef);
    if ~isfield(src, 'name')
        error('Each conversion variable must have a name.');
    end

    name = strtrim(string(src.name));
    if strlength(name) == 0
        error('Conversion variable name cannot be empty.');
    end

    normalizedName = lower(name);
    if any(usedNames(1:iDef - 1) == normalizedName)
        error('Duplicate conversion variable name: %s', name);
    end
    usedNames(iDef, 1) = normalizedName;

    [startIndex, endIndex] = normalizeDefinitionRange(src, nSpec);
    divisor = getDefinitionDivisor(src);

    defs(iDef) = struct( ...
        'name', char(name), ...
        'startIndex', startIndex, ...
        'endIndex', endIndex, ...
        'divisor', divisor, ...
        'useNumerator', getLogicalField(src, 'useNumerator'), ...
        'useDenominator', getLogicalField(src, 'useDenominator'));
end
end

function [startIndex, endIndex] = normalizeDefinitionRange(src, nSpec)
if isfield(src, 'startIndex') && isfield(src, 'endIndex')
    startIndex = src.startIndex;
    endIndex = src.endIndex;
elseif isfield(src, 'range')
    range = src.range;
    if numel(range) < 2
        error('Conversion range must contain start and end indices.');
    end
    startIndex = range(1);
    endIndex = range(2);
else
    error('Each conversion variable must have start and end indices.');
end

startIndex = round(startIndex);
endIndex = round(endIndex);

if ~isfinite(startIndex) || ~isfinite(endIndex)
    error('Conversion range indices must be finite.');
end

startIndex = max(1, min(nSpec, startIndex));
endIndex = max(1, min(nSpec, endIndex));

if startIndex > endIndex
    tmp = startIndex;
    startIndex = endIndex;
    endIndex = tmp;
end
end

function value = getNumericField(src, fieldName, defaultValue)
if nargin < 3
    defaultValue = [];
end

if isfield(src, fieldName)
    value = double(src.(fieldName));
elseif isempty(defaultValue)
    error('Missing numeric field: %s', fieldName);
else
    value = defaultValue;
end

if ~isscalar(value) || ~isfinite(value)
    error('Field "%s" must be a finite scalar.', fieldName);
end
end

function divisor = getDefinitionDivisor(src)
if isfield(src, 'divisor')
    divisor = getNumericField(src, 'divisor', 1);
elseif isfield(src, 'multiplier')
    divisor = getNumericField(src, 'multiplier', 1);
else
    divisor = 1;
end

if divisor == 0
    error('Divisor must be non-zero.');
end
end

function value = getLogicalField(src, fieldName)
if ~isfield(src, fieldName)
    value = false;
    return;
end

rawValue = src.(fieldName);
if islogical(rawValue)
    value = logical(rawValue);
elseif isnumeric(rawValue)
    value = rawValue ~= 0;
elseif isstring(rawValue) || ischar(rawValue)
    value = any(strcmpi(string(rawValue), ["true", "1", "yes"]));
else
    value = logical(rawValue);
end
end

function def = makeEmptyDefinition()
def = struct( ...
    'name', '', ...
    'startIndex', 1, ...
    'endIndex', 1, ...
    'divisor', 1, ...
    'useNumerator', false, ...
    'useDenominator', false);
end
