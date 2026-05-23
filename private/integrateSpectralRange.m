function integrated3D = integrateSpectralRange(spectrum4D, idxRange, valueMode)
%INTEGRATESPECTRALRANGE Integrate a selected spectral range into a 3D volume.

if nargin < 3 || isempty(valueMode)
    valueMode = 'abs';
end

if isempty(idxRange)
    error('Диапазон интегрирования пуст.');
end

nSpec = size(spectrum4D, 1);
idxRange = round(idxRange(:)');
idxRange = idxRange(~isnan(idxRange));
idxRange = idxRange(idxRange >= 1 & idxRange <= nSpec);

if isempty(idxRange)
    error('Диапазон интегрирования вне границ спектра.');
end

selectedSpectrum = spectrum4D(idxRange, :, :, :);
switch lower(char(string(valueMode)))
    case 'abs'
        scalarData = abs(selectedSpectrum);
    case {'re', 'real'}
        scalarData = real(selectedSpectrum);
    otherwise
        error('Unsupported spectral value mode: %s', char(string(valueMode)));
end

integrated3D = squeeze(sum(scalarData, 1));
end
