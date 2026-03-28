function openPhaseCorrectionFigure(info, currentVoxel, activeRange, onSaveCallback)
%OPENPHASECORRECTIONFIGURE Open a separate phase-correction window.

if nargin < 4
    onSaveCallback = [];
end

spectrum4D = info.spectrum4D;
meta = info.meta;
nSpec = size(spectrum4D, 1);

if nargin < 2 || isempty(currentVoxel)
    currentVoxel = [1, 1, 1];
end
if nargin < 3 || isempty(activeRange)
    activeRange = [1, nSpec];
end

voxelX = currentVoxel(1);
voxelY = currentVoxel(2);
voxelZ = currentVoxel(3);

if isfield(meta, 'phaseParams') && isstruct(meta.phaseParams)
    ph0Deg = meta.phaseParams.ph0Deg;
    ph1Deg = meta.phaseParams.ph1Deg;
    pivotIndex = meta.phaseParams.pivotIndex;
else
    ph0Deg = 0;
    ph1Deg = 0;
    pivotIndex = round(nSpec / 2);
end

if isfield(meta, 'phaseUiRanges') && isstruct(meta.phaseUiRanges)
    ph0Limits = normalizeSliderLimits(meta.phaseUiRanges.ph0, [-360, 360]);
    ph1Limits = normalizeSliderLimits(meta.phaseUiRanges.ph1, [-720, 720]);
else
    ph0Limits = [-360, 360];
    ph1Limits = [-720, 720];
end

ph0Deg = clampToLimits(ph0Deg, ph0Limits);
ph1Deg = clampToLimits(ph1Deg, ph1Limits);

setPivotFromClick = false;

fig = uifigure('Name', ['Phase correction: ' info.varName], 'Position', [120 120 1180 720]);
movegui(fig, 'center');

specAxes = uiaxes(fig, 'Position', [260 90 890 600]);
leftPanel = uipanel(fig, 'Title', 'Phase Controls', 'Position', [15 90 225 600]);

uilabel(leftPanel, 'Position', [15 548 70 22], 'Text', 'PH0 (deg)');
ph0Field = uieditfield(leftPanel, 'numeric', 'Position', [95 548 100 22], ...
    'Value', ph0Deg, 'ValueChangedFcn', @(~, ~) onPh0FieldChanged());
ph0Slider = uislider(leftPanel, 'Position', [15 528 180 3], 'Limits', ph0Limits, ...
    'Value', ph0Deg, 'ValueChangedFcn', @(~, ~) onPh0SliderChanged());
uilabel(leftPanel, 'Position', [15 496 28 18], 'Text', 'Min');
ph0MinField = uieditfield(leftPanel, 'numeric', 'Position', [45 494 55 22], ...
    'Value', ph0Limits(1), 'ValueChangedFcn', @(~, ~) onPh0RangeChanged());
uilabel(leftPanel, 'Position', [112 496 28 18], 'Text', 'Max');
ph0MaxField = uieditfield(leftPanel, 'numeric', 'Position', [140 494 55 22], ...
    'Value', ph0Limits(2), 'ValueChangedFcn', @(~, ~) onPh0RangeChanged());

uilabel(leftPanel, 'Position', [15 448 70 22], 'Text', 'PH1 (deg)');
ph1Field = uieditfield(leftPanel, 'numeric', 'Position', [95 448 100 22], ...
    'Value', ph1Deg, 'ValueChangedFcn', @(~, ~) onPh1FieldChanged());
ph1Slider = uislider(leftPanel, 'Position', [15 428 180 3], 'Limits', ph1Limits, ...
    'Value', ph1Deg, 'ValueChangedFcn', @(~, ~) onPh1SliderChanged());
uilabel(leftPanel, 'Position', [15 396 28 18], 'Text', 'Min');
ph1MinField = uieditfield(leftPanel, 'numeric', 'Position', [45 394 55 22], ...
    'Value', ph1Limits(1), 'ValueChangedFcn', @(~, ~) onPh1RangeChanged());
uilabel(leftPanel, 'Position', [112 396 28 18], 'Text', 'Max');
ph1MaxField = uieditfield(leftPanel, 'numeric', 'Position', [140 394 55 22], ...
    'Value', ph1Limits(2), 'ValueChangedFcn', @(~, ~) onPh1RangeChanged());

uilabel(leftPanel, 'Position', [15 340 75 22], 'Text', 'Pivot idx');
pivotField = uieditfield(leftPanel, 'numeric', 'Position', [95 340 100 22], ...
    'Limits', [1, nSpec], 'RoundFractionalValues', true, ...
    'Value', pivotIndex, 'ValueChangedFcn', @(~, ~) onPivotFieldChanged());

uibutton(leftPanel, 'push', 'Position', [15 292 180 32], ...
    'Text', 'Set Pivot from Click', 'ButtonPushedFcn', @(~, ~) onSetPivotFromClick());

showImagCheck = uicheckbox(leftPanel, 'Position', [15 248 180 22], ...
    'Text', 'Show imaginary', 'Value', true, 'ValueChangedFcn', @(~, ~) updatePlot());

showOriginalCheck = uicheckbox(leftPanel, 'Position', [15 220 180 22], ...
    'Text', 'Show original', 'Value', true, 'ValueChangedFcn', @(~, ~) updatePlot());

showPivotCheck = uicheckbox(leftPanel, 'Position', [15 192 180 22], ...
    'Text', 'Show pivot marker', 'Value', true, 'ValueChangedFcn', @(~, ~) updatePlot());

uibutton(leftPanel, 'push', 'Position', [15 138 180 34], ...
    'Text', 'Save phase params', 'ButtonPushedFcn', @(~, ~) onSavePhase());

uibutton(leftPanel, 'push', 'Position', [15 94 180 34], ...
    'Text', 'Reset phase', 'ButtonPushedFcn', @(~, ~) onResetPhase());

statusLabel = uilabel(fig, 'Position', [15 20 1130 22], ...
    'Text', sprintf('Voxel (%d, %d, %d), integration range [%d, %d].', ...
    voxelX, voxelY, voxelZ, activeRange(1), activeRange(2)));

updatePlot();

    function onPh0FieldChanged()
        ph0Deg = clampToLimits(ph0Field.Value, ph0Slider.Limits);
        ph0Field.Value = ph0Deg;
        ph0Slider.Value = ph0Deg;
        updatePlot();
    end

    function onPh0SliderChanged()
        ph0Deg = ph0Slider.Value;
        ph0Field.Value = ph0Deg;
        updatePlot();
    end

    function onPh0RangeChanged()
        ph0Limits = normalizeSliderLimits([ph0MinField.Value, ph0MaxField.Value], ph0Slider.Limits);
        ph0MinField.Value = ph0Limits(1);
        ph0MaxField.Value = ph0Limits(2);
        ph0Slider.Limits = ph0Limits;
        ph0Deg = clampToLimits(ph0Deg, ph0Limits);
        ph0Field.Value = ph0Deg;
        ph0Slider.Value = ph0Deg;
        updatePlot();
    end

    function onPh1FieldChanged()
        ph1Deg = clampToLimits(ph1Field.Value, ph1Slider.Limits);
        ph1Field.Value = ph1Deg;
        ph1Slider.Value = ph1Deg;
        updatePlot();
    end

    function onPh1SliderChanged()
        ph1Deg = ph1Slider.Value;
        ph1Field.Value = ph1Deg;
        updatePlot();
    end

    function onPh1RangeChanged()
        ph1Limits = normalizeSliderLimits([ph1MinField.Value, ph1MaxField.Value], ph1Slider.Limits);
        ph1MinField.Value = ph1Limits(1);
        ph1MaxField.Value = ph1Limits(2);
        ph1Slider.Limits = ph1Limits;
        ph1Deg = clampToLimits(ph1Deg, ph1Limits);
        ph1Field.Value = ph1Deg;
        ph1Slider.Value = ph1Deg;
        updatePlot();
    end

    function onPivotFieldChanged()
        pivotIndex = clampPhaseIndex(pivotField.Value, nSpec);
        pivotField.Value = pivotIndex;
        updatePlot();
    end

    function onSetPivotFromClick()
        setPivotFromClick = true;
        statusLabel.Text = 'Click the spectrum plot to set the pivot point.';
    end

    function updatePlot()
        spectrum = squeeze(spectrum4D(:, voxelX, voxelY, voxelZ));
        corrected = applyPhaseCorrection(spectrum, ph0Deg, ph1Deg, pivotIndex);

        cla(specAxes);
        hold(specAxes, 'on');
        if showOriginalCheck.Value
            plot(specAxes, real(spectrum), 'Color', [0.6 0.6 0.6], 'DisplayName', 'Original Re');
        end
        hCorr = plot(specAxes, real(corrected), 'b-', 'LineWidth', 1.4, 'DisplayName', 'Corrected Re');
        if showImagCheck.Value
            plot(specAxes, imag(corrected), 'm--', 'DisplayName', 'Corrected Im');
        end
        if showPivotCheck.Value
            xline(specAxes, pivotIndex, '--r', 'Pivot', 'LineWidth', 1.2);
        end
        hold(specAxes, 'off');

        grid(specAxes, 'on');
        xlabel(specAxes, 'Spectral point');
        ylabel(specAxes, 'Signal');
        title(specAxes, sprintf('Voxel (%d, %d, %d), PH0=%.1f, PH1=%.1f, pivot=%d', ...
            voxelX, voxelY, voxelZ, ph0Deg, ph1Deg, pivotIndex));
        legend(specAxes, 'Location', 'best');

        specAxes.ButtonDownFcn = @(~, event) onSpectrumClicked(event);
        hCorr.ButtonDownFcn = @(~, event) onSpectrumClicked(event);
        bindSpectrumClickChildren();
    end

    function bindSpectrumClickChildren()
        children = specAxes.Children;
        for k = 1:numel(children)
            if isprop(children(k), 'ButtonDownFcn')
                children(k).PickableParts = 'all';
                children(k).HitTest = 'on';
                children(k).ButtonDownFcn = @(~, event) onSpectrumClicked(event);
            end
        end
    end

    function onSpectrumClicked(event)
        if ~setPivotFromClick
            return;
        end

        if isprop(event, 'IntersectionPoint')
            xClick = event.IntersectionPoint(1);
        else
            pt = specAxes.CurrentPoint;
            xClick = pt(1, 1);
        end

        pivotIndex = clampPhaseIndex(xClick, nSpec);
        pivotField.Value = pivotIndex;
        setPivotFromClick = false;
        statusLabel.Text = sprintf('Pivot set to %d. Adjust PH0/PH1 and save when ready.', pivotIndex);
        updatePlot();
    end

    function onResetPhase()
        ph0Deg = 0;
        ph1Deg = 0;
        pivotIndex = round(nSpec / 2);
        ph0Field.Value = ph0Deg;
        ph0Slider.Value = ph0Deg;
        ph1Field.Value = ph1Deg;
        ph1Slider.Value = ph1Deg;
        pivotField.Value = pivotIndex;
        statusLabel.Text = 'Phase parameters reset.';
        updatePlot();
    end

    function onSavePhase()
        meta.phaseEnabled = true;
        meta.phaseParams = struct( ...
            'ph0Deg', ph0Deg, ...
            'ph1Deg', ph1Deg, ...
            'pivotIndex', pivotIndex, ...
            'voxel', [voxelX, voxelY, voxelZ], ...
            'updatedAt', char(datetime('now')));
        meta.phaseUiRanges = struct('ph0', ph0Slider.Limits, 'ph1', ph1Slider.Limits);

        if isfield(meta, 'currentSpectralRange') && ~isempty(meta.currentSpectralRange)
            savedRange = meta.currentSpectralRange;
        else
            savedRange = activeRange;
        end

        savedRange = normalizePhaseRange(savedRange, nSpec);
        [updatedVolume, ~] = buildIntegratedVolumeFromSpectrum( ...
            spectrum4D, savedRange(1):savedRange(2), meta);

        assignin('base', info.metaVarName, meta);
        assignin('base', info.varName, updatedVolume);

        if ~isempty(onSaveCallback)
            onSaveCallback(updatedVolume, meta);
        end

        statusLabel.Text = sprintf('Saved PH0=%.1f, PH1=%.1f, pivot=%d.', ph0Deg, ph1Deg, pivotIndex);
    end
end

function value = clampPhaseIndex(value, maxValue)
value = max(1, min(maxValue, round(value)));
end

function limits = normalizeSliderLimits(values, defaultLimits)
if nargin < 2
    defaultLimits = [-1, 1];
end

values = double(values(:)');
if numel(values) < 2 || any(~isfinite(values(1:2)))
    limits = defaultLimits;
    return;
end

limits = sort(values(1:2));
if limits(1) == limits(2)
    limits = defaultLimits;
end
end

function value = clampToLimits(value, limits)
value = max(limits(1), min(limits(2), double(value)));
end

function range = normalizePhaseRange(values, nSpec)
values = round(values(:)');
values = sort(values(1:2));
values(1) = max(1, min(nSpec, values(1)));
values(2) = max(1, min(nSpec, values(2)));
range = values;
end
