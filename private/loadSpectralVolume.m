function [integrated3D, spectrum4D, meta] = loadSpectralVolume(fullPath, dimX, dimY, dimZ)
%LOADSPECTRALVOLUME Load a CSI file as a 4D complex spectrum volume.
% The first dimension is the spectral axis, followed by X, Y, Z.
% The default 3D view is built by integrating abs(rawData) over spectra.

voxelCount = dimX * dimY * dimZ;
[readerType, bytesPerScalar, nSpecPoints] = detectSpectralLayout(fullPath, voxelCount);

fid = fopen(fullPath, 'rb');
if fid == -1
    error('Не удалось открыть спектральный файл.');
end

cleaner = onCleanup(@() fclose(fid));
raw = fread(fid, Inf, readerType);
expectedScalarCount = 2 * voxelCount * nSpecPoints;
if numel(raw) ~= expectedScalarCount
    error('Некорректный размер спектрального файла после чтения.');
end

raw = reshape(raw, 2, []);
complexData = complex(raw(1, :), raw(2, :));
timeDomain4D = reshape(complexData, [nSpecPoints, dimX, dimY, dimZ]);
spectrum4D = fft(timeDomain4D, [], 1);
integrated3D = squeeze(sum(abs(timeDomain4D), 1));

meta = struct( ...
    'readerType', readerType, ...
    'bytesPerScalar', bytesPerScalar, ...
    'spectralPoints', nSpecPoints, ...
    'spatialSize', [dimX, dimY, dimZ], ...
    'defaultIntegrationMode', 'sum(abs(timeDomain),1)', ...
    'defaultSpectralRange', [1, nSpecPoints]);
end

function [readerType, bytesPerScalar, nSpecPoints] = detectSpectralLayout(fullPath, voxelCount)
fileInfo = dir(fullPath);
if isempty(fileInfo)
    error('Файл не найден: %s', fullPath);
end

[~, ~, ext] = fileparts(fullPath);

if strcmpi(ext, '.ser')
    candidates = { ...
        'int32', 4; ...
        'double', 8; ...
        'single', 4};
else
    candidates = { ...
        'double', 8; ...
        'single', 4; ...
        'int32', 4};
end

for i = 1:size(candidates, 1)
    candidateType = candidates{i, 1};
    candidateBytes = candidates{i, 2};
    scalarCount = fileInfo.bytes / candidateBytes;
    complexCount = scalarCount / 2;
    specPoints = complexCount / voxelCount;

    if isfinite(specPoints) && specPoints >= 1 && abs(specPoints - round(specPoints)) < 1e-9
        readerType = candidateType;
        bytesPerScalar = candidateBytes;
        nSpecPoints = round(specPoints);
        return;
    end
end

error(['Не удалось автоматически определить формат 4D спектрального файла. ' ...
    'Проверьте X, Y, Z и тип входных данных.']);
end
