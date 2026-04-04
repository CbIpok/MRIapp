function saveVolumeAsRawFloat(volume3D, defaultFileName)
%SAVEVOLUMEASRAWFLOAT Save a 3D volume in the plain float format used by the app.

volume3D = normalizeVolumeForDisplay(volume3D);

if nargin < 2 || isempty(defaultFileName)
    defaultFileName = 'conversion_volume.bin';
end

[fileName, pathName] = uiputfile( ...
    {'*.bin', 'Binary float volume (*.bin)'; ...
     '*.dat', 'Binary float volume (*.dat)'; ...
     '*.*', 'All files (*.*)'}, ...
    'Save conversion volume', defaultFileName);

if isequal(fileName, 0)
    return;
end

fullPath = fullfile(pathName, fileName);
fid = fopen(fullPath, 'wb');
if fid == -1
    error('Unable to open file for writing: %s', fullPath);
end

cleaner = onCleanup(@() fclose(fid));
count = fwrite(fid, single(volume3D), 'float');

if count ~= numel(volume3D)
    error('Failed to write the full conversion volume to disk.');
end
end
