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

fig = uifigure('Name', ['Spectrum interaction: ' info.varName], 'Position', [100 100 1180 720]);
movegui(fig, 'center');

axialAxes = uiaxes(fig, 'Position', [20 370 320 300]);
coronalAxes = uiaxes(fig, 'Position', [360 370 320 300]);
sagittalAxes = uiaxes(fig, 'Position', [700 370 320 300]);
spectrumAxes = uiaxes(fig, 'Position', [20 40 760 260]);

uilabel(fig, 'Position', [820 620 80 22], 'Text', 'Voxel X');
spinX = uispinner(fig, 'Position', [900 620 80 22], 'Limits', [1, nX], ...
    'RoundFractionalValues', true, 'Value', current.x, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());

uilabel(fig, 'Position', [820 580 80 22], 'Text', 'Voxel Y');
spinY = uispinner(fig, 'Position', [900 580 80 22], 'Limits', [1, nY], ...
    'RoundFractionalValues', true, 'Value', current.y, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());

uilabel(fig, 'Position', [820 540 80 22], 'Text', 'Voxel Z');
spinZ = uispinner(fig, 'Position', [900 540 80 22], 'Limits', [1, nZ], ...
    'RoundFractionalValues', true, 'Value', current.z, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());

uilabel(fig, 'Position', [820 470 220 22], 'Text', 'Integration range');
startField = uieditfield(fig, 'numeric', 'Position', [820 440 70 28], ...
    'Limits', [1, nSpec], 'RoundFractionalValues', true, 'Value', previewRange(1));
endField = uieditfield(fig, 'numeric', 'Position', [910 440 70 28], ...
    'Limits', [1, nSpec], 'RoundFractionalValues', true, 'Value', previewRange(2));

uibutton(fig, 'push', 'Position', [820 390 160 32], ...
    'Text', 'Preview range', 'ButtonPushedFcn', @(~, ~) onPreviewRange());

uibutton(fig, 'push', 'Position', [820 345 160 32], ...
    'Text', 'Save range', 'ButtonPushedFcn', @(~, ~) onSaveRange());

uibutton(fig, 'push', 'Position', [820 300 160 32], ...
    'Text', 'Use selected voxel', 'ButtonPushedFcn', @(~, ~) onPickRangeFromPlot());

savedRangeLabel = uilabel(fig, 'Position', [820 240 320 44], ...
    'Text', sprintf('Saved range: [%d, %d]', savedRange(1), savedRange(2)));

statusLabel = uilabel(fig, 'Position', [20 10 1120 22], ...
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
        drawnow;
        [xVals, ~] = ginput(2);
        if numel(xVals) ~= 2
            return;
        end
        chosenRange = normalizeRange(sort(round(xVals)), nSpec);
        startField.Value = chosenRange(1);
        endField.Value = chosenRange(2);
        previewRange = chosenRange;
        statusLabel.Text = sprintf('Picked range from spectrum: [%d, %d]. Click Preview or Save.', ...
            chosenRange(1), chosenRange(2));
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
        plot(spectrumAxes, spec, 'b-', 'LineWidth', 1.2);
        title(spectrumAxes, sprintf('Spectrum (%d, %d, %d)', current.x, current.y, current.z));
        xlabel(spectrumAxes, 'Spectral point');
        ylabel(spectrumAxes, 'Amplitude');
        grid(spectrumAxes, 'on');
        hold(spectrumAxes, 'on');
        xline(spectrumAxes, previewRange(1), '--r', 'Start');
        xline(spectrumAxes, previewRange(2), '--r', 'End');
        hold(spectrumAxes, 'off');
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
