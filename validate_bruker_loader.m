function validate_bruker_loader(samplePath)
%VALIDATE_BRUKER_LOADER Synthetic fixtures plus optional real reconstruction.
% Run from the project root. Test data is created only in a temporary folder.
testFolder = tempname;
mkdir(testFolder);
cleanup = onCleanup(@() removeTestFolder(testFolder));
filename = fullfile(testFolder, '2dseq');

% Non-square, asymmetric frames prove row/column and frame order, signedness,
% big endian, per-frame scaling, and Visu priority over conflicting RECO.
raw = int16([-4, 7, 300; 1000, -200, 15]);
raw(:, :, 2) = int16([11, 22, 33; -44, 55, 66]);
visu = sprintf(['##$VisuCoreDim=2\n##$VisuCoreSize=( 2 )\n3 2\n' ...
    '##$VisuCoreFrameCount=2\n##$VisuCoreWordType=_16BIT_SGN_INT\n' ...
    '##$VisuCoreByteOrder=bigEndian\n##$VisuCoreDataSlope=( 2 )\n2 4\n' ...
    '$$ comment must not be parsed as a value\n##$VisuCoreDataOffs=( 2 )\n10 -3\n']);
reco = sprintf(['##$RECO_size=( 2 )\n8 9\n##$RECO_wordtype=_32BIT_FLOAT\n' ...
    '##$RECO_byte_order=littleEndian\n##$RECO_map_slope=0.1\n##$RECO_map_offset=99\n']);
writeFixture(filename, raw, 'int16', 'ieee-be', visu, reco);
[data, meta, decoded] = readBruker2dseq(filename);
assert(isequal(decoded, raw) && isa(decoded, 'int16'), 'Incorrect raw orientation/type.');
expected = double(raw) .* reshape([2 4], 1, 1, 2) + reshape([10 -3], 1, 1, 2);
assert(isequal(data, expected) && isequal(size(data), [2 3 2]));
assert(strcmp(meta.sizeSource, 'VisuCoreSize') && meta.scaling.applied);
assert(strcmp(meta.typeSource, 'VisuCoreWordType'));
assert(strcmp(meta.endianSource, 'VisuCoreByteOrder'));
assert(isequal(data(:, :, 1), [-4 7 300; 1000 -200 15] * 2 + 10));

% The existing dispatcher must ignore manually entered dimensions for 2dseq.
[~, appData, extras, appMeta] = loadVolumeForApp(filename, 99, 98, 97);
assert(isequal(appData, expected) && isequal(extras.rawData, raw));
assert(strcmp(appMeta.sourceKind, 'bruker2dseq') && isfield(appMeta, 'rawVarName'));
validateAppIntegration(filename, raw, expected);

% Missing reco, scalar slope broadcast, compressed JCAMP and D exponents.
visuScalar = strrep(visu, sprintf('2 4\n'), sprintf('@2*(2D0)\n'));
writeFixture(filename, raw, 'int16', 'ieee-be', visuScalar, '');
[data, meta] = readBruker2dseq(filename);
assert(~meta.hasReco && isequal(data, double(raw) .* 2 + reshape([10 -3], 1, 1, 2)));

% RECO-only: aliases/case, inferred frames, inverse (not multiplicative)
% mapping with a NONZERO offset, and unsigned 16-bit values above 32767.
unsignedRaw = uint16([0 40000 65535; 100 200 300]);
unsignedRaw(:, :, 2) = uint16([8 9 10; 11 12 13]);
recoOnly = sprintf(['##$reco_SIZE=( 2 )\n3 2\n##$RECO_word_type=_16BIT_UNSGN_INT\n' ...
    '##$RECO_byte_order=<littleEndian>\n##$RECO_map_slope=( 2 )\n0.5 0.25\n' ...
    '##$RECO_map_offset=( 2 )\n7 -9\n']);
writeFixture(filename, unsignedRaw, 'uint16', 'ieee-le', '', recoOnly);
[data, meta, decoded] = readBruker2dseq(filename);
assert(isequal(decoded, unsignedRaw) && meta.frameCount == 2 && ~meta.hasVisuPars);
assert(isequal(data, double(unsignedRaw) .* reshape([2 4], 1, 1, 2) + reshape([7 -9], 1, 1, 2)));

% Per-field fallback: partial Visu metadata plus a complete RECO record.
partialVisu = sprintf('##$VisuCoreSize=( 2 )\n3 2\n##$VisuCoreFrameCount=2\n');
writeFixture(filename, unsignedRaw, 'uint16', 'ieee-le', partialVisu, recoOnly);
[dataPartial, meta] = readBruker2dseq(filename);
assert(isequal(dataPartial, data) && strcmp(meta.typeSource, 'RECO_wordtype'));
writeFixture(filename, unsignedRaw, 'uint16', 'ieee-le', '', ...
    [recoOnly sprintf('##$RECO_transposition=1\n')]);
assertError(@() readBruker2dseq(filename), 'Bruker:UnsupportedOrientation');

% Missing float scaling uses an explicit, recorded identity/zero fallback.
floatHeader = sprintf(['##$VisuCoreSize=( 2 )\n3 2\n##$VisuCoreFrameCount=1\n' ...
    '##$VisuCoreWordType=_32BIT_FLOAT\n##$VisuCoreByteOrder=littleEndian\n']);
floatRaw = single([1.25 2.5 3.75; -4.25 5.5 6.75]);
writeFixture(filename, floatRaw, 'single', 'ieee-le', floatHeader, '');
[floatData, floatMeta] = readBruker2dseq(filename);
assert(isequal(floatData, double(floatRaw)) && ~isempty(floatMeta.notes));

% Every supported word type, endian, one row/column and a single plane.
types = {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'single', 'double'};
words = {'_8BIT_SGN_INT', '_8BIT_UNSGN_INT', '_16BIT_SGN_INT', '_16BIT_UNSGN_INT', ...
    '_32BIT_SGN_INT', '_32BIT_UNSGN_INT', '_32BIT_FLOAT', '_64BIT_FLOAT'};
for k = 1:numel(types)
    smallRaw = cast([1; 2; 3], types{k});
    if startsWith(types{k}, 'int'), smallRaw(1) = -1; end
    if ismember(types{k}, {'single', 'double'}), smallRaw(2) = 2.5; end
    for byteOrder = {'littleEndian', 'bigEndian'}
        endian = 'ieee-le';
        if strcmp(byteOrder{1}, 'bigEndian'), endian = 'ieee-be'; end
        header = sprintf(['##$VisuCoreSize=( 2 )\n1 3\n##$VisuCoreFrameCount=1\n' ...
            '##$VisuCoreWordType=%s\n##$VisuCoreByteOrder=%s\n' ...
            '##$VisuCoreDataSlope=2\n##$VisuCoreDataOffs=1\n'], words{k}, byteOrder{1});
        writeFixture(filename, smallRaw, types{k}, endian, header, '');
        [data, ~, decoded] = readBruker2dseq(filename);
        assert(isequal(size(data), [3 1]) && isequal(decoded, smallRaw));
        assert(isequal(data, double(smallRaw) * 2 + 1));
    end
end

% 3D core frames flatten z first, then frames; scaling is per core frame.
volumeRaw = reshape(int16(1:24), 2, 3, 4);
header3D = sprintf(['##$VisuCoreDim=3\n##$VisuCoreSize=( 3 )\n3 2 2\n' ...
    '##$VisuCoreFrameCount=2\n##$VisuCoreWordType=_16BIT_SGN_INT\n' ...
    '##$VisuCoreByteOrder=littleEndian\n##$VisuCoreDataSlope=( 2 )\n2 3\n' ...
    '##$VisuCoreDataOffs=0\n']);
writeFixture(filename, volumeRaw, 'int16', 'ieee-le', header3D, '');
[data, meta, decoded] = readBruker2dseq(filename);
assert(isequal(decoded, volumeRaw) && meta.planeCount == 4);
assert(isequal(data, double(volumeRaw) .* reshape([2 2 3 3], 1, 1, 4)));

% Explicit failures must never silently reinterpret invalid metadata.
assertError(@() readBruker2dseq(fullfile(testFolder, 'missing')), 'Bruker:MissingData');
writeFixture(filename, raw, 'int16', 'ieee-be', '', '');
assertError(@() readBruker2dseq(filename), 'Bruker:MissingMetadata');
badHeaders = { ...
    strrep(visu, '3 2', '3 0'), 'Bruker:InvalidDimensions'; ...
    strrep(visu, '3 2', '3'), 'Bruker:InvalidMetadata'; ...
    strrep(visu, 'VisuCoreSize', 'UnknownSize'), 'Bruker:MissingParameter'; ...
    strrep(visu, '_16BIT_SGN_INT', '_12BIT_INT'), 'Bruker:UnsupportedDataType'; ...
    strrep(visu, 'VisuCoreWordType', 'UnknownWordType'), 'Bruker:MissingParameter'; ...
    strrep(visu, 'bigEndian', 'unknownEndian'), 'Bruker:UnsupportedEndian'; ...
    strrep(visu, 'VisuCoreByteOrder', 'UnknownByteOrder'), 'Bruker:MissingParameter'; ...
    strrep(visu, 'VisuCoreFrameCount=2', 'VisuCoreFrameCount=3'), 'Bruker:SizeMismatch'; ...
    strrep(visu, 'VisuCoreDataSlope', 'UnknownSlope'), 'Bruker:MissingScaling'; ...
    strrep(visu, sprintf('2 4\n'), sprintf('0 4\n')), 'Bruker:InvalidScaling'; ...
    strrep(visu, sprintf('2 4\n'), sprintf('2+3i 4\n')), 'Bruker:InvalidMetadata'; ...
    strrep(visu, sprintf('( 2 )\n2 4'), sprintf('( 3 )\n2 4 6')), 'Bruker:InvalidScaling'; ...
    [visu sprintf('##$VisuCoreTransposition=1\n')], 'Bruker:UnsupportedOrientation'};
for k = 1:size(badHeaders, 1)
    writeFixture(filename, raw, 'int16', 'ieee-be', badHeaders{k, 1}, '');
    assertError(@() readBruker2dseq(filename), badHeaders{k, 2});
end
writeFixture(filename, raw, 'int16', 'ieee-be', visu, '');
fid = fopen(filename, 'ab'); fwrite(fid, uint8(1), 'uint8'); fclose(fid);
assertError(@() readBruker2dseq(filename), 'Bruker:SizeMismatch');
writeFixture(filename, raw(:, :, 1), 'int16', 'ieee-be', visu, '');
assertError(@() readBruker2dseq(filename), 'Bruker:SizeMismatch');

% Existing formats keep their original binary interpretation and axes.
plainPath = fullfile(testFolder, 'plain.bin');
plain = reshape(single(1:24), 3, 4, 2);
fid = fopen(plainPath, 'wb'); fwrite(fid, plain, 'float'); fclose(fid);
[~, plainData, plainExtras, plainMeta] = loadVolumeForApp(plainPath, 3, 4, 2);
assert(isequal(plainData, double(plain)) && isempty(fieldnames(plainExtras)));
assert(strcmp(plainMeta.sourceKind, 'plain3d'));
for extension = {'.64', '.ser'}
    spectralPath = fullfile(testFolder, ['spectrum' extension{1}]);
    timeDomain = reshape(complex(1:48, 49:96), 8, 3, 2);
    interleaved = [real(timeDomain(:)).'; imag(timeDomain(:)).'];
    storageType = 'double';
    if strcmp(extension{1}, '.ser'), storageType = 'int32'; end
    fid = fopen(spectralPath, 'wb'); fwrite(fid, interleaved, storageType); fclose(fid);
    [~, volume, spectralExtras, spectralMeta] = loadVolumeForApp(spectralPath, 3, 2, 1);
    assert(isequal(volume, squeeze(sum(abs(timeDomain), 1))));
    assert(isequal(spectralExtras.spectrum4D, fft(timeDomain, [], 1)));
    assert(strcmp(spectralMeta.sourceKind, 'spectral4d'));
end

if nargin > 0 && ~isempty(samplePath)
    [sampleData, sampleMeta, sampleRaw] = readBruker2dseq(samplePath);
    info = dir(samplePath);
    assert(info.bytes == 8192 && numel(sampleRaw) == 4096);
    assert(isequal(size(sampleData), [64 64]) && isa(sampleRaw, 'int16'));
    assert(sampleMeta.frameCount == 1 && strcmp(sampleMeta.machineFormat, 'ieee-le'));
    assert(min(sampleRaw(:)) == 362 && max(sampleRaw(:)) == 32765);
    fid = fopen(samplePath, 'rb', 'ieee-le');
    referenceRaw = reshape(fread(fid, 4096, 'int16=>double'), 64, 64).';
    fclose(fid);
    assert(isequal(double(sampleRaw), referenceRaw));
    assert(max(abs(sampleData(:) - referenceRaw(:) * 131.28231291914)) < 1e-8);
    fprintf('Real sample: %d bytes, %d elements, [%s], raw %g..%g, scaled %.10g..%.10g\n', ...
        info.bytes, numel(sampleRaw), num2str(size(sampleData)), ...
        min(sampleRaw(:)), max(sampleRaw(:)), min(sampleData(:)), max(sampleData(:)));
    % Compare actual reconstruction-only fallback with authoritative Visu.
    copyfile(samplePath, filename);
    copyfile(fullfile(fileparts(samplePath), 'reco'), fullfile(testFolder, 'reco'));
    delete(fullfile(testFolder, 'visu_pars'));
    recoData = readBruker2dseq(filename);
    assert(max(abs(recoData(:) - sampleData(:))) < 1e-7, 'Real RECO fallback differs from Visu scaling.');
end
disp('Bruker loader, orientation, scaling, fallbacks and legacy formats ok');
end

function writeFixture(filename, raw, dataType, endian, visu, reco)
fid = fopen(filename, 'wb', endian);
assert(fid >= 0);
fwrite(fid, permute(raw, [2 1 3]), dataType);
fclose(fid);
writeHeader(fullfile(fileparts(filename), 'visu_pars'), visu);
writeHeader(fullfile(fileparts(filename), 'reco'), reco);
end

function writeHeader(filename, text)
if isempty(text)
    if isfile(filename), delete(filename); end
    return;
end
fid = fopen(filename, 'wt');
assert(fid >= 0);
fprintf(fid, '%s', text);
fclose(fid);
end

function assertError(callback, expectedId)
try
    callback();
catch exception
    assert(strcmp(exception.identifier, expectedId), ...
        'Expected %s, got %s: %s', expectedId, exception.identifier, exception.message);
    return;
end
error('Expected error %s was not raised.', expectedId);
end

function validateAppIntegration(filename, raw, expected)
% Exercise the real callback and display with only the modal picker stubbed.
mockFolder = fullfile(fileparts(filename), 'file_picker_stub');
mkdir(mockFolder);
mockPath = strrep(fileparts(filename), '''', '''''');
stub = sprintf(['function [fileName, pathName] = uigetfile(varargin)\n' ...
    'fileName = ''2dseq''; pathName = ''%s'';\nend\n'], mockPath);
writeHeader(fullfile(mockFolder, 'uigetfile.m'), stub);
oldPath = path;
oldVisibility = get(groot, 'defaultFigureVisible');
oldFigures = findall(groot, 'Type', 'figure');
oldNames = evalin('base', 'who');
cleanup = onCleanup(@() cleanupAppTest(oldPath, oldVisibility, oldFigures, oldNames));
addpath(mockFolder, '-begin');
set(groot, 'defaultFigureVisible', 'off');
fig = uifigure('Visible', 'off');
listBox = uilistbox(fig, 'Items', {}, 'Multiselect', 'on');
manualSize = struct('Value', 999);
openFileCallback(manualSize, manualSize, manualSize, listBox);
openFileCallback(manualSize, manualSize, manualSize, listBox);
assert(numel(listBox.Items) == 2);
firstName = parseVolumeListItem(listBox.Items{1});
secondName = parseVolumeListItem(listBox.Items{2});
assert(~strcmp(firstName, secondName), 'Loading another 2dseq overwrote the first.');
for name = {firstName, secondName}
    meta = evalin('base', [name{1} '__meta']);
    assert(isequal(evalin('base', name{1}), expected));
    assert(isequal(evalin('base', meta.rawVarName), raw));
    assert(strcmp(meta.workspaceVarName, name{1}));
end
listBox.Value = listBox.Items(1);
assert(~isSpectralListSelection(listBox.Value), 'Bruker images must not enable CSI processing.');
displaySelectedCallback(listBox, []);
displayFigure = findall(groot, 'Type', 'figure', 'Name', sprintf('Срезы: %s', firstName));
images = findall(displayFigure, 'Type', 'image');
assert(numel(images) == 2, 'Expected one image per Bruker frame.');
shownData = {images.CData};
assert(any(cellfun(@(x) isequal(x, expected(:, :, 1)), shownData)));
assert(any(cellfun(@(x) isequal(x, expected(:, :, 2)), shownData)));
disp('Bruker file callback, workspace storage and slice display ok');
end

function cleanupAppTest(oldPath, oldVisibility, oldFigures, oldNames)
path(oldPath);
set(groot, 'defaultFigureVisible', oldVisibility);
newFigures = setdiff(findall(groot, 'Type', 'figure'), oldFigures);
delete(newFigures);
newNames = setdiff(evalin('base', 'who'), oldNames);
for k = 1:numel(newNames)
    evalin('base', ['clear ' newNames{k}]);
end
end

function removeTestFolder(folder)
% Only remove the exact temporary directory created by this test.
if isfolder(folder) && startsWith(folder, tempdir)
    rmdir(folder, 's');
end
end
