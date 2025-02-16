function displaySelectedCallback(listBox)
    % Получаем выбранный элемент из списка.
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
    
    % Предполагается, что строка имеет формат:
    % "имя_файла [x, y, z]"
    % Извлекаем имя файла (первый токен до пробела).
    tokens = strsplit(selectedStr, ' ');
    fileNameWithExt = tokens{1};
    
    % Извлекаем имя переменной (без расширения)
    [varName, ~, ~] = fileparts(fileNameWithExt);
    varName = fileNameWithExt;
    
    % Получаем массив из базового рабочего пространства
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
    
    % Отображаем каждый срез вдоль оси z
    for i = 1:numSlices
        subplot(rows, cols, i);
        imagesc(array3D(:,:,i), [globalMin, globalMax]);  % единое масштабирование
        axis image off;
        title(sprintf('z = %d', i));
    end
    
    % Задаем единый colormap для всех осей, например, jet
    colormap(jet);
    
    % Добавляем общий цветовой бар (расположен с правой стороны окна)
    % Для создания единого colorbar используется размещение отдельной оси.
    cb = colorbar('Position',[0.92 0.1 0.02 0.8]);
end
