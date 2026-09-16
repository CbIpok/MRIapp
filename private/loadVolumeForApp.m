function [varName, array3D, extras, meta] = loadVolumeForApp(fullPath, dimX, dimY, dimZ)
%LOADVOLUMEFORAPP Load either a plain 3D volume or a 4D CSI spectrum volume.

[~, fileName, ext] = fileparts(fullPath);
varName = matlab.lang.makeValidName(fileName);
ext = lower(ext);

if strcmpi([fileName ext], '2dseq')
    [array3D, meta, rawData] = readBruker2dseq(fullPath);
    extras = struct('rawData', rawData);
    meta.sourceKind = 'bruker2dseq';
    meta.workspaceVarName = varName;
    meta.rawVarName = [varName '__raw'];
    meta.metaVarName = [varName '__meta'];
    return;
end

switch ext
    case {'.64', '.ser'}
        [array3D, spectrum4D, spectralMeta] = loadSpectralVolume(fullPath, dimX, dimY, dimZ);
        extras = struct('spectrum4D', spectrum4D);
        meta = spectralMeta;
        meta.sourceKind = 'spectral4d';
        meta.originalPath = fullPath;
        meta.workspaceVarName = varName;
        meta.spectrumVarName = [varName '__spectrum4d'];
        meta.metaVarName = [varName '__meta'];

    otherwise
        array3D = loadPlain3DVolume(fullPath, dimX, dimY, dimZ);
        extras = struct();
        meta = struct( ...
            'sourceKind', 'plain3d', ...
            'originalPath', fullPath, ...
            'workspaceVarName', varName, ...
            'metaVarName', [varName '__meta']);
end
end

function array3D = loadPlain3DVolume(fullPath, dimX, dimY, dimZ)
expectedTotalElements = dimX * dimY * dimZ;

fid = fopen(fullPath, 'rb');
if fid == -1
    error('Не удалось открыть файл.');
end

cleaner = onCleanup(@() fclose(fid));
data = fread(fid, Inf, 'float');

if numel(data) ~= expectedTotalElements
    error(['Размер данных в файле (%d элементов) не соответствует ' ...
        'ожидаемому размеру (%d элементов).'], numel(data), expectedTotalElements);
end

array3D = reshape(data, [dimX, dimY, dimZ]);
end
