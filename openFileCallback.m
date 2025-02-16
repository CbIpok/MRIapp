function openFileCallback(edt1, edt2, edt3, listBox)
    % Считываем размеры массива из текстовых полей
    dimX = edt1.Value;
    dimY = edt2.Value;
    dimZ = edt3.Value;
    totalElements = dimX * dimY * dimZ;
    
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
    
    % Читаем данные из файла как float
    data = fread(fid, totalElements, 'float');
    fclose(fid);
    
    % Проверяем, что в файле содержится требуемое количество элементов
    if numel(data) < totalElements
        warndlg(sprintf('В файле содержится меньше данных (%d), чем ожидается (%d).', numel(data), totalElements), 'Предупреждение');
        % Можно завершить выполнение функции или дополнить недостающие данные
        return;
    elseif numel(data) > totalElements
        warndlg(sprintf('В файле содержится больше данных (%d), чем ожидается (%d). Данные будут усечены.', numel(data), totalElements), 'Предупреждение');
        data = data(1:totalElements);
    end
    
    % Преобразуем в трехмерный массив размером [dimX, dimY, dimZ]
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
