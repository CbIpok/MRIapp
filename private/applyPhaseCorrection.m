function S_corr = applyPhaseCorrection(S, ph0_deg, ph1_deg, pivotIndex)
%APPLYPHASECORRECTION Apply zero- and first-order phase correction.
% Phase parameters may be scalars or spatial arrays matching size(S, 2:end).

N = size(S, 1);
if N < 1
    S_corr = S;
    return;
end

spatialSize = size(S);
spatialSize = spatialSize(2:end);
parameterShape = [1, spatialSize];

ph0_deg = reshapePhaseParameter(ph0_deg, spatialSize, parameterShape, 'PH0');
ph1_deg = reshapePhaseParameter(ph1_deg, spatialSize, parameterShape, 'PH1');
pivotIndex = reshapePhaseParameter(pivotIndex, spatialSize, parameterShape, 'pivot');
pivotIndex = max(1, min(N, round(pivotIndex)));

if N == 1
    g = zeros(parameterShape);
else
    pointShape = [N, ones(1, numel(spatialSize))];
    pointIndex = reshape((1:N)', pointShape);
    g = (pointIndex - pivotIndex) ./ (N - 1);
end

phi_rad = (ph0_deg + ph1_deg .* g) .* (pi / 180);
phaseVec = exp(1i * phi_rad);
S_corr = S .* phaseVec;
end

function value = reshapePhaseParameter(value, spatialSize, parameterShape, parameterName)
value = double(value);
if isempty(value) || any(~isfinite(value(:)))
    error('%s phase parameter must contain finite values.', parameterName);
end

if isscalar(value)
    return;
end

if numel(value) ~= prod(spatialSize)
    error('%s phase parameter must be scalar or match spectrum spatial dimensions.', parameterName);
end

value = reshape(value, parameterShape);
end
