function cnrCalculator
    % Создаем окно для расчета CNR
    fig = uifigure('Name', 'Расчет CNR', 'Position', [100 100 400 350]);
    movegui(fig, 'center');
    
    %% Элементы управления
    % Выпадающий список для выбора массива (3D массив)
    lblArray = uilabel(fig, 'Text', 'Выбор массива:', 'Position', [20, 300, 100, 22]);
    ddArray = uidropdown(fig, 'Position', [130, 300, 240, 22]);
    ddArray.Items = get3DArrayNames();
    
    % Выпадающий список для выбора маски сигнала (2D логическая переменная)
    lblSigMask = uilabel(fig, 'Text', 'Маска сигнала:', 'Position', [20, 260, 100, 22]);
    ddSigMask = uidropdown(fig, 'Position', [130, 260, 240, 22]);
    ddSigMask.Items = get2DLogicalVarNames();
    
    % Выпадающий список для выбора маски фона (background/noise)
    lblBkgMask = uilabel(fig, 'Text', 'Маска фона:', 'Position', [20, 220, 100, 22]);
    ddBkgMask = uidropdown(fig, 'Position', [130, 220, 240, 22]);
    ddBkgMask.Items = get2DLogicalVarNames();
    
    % Поле для ввода номера слоя
    lblLayer = uilabel(fig, 'Text', 'Номер слоя:', 'Position', [20, 180, 100, 22]);
    efLayer = uieditfield(fig, 'numeric', 'Position', [130, 180, 80, 22], ...
        'Value', 1, 'Limits', [1, Inf], 'RoundFractionalValues', true);
    
    % Кнопка "Посчитать" для расчета CNR на выбранном слое
    btnCalc = uibutton(fig, 'push', 'Text', 'Посчитать', ...
        'Position', [20, 140, 100, 30], 'ButtonPushedFcn', @(~,~) calculateCNR());
    
    % Кнопка "Отобразить распределение CNR" для построения графика по всем слоям
    btnPlot = uibutton(fig, 'push', 'Text', 'Отобразить распределение CNR', ...
        'Position', [140, 140, 230, 30], 'ButtonPushedFcn', @(~,~) plotCNRDistribution());
    
    % Кнопка "Сохранить в Excel" для сохранения распределения CNR
    btnSaveExcel = uibutton(fig, 'push', 'Text', 'Сохранить в Excel', ...
        'Position', [20, 100, 150, 30], 'ButtonPushedFcn', @(~,~) saveCNRToExcel());
    
    % Метка для вывода результата расчета CNR для выбранного слоя
    lblResult = uilabel(fig, 'Text', '', 'Position', [20, 60, 350, 22]);
    
    %% Callback: Расчет CNR для выбранного слоя
    function calculateCNR()
        % Получаем выбранные значения
        arrayName = ddArray.Value;
        sigMaskName = ddSigMask.Value;
        bkgMaskName = ddBkgMask.Value;
        layerNum = round(efLayer.Value);
        
        % Считываем переменные из рабочего пространства
        try
            array3D = evalin('base', arrayName);
        catch
            uialert(fig, ['Массив ', arrayName, ' не найден.'], 'Ошибка');
            return;
        end
        try
            sigMask = evalin('base', sigMaskName);
        catch
            uialert(fig, ['Маска сигнала ', sigMaskName, ' не найдена.'], 'Ошибка');
            return;
        end
        try
            bkgMask = evalin('base', bkgMaskName);
        catch
            uialert(fig, ['Маска фона ', bkgMaskName, ' не найдена.'], 'Ошибка');
            return;
        end
        
        % Проверяем, что выбранный слой существует
        if layerNum > size(array3D, 3)
            uialert(fig, 'Номер слоя превышает число слоев массива.', 'Ошибка');
            return;
        end
        
        layerImage = array3D(:,:,layerNum);
        
        % Применяем маски: извлекаем значения там, где маска истинна
        signalVals = double(layerImage(sigMask));
        backgroundVals = double(layerImage(bkgMask));
        
        if isempty(signalVals) || isempty(backgroundVals)
            uialert(fig, 'Проверьте, что маски содержат ненулевые элементы.', 'Ошибка');
            return;
        end
        
        % Расчет CNR:
        % m(signal) = mean(signalVals)
        % m(background) = mean(backgroundVals)
        % sigma(background) = std(backgroundVals)  (sample std)
        
        mSignal = mean(signalVals);
        mBkg = mean(backgroundVals);
        stdBkg = std(backgroundVals);
        
        cnrVal = (mSignal - mBkg) / stdBkg;
        
        lblResult.Text = sprintf('CNR слоя %d: %.3f', layerNum, cnrVal);
    end

    %% Callback: Построение графика распределения CNR по всем слоям
    function plotCNRDistribution()
        arrayName = ddArray.Value;
        sigMaskName = ddSigMask.Value;
        bkgMaskName = ddBkgMask.Value;
        
        try
            array3D = evalin('base', arrayName);
        catch
            uialert(fig, ['Массив ', arrayName, ' не найден.'], 'Ошибка');
            return;
        end
        try
            sigMask = evalin('base', sigMaskName);
        catch
            uialert(fig, ['Маска сигнала ', sigMaskName, ' не найдена.'], 'Ошибка');
            return;
        end
        try
            bkgMask = evalin('base', bkgMaskName);
        catch
            uialert(fig, ['Маска фона ', bkgMaskName, ' не найдена.'], 'Ошибка');
            return;
        end
        
        numLayers = size(array3D, 3);
        cnrValues = zeros(numLayers, 1);
        
        for layerNum = 1:numLayers
            layerImage = array3D(:,:,layerNum);
            signalVals = double(layerImage(sigMask));
            backgroundVals = double(layerImage(bkgMask));
            
            if isempty(signalVals) || isempty(backgroundVals)
                cnrValues(layerNum) = NaN;
            else
                mSignal = mean(signalVals);
                mBkg = mean(backgroundVals);
                stdBkg = std(backgroundVals);
                cnrValues(layerNum) = (mSignal - mBkg) / stdBkg;
            end
        end
        
        % Отображаем график распределения CNR
        figure('Name', 'Распределение CNR');
        plot(1:numLayers, cnrValues, '-o');
        xlabel('Номер слоя');
        ylabel('CNR');
        title(['Распределение CNR для массива ', arrayName]);
        grid on;
    end

    %% Callback: Сохранение распределения CNR в Excel
    function saveCNRToExcel()
        arrayName = ddArray.Value;
        sigMaskName = ddSigMask.Value;
        bkgMaskName = ddBkgMask.Value;
        
        try
            array3D = evalin('base', arrayName);
        catch
            uialert(fig, ['Массив ', arrayName, ' не найден.'], 'Ошибка');
            return;
        end
        try
            sigMask = evalin('base', sigMaskName);
        catch
            uialert(fig, ['Маска сигнала ', sigMaskName, ' не найдена.'], 'Ошибка');
            return;
        end
        try
            bkgMask = evalin('base', bkgMaskName);
        catch
            uialert(fig, ['Маска фона ', bkgMaskName, ' не найдена.'], 'Ошибка');
            return;
        end
        
        numLayers = size(array3D, 3);
        cnrValues = zeros(numLayers, 1);
        
        for layerNum = 1:numLayers
            layerImage = array3D(:,:,layerNum);
            signalVals = double(layerImage(sigMask));
            backgroundVals = double(layerImage(bkgMask));
            if isempty(signalVals) || isempty(backgroundVals)
                cnrValues(layerNum) = NaN;
            else
                mSignal = mean(signalVals);
                mBkg = mean(backgroundVals);
                stdBkg = std(backgroundVals);
                cnrValues(layerNum) = (mSignal - mBkg) / stdBkg;
            end
        end
        
        % Формируем таблицу с результатами
        T = table((1:numLayers)', cnrValues, 'VariableNames', {'Layer', 'CNR'});
        
        % Выбор имени файла для сохранения
        [file, path] = uiputfile('*.xlsx', 'Сохранить распределение CNR в Excel');
        if isequal(file,0)
            return; % пользователь отменил
        end
        fullFileName = fullfile(path, file);
        try
            writetable(T, fullFileName);
            uialert(fig, sprintf('Данные сохранены в файл:\n%s', fullFileName), 'Успех');
        catch ME
            uialert(fig, ['Ошибка при сохранении файла: ' ME.message], 'Ошибка');
        end
    end

    %% Вспомогательные функции
    function names = get3DArrayNames()
        info = evalin('base', 'whos');
        names = {};
        for i = 1:numel(info)
            if (strcmp(info(i).class, 'double') || strcmp(info(i).class, 'single')) && numel(info(i).size) == 3
                names{end+1} = info(i).name; %#ok<AGROW>
            end
        end
        if isempty(names)
            names = {'Нет 3D массивов'};
        end
    end

    function names = get2DLogicalVarNames()
        info = evalin('base', 'whos');
        names = {};
        for i = 1:numel(info)
            if strcmp(info(i).class, 'logical') && numel(info(i).size) == 2
                names{end+1} = info(i).name; %#ok<AGROW>
            end
        end
        if isempty(names)
            names = {'Нет масок'};
        end
    end
end
