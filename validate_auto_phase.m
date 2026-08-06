function validate_auto_phase()
nSpec = 256;
pointIndex = (1:nSpec).';
firstPeak = 1 ./ (1 + 1i .* ((pointIndex - 70) ./ 5));
secondPeak = 1 ./ (1 + 1i .* ((pointIndex - 170) ./ 8));

absorptive = zeros(nSpec, 2, 1, 1);
absorptive(:, 1, 1, 1) = firstPeak + 0.55 .* secondPeak;
absorptive(:, 2, 1, 1) = 0.45 .* firstPeak + secondPeak;

truePh0 = reshape([35, 22], [2, 1, 1]);
truePh1 = reshape([55, 38], [2, 1, 1]);
truePivot = reshape([70, 170], [2, 1, 1]);
observed = applyPhaseCorrection(absorptive, -truePh0, -truePh1, truePivot);

initialParams = struct('ph0Deg', 30, 'ph1Deg', 45, 'pivotIndex', 70);
[acmeMaps, acmeSummary] = autoPhaseVolume(observed, 'acme', initialParams);
assert(acmeSummary.successCount == 2, 'ACME should converge for both synthetic voxels.');
assert(isequal(size(acmeMaps.ph0Deg), [2, 1]), 'Unexpected ACME phase-map size.');

acmeCorrected = applyPhaseCorrection( ...
    observed, acmeMaps.ph0Deg, acmeMaps.ph1Deg, acmeMaps.pivotIndex);
initialCorrected = applyPhaseCorrection( ...
    observed, initialParams.ph0Deg, initialParams.ph1Deg, initialParams.pivotIndex);
assert(norm(real(acmeCorrected(:)) - real(absorptive(:))) < ...
    norm(real(initialCorrected(:)) - real(absorptive(:))), ...
    'ACME did not improve the absorptive real spectrum.');
assert(sum(min(real(acmeCorrected(:)), 0) .^ 2) <= ...
    sum(min(real(initialCorrected(:)), 0) .^ 2), ...
    'ACME did not reduce negative real signal.');
assert(acmeMaps.pivotIndex(1) == 70 && acmeMaps.pivotIndex(2) == 170, ...
    'Automatic pivot should follow the strongest peak in each voxel.');

[peakParams, peakInfo] = autoPhaseSpectrum( ...
    observed(:, 1, 1, 1), 'peak_minima', initialParams);
assert(peakInfo.success, 'Peak-minima optimization should converge on a simple spectrum.');
assert(all(isfinite([peakParams.ph0Deg, peakParams.ph1Deg, peakParams.pivotIndex])), ...
    'Peak-minima parameters must be finite.');

zeroSpectrum = zeros(nSpec, 1);
[fallbackParams, fallbackInfo] = autoPhaseSpectrum( ...
    zeroSpectrum, 'acme', initialParams);
assert(~fallbackInfo.success, 'Empty spectrum should use fallback parameters.');
assert(isequal(fallbackParams, initialParams), ...
    'Failed automatic phase must retain the manual initial parameters.');

disp('automatic phase correction ok');
end
