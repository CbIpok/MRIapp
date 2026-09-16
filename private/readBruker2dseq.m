function [data, metadata, rawData] = readBruker2dseq(filename)
%READBRUKER2DSEQ Read reconstructed Bruker pixels as [row, column, plane].
% VisuCoreSize is [columns, rows, optional depth]. Pixels on disk run
% left-to-right, then top-to-bottom, then frame-to-frame. No anatomical
% reorientation is performed; original geometry/frame groups are retained.
% Visu scaling: data = stored * slope + offset.
% RECO fallback: data = stored / RECO_map_slope + RECO_map_offset.
% References and supported scope are documented in BRUKER_2DSEQ.md.

if ~isfile(filename)
    error('Bruker:MissingData', '2dseq file does not exist: %s', filename);
end
[folder, name, ext] = fileparts(filename);
if ~strcmpi([name ext], '2dseq')
    error('Bruker:InvalidFilename', 'Expected a file named 2dseq.');
end
visuPath = fullfile(folder, 'visu_pars');
recoPath = fullfile(folder, 'reco');
hasVisu = isfile(visuPath);
hasReco = isfile(recoPath);
if ~hasVisu && ~hasReco
    error('Bruker:MissingMetadata', 'Neither visu_pars nor reco was found beside %s.', filename);
end
visu = struct();
reco = struct();
if hasVisu, visu = readBrukerParameterFile(visuPath); end
if hasReco, reco = readBrukerParameterFile(recoPath); end
notes = {};
if ~hasVisu, notes{end+1} = 'visu_pars missing; using reco.'; end
if ~hasReco, notes{end+1} = 'reco missing; using visu_pars.'; end

[sizeText, sizeSource] = chooseParameter(visu, reco, 'VisuCoreSize', 'RECO_size');
coreSize = numericParameter(sizeText, sizeSource);
if ~ismember(numel(coreSize), [2 3]) || any(coreSize < 1 | coreSize ~= fix(coreSize))
    error('Bruker:InvalidDimensions', '%s must contain two or three positive integer dimensions.', sizeSource);
end
dimText = parameter(visu, 'VisuCoreDim');
if ~isempty(dimText) && startsWith(sizeSource, 'Visu')
    coreDim = numericParameter(dimText, 'VisuCoreDim');
    if ~isscalar(coreDim) || coreDim ~= numel(coreSize)
        error('Bruker:InvalidDimensions', 'VisuCoreDim does not match VisuCoreSize.');
    end
end
if strcmp(sizeSource, 'RECO_size')
    recoTranspose = parameter(reco, 'RECO_transposition');
    if ~isempty(recoTranspose)
        transposeValues = numericParameter(recoTranspose, 'RECO_transposition');
        % Without Visu's final matrix sizes, unequal reconstructed axes can
        % be ambiguous across object-dependent RECO transpositions.
        if any(transposeValues ~= 0) && any(coreSize ~= coreSize(1))
            error('Bruker:UnsupportedOrientation', ...
                'Transposed non-square RECO data requires VisuCoreSize to determine the stored matrix.');
        end
    end
end
[typeText, typeSource] = chooseParameter(visu, reco, 'VisuCoreWordType', 'RECO_wordtype');
[dataType, bytesPerElement] = decodeWordType(typeText);
[endianText, endianSource] = chooseParameter(visu, reco, 'VisuCoreByteOrder', 'RECO_byte_order');
switch normalizedToken(endianText)
    case {'littleendian', 'ieeele'}
        machineFormat = 'ieee-le';
    case {'bigendian', 'ieeebe'}
        machineFormat = 'ieee-be';
    otherwise
        error('Bruker:UnsupportedEndian', 'Unknown Bruker byte order: %s.', endianText);
end

fileInfo = dir(filename);
bytesPerFrame = prod(coreSize) * bytesPerElement;
frameText = parameter(visu, 'VisuCoreFrameCount');
frameSource = 'VisuCoreFrameCount';
if isempty(frameText)
    frameCount = fileInfo.bytes / bytesPerFrame;
    frameSource = 'file size / bytes per core frame';
    notes{end+1} = 'VisuCoreFrameCount missing; inferred complete frames from file size.';
else
    frameCount = numericParameter(frameText, frameSource);
end
if ~isscalar(frameCount) || ~isfinite(frameCount) || frameCount < 1 || frameCount ~= fix(frameCount)
    error('Bruker:InvalidFrames', 'Cannot determine a positive integer frame count from %s.', frameSource);
end
expectedElements = prod(coreSize) * frameCount;
if fileInfo.bytes ~= expectedElements * bytesPerElement
    error('Bruker:SizeMismatch', ...
        '2dseq has %g bytes; metadata requires %g bytes (%g %s values).', ...
        fileInfo.bytes, expectedElements * bytesPerElement, expectedElements, dataType);
end

% RECO_transposition describes reconstruction already performed on disk;
% do not apply it again. Explicit additional VISU storage transforms require
% a geometry-aware reader, rather than guessing flips from the image.
transpositionText = parameter(visu, 'VisuCoreTransposition');
if ~isempty(transpositionText) && any(numericParameter(transpositionText, 'VisuCoreTransposition') ~= 0)
    error('Bruker:UnsupportedOrientation', ...
        'Nonzero VisuCoreTransposition is not supported; refusing to guess image orientation.');
end

[slope, offset, scaling, scalingNotes] = resolveScaling(visu, reco, frameCount, dataType);
notes = [notes, scalingNotes];
fid = fopen(filename, 'rb', machineFormat);
if fid < 0
    error('Bruker:OpenFailed', 'Cannot open 2dseq: %s', filename);
end
cleanup = onCleanup(@() fclose(fid));
[stored, count] = fread(fid, Inf, ['*' dataType]);
[readMessage, readError] = ferror(fid);
% fread(..., Inf) deliberately reaches EOF; MATLAB reports that via ferror.
if readError ~= 0 && ~feof(fid)
    error('Bruker:ReadFailed', 'Error reading 2dseq: %s', readMessage);
end
if count ~= expectedElements || ftell(fid) ~= fileInfo.bytes
    error('Bruker:ReadCountMismatch', 'Unexpected amount of data read from 2dseq.');
end

depth = 1;
if numel(coreSize) == 3, depth = coreSize(3); end
% First restore disk axes, then adapt once to imagesc(array(:,:,plane)).
rawFrames = permute(reshape(stored, [coreSize(1:2), depth, frameCount]), [2 1 3 4]);
scaledFrames = double(rawFrames) .* reshape(slope, 1, 1, 1, []) ...
    + reshape(offset, 1, 1, 1, []);
outputSize = [coreSize(2), coreSize(1), depth * frameCount];
rawData = reshape(rawFrames, outputSize);
data = reshape(scaledFrames, outputSize);

metadata = struct( ...
    'format', 'Bruker 2dseq', 'originalPath', filename, ...
    'visuParsPath', visuPath, 'recoPath', recoPath, ...
    'hasVisuPars', hasVisu, 'hasReco', hasReco, ...
    'visuPars', visu, 'reco', reco, ...
    'coreSize', coreSize, 'frameCount', frameCount, ...
    'spatialSize', outputSize, 'planeCount', outputSize(3), ...
    'dataType', dataType, 'bytesPerElement', bytesPerElement, ...
    'machineFormat', machineFormat, 'elementCount', count, ...
    'sizeSource', sizeSource, 'typeSource', typeSource, ...
    'endianSource', endianSource, 'frameCountSource', frameSource, ...
    'scaling', scaling, ...
    'arrayOrder', 'row,column,plane; plane = z + (frame-1)*depth', ...
    'orientationPolicy', 'Stored image rows; no anatomical reorientation or frame reordering', ...
    'notes', {notes});
end

function [value, source] = chooseParameter(visu, reco, visuName, recoName)
value = parameter(visu, visuName);
source = visuName;
if isempty(value)
    value = parameter(reco, recoName);
    source = recoName;
end
if isempty(value)
    error('Bruker:MissingParameter', 'Cannot determine %s: neither %s nor %s is available.', ...
        visuName, visuName, recoName);
end
end

function value = parameter(parameters, requestedName)
% Ignore case and underscores (e.g. RECO_word_type versus RECO_wordtype).
names = fieldnames(parameters);
matches = strcmp(cellfun(@normalizedToken, names, 'UniformOutput', false), normalizedToken(requestedName));
if nnz(matches) > 1
    error('Bruker:InvalidMetadata', 'Ambiguous aliases for %s.', requestedName);
end
value = '';
if any(matches), value = parameters.(names{find(matches, 1)}); end
end

function token = normalizedToken(value)
token = lower(regexprep(value, '[^a-zA-Z0-9]', ''));
end

function values = numericParameter(text, name)
% Strip JCAMP array dimensions, not the values. Expand @N*(value) repeats.
declaration = regexp(text, '^\(\s*([\d,\s]+)\)\s*', 'tokens', 'once');
declaredCount = [];
if ~isempty(declaration)
    dims = str2double(regexp(declaration{1}, '\d+', 'match'));
    declaredCount = prod(dims);
    text = regexprep(text, '^\(\s*[\d,\s]+\)\s*', '');
end
tokens = regexp(strtrim(text), '@\d+\*\([^()]*\)|[^\s,]+', 'match');
values = [];
for k = 1:numel(tokens)
    repeat = regexp(tokens{k}, '^@(\d+)\*\(\s*([^()]*)\s*\)$', 'tokens', 'once');
    repeatCount = 1;
    numberText = tokens{k};
    if ~isempty(repeat)
        repeatCount = str2double(repeat{1});
        numberText = strtrim(repeat{2});
    end
    number = str2double(regexprep(numberText, '[dD]', 'e'));
    if ~isreal(number) || ~isfinite(number) || repeatCount < 1 || repeatCount > 1e7
        error('Bruker:InvalidMetadata', '%s contains an invalid numeric value.', name);
    end
    values = [values, repmat(number, 1, repeatCount)]; %#ok<AGROW>
end
if isempty(values) || (~isempty(declaredCount) && numel(values) ~= declaredCount)
    error('Bruker:InvalidMetadata', '%s has missing values or an incorrect array length.', name);
end
end

function [dataType, bytes] = decodeWordType(text)
token = normalizedToken(text);
switch token
    case {'8bitunsgnint', '8bitunsignedint', 'uint8'}, dataType = 'uint8'; bytes = 1;
    case {'8bitsgnint', '8bitsignedint', 'int8'}, dataType = 'int8'; bytes = 1;
    case {'16bitunsgnint', '16bitunsignedint', 'uint16'}, dataType = 'uint16'; bytes = 2;
    case {'16bitsgnint', '16bitsignedint', 'int16'}, dataType = 'int16'; bytes = 2;
    case {'32bitunsgnint', '32bitunsignedint', 'uint32'}, dataType = 'uint32'; bytes = 4;
    case {'32bitsgnint', '32bitsignedint', 'int32'}, dataType = 'int32'; bytes = 4;
    case {'32bitfloat', 'float32', 'single'}, dataType = 'single'; bytes = 4;
    case {'64bitfloat', 'float64', 'double'}, dataType = 'double'; bytes = 8;
    otherwise
        error('Bruker:UnsupportedDataType', 'Unsupported Bruker word type: %s.', text);
end
end

function [slope, offset, scaling, notes] = resolveScaling(visu, reco, frameCount, dataType)
notes = {};
slopeText = parameter(visu, 'VisuCoreDataSlope');
slopeSource = 'VisuCoreDataSlope';
if isempty(slopeText)
    slopeText = parameter(reco, 'RECO_map_slope');
    slopeSource = 'RECO_map_slope (inverse)';
end
if isempty(slopeText)
    if ismember(dataType, {'single', 'double'})
        slope = ones(1, frameCount);
        slopeSource = 'identity (floating point)';
        notes{end+1} = 'No slope provided; using identity for unmapped data.';
    else
        error('Bruker:MissingScaling', 'Missing VisuCoreDataSlope and RECO_map_slope for integer image data.');
    end
else
    slope = frameValues(numericParameter(slopeText, slopeSource), frameCount, slopeSource);
    if any(slope == 0)
        error('Bruker:InvalidScaling', 'Image slope must be nonzero.');
    end
    if startsWith(slopeSource, 'RECO'), slope = 1 ./ slope; end
    if any(~isfinite(slope))
        error('Bruker:InvalidScaling', 'Inverse RECO slope is not finite.');
    end
end
offsetText = parameter(visu, 'VisuCoreDataOffs');
offsetSource = 'VisuCoreDataOffs';
if isempty(offsetText)
    offsetText = parameter(visu, 'VisuCoreDataOffset');
    offsetSource = 'VisuCoreDataOffset';
end
if isempty(offsetText)
    offsetText = parameter(reco, 'RECO_map_offset');
    offsetSource = 'RECO_map_offset';
end
if isempty(offsetText)
    offset = zeros(1, frameCount);
    offsetSource = 'zero (offset absent)';
    notes{end+1} = 'No image offset provided; using zero.';
else
    offset = frameValues(numericParameter(offsetText, offsetSource), frameCount, offsetSource);
end
scaling = struct('applied', true, 'formula', 'data = double(rawData) .* slope + offset', ...
    'slope', slope, 'offset', offset, 'slopeSource', slopeSource, 'offsetSource', offsetSource);
end

function values = frameValues(values, count, name)
if isscalar(values)
    values = repmat(values, 1, count);
elseif numel(values) ~= count
    error('Bruker:InvalidScaling', '%s must contain one value or %g frame values.', name, count);
end
end
