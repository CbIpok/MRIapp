function displayMultipleCallback(listBox)
    % Получаем выбранные элементы из списка
    selectedItems = listBox.Value;
    if isempty(selectedItems)
        uialert(listBox.Parent, 'Не выбран ни один элемент.', 'Ошибка');
        return;
    end
    if ~iscell(selectedItems)
        selectedItems = {selectedItems};
    end
    numArrays = numel(selectedItems);
    
    % Инициализация массивов и имён
    arrays = cell(1, numArrays);
    names  = cell(1, numArrays);
    
    % Вычисляем глобальный минимум и максимум для всех выбранных массивов
    globalMin = inf;
    globalMax = -inf;
    for i = 1:numArrays
        % Ожидаемый формат: "имя_файла [x, y, z]"
        tokens = strsplit(selectedItems{i}, ' ');
        fileNameWithExt = tokens{1};
        [varName, ~, ~] = fileparts(fileNameWithExt);
        % В проекте имя переменной совпадает с именем файла (с расширением)
        varName = fileNameWithExt;
        names{i} = varName;
        try
            arr = evalin('base', varName);
        catch
            uialert(listBox.Parent, ['Переменная "', varName, '" не найдена в рабочем пространстве.'], 'Ошибка');
            return;
        end
        arrays{i} = arr;
        globalMin = min(globalMin, min(arr(:)));
        globalMax = max(globalMax, max(arr(:)));
    end
    
    % Определяем максимальное число срезов среди выбранных массивов
    maxSlices = 0;
    for i = 1:numArrays
        [~, ~, zDim] = size(arrays{i});
        maxSlices = max(maxSlices, zDim);
    end
    
    % Начальные пределы для цветовой шкалы
    currentMin = globalMin;
    currentMax = globalMax;
    
    %% Создаем окно просмотра с новой разметкой
    viewFig = uifigure('Name', 'Просмотр нескольких массивов', 'Position', [100 100 800 600]);
    movegui(viewFig, 'center');
    
    % Определяем размеры для трех панелей:
    % topControlPanel - верхняя панель для управления (высота 80)
    % axesPanel - панель для осей срезов (средняя, высота 420)
    % colorbarPanel - нижняя панель для колорбара и его элементов (высота 100)
    topPanelHeight = 80;
    colorbarPanelHeight = 100;
    axesPanelHeight = viewFig.Position(4) - topPanelHeight - colorbarPanelHeight;
    
    topControlPanel = uipanel(viewFig, 'Position', [0, viewFig.Position(4)-topPanelHeight, viewFig.Position(3), topPanelHeight]);
    axesPanel = uipanel(viewFig, 'Position', [0, colorbarPanelHeight, viewFig.Position(3), axesPanelHeight]);
    colorbarPanel = uipanel(viewFig, 'Position', [0, 0, viewFig.Position(3), colorbarPanelHeight]);
    
    %% Элементы управления в topControlPanel
    defaultNumCols = 3;
    lblNumCols = uilabel(topControlPanel, 'Position', [20, 40, 180, 22], 'Text', 'Картинок по горизонтали:');
    numColsField = uieditfield(topControlPanel, 'numeric', ...
        'Position', [200, 40, 80, 22], ...
        'Value', defaultNumCols, ...
        'Limits', [1 Inf], ...
        'RoundFractionalValues', true);
    applyLayoutButton = uibutton(topControlPanel, 'push', ...
        'Text', 'Применить', ...
        'Position', [300, 40, 100, 22], ...
        'ButtonPushedFcn', @(src,event) createAxesLayout());
    
    sliderControl = uislider(topControlPanel, ...
        'Position', [20, 10, viewFig.Position(3)-40, 3], ...
        'Limits', [1, maxSlices], ...
        'Value', 1);
    sliderControl.ValueChangedFcn = @(sld,event) updateSlices(round(sld.Value));
    
    %% Элементы управления в colorbarPanel
    % Ось для отображения горизонтального колорбара
    cbAx = uiaxes(colorbarPanel, 'Position', [20, 55, viewFig.Position(3)-40, 30]);
    % Устанавливаем отметки для колорбара
    updateColorbarDisplay();
    
    % Элементы ручного управления колорбаром
    lblManual = uilabel(colorbarPanel, 'Text', 'Manual:', 'Position', [20, 20, 60, 22]);
    manualMinField = uieditfield(colorbarPanel, 'numeric', 'Position', [80, 20, 80, 22], 'Value', currentMin);
    lblTo = uilabel(colorbarPanel, 'Text', 'to', 'Position', [170, 20, 30, 22]);
    manualMaxField = uieditfield(colorbarPanel, 'numeric', 'Position', [210, 20, 80, 22], 'Value', currentMax);
    btnApplyCB = uibutton(colorbarPanel, 'push', 'Text', 'Применить цветбар', ...
        'Position', [300, 20, 120, 22], 'ButtonPushedFcn', @(src,event) applyColorbarLimits());
    
    % Элементы автоматического расчета min/max:
    lblAuto = uilabel(colorbarPanel, 'Text', 'Auto:', 'Position', [430, 20, 40, 22]);
    lblAutoArray = uilabel(colorbarPanel, 'Text', 'Массив:', 'Position', [480, 20, 60, 22]);
    autoArrayDD = uidropdown(colorbarPanel, 'Position', [540, 20, 120, 22]);
    autoArrayDD.Items = get3DArrayNames();  % список 3D массивов из base
    lblAutoLayer = uilabel(colorbarPanel, 'Text', 'Слой:', 'Position', [670, 20, 50, 22]);
    % Текстовое поле типа 'text' для возможности оставить его пустым
    autoLayerField = uieditfield(colorbarPanel, 'text', 'Position', [720, 20, 50, 22], 'Value', ''); 
    % Кнопка для автоматического расчета
    btnAutoCalc = uibutton(colorbarPanel, 'push', 'Text', 'Авто рассчитать', ...
        'Position', [20, 0, 120, 22], 'ButtonPushedFcn', @(src,event) autoCalculateCB());
    
    %% Переменные для осей изображений
    axesHandles = {};
    numCols = defaultNumCols; % текущее число изображений по горизонтали
    
    % Функция для создания/пересоздания разметки осей на axesPanel
    function createAxesLayout()
        delete(axesPanel.Children);
        panelWidth = axesPanel.Position(3);
        panelHeight = axesPanel.Position(4);
        rowHeight = panelHeight / numArrays;
        colWidth  = panelWidth / numColsField.Value;  % Используем значение из текстового поля
        numCols = round(numColsField.Value);
        axesHandles = cell(numArrays, numCols);
        for i = 1:numArrays
            for j = 1:numCols
                left = (j-1)*colWidth;
                bottom = panelHeight - i*rowHeight;
                pos = [left, bottom, colWidth, rowHeight];
                axesHandles{i,j} = uiaxes(axesPanel, 'Position', pos, 'XTick', [], 'YTick', []);
            end
        end
        updateSlices(round(sliderControl.Value));
    end

    % Функция обновления изображений в осях
    function updateSlices(startSlice)
        for i = 1:numArrays
            [~, ~, zDim] = size(arrays{i});
            for j = 1:numCols
                sliceIndex = startSlice + j - 1;
                if sliceIndex > zDim
                    sliceIndex = zDim;
                end
                ax = axesHandles{i,j};
                imagesc(ax, arrays{i}(:,:,sliceIndex), [currentMin, currentMax]);
                colormap(ax, jet);
                title(ax, sprintf('%s (z = %d)', names{i}, sliceIndex));
                ax.XTick = [];
                ax.YTick = [];
            end
        end
        updateColorbarDisplay();
    end

    % Функция обновления отображения горизонтального колорбара с отметками
    function updateColorbarDisplay()
        % Создаем градиентную матрицу для отображения колорбара
        grad = repmat(linspace(currentMin, currentMax, 256), 20, 1);
        imagesc(cbAx, grad);
        % Устанавливаем отметки: например 5 отметок равномерно по диапазону
        cbAx.XTick = linspace(1, 256, 5);
        cbAx.XTickLabel = num2cell(linspace(currentMin, currentMax, 5));
        cbAx.YTick = [];
        colormap(cbAx, jet);
    end

    % Callback кнопки "Применить цветбар" - применение ручных значений
    function applyColorbarLimits()
        currentMin = manualMinField.Value;
        currentMax = manualMaxField.Value;
        updateSlices(round(sliderControl.Value));
    end

    % Callback кнопки "Авто рассчитать" - вычисление min и max для выбранного массива/слоя
    function autoCalculateCB()
        selectedArray = autoArrayDD.Value;
        try
            arr = evalin('base', selectedArray);
        catch
            uialert(viewFig, ['Массив ' selectedArray ' не найден.'], 'Ошибка');
            return;
        end
        layerStr = strtrim(autoLayerField.Value);
        if isempty(layerStr)
            % Если поле пустое, ищем по всему массиву
            currentMin = min(arr(:));
            currentMax = max(arr(:));
        else
            layerVal = str2double(layerStr);
            if isnan(layerVal) || layerVal < 1 || layerVal > size(arr,3)
                uialert(viewFig, 'Некорректный номер слоя.','Ошибка');
                return;
            else
                layerImage = arr(:,:,round(layerVal));
                currentMin = min(layerImage(:));
                currentMax = max(layerImage(:));
            end
        end
        % Обновляем ручные поля
        manualMinField.Value = currentMin;
        manualMaxField.Value = currentMax;
        updateSlices(round(sliderControl.Value));
    end

    % Вспомогательная функция для получения имен 3D-массивов из base
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

    % Вспомогательная функция для получения имен 2D логических переменных из base
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

    % Изначально создаем разметку осей
    createAxesLayout();
end
