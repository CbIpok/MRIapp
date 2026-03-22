function S_corr = applyPhaseCorrection(S, ph0_deg, ph1_deg, pivotIndex)
%APPLYPHASECORRECTION Apply zero- and first-order phase correction.

N = size(S, 1);
if N < 1
    S_corr = S;
    return;
end

pivotIndex = max(1, min(N, round(pivotIndex)));

if N == 1
    g = 0;
else
    g = ((1:N)' - pivotIndex) ./ (N - 1);
end

phi_rad = (ph0_deg + ph1_deg .* g) .* (pi / 180);
phaseVec = exp(1i * phi_rad);
reshapeDims = [N, ones(1, ndims(S) - 1)];
S_corr = S .* reshape(phaseVec, reshapeDims);
end
