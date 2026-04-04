function openConversionDistributionFigure(volume3D, currentVoxel, figureTitle)
%OPENCONVERSIONDISTRIBUTIONFIGURE Read-only viewer for conversion maps.

volume3D = normalizeVolumeForDisplay(volume3D);
[nX, nY, nZ] = size(volume3D);

if nargin < 2 || isempty(currentVoxel)
    currentVoxel = [ceil(nX / 2), ceil(nY / 2), ceil(nZ / 2)];
end

if nargin < 3 || isempty(figureTitle)
    figureTitle = 'Conversion distribution';
end

current = struct( ...
    'x', clampViewerIndex(currentVoxel(1), nX), ...
    'y', clampViewerIndex(currentVoxel(2), nY), ...
    'z', clampViewerIndex(currentVoxel(3), nZ));

fig = uifigure('Name', figureTitle, 'Position', [130 130 1320 760]);
movegui(fig, 'center');

mainGrid = uigridlayout(fig, [2, 4]);
mainGrid.RowHeight = {'1x', 34};
mainGrid.ColumnWidth = {'1x', '1x', '1x', 230};
mainGrid.RowSpacing = 10;
mainGrid.ColumnSpacing = 10;
mainGrid.Padding = [10 10 10 10];

axesGrid = uigridlayout(mainGrid, [2, 2]);
axesGrid.RowHeight = {'1x', '1x'};
axesGrid.ColumnWidth = {'1x', '1x'};
axesGrid.RowSpacing = 10;
axesGrid.ColumnSpacing = 10;
axesGrid.Layout.Row = 1;
axesGrid.Layout.Column = [1 3];

axialAxes = uiaxes(axesGrid);
axialAxes.Layout.Row = 1;
axialAxes.Layout.Column = 1;

coronalAxes = uiaxes(axesGrid);
coronalAxes.Layout.Row = 1;
coronalAxes.Layout.Column = 2;

sagittalAxes = uiaxes(axesGrid);
sagittalAxes.Layout.Row = 2;
sagittalAxes.Layout.Column = 1;

colorAxes = uiaxes(axesGrid);
colorAxes.Layout.Row = 2;
colorAxes.Layout.Column = 2;

controlPanel = uipanel(mainGrid, 'Title', 'View Controls');
controlPanel.Layout.Row = 1;
controlPanel.Layout.Column = 4;

controlsGrid = uigridlayout(controlPanel, [10, 2]);
controlsGrid.RowHeight = {22, 32, 22, 32, 22, 32, 22, 22, 22, '1x'};
controlsGrid.ColumnWidth = {70, '1x'};
controlsGrid.RowSpacing = 8;
controlsGrid.ColumnSpacing = 8;
controlsGrid.Padding = [10 10 10 10];

labelX = uilabel(controlsGrid, 'Text', 'Voxel X');
labelX.Layout.Row = 1;
labelX.Layout.Column = 1;
spinX = uispinner(controlsGrid, 'Limits', [1, nX], ...
    'RoundFractionalValues', true, 'Value', current.x, ...
    'ValueChangedFcn', @(~, ~) onVoxelChanged());
spinX.Layout.Row = 2;
spinX.Layout.Column = [1 2];

labelY = uilabel(controlsGrid, 'Text', 'Voxel Y');
labelY.Layout.Row = 3;
labelY.Layout.Column = 1;
spinY = uispinner(controlsGrid, 'Limits', [1, nY], ...
    'RoundFractionalValues', true, 'Value', current.y, ...
    'ValueChangedFcn', @(~, ~) onVoxelChanged());
spinY.Layout.Row = 4;
spinY.Layout.Column = [1 2];

labelZ = uilabel(controlsGrid, 'Text', 'Voxel Z');
labelZ.Layout.Row = 5;
labelZ.Layout.Column = 1;
spinZ = uispinner(controlsGrid, 'Limits', [1, nZ], ...
    'RoundFractionalValues', true, 'Value', current.z, ...
    'ValueChangedFcn', @(~, ~) onVoxelChanged());
spinZ.Layout.Row = 6;
spinZ.Layout.Column = [1 2];

rangeLabel = uilabel(controlsGrid, ...
    'Text', sprintf('Value: %.6g', volume3D(current.x, current.y, current.z)), ...
    'WordWrap', 'on');
rangeLabel.Layout.Row = 7;
rangeLabel.Layout.Column = [1 2];

minLabel = uilabel(controlsGrid, ...
    'Text', sprintf('Min: %.6g', min(volume3D(:), [], 'omitnan')), ...
    'WordWrap', 'on');
minLabel.Layout.Row = 8;
minLabel.Layout.Column = [1 2];

maxLabel = uilabel(controlsGrid, ...
    'Text', sprintf('Max: %.6g', max(volume3D(:), [], 'omitnan')), ...
    'WordWrap', 'on');
maxLabel.Layout.Row = 9;
maxLabel.Layout.Column = [1 2];

statusLabel = uilabel(mainGrid, ...
    'Text', 'Read-only view of the current conversion distribution.', ...
    'WordWrap', 'on');
statusLabel.Layout.Row = 2;
statusLabel.Layout.Column = [1 4];

updateViews();

    function onVoxelChanged()
        current.x = round(spinX.Value);
        current.y = round(spinY.Value);
        current.z = round(spinZ.Value);
        updateViews();
    end

    function updateViews()
        axialSlice = volume3D(:, :, current.z);
        coronalSlice = reshape(volume3D(:, current.y, :), [nX, nZ]);
        sagittalSlice = reshape(volume3D(current.x, :, :), [nY, nZ])';

        plotSlice(axialAxes, axialSlice, sprintf('Axial (Z = %d)', current.z), current.y, current.x);
        plotSlice(coronalAxes, coronalSlice, sprintf('Coronal (Y = %d)', current.y), current.z, current.x);
        plotSlice(sagittalAxes, sagittalSlice, sprintf('Sagittal (X = %d)', current.x), current.y, current.z);
        updateColorbarView();

        rangeLabel.Text = sprintf('Value: %.6g', volume3D(current.x, current.y, current.z));
    end

    function plotSlice(ax, sliceData, plotTitle, markerX, markerY)
        imagesc(ax, sliceData);
        axis(ax, 'image');
        ax.XTick = [];
        ax.YTick = [];
        title(ax, plotTitle);
        colormap(ax, hot);
        hold(ax, 'on');
        plot(ax, markerX, markerY, 'g+', 'MarkerSize', 10, 'LineWidth', 1.5);
        hold(ax, 'off');
    end

    function updateColorbarView()
        cla(colorAxes);
        grad = repmat(linspace(min(volume3D(:), [], 'omitnan'), max(volume3D(:), [], 'omitnan'), 256), 40, 1);
        imagesc(colorAxes, grad);
        colorAxes.YTick = [];
        colorAxes.XTick = linspace(1, 256, 5);
        colorAxes.XTickLabel = num2cell(linspace(min(volume3D(:), [], 'omitnan'), ...
            max(volume3D(:), [], 'omitnan'), 5));
        title(colorAxes, 'Color scale');
        colormap(colorAxes, hot);
    end
end

function value = clampViewerIndex(value, maxValue)
value = max(1, min(maxValue, round(value)));
end
