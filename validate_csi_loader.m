function validate_csi_loader()
addpath('E:/matlab/CSI matlab soft');

[data_fft_ref, int_data_ref] = load_fid_data( ...
    'E:/matlab/CSI matlab soft/data/fid_proc.64', 1024, 8, 8, 16);

[varName, int_data_new, extras, meta] = loadVolumeForApp( ...
    'E:/matlab/CSI matlab soft/data/fid_proc.64', 8, 8, 16);

fprintf('var=%s\n', varName);
fprintf('integrated size: [%s]\n', num2str(size(int_data_new)));
fprintf('spectral size:   [%s]\n', num2str(size(extras.spectrum4D)));
fprintf('spectral points: %d\n', meta.spectralPoints);
fprintf('max integrated diff: %g\n', max(abs(int_data_ref(:) - int_data_new(:))));
fprintf('max fft diff:        %g\n', max(abs(data_fft_ref(:) - extras.spectrum4D(:))));
end
