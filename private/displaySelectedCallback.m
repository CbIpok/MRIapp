function displaySelectedCallback(listBox, maskList)
    % Получаем выбранный элемент из списка файлов.
    selectedItems = listBox.Value;
    if isempty(selectedItems)
        uialert(listBox.Parent, 'Не выбран ни один элемент.', 'Ошибка');
        return;
    end

    % Если выбрано несколько, берем первый.
    if iscell(selectedItems)
        selectedStr = selectedItems{1};
    else
        selectedStr = selectedItems;
    end

    % Предполагается, что строка имеет формат: "имя_файла [x, y, z]"
    tokens = strsplit(selectedStr, ' ');
    fileNameWithExt = tokens{1};

    % Извлекаем имя переменной (без расширения)
    [varName, ~, ~] = fileparts(fileNameWithExt);
    varName = fileNameWithExt;  % если имя переменной совпадает с именем файла

    % Получаем 3D-массив из базового рабочего пространства
    try
        array3D = evalin('base', varName);
    catch
        uialert(listBox.Parent, ['Переменная "', varName, '" не найдена в базовом рабочем пространстве.'], 'Ошибка');
        return;
    end

    % Проверяем, что массив трехмерный
    if ndims(array3D) < 3
        uialert(listBox.Parent, 'Выбранный элемент не является 3D массивом.', 'Ошибка');
        return;
    end

    % Получаем количество срезов по оси z
    [~, ~, numSlices] = size(array3D);

    % Вычисляем оптимальное число строк и столбцов для субплотов
    cols = ceil(sqrt(numSlices));
    rows = ceil(numSlices / cols);

    % Определяем общий диапазон значений для корректного отображения colormap
    globalMin = min(array3D(:));
    globalMax = max(array3D(:));

    % Создаем новое окно для отображения срезов
    figSlices = figure('Name', sprintf('Срезы: %s', varName));

    for i = 1:numSlices
        subplot(rows, cols, i);
        imagesc(array3D(:,:,i), [globalMin, globalMax]);  % единое масштабирование
        axis image off;
        title(sprintf('z = %d', i));

        % Если передан список масок и в нем выбран элемент,
        % пытаемся наложить полупрозрачную розовую маску.
        if nargin > 1 && ~isempty(maskList) && ~isempty(maskList.Value)
            % Если выбрано несколько масок, берем первую.
            if iscell(maskList.Value)
                maskNameStr = maskList.Value{1};
            else
                maskNameStr = maskList.Value;
            end

            % Попытка получить маску из базового workspace.
            try
                mask = evalin('base', maskNameStr);
            catch
                continue;
            end

            % Проверяем, что маска – логическая и ее размер совпадает с размером среза.
            if islogical(mask) && all(size(mask) == size(array3D(:,:,i)))
                hold on;
                % Создаем RGB-изображение, где все пиксели розовые: [1 0 1]
                maskRGB = repmat(reshape([1, 0, 1], 1, 1, 3), size(mask,1), size(mask,2));
                % Отображаем его поверх среза с прозрачностью 0.5 там, где маска истинна.
                hMask = image(maskRGB, 'Parent', gca);
                set(hMask, 'AlphaData', 0.25 * double(mask));
                hold off;
            end
        end
    end

    % Задаем единый colormap для всех осей, например, jet.
    colormap(jet);

    % Добавляем общий цветовой бар (расположен с правой стороны окна)
    cb = colorbar('Position',[0.92 0.1 0.02 0.8]);
end
