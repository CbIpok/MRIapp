function openFileCallback(edt1, edt2, edt3, listBox)
    % Считываем размеры массива из текстовых полей
    dimX = edt1.Value;
    dimY = edt2.Value;
    dimZ = edt3.Value;
    expectedTotalElements = dimX * dimY * dimZ;
    
    % Открываем диалоговое окно для выбора бинарного файла
    [fileName, pathName] = uigetfile({'*.bin;*.dat;*.*', 'Бинарные файлы (*.bin, *.dat, ...)'}, 'Выберите бинарный файл');
    
    if isequal(fileName, 0)
        disp('Файл не выбран.');
        return;
    end
    
    fullPath = fullfile(pathName, fileName);
    
    % Открываем файл для чтения в бинарном режиме
    fid = fopen(fullPath, 'rb');
    if fid == -1
        errordlg('Не удалось открыть файл.', 'Ошибка');
        return;
    end
    
    % Считываем весь файл как float
    data = fread(fid, Inf, 'float');
    fclose(fid);
    
    % Проверяем, что количество считанных элементов совпадает с ожидаемым
    if numel(data) ~= expectedTotalElements
        errordlg(sprintf('Размер данных в файле (%d элементов) не соответствует ожидаемому размеру (%d элементов).', numel(data), expectedTotalElements), 'Ошибка');
        return;
    end
    
    % Преобразуем данные в трехмерный массив размером [dimX, dimY, dimZ]
    array3D = reshape(data, [dimX, dimY, dimZ]);
    
    % Извлекаем имя переменной из имени файла (без расширения)
    [varName, ~, ~] = fileparts(fileName);
    
    % Создаем переменную в базовом рабочем пространстве
    assignin('base', fileName, array3D);
    
    % Формируем строку для отображения в списке: "имя_файла [dimX, dimY, dimZ]"
    newItem = sprintf('%s [%g, %g, %g]', fileName, dimX, dimY, dimZ);
    items = listBox.Items;
    if isempty(items)
        items = {newItem};
    else
        items{end+1} = newItem;
    end
    listBox.Items = items;
    
    % Выводим сообщение в командное окно
    disp(['Переменная "', varName, '" создана с размерностью [', num2str(dimX), ', ', num2str(dimY), ', ', num2str(dimZ), '].']);
end
