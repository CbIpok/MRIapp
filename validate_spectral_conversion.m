spectrum4D = zeros(8, 2, 1, 1);
spectrum4D(:, 1, 1, 1) = (1:8).';
spectrum4D(:, 2, 1, 1) = 2 .* (1:8).';

definitions = struct( ...
    'name', {'A', 'B', 'C'}, ...
    'startIndex', {1, 3, 5}, ...
    'endIndex', {2, 4, 5}, ...
    'multiplier', {1, 0.5, 1}, ...
    'useNumerator', {true, true, false}, ...
    'useDenominator', {false, true, true});

[resultVolume, details] = buildSpectralConversionVolume(spectrum4D, definitions, struct());
[resultValue, valueDetails] = evaluateSpectralConversionValue(spectrum4D(:, 1, 1, 1), definitions, struct());

expectedVoxel1 = (3 + 0.5 * 7) / (0.5 * 7 + 5);
expectedVoxel2 = (6 + 0.5 * 14) / (0.5 * 14 + 10);

assert(abs(resultVolume(1, 1, 1) - expectedVoxel1) < 1e-12);
assert(abs(resultVolume(2, 1, 1) - expectedVoxel2) < 1e-12);
assert(abs(resultValue - expectedVoxel1) < 1e-12);
assert(abs(details.numerator(1, 1, 1) - (3 + 0.5 * 7)) < 1e-12);
assert(abs(valueDetails.denominatorValue - (0.5 * 7 + 5)) < 1e-12);

disp('spectral conversion ok');
