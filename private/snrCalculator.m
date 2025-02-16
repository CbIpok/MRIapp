function snrCalculator
    % Создаем окно для расчета SNR
    fig = uifigure('Name', 'Расчет SNR', 'Position', [100 100 400 350]);
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
    
    % Выпадающий список для выбора маски шума (2D логическая переменная)
    lblNoiseMask = uilabel(fig, 'Text', 'Маска шума:', 'Position', [20, 220, 100, 22]);
    ddNoiseMask = uidropdown(fig, 'Position', [130, 220, 240, 22]);
    ddNoiseMask.Items = get2DLogicalVarNames();
    
    % Поле для ввода номера слоя
    lblLayer = uilabel(fig, 'Text', 'Номер слоя:', 'Position', [20, 180, 100, 22]);
    efLayer = uieditfield(fig, 'numeric', 'Position', [130, 180, 80, 22], ...
        'Value', 1, 'Limits', [1, Inf], 'RoundFractionalValues', true);
    
    % Кнопка "Посчитать" для расчета SNR на выбранном слое
    btnCalc = uibutton(fig, 'push', 'Text', 'Посчитать', ...
        'Position', [20, 140, 100, 30], 'ButtonPushedFcn', @(~,~) calculateSNR());
    
    % Кнопка "Отобразить распределение SNR" для построения графика по всем слоям
    btnPlot = uibutton(fig, 'push', 'Text', 'Отобразить распределение SNR', ...
        'Position', [140, 140, 230, 30], 'ButtonPushedFcn', @(~,~) plotSNRDistribution());
    
    % Новая кнопка "Сохранить в Excel" для сохранения распределения SNR
    btnSaveExcel = uibutton(fig, 'push', 'Text', 'Сохранить в Excel', ...
        'Position', [20, 100, 150, 30], 'ButtonPushedFcn', @(~,~) saveSNRToExcel());
    
    % Метка для вывода результата расчета SNR для выбранного слоя
    lblResult = uilabel(fig, 'Text', '', 'Position', [20, 60, 350, 22]);
    
    %% Callback: Расчет SNR для выбранного слоя
    function calculateSNR()
        % Получаем выбранные значения
        arrayName = ddArray.Value;
        sigMaskName = ddSigMask.Value;
        noiseMaskName = ddNoiseMask.Value;
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
            noiseMask = evalin('base', noiseMaskName);
        catch
            uialert(fig, ['Маска шума ', noiseMaskName, ' не найдена.'], 'Ошибка');
            return;
        end
        
        % Проверяем, что выбранный слой существует
        if layerNum > size(array3D, 3)
            uialert(fig, 'Номер слоя превышает число слоев массива.', 'Ошибка');
            return;
        end
        
        layerImage = array3D(:,:,layerNum);
        
        % Применяем маски: извлекаем значения там, где маска истинна
        sigValues = double(layerImage(sigMask));
        noiseValues = double(layerImage(noiseMask));
        
        if isempty(sigValues) || isempty(noiseValues)
            uialert(fig, 'Проверьте, что маски содержат ненулевые элементы.', 'Ошибка');
            return;
        end
        
        % Расчет параметров
        mean_signal = mean(sigValues);
        mean_noise = mean(noiseValues);
        std_noise = std(noiseValues);
        
        snrVal = (mean_signal - mean_noise) / std_noise;
        
        lblResult.Text = sprintf('SNR слоя %d: %.3f', layerNum, snrVal);
    end

    %% Callback: Построение графика распределения SNR по всем слоям
    function plotSNRDistribution()
        arrayName = ddArray.Value;
        sigMaskName = ddSigMask.Value;
        noiseMaskName = ddNoiseMask.Value;
        
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
            noiseMask = evalin('base', noiseMaskName);
        catch
            uialert(fig, ['Маска шума ', noiseMaskName, ' не найдена.'], 'Ошибка');
            return;
        end
        
        numLayers = size(array3D, 3);
        snrValues = zeros(numLayers, 1);
        
        for layerNum = 1:numLayers
            layerImage = array3D(:,:,layerNum);
            sigValues = double(layerImage(sigMask));
            noiseValues = double(layerImage(noiseMask));
            if isempty(sigValues) || isempty(noiseValues)
                snrValues(layerNum) = NaN;
            else
                mean_signal = mean(sigValues);
                mean_noise = mean(noiseValues);
                std_noise = std(noiseValues);
                snrValues(layerNum) = (mean_signal - mean_noise) / std_noise;
            end
        end
        
        % Отображаем график распределения SNR
        figure('Name', 'Распределение SNR');
        plot(1:numLayers, snrValues, '-o');
        xlabel('Номер слоя');
        ylabel('SNR');
        title(['Распределение SNR для массива ', arrayName]);
        grid on;
    end

    %% Callback: Сохранение распределения SNR в Excel
    function saveSNRToExcel()
        arrayName = ddArray.Value;
        sigMaskName = ddSigMask.Value;
        noiseMaskName = ddNoiseMask.Value;
        
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
            noiseMask = evalin('base', noiseMaskName);
        catch
            uialert(fig, ['Маска шума ', noiseMaskName, ' не найдена.'], 'Ошибка');
            return;
        end
        
        numLayers = size(array3D, 3);
        snrValues = zeros(numLayers, 1);
        
        for layerNum = 1:numLayers
            layerImage = array3D(:,:,layerNum);
            sigValues = double(layerImage(sigMask));
            noiseValues = double(layerImage(noiseMask));
            if isempty(sigValues) || isempty(noiseValues)
                snrValues(layerNum) = NaN;
            else
                mean_signal = mean(sigValues);
                mean_noise = mean(noiseValues);
                std_noise = std(noiseValues);
                snrValues(layerNum) = (mean_signal - mean_noise) / std_noise;
            end
        end
        
        % Формируем таблицу с результатами
        T = table((1:numLayers)', snrValues, 'VariableNames', {'Layer', 'SNR'});
        
        % Выбор имени файла для сохранения
        [file, path] = uiputfile('*.xlsx', 'Сохранить распределение SNR в Excel');
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

    %% Вспомогательные функции для заполнения выпадающих списков
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
