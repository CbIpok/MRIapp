function segmentLayerCallback(fileList, sliceField)
    % Получаем выбранный элемент из списка файлов
    selectedItems = fileList.Value;
    if isempty(selectedItems)
        uialert(fileList.Parent.Parent.Parent, 'Не выбран ни один файл.', 'Ошибка');
        return;
    end
    if iscell(selectedItems)
        selectedStr = selectedItems{1};
    else
        selectedStr = selectedItems;
    end

    % Ожидается формат: "имя_файла [x, y, z]"
    tokens = strsplit(selectedStr, ' ');
    fileNameWithExt = tokens{1};
    [varName, ~, ~] = fileparts(fileNameWithExt);
    varName = fileNameWithExt;  % если имя переменной совпадает с именем файла

    % Получаем 3D-массив из базового workspace
    try
        array3D = evalin('base', varName);
    catch
        uialert(fileList.Parent, ...
            ['Переменная "', varName, '" не найдена в базовом рабочем пространстве.'], ...
            'Ошибка');
        return;
    end

    % Проверяем корректность номера слоя
    sliceNumber = round(sliceField.Value);
    [~, ~, zDim] = size(array3D);
    if sliceNumber < 1 || sliceNumber > zDim
        uialert(fileList.Parent.Parent.Parent, sprintf('Номер слоя должен быть в диапазоне [1, %d].', zDim), 'Ошибка');
        return;
    end

    % Извлекаем указанный слой (2D-срез)
    sliceImage = array3D(:,:,sliceNumber);

    % Запускаем Image Segmenter с выбранным срезом
    imageSegmenter(sliceImage);
end
