function array3D = normalizeVolumeForDisplay(arrayIn)
%NORMALIZEVOLUMEFORDISPLAY Treat 2D arrays as single-slice 3D volumes.

if ~(isnumeric(arrayIn) || islogical(arrayIn))
    error('Selected variable must be numeric or logical.');
end

if ndims(arrayIn) > 3
    error('Selected variable must be 2D or 3D.');
end

if ismatrix(arrayIn)
    array3D = reshape(arrayIn, size(arrayIn, 1), size(arrayIn, 2), 1);
else
    array3D = arrayIn;
end
end
