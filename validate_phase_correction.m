function validate_phase_correction()
S = exp(1i * linspace(0, pi, 64)).';
pivot = 20;

S0 = applyPhaseCorrection(S, 0, 0, pivot);
assert(max(abs(S0 - S)) < 1e-12, 'Zero phase correction should not change spectrum.');

S1 = applyPhaseCorrection(S, 15, 30, pivot);
assert(isequal(size(S1), size(S)), 'Output size mismatch.');

gPivot = (pivot - pivot) / (numel(S) - 1);
phiPivot = (15 + 30 * gPivot) * pi / 180;
assert(abs(angle(S1(pivot) / S(pivot)) - phiPivot) < 1e-10, 'Pivot phase mismatch.');

vol4D = repmat(reshape(S, [], 1, 1, 1), 1, 4, 3, 2);
meta = struct( ...
    'phaseEnabled', true, ...
    'phaseParams', struct('ph0Deg', 15, 'ph1Deg', 30, 'pivotIndex', pivot));
[vol3D, corrected] = buildIntegratedVolumeFromSpectrum(vol4D, 10:20, meta);
assert(isequal(size(vol3D), [4, 3, 2]), 'Integrated volume size mismatch.');
assert(isequal(size(corrected), size(vol4D)), 'Corrected spectrum size mismatch.');

disp('phase correction ok');
end
