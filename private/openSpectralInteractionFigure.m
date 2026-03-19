function openSpectralInteractionFigure(info)
%OPENSPECTRALINTERACTIONFIGURE Inspect a spectral 4D dataset and save range integration.

spectrum4D = info.spectrum4D;
currentVolume = info.volume3D;
meta = info.meta;

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
previewVolume = currentVolume;
isPickingRange = false;
pickedRangePoints = [];

fig = uifigure('Name', ['Spectrum interaction: ' info.varName], 'Position', [100 100 1180 720]);
movegui(fig, 'center');

fig.Position(3:4) = [1360 760];

axialAxes = uiaxes(fig, 'Position', [20 390 360 320]);
coronalAxes = uiaxes(fig, 'Position', [405 390 360 320]);
sagittalAxes = uiaxes(fig, 'Position', [790 390 300 320]);
spectrumAxes = uiaxes(fig, 'Position', [20 55 1070 280]);

controlPanel = uipanel(fig, 'Title', 'Controls', 'Position', [1110 55 230 655]);

uilabel(controlPanel, 'Position', [18 580 80 22], 'Text', 'Voxel X');
spinX = uispinner(controlPanel, 'Position', [110 580 90 22], 'Limits', [1, nX], ...
    'RoundFractionalValues', true, 'Value', current.x, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());

uilabel(controlPanel, 'Position', [18 540 80 22], 'Text', 'Voxel Y');
spinY = uispinner(controlPanel, 'Position', [110 540 90 22], 'Limits', [1, nY], ...
    'RoundFractionalValues', true, 'Value', current.y, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());

uilabel(controlPanel, 'Position', [18 500 80 22], 'Text', 'Voxel Z');
spinZ = uispinner(controlPanel, 'Position', [110 500 90 22], 'Limits', [1, nZ], ...
    'RoundFractionalValues', true, 'Value', current.z, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());

uilabel(controlPanel, 'Position', [18 430 180 22], 'Text', 'Integration range');
startField = uieditfield(controlPanel, 'numeric', 'Position', [18 395 80 28], ...
    'Limits', [1, nSpec], 'RoundFractionalValues', true, 'Value', previewRange(1));
endField = uieditfield(controlPanel, 'numeric', 'Position', [120 395 80 28], ...
    'Limits', [1, nSpec], 'RoundFractionalValues', true, 'Value', previewRange(2));

uilabel(controlPanel, 'Position', [18 370 180 18], 'Text', 'Start / End points');

uibutton(controlPanel, 'push', 'Position', [18 325 182 34], ...
    'Text', 'Preview range', 'ButtonPushedFcn', @(~, ~) onPreviewRange());

uibutton(controlPanel, 'push', 'Position', [18 280 182 34], ...
    'Text', 'Save range', 'ButtonPushedFcn', @(~, ~) onSaveRange());

uibutton(controlPanel, 'push', 'Position', [18 235 182 34], ...
    'Text', 'Pick range on plot', 'Tooltip', {'Select two points on the spectrum plot.'}, ...
    'ButtonPushedFcn', @(~, ~) onPickRangeFromPlot());

savedRangeLabel = uilabel(controlPanel, 'Position', [18 165 190 50], ...
    'Text', sprintf('Saved range: [%d, %d]', savedRange(1), savedRange(2)));

statusLabel = uilabel(fig, 'Position', [20 18 1320 22], ...
    'Text', 'Preview shows the current 3D volume. Save updates the workspace volume used by the app.');

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
            previewVolume = integrateSpectralRange(spectrum4D, previewRange(1):previewRange(2));
            statusLabel.Text = sprintf('Preview range applied: [%d, %d].', previewRange(1), previewRange(2));
            updateAllViews();
        catch ME
            uialert(fig, ME.message, 'Ошибка');
        end
    end

    function onSaveRange()
        try
            previewRange = normalizeRange([startField.Value, endField.Value], nSpec);
            previewVolume = integrateSpectralRange(spectrum4D, previewRange(1):previewRange(2));
        catch ME
            uialert(fig, ME.message, 'Ошибка');
            return;
        end

        meta.currentIntegrationMode = 'sum(abs(spectrum4D(idxRange,:,:,:)),1)';
        meta.currentSpectralRange = previewRange;
        meta.lastInteractionVoxel = [current.x, current.y, current.z];
        meta.lastUpdatedAt = char(datetime('now'));

        assignin('base', info.varName, previewVolume);
        assignin('base', info.metaVarName, meta);

        currentVolume = previewVolume;
        savedRange = previewRange;
        savedRangeLabel.Text = sprintf('Saved range: [%d, %d]', savedRange(1), savedRange(2));
        statusLabel.Text = sprintf('Saved range [%d, %d] and updated "%s" in base workspace.', ...
            savedRange(1), savedRange(2), info.varName);
        updateAllViews();
    end

    function onPickRangeFromPlot()
        isPickingRange = true;
        pickedRangePoints = [];
        statusLabel.Text = 'Click two points on the spectrum plot to set the integration range.';
        updateSpectrumPlot();
    end

    function updateAllViews()
        updateSliceViews();
        updateSpectrumPlot();
    end

    function updateSliceViews()
        imagesc(axialAxes, currentVolume(:, :, current.z));
        axis(axialAxes, 'image');
        axialAxes.XTick = [];
        axialAxes.YTick = [];
        title(axialAxes, sprintf('Axial (Z = %d)', current.z));
        colormap(axialAxes, hot);
        hold(axialAxes, 'on');
        plot(axialAxes, current.y, current.x, 'g+', 'MarkerSize', 10, 'LineWidth', 1.5);
        hold(axialAxes, 'off');

        imagesc(coronalAxes, squeeze(currentVolume(:, current.y, :)));
        axis(coronalAxes, 'image');
        coronalAxes.XTick = [];
        coronalAxes.YTick = [];
        title(coronalAxes, sprintf('Coronal (Y = %d)', current.y));
        colormap(coronalAxes, hot);
        hold(coronalAxes, 'on');
        plot(coronalAxes, current.z, current.x, 'g+', 'MarkerSize', 10, 'LineWidth', 1.5);
        hold(coronalAxes, 'off');

        imagesc(sagittalAxes, squeeze(currentVolume(current.x, :, :))');
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
        spec = abs(spectrum4D(:, current.x, current.y, current.z));
        hSpec = plot(spectrumAxes, spec, 'b-', 'LineWidth', 1.2);
        title(spectrumAxes, sprintf('Spectrum (%d, %d, %d)', current.x, current.y, current.z));
        xlabel(spectrumAxes, 'Spectral point');
        ylabel(spectrumAxes, 'Amplitude');
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
