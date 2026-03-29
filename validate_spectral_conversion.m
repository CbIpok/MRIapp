spectrum4D = zeros(8, 2, 1, 1);
spectrum4D(:, 1, 1, 1) = (1:8).';
spectrum4D(:, 2, 1, 1) = 2 .* (1:8).';

definitions = struct( ...
    'name', {'A', 'B', 'C'}, ...
    'startIndex', {1, 3, 5}, ...
    'endIndex', {2, 4, 5}, ...
    'divisor', {1, 2, 4}, ...
    'useNumerator', {true, true, false}, ...
    'useDenominator', {false, true, true});

[resultVolume, details] = buildSpectralConversionVolume(spectrum4D, definitions, struct());
[resultValue, valueDetails] = evaluateSpectralConversionValue(spectrum4D(:, 1, 1, 1), definitions, struct());

expectedVoxel1 = (3 + 7 / 2) / (7 / 2 + 5 / 4);
expectedVoxel2 = (6 + 14 / 2) / (14 / 2 + 10 / 4);

assert(abs(resultVolume(1, 1, 1) - expectedVoxel1) < 1e-12);
assert(abs(resultVolume(2, 1, 1) - expectedVoxel2) < 1e-12);
assert(abs(resultValue - expectedVoxel1) < 1e-12);
assert(abs(details.numerator(1, 1, 1) - (3 + 7 / 2)) < 1e-12);
assert(abs(valueDetails.denominatorValue - (7 / 2 + 5 / 4)) < 1e-12);

disp('spectral conversion ok');
