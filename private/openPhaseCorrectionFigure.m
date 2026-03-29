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
activePhaseTarget = 'ph0';
phaseStep = 0.5;

fig = uifigure('Name', ['Phase correction: ' info.varName], 'Position', [120 120 1180 720]);
movegui(fig, 'center');
fig.WindowKeyPressFcn = @(~, event) onWindowKeyPress(event);
fig.WindowScrollWheelFcn = @(~, event) onWindowScroll(event);

specAxes = uiaxes(fig, 'Position', [260 90 890 600]);
leftPanel = uipanel(fig, 'Title', 'Phase Controls', 'Position', [15 90 225 600], ...
    'Scrollable', 'on');

controlsGrid = uigridlayout(leftPanel, [14, 1]);
controlsGrid.RowHeight = {32, 20, 32, 32, 20, 32, 32, 32, 24, 24, 24, 34, 34, '1x'};
controlsGrid.ColumnWidth = {'1x'};
controlsGrid.RowSpacing = 8;
controlsGrid.ColumnSpacing = 0;
controlsGrid.Padding = [10 10 10 10];

ph0Row = uigridlayout(controlsGrid, [1, 2]);
ph0Row.RowHeight = {22};
ph0Row.ColumnWidth = {70, '1x'};
ph0Row.Padding = [0 0 0 0];
ph0Row.Layout.Row = 1;
ph0Row.Layout.Column = 1;
uilabel(ph0Row, 'Text', 'PH0 (deg)');
ph0Field = uieditfield(ph0Row, 'numeric', ...
    'Value', ph0Deg, 'ValueChangedFcn', @(~, ~) onPh0FieldChanged());
ph0Field.Layout.Row = 1;
ph0Field.Layout.Column = 2;

ph0Slider = uislider(controlsGrid, 'Limits', ph0Limits, ...
    'Value', ph0Deg, 'ValueChangedFcn', @(~, ~) onPh0SliderChanged(), ...
    'ValueChangingFcn', @(~, event) onPh0SliderChanging(event));
ph0Slider.Layout.Row = 2;
ph0Slider.Layout.Column = 1;

ph0RangeGrid = uigridlayout(controlsGrid, [1, 4]);
ph0RangeGrid.RowHeight = {22};
ph0RangeGrid.ColumnWidth = {28, '1x', 28, '1x'};
ph0RangeGrid.Padding = [0 0 0 0];
ph0RangeGrid.ColumnSpacing = 6;
ph0RangeGrid.Layout.Row = 3;
ph0RangeGrid.Layout.Column = 1;
uilabel(ph0RangeGrid, 'Text', 'Min');
ph0MinField = uieditfield(ph0RangeGrid, 'numeric', ...
    'Value', ph0Limits(1), 'ValueChangedFcn', @(~, ~) onPh0RangeChanged());
ph0MinField.Layout.Row = 1;
ph0MinField.Layout.Column = 2;
maxPh0Label = uilabel(ph0RangeGrid, 'Text', 'Max');
maxPh0Label.Layout.Row = 1;
maxPh0Label.Layout.Column = 3;
ph0MaxField = uieditfield(ph0RangeGrid, 'numeric', ...
    'Value', ph0Limits(2), 'ValueChangedFcn', @(~, ~) onPh0RangeChanged());
ph0MaxField.Layout.Row = 1;
ph0MaxField.Layout.Column = 4;

ph1Row = uigridlayout(controlsGrid, [1, 2]);
ph1Row.RowHeight = {22};
ph1Row.ColumnWidth = {70, '1x'};
ph1Row.Padding = [0 0 0 0];
ph1Row.Layout.Row = 4;
ph1Row.Layout.Column = 1;
uilabel(ph1Row, 'Text', 'PH1 (deg)');
ph1Field = uieditfield(ph1Row, 'numeric', ...
    'Value', ph1Deg, 'ValueChangedFcn', @(~, ~) onPh1FieldChanged());
ph1Field.Layout.Row = 1;
ph1Field.Layout.Column = 2;

ph1Slider = uislider(controlsGrid, 'Limits', ph1Limits, ...
    'Value', ph1Deg, 'ValueChangedFcn', @(~, ~) onPh1SliderChanged(), ...
    'ValueChangingFcn', @(~, event) onPh1SliderChanging(event));
ph1Slider.Layout.Row = 5;
ph1Slider.Layout.Column = 1;

ph1RangeGrid = uigridlayout(controlsGrid, [1, 4]);
ph1RangeGrid.RowHeight = {22};
ph1RangeGrid.ColumnWidth = {28, '1x', 28, '1x'};
ph1RangeGrid.Padding = [0 0 0 0];
ph1RangeGrid.ColumnSpacing = 6;
ph1RangeGrid.Layout.Row = 6;
ph1RangeGrid.Layout.Column = 1;
uilabel(ph1RangeGrid, 'Text', 'Min');
ph1MinField = uieditfield(ph1RangeGrid, 'numeric', ...
    'Value', ph1Limits(1), 'ValueChangedFcn', @(~, ~) onPh1RangeChanged());
ph1MinField.Layout.Row = 1;
ph1MinField.Layout.Column = 2;
maxPh1Label = uilabel(ph1RangeGrid, 'Text', 'Max');
maxPh1Label.Layout.Row = 1;
maxPh1Label.Layout.Column = 3;
ph1MaxField = uieditfield(ph1RangeGrid, 'numeric', ...
    'Value', ph1Limits(2), 'ValueChangedFcn', @(~, ~) onPh1RangeChanged());
ph1MaxField.Layout.Row = 1;
ph1MaxField.Layout.Column = 4;

pivotGrid = uigridlayout(controlsGrid, [1, 2]);
pivotGrid.RowHeight = {22};
pivotGrid.ColumnWidth = {70, '1x'};
pivotGrid.Padding = [0 0 0 0];
pivotGrid.Layout.Row = 7;
pivotGrid.Layout.Column = 1;
pivotLabel = uilabel(pivotGrid, 'Text', 'Pivot idx');
pivotLabel.Layout.Row = 1;
pivotLabel.Layout.Column = 1;
pivotField = uieditfield(pivotGrid, 'numeric', ...
    'Limits', [1, nSpec], 'RoundFractionalValues', true, ...
    'Value', pivotIndex, 'ValueChangedFcn', @(~, ~) onPivotFieldChanged());
pivotField.Layout.Row = 1;
pivotField.Layout.Column = 2;

pivotButton = uibutton(controlsGrid, 'push', ...
    'Text', 'Set Pivot from Click', 'ButtonPushedFcn', @(~, ~) onSetPivotFromClick());
pivotButton.Layout.Row = 8;
pivotButton.Layout.Column = 1;

showImagCheck = uicheckbox(controlsGrid, ...
    'Text', 'Show imaginary', 'Value', true, 'ValueChangedFcn', @(~, ~) updatePlot());
showImagCheck.Layout.Row = 9;
showImagCheck.Layout.Column = 1;

showOriginalCheck = uicheckbox(controlsGrid, ...
    'Text', 'Show original', 'Value', true, 'ValueChangedFcn', @(~, ~) updatePlot());
showOriginalCheck.Layout.Row = 10;
showOriginalCheck.Layout.Column = 1;

showPivotCheck = uicheckbox(controlsGrid, ...
    'Text', 'Show pivot marker', 'Value', true, 'ValueChangedFcn', @(~, ~) updatePlot());
showPivotCheck.Layout.Row = 11;
showPivotCheck.Layout.Column = 1;

saveButton = uibutton(controlsGrid, 'push', ...
    'Text', 'Save phase params', 'ButtonPushedFcn', @(~, ~) onSavePhase());
saveButton.Layout.Row = 12;
saveButton.Layout.Column = 1;

resetButton = uibutton(controlsGrid, 'push', ...
    'Text', 'Reset phase', 'ButtonPushedFcn', @(~, ~) onResetPhase());
resetButton.Layout.Row = 13;
resetButton.Layout.Column = 1;

statusLabel = uilabel(fig, 'Position', [15 20 1130 22], ...
    'Text', sprintf('Voxel (%d, %d, %d), integration range [%d, %d].', ...
    voxelX, voxelY, voxelZ, activeRange(1), activeRange(2)));

updatePlot();

    function onPh0FieldChanged()
        activePhaseTarget = 'ph0';
        ph0Deg = clampToLimits(ph0Field.Value, ph0Slider.Limits);
        ph0Field.Value = ph0Deg;
        ph0Slider.Value = ph0Deg;
        updatePlot();
    end

    function onPh0SliderChanged()
        activePhaseTarget = 'ph0';
        ph0Deg = ph0Slider.Value;
        ph0Field.Value = ph0Deg;
        updatePlot();
    end

    function onPh0SliderChanging(event)
        activePhaseTarget = 'ph0';
        ph0Deg = clampToLimits(event.Value, ph0Slider.Limits);
        ph0Field.Value = ph0Deg;
        updatePlot();
    end

    function onPh0RangeChanged()
        activePhaseTarget = 'ph0';
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
        activePhaseTarget = 'ph1';
        ph1Deg = clampToLimits(ph1Field.Value, ph1Slider.Limits);
        ph1Field.Value = ph1Deg;
        ph1Slider.Value = ph1Deg;
        updatePlot();
    end

    function onPh1SliderChanged()
        activePhaseTarget = 'ph1';
        ph1Deg = ph1Slider.Value;
        ph1Field.Value = ph1Deg;
        updatePlot();
    end

    function onPh1SliderChanging(event)
        activePhaseTarget = 'ph1';
        ph1Deg = clampToLimits(event.Value, ph1Slider.Limits);
        ph1Field.Value = ph1Deg;
        updatePlot();
    end

    function onPh1RangeChanged()
        activePhaseTarget = 'ph1';
        ph1Limits = normalizeSliderLimits([ph1MinField.Value, ph1MaxField.Value], ph1Slider.Limits);
        ph1MinField.Value = ph1Limits(1);
        ph1MaxField.Value = ph1Limits(2);
        ph1Slider.Limits = ph1Limits;
        ph1Deg = clampToLimits(ph1Deg, ph1Limits);
        ph1Field.Value = ph1Deg;
        ph1Slider.Value = ph1Deg;
        updatePlot();
    end

    function onWindowKeyPress(event)
        target = getActivePhaseTarget();
        if isempty(target)
            return;
        end

        switch event.Key
            case 'leftarrow'
                applyPhaseDelta(target, -phaseStep);
            case 'rightarrow'
                applyPhaseDelta(target, phaseStep);
        end
    end

    function onWindowScroll(event)
        target = getActivePhaseTarget();
        if isempty(target)
            return;
        end

        applyPhaseDelta(target, -phaseStep * event.VerticalScrollCount);
    end

    function target = getActivePhaseTarget()
        focused = fig.CurrentObject;
        ph0Controls = [ph0Field, ph0Slider, ph0MinField, ph0MaxField];
        ph1Controls = [ph1Field, ph1Slider, ph1MinField, ph1MaxField];

        if any(arrayfun(@(x) isequal(focused, x), ph0Controls))
            target = 'ph0';
        elseif any(arrayfun(@(x) isequal(focused, x), ph1Controls))
            target = 'ph1';
        elseif strcmp(activePhaseTarget, 'ph0') || strcmp(activePhaseTarget, 'ph1')
            target = activePhaseTarget;
        else
            target = [];
        end
    end

    function applyPhaseDelta(target, deltaValue)
        switch target
            case 'ph0'
                activePhaseTarget = 'ph0';
                ph0Deg = clampToLimits(ph0Deg + deltaValue, ph0Slider.Limits);
                ph0Field.Value = ph0Deg;
                ph0Slider.Value = ph0Deg;
            case 'ph1'
                activePhaseTarget = 'ph1';
                ph1Deg = clampToLimits(ph1Deg + deltaValue, ph1Slider.Limits);
                ph1Field.Value = ph1Deg;
                ph1Slider.Value = ph1Deg;
            otherwise
                return;
        end

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
