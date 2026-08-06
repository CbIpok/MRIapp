function [params, info] = autoPhaseSpectrum(spectrum, algorithm, initialParams)
%AUTOPHASESPECTRUM Estimate PH0/PH1 for one complex spectrum.

spectrum = reshape(spectrum, [], 1);
nSpec = numel(spectrum);
initialParams = normalizeInitialParams(initialParams, nSpec);
params = initialParams;

info = struct( ...
    'success', false, ...
    'algorithm', normalizeAlgorithm(algorithm), ...
    'initialScore', NaN, ...
    'finalScore', NaN, ...
    'exitFlag', NaN, ...
    'iterations', 0, ...
    'reason', 'Optimization was not started.');

if nSpec < 3 || any(~isfinite(real(spectrum))) || any(~isfinite(imag(spectrum)))
    info.reason = 'Spectrum is too short or contains non-finite values.';
    return;
end

amplitude = max(abs(spectrum));
if ~isfinite(amplitude) || amplitude <= eps
    info.reason = 'Spectrum has no measurable signal.';
    return;
end
spectrum = spectrum ./ amplitude;

[~, pivotIndex] = max(abs(spectrum));
seedPh0 = initialParams.ph0Deg + initialParams.ph1Deg .* ...
    (pivotIndex - initialParams.pivotIndex) ./ (nSpec - 1);
seed = [seedPh0, initialParams.ph1Deg];

switch info.algorithm
    case 'acme'
        objective = @(phaseValues) acmeScore(phaseValues, spectrum, pivotIndex);
    case 'peak_minima'
        peakWidth = max(1, min(100, floor((nSpec - 1) / 2)));
        objective = @(phaseValues) peakMinimaScore( ...
            phaseValues, spectrum, pivotIndex, peakWidth);
    otherwise
        error('Unsupported automatic phase algorithm: %s', info.algorithm);
end

try
    info.initialScore = objective(seed);
    options = optimset( ...
        'Display', 'off', ...
        'MaxIter', 2000, ...
        'MaxFunEvals', 4000, ...
        'TolX', 1e-3, ...
        'TolFun', 1e-8);
    [optimized, finalScore, exitFlag, output] = fminsearch(objective, seed, options);

    info.finalScore = finalScore;
    info.exitFlag = exitFlag;
    info.iterations = output.iterations;

    scoreTolerance = 1e-10 * max(1, abs(info.initialScore));
    isUsable = exitFlag > 0 && all(isfinite(optimized)) && isfinite(finalScore) ...
        && isfinite(info.initialScore) && finalScore <= info.initialScore + scoreTolerance;
    if ~isUsable
        info.reason = 'Optimizer did not converge to a finite improved solution.';
        return;
    end

    params = struct( ...
        'ph0Deg', optimized(1), ...
        'ph1Deg', optimized(2), ...
        'pivotIndex', pivotIndex);
    info.success = true;
    info.reason = '';
catch ME
    info.reason = ME.message;
end
end

function score = acmeScore(phaseValues, spectrum, pivotIndex)
corrected = applyPhaseCorrection( ...
    spectrum, phaseValues(1), phaseValues(2), pivotIndex);
realSpectrum = real(corrected);

firstDerivative = abs(diff(realSpectrum) ./ 2);
derivativeSum = sum(firstDerivative);
if derivativeSum > eps
    probabilities = firstDerivative ./ derivativeSum;
    probabilities = probabilities(probabilities > 0);
    entropyValue = -sum(probabilities .* log(probabilities));
else
    entropyValue = 0;
end

negativeValues = min(realSpectrum, 0);
negativePenalty = sum(negativeValues .^ 2);
positiveMaximum = max(realSpectrum);
if ~isfinite(positiveMaximum) || positiveMaximum <= eps
    score = realmax('double');
    return;
end

score = (entropyValue + 1000 .* negativePenalty) ./ ...
    (numel(realSpectrum) .* positiveMaximum);
if ~isfinite(score)
    score = realmax('double');
end
end

function score = peakMinimaScore(phaseValues, spectrum, pivotIndex, peakWidth)
corrected = applyPhaseCorrection( ...
    spectrum, phaseValues(1), phaseValues(2), pivotIndex);
realSpectrum = real(corrected);
[~, peakIndex] = max(realSpectrum);

leftIndices = max(1, peakIndex - peakWidth):(peakIndex - 1);
rightIndices = (peakIndex + 1):min(numel(realSpectrum), peakIndex + peakWidth);
if isempty(leftIndices) || isempty(rightIndices)
    score = realmax('double');
    return;
end

leftMinimum = min(realSpectrum(leftIndices));
rightMinimum = min(realSpectrum(rightIndices));
score = abs(leftMinimum - rightMinimum);
if ~isfinite(score)
    score = realmax('double');
end
end

function initialParams = normalizeInitialParams(initialParams, nSpec)
if nargin < 1 || ~isstruct(initialParams)
    initialParams = struct();
end

initialParams = struct( ...
    'ph0Deg', getFiniteScalar(initialParams, 'ph0Deg', 0), ...
    'ph1Deg', getFiniteScalar(initialParams, 'ph1Deg', 0), ...
    'pivotIndex', getFiniteScalar(initialParams, 'pivotIndex', round(nSpec / 2)));
initialParams.pivotIndex = max(1, min(max(1, nSpec), round(initialParams.pivotIndex)));
end

function value = getFiniteScalar(source, fieldName, defaultValue)
value = defaultValue;
if isfield(source, fieldName)
    candidate = double(source.(fieldName));
    if isscalar(candidate) && isfinite(candidate)
        value = candidate;
    end
end
end

function algorithm = normalizeAlgorithm(value)
algorithm = lower(strtrim(char(string(value))));
algorithm = strrep(algorithm, ' ', '_');
switch algorithm
    case 'acme'
        algorithm = 'acme';
    case {'peak_minima', 'peakminima'}
        algorithm = 'peak_minima';
    otherwise
        error('Automatic phase algorithm must be ACME or Peak minima.');
end
end
