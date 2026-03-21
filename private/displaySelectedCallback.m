function displaySelectedCallback(listBox, maskList)
    parentFigure = ancestor(listBox, 'figure');

    selectedItems = listBox.Value;
    if isempty(selectedItems)
        uialert(parentFigure, 'Не выбран ни один элемент.', 'Ошибка');
        return;
    end

    if iscell(selectedItems)
        selectedStr = selectedItems{1};
    else
        selectedStr = selectedItems;
    end

    varName = parseVolumeListItem(selectedStr);

    try
        array3D = evalin('base', varName);
    catch
        uialert(parentFigure, ['Переменная "' varName '" не найдена в базовом рабочем пространстве.'], 'Ошибка');
        return;
    end

    if ndims(array3D) > 3
        uialert(parentFigure, 'Выбранный элемент не является 3D массивом.', 'Ошибка');
        return;
    end

    [~, ~, numSlices] = size(array3D);
    cols = ceil(sqrt(numSlices));
    rows = ceil(numSlices / cols);

    globalMin = min(array3D(:));
    globalMax = max(array3D(:));

    figure('Name', sprintf('Срезы: %s', varName));

    for i = 1:numSlices
        subplot(rows, cols, i);
        imagesc(array3D(:, :, i), [globalMin, globalMax]);
        axis image off;
        title(sprintf('z = %d', i));

        if nargin > 1 && ~isempty(maskList) && ~isempty(maskList.Value)
            if iscell(maskList.Value)
                maskNameStr = maskList.Value{1};
            else
                maskNameStr = maskList.Value;
            end

            try
                mask = evalin('base', maskNameStr);
            catch
                continue;
            end

            if islogical(mask) && all(size(mask) == size(array3D(:, :, i)))
                hold on;
                maskRGB = repmat(reshape([1, 0, 1], 1, 1, 3), size(mask, 1), size(mask, 2));
                hMask = image(maskRGB, 'Parent', gca);
                set(hMask, 'AlphaData', 0.25 * double(mask));
                hold off;
            end
        end
    end

    colormap(jet);
    colorbar('Position', [0.92 0.1 0.02 0.8]);
end
