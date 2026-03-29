function openSpectralConversionFigure(info, currentVoxel)
%OPENSPECTRALCONVERSIONFIGURE Configure named integrals and calculate a conversion map.

spectrum4D = info.spectrum4D;
currentVolume = info.volume3D;
meta = info.meta;

[nSpec, nX, nY, nZ] = size(spectrum4D);
if nargin < 2 || isempty(currentVoxel)
    currentVoxel = [ceil(nX / 2), ceil(nY / 2), ceil(nZ / 2)];
end

current = struct( ...
    'x', clampConversionIndex(currentVoxel(1), nX), ...
    'y', clampConversionIndex(currentVoxel(2), nY), ...
    'z', clampConversionIndex(currentVoxel(3), nZ));

correctedSpectrum4D = applyMetaPhaseIfNeeded(spectrum4D, meta);
definitions = loadInitialDefinitions(meta, nSpec);
selectedDefinitionIndex = [];
isPickingRange = false;
pickedRangePoints = [];

defaultOutputName = matlab.lang.makeValidName([info.varName '_conversion']);
if isfield(meta, 'lastConversionOutputName') && ~isempty(meta.lastConversionOutputName)
    defaultOutputName = char(string(meta.lastConversionOutputName));
end

fig = uifigure('Name', ['Calculate convertion: ' info.varName], 'Position', [110 110 1500 820]);
movegui(fig, 'center');

mainGrid = uigridlayout(fig, [3, 4]);
mainGrid.RowHeight = {'1x', '1x', 40};
mainGrid.ColumnWidth = {'1x', '1x', '1x', 400};
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

controlPanel = uipanel(mainGrid, 'Title', 'Conversion Controls');
controlPanel.Layout.Row = [1 2];
controlPanel.Layout.Column = 4;

controlsGrid = uigridlayout(controlPanel, [7, 1]);
controlsGrid.RowHeight = {108, 138, 72, 220, 42, 74, '1x'};
controlsGrid.RowSpacing = 8;
controlsGrid.ColumnSpacing = 0;
controlsGrid.Padding = [10 10 10 10];
controlsGrid.Scrollable = 'on';

voxelGrid = uigridlayout(controlsGrid, [3, 2]);
voxelGrid.RowHeight = {22, 22, 22};
voxelGrid.ColumnWidth = {70, '1x'};
voxelGrid.RowSpacing = 6;
voxelGrid.ColumnSpacing = 8;
voxelGrid.Padding = [0 0 0 0];
voxelGrid.Layout.Row = 1;
voxelGrid.Layout.Column = 1;

labelX = uilabel(voxelGrid, 'Text', 'Voxel X');
labelX.Layout.Row = 1;
labelX.Layout.Column = 1;
spinX = uispinner(voxelGrid, 'Limits', [1, nX], 'RoundFractionalValues', true, 'Value', current.x, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());
spinX.Layout.Row = 1;
spinX.Layout.Column = 2;

labelY = uilabel(voxelGrid, 'Text', 'Voxel Y');
labelY.Layout.Row = 2;
labelY.Layout.Column = 1;
spinY = uispinner(voxelGrid, 'Limits', [1, nY], 'RoundFractionalValues', true, 'Value', current.y, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());
spinY.Layout.Row = 2;
spinY.Layout.Column = 2;

labelZ = uilabel(voxelGrid, 'Text', 'Voxel Z');
labelZ.Layout.Row = 3;
labelZ.Layout.Column = 1;
spinZ = uispinner(voxelGrid, 'Limits', [1, nZ], 'RoundFractionalValues', true, 'Value', current.z, ...
    'ValueChangedFcn', @(~, ~) onVoxelSpinnerChanged());
spinZ.Layout.Row = 3;
spinZ.Layout.Column = 2;

entryGrid = uigridlayout(controlsGrid, [4, 2]);
entryGrid.RowHeight = {22, 32, 32, 32};
entryGrid.ColumnWidth = {95, '1x'};
entryGrid.RowSpacing = 6;
entryGrid.ColumnSpacing = 8;
entryGrid.Padding = [0 0 0 0];
entryGrid.Layout.Row = 2;
entryGrid.Layout.Column = 1;

nameLabel = uilabel(entryGrid, 'Text', 'Variable name');
nameLabel.Layout.Row = 1;
nameLabel.Layout.Column = 1;
nameField = uieditfield(entryGrid, 'text', 'Value', nextDefaultName(definitions));
nameField.Layout.Row = 1;
nameField.Layout.Column = 2;

startLabel = uilabel(entryGrid, 'Text', 'Start index');
startLabel.Layout.Row = 2;
startLabel.Layout.Column = 1;
startField = uieditfield(entryGrid, 'numeric', 'Limits', [1, nSpec], ...
    'RoundFractionalValues', true, 'Value', 1);
startField.Layout.Row = 2;
startField.Layout.Column = 2;

endLabel = uilabel(entryGrid, 'Text', 'End index');
endLabel.Layout.Row = 3;
endLabel.Layout.Column = 1;
endField = uieditfield(entryGrid, 'numeric', 'Limits', [1, nSpec], ...
    'RoundFractionalValues', true, 'Value', min(nSpec, 10));
endField.Layout.Row = 3;
endField.Layout.Column = 2;

divisorLabel = uilabel(entryGrid, 'Text', 'Divisor');
divisorLabel.Layout.Row = 4;
divisorLabel.Layout.Column = 1;
divisorField = uieditfield(entryGrid, 'numeric', 'Value', 1);
divisorField.Layout.Row = 4;
divisorField.Layout.Column = 2;

buttonGrid = uigridlayout(controlsGrid, [2, 2]);
buttonGrid.RowHeight = {32, 32};
buttonGrid.ColumnWidth = {'1x', '1x'};
buttonGrid.RowSpacing = 8;
buttonGrid.ColumnSpacing = 8;
buttonGrid.Padding = [0 0 0 0];
buttonGrid.Layout.Row = 3;
buttonGrid.Layout.Column = 1;

addButton = uibutton(buttonGrid, 'push', 'Text', 'Add variable', ...
    'ButtonPushedFcn', @(~, ~) onAddVariable());
addButton.Layout.Row = 1;
addButton.Layout.Column = 1;

updateButton = uibutton(buttonGrid, 'push', 'Text', 'Update selected', ...
    'ButtonPushedFcn', @(~, ~) onUpdateSelected());
updateButton.Layout.Row = 1;
updateButton.Layout.Column = 2;

removeButton = uibutton(buttonGrid, 'push', 'Text', 'Remove selected', ...
    'ButtonPushedFcn', @(~, ~) onRemoveSelected());
removeButton.Layout.Row = 2;
removeButton.Layout.Column = 1;

pickRangeButton = uibutton(buttonGrid, 'push', 'Text', 'Pick range on plot', ...
    'Tooltip', {'Select two points on the spectrum plot for the variable range.'}, ...
    'ButtonPushedFcn', @(~, ~) onPickRangeFromPlot());
pickRangeButton.Layout.Row = 2;
pickRangeButton.Layout.Column = 2;

variableTable = uitable(controlsGrid, ...
    'ColumnName', {'Name', 'Start', 'End', 'Divisor', 'Num', 'Den', 'Value'}, ...
    'ColumnEditable', [true true true true true true false], ...
    'ColumnFormat', {'char', 'numeric', 'numeric', 'numeric', 'logical', 'logical', 'numeric'}, ...
    'RowName', {}, ...
    'CellSelectionCallback', @(src, event) onTableSelection(event), ...
    'CellEditCallback', @(src, event) onTableEdited(src, event));
variableTable.Layout.Row = 4;
variableTable.Layout.Column = 1;
variableTable.ColumnWidth = {90, 55, 55, 75, 45, 45, 70};

outputGrid = uigridlayout(controlsGrid, [1, 2]);
outputGrid.RowHeight = {32};
outputGrid.ColumnWidth = {90, '1x'};
outputGrid.ColumnSpacing = 8;
outputGrid.Padding = [0 0 0 0];
outputGrid.Layout.Row = 5;
outputGrid.Layout.Column = 1;

outputLabel = uilabel(outputGrid, 'Text', 'Output name');
outputLabel.Layout.Row = 1;
outputLabel.Layout.Column = 1;
outputField = uieditfield(outputGrid, 'text', 'Value', defaultOutputName);
outputField.Layout.Row = 1;
outputField.Layout.Column = 2;

resultGrid = uigridlayout(controlsGrid, [3, 1]);
resultGrid.RowHeight = {32, 18, 18};
resultGrid.RowSpacing = 4;
resultGrid.Padding = [0 0 0 0];
resultGrid.Layout.Row = 6;
resultGrid.Layout.Column = 1;

calcButton = uibutton(resultGrid, 'push', 'Text', 'Calculate current voxel', ...
    'ButtonPushedFcn', @(~, ~) onCalculateCurrentVoxel());
calcButton.Layout.Row = 1;
calcButton.Layout.Column = 1;

resultLabel = uilabel(resultGrid, 'Text', 'Result: not calculated yet', 'WordWrap', 'on');
resultLabel.Layout.Row = 2;
resultLabel.Layout.Column = 1;

fractionLabel = uilabel(resultGrid, 'Text', 'Numerator / Denominator: - / -', 'WordWrap', 'on');
fractionLabel.Layout.Row = 3;
fractionLabel.Layout.Column = 1;

saveGrid = uigridlayout(controlsGrid, [2, 1]);
saveGrid.RowHeight = {32, '1x'};
saveGrid.RowSpacing = 6;
saveGrid.Padding = [0 0 0 0];
saveGrid.Layout.Row = 7;
saveGrid.Layout.Column = 1;

saveButton = uibutton(saveGrid, 'push', 'Text', 'Save result volume', ...
    'ButtonPushedFcn', @(~, ~) onSaveResultVolume());
saveButton.Layout.Row = 1;
saveButton.Layout.Column = 1;

panelStatusLabel = uilabel(saveGrid, 'Text', 'Configure variables, then calculate or save.', 'WordWrap', 'on');
panelStatusLabel.Layout.Row = 2;
panelStatusLabel.Layout.Column = 1;

statusLabel = uilabel(mainGrid, 'Text', 'Click slices to choose a voxel. The table controls inclusion in numerator and denominator.', ...
    'WordWrap', 'on');
statusLabel.Layout.Row = 3;
statusLabel.Layout.Column = [1 4];

refreshAll();

    function onVoxelSpinnerChanged()
        current.x = round(spinX.Value);
        current.y = round(spinY.Value);
        current.z = round(spinZ.Value);
        refreshAll();
    end

    function onAddVariable()
        try
            newDef = buildDefinitionFromFields();
            definitions = [definitions; newDef];
            selectedDefinitionIndex = numel(definitions);
            nameField.Value = nextDefaultName(definitions);
            panelStatusLabel.Text = sprintf('Added variable "%s".', newDef.name);
            refreshAll();
        catch ME
            uialert(fig, ME.message, 'Error');
        end
    end

    function onUpdateSelected()
        if isempty(selectedDefinitionIndex) || selectedDefinitionIndex < 1 || selectedDefinitionIndex > numel(definitions)
            uialert(fig, 'Select a variable in the table first.', 'Error');
            return;
        end

        try
            updatedDef = buildDefinitionFromFields();
            definitions(selectedDefinitionIndex) = updatedDef;
            panelStatusLabel.Text = sprintf('Updated variable "%s".', updatedDef.name);
            refreshAll();
        catch ME
            uialert(fig, ME.message, 'Error');
        end
    end

    function onRemoveSelected()
        if isempty(selectedDefinitionIndex) || selectedDefinitionIndex < 1 || selectedDefinitionIndex > numel(definitions)
            uialert(fig, 'Select a variable in the table first.', 'Error');
            return;
        end

        removedName = definitions(selectedDefinitionIndex).name;
        definitions(selectedDefinitionIndex) = [];
        if isempty(definitions)
            selectedDefinitionIndex = [];
        else
            selectedDefinitionIndex = min(selectedDefinitionIndex, numel(definitions));
        end
        nameField.Value = nextDefaultName(definitions);
        panelStatusLabel.Text = sprintf('Removed variable "%s".', removedName);
        refreshAll();
    end

    function onPickRangeFromPlot()
        isPickingRange = true;
        pickedRangePoints = [];
        panelStatusLabel.Text = 'Click two points on the spectrum plot to set the variable range.';
        updateSpectrumPlot();
    end

    function onCalculateCurrentVoxel()
        try
            defs = validateDefinitionsForComputation(definitions);
            currentSpectrum = correctedSpectrum4D(:, current.x, current.y, current.z);
            [resultValue, details] = evaluateSpectralConversionValue(currentSpectrum, defs, struct());
            resultLabel.Text = sprintf('Result: %.6g', resultValue);
            fractionLabel.Text = sprintf('Numerator / Denominator: %.6g / %.6g', ...
                details.numeratorValue, details.denominatorValue);
            panelStatusLabel.Text = sprintf('Calculated current voxel (%d, %d, %d).', ...
                current.x, current.y, current.z);
            refreshTable();
        catch ME
            uialert(fig, ME.message, 'Error');
        end
    end

    function onSaveResultVolume()
        try
            defs = validateDefinitionsForComputation(definitions);
            outputName = strtrim(outputField.Value);
            if isempty(outputName)
                error('Output name cannot be empty.');
            end

            outputName = matlab.lang.makeValidName(outputName);
            outputField.Value = outputName;

            [resultVolume, details] = buildSpectralConversionVolume(spectrum4D, defs, meta);
            assignin('base', outputName, resultVolume);

            meta.conversionDefinitions = defs;
            meta.lastConversionOutputName = outputName;
            meta.lastConversionUpdatedAt = char(datetime('now'));
            assignin('base', info.metaVarName, meta);

            currentValue = resultVolume(current.x, current.y, current.z);
            resultLabel.Text = sprintf('Result: %.6g', currentValue);
            fractionLabel.Text = sprintf('Numerator / Denominator: %.6g / %.6g', ...
                details.numerator(current.x, current.y, current.z), ...
                details.denominator(current.x, current.y, current.z));
            panelStatusLabel.Text = sprintf('Saved conversion volume as "%s".', outputName);
        catch ME
            uialert(fig, ME.message, 'Error');
        end
    end

    function onTableSelection(event)
        if isempty(event.Indices)
            return;
        end

        selectedDefinitionIndex = event.Indices(1);
        if selectedDefinitionIndex >= 1 && selectedDefinitionIndex <= numel(definitions)
            loadDefinitionIntoFields(definitions(selectedDefinitionIndex));
        end
    end

    function onTableEdited(src, event)
        previousDefs = definitions;
        try
            definitions = definitionsFromTableData(src.Data);
            if isempty(event.Indices)
                selectedDefinitionIndex = [];
            else
                selectedDefinitionIndex = event.Indices(1);
            end
            if ~isempty(selectedDefinitionIndex) && selectedDefinitionIndex <= numel(definitions)
                loadDefinitionIntoFields(definitions(selectedDefinitionIndex));
            end
            panelStatusLabel.Text = 'Variable table updated.';
            refreshAll();
        catch ME
            definitions = previousDefs;
            refreshTable();
            uialert(fig, ME.message, 'Error');
        end
    end

    function refreshAll()
        updateSliceViews();
        updateSpectrumPlot();
        refreshTable();
    end

    function refreshTable()
        currentSpectrum = correctedSpectrum4D(:, current.x, current.y, current.z);
        variableValues = zeros(numel(definitions), 1);
        for iDef = 1:numel(definitions)
            idxRange = definitions(iDef).startIndex:definitions(iDef).endIndex;
            variableValues(iDef) = sum(abs(currentSpectrum(idxRange)));
        end
        variableTable.Data = buildTableData(definitions, variableValues);
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
                current.x = clampConversionIndex(yClick, nX);
                current.y = clampConversionIndex(xClick, nY);
            case 'coronal'
                current.x = clampConversionIndex(yClick, nX);
                current.z = clampConversionIndex(xClick, nZ);
            case 'sagittal'
                current.y = clampConversionIndex(xClick, nY);
                current.z = clampConversionIndex(yClick, nZ);
        end

        spinX.Value = current.x;
        spinY.Value = current.y;
        spinZ.Value = current.z;
        refreshAll();
    end

    function updateSpectrumPlot()
        cla(spectrumAxes);
        currentSpectrum = abs(correctedSpectrum4D(:, current.x, current.y, current.z));
        hSpec = plot(spectrumAxes, currentSpectrum, 'b-', 'LineWidth', 1.2);
        title(spectrumAxes, sprintf('Spectrum (%d, %d, %d)', current.x, current.y, current.z));
        xlabel(spectrumAxes, 'Spectral point');
        ylabel(spectrumAxes, 'Amplitude');
        grid(spectrumAxes, 'on');
        hold(spectrumAxes, 'on');
        plotDefinitionRanges();
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

    function plotDefinitionRanges()
        colors = lines(max(numel(definitions), 1));
        for iDef = 1:numel(definitions)
            c = colors(iDef, :);
            xline(spectrumAxes, definitions(iDef).startIndex, '-', 'Color', c, 'Alpha', 0.25);
            xline(spectrumAxes, definitions(iDef).endIndex, '-', 'Color', c, 'Alpha', 0.25);
        end

        if ~isempty(selectedDefinitionIndex) && selectedDefinitionIndex >= 1 && selectedDefinitionIndex <= numel(definitions)
            selectedDef = definitions(selectedDefinitionIndex);
            patch(spectrumAxes, ...
                [selectedDef.startIndex, selectedDef.endIndex, selectedDef.endIndex, selectedDef.startIndex], ...
                [0, 0, spectrumAxes.YLim(2), spectrumAxes.YLim(2)], ...
                [1, 0.85, 0.2], 'FaceAlpha', 0.15, 'EdgeColor', 'none');
        else
            enteredRange = sort([startField.Value, endField.Value]);
            enteredRange = [clampConversionIndex(enteredRange(1), nSpec), clampConversionIndex(enteredRange(2), nSpec)];
            patch(spectrumAxes, ...
                [enteredRange(1), enteredRange(2), enteredRange(2), enteredRange(1)], ...
                [0, 0, spectrumAxes.YLim(2), spectrumAxes.YLim(2)], ...
                [0.8, 0.9, 1], 'FaceAlpha', 0.12, 'EdgeColor', 'none');
        end
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

        xClick = clampConversionIndex(xClick, nSpec);
        pickedRangePoints(end + 1) = xClick;

        if numel(pickedRangePoints) >= 2
            chosenRange = sort(pickedRangePoints(1:2));
            startField.Value = chosenRange(1);
            endField.Value = chosenRange(2);
            pickedRangePoints = [];
            isPickingRange = false;
            panelStatusLabel.Text = sprintf('Picked range [%d, %d] for variable "%s".', ...
                chosenRange(1), chosenRange(2), strtrim(nameField.Value));
        else
            panelStatusLabel.Text = sprintf('First range point selected: %d. Click the second point.', xClick);
        end

        updateSpectrumPlot();
    end

    function loadDefinitionIntoFields(definition)
        nameField.Value = definition.name;
        startField.Value = definition.startIndex;
        endField.Value = definition.endIndex;
        divisorField.Value = definition.divisor;
        updateSpectrumPlot();
    end

    function newDef = buildDefinitionFromFields()
        newName = strtrim(nameField.Value);
        if isempty(newName)
            error('Variable name cannot be empty.');
        end

        newStart = clampConversionIndex(startField.Value, nSpec);
        newEnd = clampConversionIndex(endField.Value, nSpec);
        if newStart > newEnd
            tmp = newStart;
            newStart = newEnd;
            newEnd = tmp;
        end

        newDivisor = double(divisorField.Value);
        if ~isscalar(newDivisor) || ~isfinite(newDivisor) || newDivisor == 0
            error('Divisor must be a finite non-zero scalar.');
        end

        existingNames = string({definitions.name});
        selectedMask = false(size(existingNames));
        if ~isempty(selectedDefinitionIndex) && selectedDefinitionIndex >= 1 && selectedDefinitionIndex <= numel(existingNames)
            selectedMask(selectedDefinitionIndex) = true;
        end

        duplicateMask = strcmpi(existingNames, newName) & ~selectedMask;
        if any(duplicateMask)
            error('Variable name "%s" already exists.', newName);
        end

        newDef = struct( ...
            'name', newName, ...
            'startIndex', newStart, ...
            'endIndex', newEnd, ...
            'divisor', newDivisor, ...
            'useNumerator', true, ...
            'useDenominator', false);

        if ~isempty(selectedDefinitionIndex) && selectedDefinitionIndex >= 1 && selectedDefinitionIndex <= numel(definitions)
            newDef.useNumerator = definitions(selectedDefinitionIndex).useNumerator;
            newDef.useDenominator = definitions(selectedDefinitionIndex).useDenominator;
        end
    end
end

function correctedSpectrum4D = applyMetaPhaseIfNeeded(spectrum4D, meta)
correctedSpectrum4D = spectrum4D;
if isstruct(meta) && isfield(meta, 'phaseEnabled') && meta.phaseEnabled ...
        && isfield(meta, 'phaseParams') && isstruct(meta.phaseParams)
    params = meta.phaseParams;
    correctedSpectrum4D = applyPhaseCorrection(spectrum4D, ...
        params.ph0Deg, params.ph1Deg, params.pivotIndex);
end
end

function definitions = loadInitialDefinitions(meta, nSpec)
definitions = repmat(makeDefaultDefinition('var1', 1, min(nSpec, 10), 1, true, false), 0, 1);

if isstruct(meta) && isfield(meta, 'conversionDefinitions') && ~isempty(meta.conversionDefinitions)
    rawDefs = meta.conversionDefinitions;
    definitions = repmat(makeDefaultDefinition('var1', 1, min(nSpec, 10), 1, true, false), numel(rawDefs), 1);
    for iDef = 1:numel(rawDefs)
        src = rawDefs(iDef);
        if isfield(src, 'name')
            name = char(string(src.name));
        else
            name = sprintf('var%d', iDef);
        end

        startIndex = 1;
        endIndex = min(nSpec, 10);
        if isfield(src, 'startIndex')
            startIndex = src.startIndex;
        elseif isfield(src, 'range') && numel(src.range) >= 1
            startIndex = src.range(1);
        end
        if isfield(src, 'endIndex')
            endIndex = src.endIndex;
        elseif isfield(src, 'range') && numel(src.range) >= 2
            endIndex = src.range(2);
        end

        definitions(iDef) = makeDefaultDefinition( ...
            name, ...
            clampConversionIndex(startIndex, nSpec), ...
            clampConversionIndex(endIndex, nSpec), ...
            getOptionalDivisor(src, 1), ...
            getOptionalLogical(src, 'useNumerator', true), ...
            getOptionalLogical(src, 'useDenominator', false));

        if definitions(iDef).startIndex > definitions(iDef).endIndex
            tmp = definitions(iDef).startIndex;
            definitions(iDef).startIndex = definitions(iDef).endIndex;
            definitions(iDef).endIndex = tmp;
        end
    end
end
end

function defs = validateDefinitionsForComputation(definitions)
if isempty(definitions)
    error('Add at least one variable before calculation.');
end
defs = definitions;
if ~any([defs.useNumerator])
    error('At least one variable must be included in the numerator.');
end
if ~any([defs.useDenominator])
    error('At least one variable must be included in the denominator.');
end
end

function data = buildTableData(definitions, variableValues)
data = cell(numel(definitions), 7);
for iDef = 1:numel(definitions)
    data{iDef, 1} = definitions(iDef).name;
    data{iDef, 2} = definitions(iDef).startIndex;
    data{iDef, 3} = definitions(iDef).endIndex;
    data{iDef, 4} = definitions(iDef).divisor;
    data{iDef, 5} = logical(definitions(iDef).useNumerator);
    data{iDef, 6} = logical(definitions(iDef).useDenominator);
    data{iDef, 7} = variableValues(iDef);
end
end

function definitions = definitionsFromTableData(tableData)
if isempty(tableData)
    definitions = repmat(makeDefaultDefinition('var1', 1, 1, 1, true, false), 0, 1);
    return;
end

nRows = size(tableData, 1);
definitions = repmat(makeDefaultDefinition('var1', 1, 1, 1, true, false), nRows, 1);
usedNames = strings(0, 1);

for iRow = 1:nRows
    name = strtrim(string(tableData{iRow, 1}));
    if strlength(name) == 0
        error('Variable name cannot be empty.');
    end
    if any(usedNames == lower(name))
        error('Duplicate variable name: %s', name);
    end
    usedNames(end + 1, 1) = lower(name); %#ok<AGROW>

    startIndex = round(double(tableData{iRow, 2}));
    endIndex = round(double(tableData{iRow, 3}));
    if ~isfinite(startIndex) || ~isfinite(endIndex)
        error('Variable range must be numeric.');
    end

    divisor = double(tableData{iRow, 4});
    if ~isscalar(divisor) || ~isfinite(divisor) || divisor == 0
        error('Divisor must be a finite non-zero scalar.');
    end

    if startIndex > endIndex
        tmp = startIndex;
        startIndex = endIndex;
        endIndex = tmp;
    end

    definitions(iRow) = makeDefaultDefinition( ...
        char(name), ...
        startIndex, ...
        endIndex, ...
        divisor, ...
        logical(tableData{iRow, 5}), ...
        logical(tableData{iRow, 6}));
end
end

function name = nextDefaultName(definitions)
candidate = numel(definitions) + 1;
existingNames = string({definitions.name});
while any(strcmpi(existingNames, sprintf('var%d', candidate)))
    candidate = candidate + 1;
end
name = sprintf('var%d', candidate);
end

function definition = makeDefaultDefinition(name, startIndex, endIndex, divisor, useNumerator, useDenominator)
definition = struct( ...
    'name', char(string(name)), ...
    'startIndex', round(startIndex), ...
    'endIndex', round(endIndex), ...
    'divisor', double(divisor), ...
    'useNumerator', logical(useNumerator), ...
    'useDenominator', logical(useDenominator));
end

function value = clampConversionIndex(value, maxValue)
value = max(1, min(maxValue, round(value)));
end

function value = getOptionalNumeric(src, fieldName, defaultValue)
if isfield(src, fieldName)
    value = double(src.(fieldName));
else
    value = defaultValue;
end
end

function value = getOptionalDivisor(src, defaultValue)
if isfield(src, 'divisor')
    value = double(src.divisor);
elseif isfield(src, 'multiplier')
    value = double(src.multiplier);
else
    value = defaultValue;
end

if ~isscalar(value) || ~isfinite(value) || value == 0
    error('Divisor must be a finite non-zero scalar.');
end
end

function value = getOptionalLogical(src, fieldName, defaultValue)
if ~isfield(src, fieldName)
    value = defaultValue;
    return;
end

rawValue = src.(fieldName);
if islogical(rawValue)
    value = logical(rawValue);
else
    value = logical(double(rawValue));
end
end
