function validate_spectral_interaction_backend()
[varName, array3D, extras, meta] = loadVolumeForApp( ...
    'E:/matlab/CSI matlab soft/data/fid_proc.64', 8, 8, 16);

assignin('base', varName, array3D);
assignin('base', meta.metaVarName, meta);
assignin('base', meta.spectrumVarName, extras.spectrum4D);

info = getSpectralDatasetInfo(varName);
assert(info.isSpectral, 'Dataset should be spectral.');

rangeVolume = integrateSpectralRange(info.spectrum4D, 100:140);
assert(isequal(size(rangeVolume), [8, 8, 16]), 'Unexpected integrated volume size.');

fig = openFigureForTest(info); %#ok<NASGU>
pause(0.5);
close(findall(groot, 'Type', 'figure'));
disp('spectral interaction backend ok');
end

function fig = openFigureForTest(info)
openSpectralInteractionFigure(info);
figs = findall(groot, 'Type', 'figure');
fig = figs(1);
end
