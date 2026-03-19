function integrated3D = integrateSpectralRange(spectrum4D, idxRange)
%INTEGRATESPECTRALRANGE Integrate a selected spectral range into a 3D volume.

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

integrated3D = squeeze(sum(abs(spectrum4D(idxRange, :, :, :)), 1));
end
