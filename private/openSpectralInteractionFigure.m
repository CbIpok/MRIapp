function openSpectralInteractionFigure(info)
%OPENSPECTRALINTERACTIONFIGURE Inspect a spectral 4D dataset and save range integration.

spectrum4D = info.spectrum4D;
meta = info.meta;
valueMode = getSpectralValueMode(meta);

[nSpec, nX, nY, nZ] = size(spectrum4D);
current = struct('x', ceil(nX / 2), 'y', ceil(nY / 2), 'z', ceil(nZ / 2));

if isfield(meta, 'currentSpectralRange') && ~isempty(meta.currentSpectralRange)
    savedRange = meta.currentSpectralRange;
elseif isfield(meta, 'defaultSpectralRange') && ~isempty(meta.defaultSpectralRange)
    savedRange = meta.defaultSpectralRange;
else
    savedRange = [1, nSpec];
end
savedRange = normalizeRange(savedRange, nSpec);
previewRange = savedRange;
[currentVolume, correctedSpectrum4D] = buildIntegratedVolumeFromSpectrum( ...
    spectrum4D, savedRange(1):savedRange(2), meta, valueMode);
previewVolume = currentVolume;
isPickingRange = false;
pickedRangePoints = [];

fig = uifigure('Name', ['Spectrum interaction: ' info.varName], 'Position', [100 100 1180 720]);
movegui(fig, 'center');
fig.Position(3:4) = [1360 760];

mainGrid = uigridlayout(fig, [3, 4]);
mainGrid.RowHeight = {'1x', '1x', 32};
mainGrid.ColumnWidth = {'1x', '1x', '1x', 260};
mainGrid.RowSpacing = 10;
mainGrid.ColumnSpacing = 10;
mainGrid.Padding = [10 10 10 10];

axialAxes = uiaxes(mainGrid);
axialAxes.Layout.Row = 1;
axialAxes.Layout.Column = 1;

coronalAxes = uiaxes(mainGrid);
coronalAxes.Layout.Row = 1;
coronalAxes.Layout.Column = 2;

sagittalAxes = uiaxes(mainGrid);
sagittalAxes.Layout.Row = 1;
sagittalAxes.Layout.Column = 3;

spectrumAxes = uiaxes(mainGrid);
spectrumAxes.Layout.Row = 2;
spectrumAxes.Layout.Column = [1 3];

controlPanel = uipanel(mainGrid, 'Title', 'Controls');
controlPanel.Layout.Row = [1 2];
controlPanel.Layout.Column = 4;

controlsGrid = uigridlayout(controlPanel, [17, 2]);
controlsGrid.RowHeight = {22, 32, 22, 32, 22, 32, 22, 52, 22, 32, 36, 36, 36, 36, 36, 36, '1x'};
controlsGrid.ColumnWidth = {70, '1x'};
controlsGrid.RowSpacing = 8;
controlsGrid.ColumnSpacing = 8;
controlsGrid.Padding = [10 10 10 10];
controlsGrid.Scrollable = 'on';

labelX = uilabel(controlsGrid, 'Text', 'Voxel X');
labelX.Layout.Row = 1;
labelX.Layout.Column = 1;
spinX = uispinner(controlsGrid, 'Limits', [1, nX], ...
    'RoundFractionalValues', true, 'Value', current.x, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());
spinX.Layout.Row = 2;
spinX.Layout.Column = [1 2];

labelY = uilabel(controlsGrid, 'Text', 'Voxel Y');
labelY.Layout.Row = 3;
labelY.Layout.Column = 1;
spinY = uispinner(controlsGrid, 'Limits', [1, nY], ...
    'RoundFractionalValues', true, 'Value', current.y, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());
spinY.Layout.Row = 4;
spinY.Layout.Column = [1 2];

labelZ = uilabel(controlsGrid, 'Text', 'Voxel Z');
labelZ.Layout.Row = 5;
labelZ.Layout.Column = 1;
spinZ = uispinner(controlsGrid, 'Limits', [1, nZ], ...
    'RoundFractionalValues', true, 'Value', current.z, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());
spinZ.Layout.Row = 6;
spinZ.Layout.Column = [1 2];

rangeLabel = uilabel(controlsGrid, 'Text', 'Integration range');
rangeLabel.Layout.Row = 7;
rangeLabel.Layout.Column = [1 2];

rangeGrid = uigridlayout(controlsGrid, [2, 2]);
rangeGrid.RowHeight = {32, 20};
rangeGrid.ColumnWidth = {'1x', '1x'};
rangeGrid.RowSpacing = 4;
rangeGrid.ColumnSpacing = 6;
rangeGrid.Padding = [0 0 0 0];
rangeGrid.Layout.Row = 8;
rangeGrid.Layout.Column = [1 2];

startField = uieditfield(rangeGrid, 'numeric', 'Limits', [1, nSpec], ...
    'RoundFractionalValues', true, 'Value', previewRange(1));
startField.Layout.Row = 1;
startField.Layout.Column = 1;

endField = uieditfield(rangeGrid, 'numeric', 'Limits', [1, nSpec], ...
    'RoundFractionalValues', true, 'Value', previewRange(2));
endField.Layout.Row = 1;
endField.Layout.Column = 2;

rangeHint = uilabel(rangeGrid, 'Text', 'Start / End points');
rangeHint.Layout.Row = 2;
rangeHint.Layout.Column = [1 2];

modeLabel = uilabel(controlsGrid, 'Text', 'Spectrum mode');
modeLabel.Layout.Row = 9;
modeLabel.Layout.Column = [1 2];

modeDropDown = uidropdown(controlsGrid, ...
    'Items', {'abs', 'Re'}, ...
    'Value', valueModeToItem(valueMode), ...
    'ValueChangedFcn', @(src, ~) onModeChanged(src.Value));
modeDropDown.Layout.Row = 10;
modeDropDown.Layout.Column = [1 2];

previewButton = uibutton(controlsGrid, 'push', ...
    'Text', 'Preview range', 'ButtonPushedFcn', @(~, ~) onPreviewRange());
previewButton.Layout.Row = 11;
previewButton.Layout.Column = [1 2];

saveButton = uibutton(controlsGrid, 'push', ...
    'Text', 'Save range', 'ButtonPushedFcn', @(~, ~) onSaveRange());
saveButton.Layout.Row = 12;
saveButton.Layout.Column = [1 2];

plotButton = uibutton(controlsGrid, 'push', ...
    'Text', 'Pick range on plot', 'Tooltip', {'Select two points on the spectrum plot.'}, ...
    'ButtonPushedFcn', @(~, ~) onPickRangeFromPlot());
plotButton.Layout.Row = 13;
plotButton.Layout.Column = [1 2];

phaseButton = uibutton(controlsGrid, 'push', ...
    'Text', 'Phase selected voxel', 'ButtonPushedFcn', @(~, ~) onOpenPhaseWindow());
phaseButton.Layout.Row = 14;
phaseButton.Layout.Column = [1 2];

conversionButton = uibutton(controlsGrid, 'push', ...
    'Text', 'Calculate convertion', 'ButtonPushedFcn', @(~, ~) onOpenConversionWindow());
conversionButton.Layout.Row = 15;
conversionButton.Layout.Column = [1 2];

saveVolumeButton = uibutton(controlsGrid, 'push', ...
    'Text', 'Save 3D volume', 'ButtonPushedFcn', @(~, ~) onSaveVolume());
saveVolumeButton.Layout.Row = 16;
saveVolumeButton.Layout.Column = [1 2];

savedRangeLabel = uilabel(controlsGrid, ...
    'Text', sprintf('Saved range: [%d, %d]', savedRange(1), savedRange(2)), ...
    'WordWrap', 'on');
savedRangeLabel.Layout.Row = 17;
savedRangeLabel.Layout.Column = [1 2];

statusLabel = uilabel(mainGrid, ...
    'Text', 'Preview shows the current 3D volume. Save updates the workspace volume used by the app.', ...
    'WordWrap', 'on');
statusLabel.Layout.Row = 3;
statusLabel.Layout.Column = [1 4];

updateAllViews();

    function onVoxelSpinnerChanged()
        current.x = round(spinX.Value);
        current.y = round(spinY.Value);
        current.z = round(spinZ.Value);
        updateAllViews();
    end

    function onPreviewRange()
        try
            previewRange = normalizeRange([startField.Value, endField.Value], nSpec);
            [previewVolume, correctedSpectrum4D] = buildIntegratedVolumeFromSpectrum( ...
                spectrum4D, previewRange(1):previewRange(2), meta, valueMode);
            statusLabel.Text = sprintf('Preview range applied: [%d, %d], mode %s.', ...
                previewRange(1), previewRange(2), valueModeToItem(valueMode));
            updateAllViews();
        catch ME
            uialert(fig, ME.message, 'Ошибка');
        end
    end

    function onSaveRange()
        try
            previewRange = normalizeRange([startField.Value, endField.Value], nSpec);
            [previewVolume, correctedSpectrum4D] = buildIntegratedVolumeFromSpectrum( ...
                spectrum4D, previewRange(1):previewRange(2), meta, valueMode);
        catch ME
            uialert(fig, ME.message, 'Ошибка');
            return;
        end

        meta.currentIntegrationMode = buildIntegrationModeLabel(valueMode);
        meta.currentSpectralValueMode = valueMode;
        meta.currentSpectralRange = previewRange;
        meta.lastInteractionVoxel = [current.x, current.y, current.z];
        meta.lastUpdatedAt = char(datetime('now'));

        assignin('base', info.varName, previewVolume);
        assignin('base', info.metaVarName, meta);

        currentVolume = previewVolume;
        savedRange = previewRange;
        savedRangeLabel.Text = sprintf('Saved range: [%d, %d]', savedRange(1), savedRange(2));
        statusLabel.Text = sprintf('Saved range [%d, %d], mode %s, and updated "%s" in base workspace.', ...
            savedRange(1), savedRange(2), valueModeToItem(valueMode), info.varName);
        updateAllViews();
    end

    function onPickRangeFromPlot()
        isPickingRange = true;
        pickedRangePoints = [];
        statusLabel.Text = 'Click two points on the spectrum plot to set the integration range.';
        updateSpectrumPlot();
    end

    function onModeChanged(selectedItem)
        try
            valueMode = itemToValueMode(selectedItem);
            meta.currentSpectralValueMode = valueMode;
            [previewVolume, correctedSpectrum4D] = buildIntegratedVolumeFromSpectrum( ...
                spectrum4D, previewRange(1):previewRange(2), meta, valueMode);
            if isequal(previewRange, savedRange)
                currentVolume = previewVolume;
            end
            statusLabel.Text = sprintf('Spectrum mode changed to %s.', selectedItem);
            updateAllViews();
        catch ME
            uialert(fig, ME.message, 'Error');
        end
    end

    function onOpenPhaseWindow()
        info.meta = meta;
        openPhaseCorrectionFigure(info, [current.x, current.y, current.z], previewRange, @onPhaseSaved);
    end

    function onOpenConversionWindow()
        info.meta = meta;
        info.meta.currentSpectralValueMode = valueMode;
        openSpectralConversionFigure(info, [current.x, current.y, current.z]);
    end

    function onSaveVolume()
        try
            defaultName = matlab.lang.makeValidName([info.varName '_integrated']);
            saveVolumeAsRawFloat(previewVolume, [defaultName '.bin']);
            statusLabel.Text = sprintf('Saved current 3D volume [%d, %d, %d], mode %s.', ...
                nX, nY, nZ, valueModeToItem(valueMode));
        catch ME
            uialert(fig, ME.message, 'Error');
        end
    end

    function onPhaseSaved(updatedVolume, updatedMeta)
        meta = updatedMeta;
        meta.currentSpectralValueMode = valueMode;
        info.meta = meta;
        [previewVolume, correctedSpectrum4D] = buildIntegratedVolumeFromSpectrum( ...
            spectrum4D, previewRange(1):previewRange(2), meta, valueMode);
        if isequal(previewRange, savedRange)
            currentVolume = previewVolume;
        end
        statusLabel.Text = sprintf('Phase parameters saved and volume was rebuilt in mode %s.', ...
            valueModeToItem(valueMode));
        updateAllViews();
    end

    function updateAllViews()
        updateSliceViews();
        updateSpectrumPlot();
    end

    function updateSliceViews()
        imagesc(axialAxes, previewVolume(:, :, current.z));
        axis(axialAxes, 'image');
        axialAxes.XTick = [];
        axialAxes.YTick = [];
        title(axialAxes, sprintf('Axial (Z = %d)', current.z));
        colormap(axialAxes, hot);
        hold(axialAxes, 'on');
        plot(axialAxes, current.y, current.x, 'g+', 'MarkerSize', 10, 'LineWidth', 1.5);
        hold(axialAxes, 'off');

        imagesc(coronalAxes, squeeze(previewVolume(:, current.y, :)));
        axis(coronalAxes, 'image');
        coronalAxes.XTick = [];
        coronalAxes.YTick = [];
        title(coronalAxes, sprintf('Coronal (Y = %d)', current.y));
        colormap(coronalAxes, hot);
        hold(coronalAxes, 'on');
        plot(coronalAxes, current.z, current.x, 'g+', 'MarkerSize', 10, 'LineWidth', 1.5);
        hold(coronalAxes, 'off');

        imagesc(sagittalAxes, squeeze(previewVolume(current.x, :, :))');
        axis(sagittalAxes, 'image');
        sagittalAxes.XTick = [];
        sagittalAxes.YTick = [];
        title(sagittalAxes, sprintf('Sagittal (X = %d)', current.x));
        colormap(sagittalAxes, hot);
        hold(sagittalAxes, 'on');
        plot(sagittalAxes, current.y, current.z, 'g+', 'MarkerSize', 10, 'LineWidth', 1.5);
        hold(sagittalAxes, 'off');

        axialAxes.ButtonDownFcn = @(~, event) onSliceClicked(event, 'axial');
        coronalAxes.ButtonDownFcn = @(~, event) onSliceClicked(event, 'coronal');
        sagittalAxes.ButtonDownFcn = @(~, event) onSliceClicked(event, 'sagittal');
        bindImageClicks(axialAxes, 'axial');
        bindImageClicks(coronalAxes, 'coronal');
        bindImageClicks(sagittalAxes, 'sagittal');
    end

    function bindImageClicks(ax, viewName)
        children = ax.Children;
        for k = 1:numel(children)
            if isprop(children(k), 'ButtonDownFcn')
                children(k).PickableParts = 'all';
                children(k).HitTest = 'on';
                children(k).ButtonDownFcn = @(~, event) onSliceClicked(event, viewName);
            end
        end
    end

    function onSliceClicked(event, viewName)
        clickPoint = event.IntersectionPoint(1, 1:2);
        xClick = round(clickPoint(1));
        yClick = round(clickPoint(2));

        switch viewName
            case 'axial'
                current.x = clampIndex(yClick, nX);
                current.y = clampIndex(xClick, nY);
            case 'coronal'
                current.x = clampIndex(yClick, nX);
                current.z = clampIndex(xClick, nZ);
            case 'sagittal'
                current.y = clampIndex(xClick, nY);
                current.z = clampIndex(yClick, nZ);
        end

        spinX.Value = current.x;
        spinY.Value = current.y;
        spinZ.Value = current.z;
        updateAllViews();
    end

    function updateSpectrumPlot()
        cla(spectrumAxes);
        spec = extractSpectrumTrace(correctedSpectrum4D(:, current.x, current.y, current.z), valueMode);
        hSpec = plot(spectrumAxes, spec, 'b-', 'LineWidth', 1.2);
        title(spectrumAxes, sprintf('Spectrum %s (%d, %d, %d)', valueModeToItem(valueMode), ...
            current.x, current.y, current.z));
        xlabel(spectrumAxes, 'Spectral point');
        ylabel(spectrumAxes, spectrumYAxisLabel(valueMode));
        grid(spectrumAxes, 'on');
        hold(spectrumAxes, 'on');
        xline(spectrumAxes, previewRange(1), '--r', 'Start');
        xline(spectrumAxes, previewRange(2), '--r', 'End');
        if ~isempty(pickedRangePoints)
            for iPoint = 1:numel(pickedRangePoints)
                xline(spectrumAxes, pickedRangePoints(iPoint), ':k');
            end
        end
        hold(spectrumAxes, 'off');
        spectrumAxes.ButtonDownFcn = @(~, event) onSpectrumClicked(event);
        hSpec.ButtonDownFcn = @(~, event) onSpectrumClicked(event);
        bindSpectrumChildClicks();
    end

    function bindSpectrumChildClicks()
        children = spectrumAxes.Children;
        for k = 1:numel(children)
            if isprop(children(k), 'ButtonDownFcn')
                children(k).PickableParts = 'all';
                children(k).HitTest = 'on';
                children(k).ButtonDownFcn = @(~, event) onSpectrumClicked(event);
            end
        end
    end

    function onSpectrumClicked(event)
        if ~isPickingRange
            return;
        end

        if isprop(event, 'IntersectionPoint')
            xClick = event.IntersectionPoint(1);
        else
            point = spectrumAxes.CurrentPoint;
            xClick = point(1, 1);
        end

        xClick = clampIndex(xClick, nSpec);
        pickedRangePoints(end + 1) = xClick;

        if numel(pickedRangePoints) >= 2
            chosenRange = normalizeRange(pickedRangePoints(1:2), nSpec);
            startField.Value = chosenRange(1);
            endField.Value = chosenRange(2);
            previewRange = chosenRange;
            pickedRangePoints = [];
            isPickingRange = false;
            statusLabel.Text = sprintf('Picked range from spectrum: [%d, %d]. Click Preview or Save.', ...
                chosenRange(1), chosenRange(2));
        else
            statusLabel.Text = sprintf('First point selected: %d. Click the second point on the spectrum.', xClick);
        end

        updateSpectrumPlot();
    end
end

function range = normalizeRange(values, nSpec)
values = round(values(:)');
if numel(values) < 2
    error('Укажите начало и конец диапазона.');
end

values = sort(values(1:2));
values(1) = max(1, min(nSpec, values(1)));
values(2) = max(1, min(nSpec, values(2)));

if values(1) > values(2)
    values = fliplr(values);
end

range = values;
end

function value = clampIndex(value, maxValue)
value = max(1, min(maxValue, round(value)));
end

function item = valueModeToItem(valueMode)
if strcmpi(valueMode, 'real')
    item = 'Re';
else
    item = 'abs';
end
end

function valueMode = itemToValueMode(item)
if strcmpi(item, 'Re')
    valueMode = 'real';
else
    valueMode = 'abs';
end
end

function values = extractSpectrumTrace(spectrumVector, valueMode)
spectrumVector = reshape(spectrumVector, [], 1);
switch lower(char(string(valueMode)))
    case 'abs'
        values = abs(spectrumVector);
    case {'re', 'real'}
        values = real(spectrumVector);
    otherwise
        error('Unsupported spectral value mode: %s', char(string(valueMode)));
end
end

function label = spectrumYAxisLabel(valueMode)
if strcmpi(valueMode, 'real')
    label = 'Real part';
else
    label = 'Amplitude';
end
end

function modeLabel = buildIntegrationModeLabel(valueMode)
if strcmpi(valueMode, 'real')
    modeLabel = 'sum(real(spectrum4D(idxRange,:,:,:)),1)';
else
    modeLabel = 'sum(abs(spectrum4D(idxRange,:,:,:)),1)';
end
end
