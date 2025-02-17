function Calculation(mainForm)

    function varName = extractVarName(fullStr)
        % Разбиваем строку по пробелу и берём первый токен как имя переменной
        tokens = strsplit(fullStr, ' ');
        varName = tokens{1};
    end
% Calculation - окно для вычисления параметров 3D MRI изображений.
% Тип расчёта определяется значением из mainForm.CalculationtypeListBox_2.
% Списки массивов и масок также берутся из mainForm, а для корректного
% извлечения имени переменной используется метод mainForm.extractVarName.
%
% Пример использования:
%   Calculation(mainForm);

% Создаем окно расчёта
fig = uifigure('Name', 'Calculation', 'Position', [100 100 500 400]);
movegui(fig, 'center');

%% Элементы интерфейса
% Отображаем выбранный тип расчёта из главной формы (для информации)
lblCalcType = uilabel(fig, 'Text', ['Calculation type: ' mainForm.CalculationtypeListBox_2.Value],...
    'Position', [20 360 300 22]);

% Выпадающий список для выбора массива (берется из mainForm.AvaliablefilesListBox)
lblArray = uilabel(fig, 'Text', 'Select Array:', 'Position', [20 320 120 22]);
ddArray = uidropdown(fig, 'Position', [150 320 200 22]);
ddArray.Items = mainForm.AvaliablefilesListBox.Items;
if ~isempty(ddArray.Items)
    ddArray.Value = ddArray.Items{1};
end

% Выпадающий список для выбора первой маски (например, маска сигнала)
lblMask1 = uilabel(fig, 'Text', 'Mask 1:', 'Position', [20 280 120 22]);
ddMask1 = uidropdown(fig, 'Position', [150 280 200 22]);
ddMask1.Items = mainForm.AvaliablemasksListBox_2.Items;
if ~isempty(ddMask1.Items)
    ddMask1.Value = ddMask1.Items{1};
end

% Выпадающий список для выбора второй маски (например, маска шума или фона)
lblMask2 = uilabel(fig, 'Text', 'Mask 2:', 'Position', [20 240 120 22]);
ddMask2 = uidropdown(fig, 'Position', [150 240 200 22]);
ddMask2.Items = mainForm.AvaliablemasksListBox_2.Items;
if ~isempty(ddMask2.Items)
    ddMask2.Value = ddMask2.Items{1};
end

% Поле для ввода номера слоя
lblLayer = uilabel(fig, 'Text', 'Layer Number:', 'Position', [20 200 120 22]);
efLayer = uieditfield(fig, 'numeric', 'Position', [150 200 100 22], 'Value', 1, 'Limits', [1 Inf], 'RoundFractionalValues', true);

% Кнопка "Calculate"
btnCalc = uibutton(fig, 'push', 'Text', 'Calculate', 'Position', [150 150 100 30]);
btnCalc.ButtonPushedFcn = @(src,event) calculateCallback();

% Поле для вывода результата
txtResult = uitextarea(fig, 'Position', [20 20 460 100], 'Editable', 'off');

%% Callback-функция расчета
    function calculateCallback()
        % Тип расчёта берется из главной формы (например, 'SNR', 'CNR' или 'MEAN')
        calcType = mainForm.CalculationtypeListBox_2.Value;
        
        % Получаем имя массива из ddArray и корректное имя переменной через extractVarName
        selectedArrayStr = ddArray.Value;
        arrayName = extractVarName(selectedArrayStr);
        
        % Пытаемся получить 3D массив из base
        try
            array3D = evalin('base', arrayName);
        catch
            uialert(fig, sprintf('Array "%s" not found in base workspace.', arrayName), 'Error');
            return;
        end
        
        % Получаем номер слоя и проверяем его
        layer = round(efLayer.Value);
        if layer < 1 || layer > size(array3D,3)
            uialert(fig, sprintf('Layer number must be between 1 and %d.', size(array3D,3)), 'Error');
            return;
        end
        
        % Получаем маски. Если значение равно 'Нет масок' или пустое, считаем маску не выбранной.
        mask1 = [];
        if ~isempty(ddMask1.Value) && ~strcmp(ddMask1.Value, 'Нет масок')
            try
                mask1 = evalin('base', ddMask1.Value);
            catch
                mask1 = [];
            end
        end
        
        mask2 = [];
        if ~isempty(ddMask2.Value) && ~strcmp(ddMask2.Value, 'Нет масок')
            try
                mask2 = evalin('base', ddMask2.Value);
            catch
                mask2 = [];
            end
        end
        
        % В зависимости от calcType вызываем соответствующую математическую функцию.
        switch upper(calcType)
            case 'SNR'
                resultValue = calcSNR(array3D, layer, mask1, mask2);
                txtResult.Value = {sprintf('SNR (Layer %d): %.3f', layer, resultValue)};
            case 'CNR'
                resultValue = calcCNR(array3D, layer, mask1, mask2);
                txtResult.Value = {sprintf('CNR (Layer %d): %.3f', layer, resultValue)};
            case 'MEAN'
                resultStruct = calcMEAN(array3D, layer, mask1, mask2);
                txtResult.Value = {sprintf('Layer %d:', layer), ...
                                  sprintf('Signal mean: %s', num2str(resultStruct.signal)), ...
                    
                                  sprintf('Background mean: %s', num2str(resultStruct.background))};
            otherwise
                uialert(fig, 'Unknown calculation type', 'Error');
        end
    end

%% Математические функции (Math functions area)
    function snrVal = calcSNR(array3D, layer, mask1, mask2)
        layerImage = array3D(:,:,layer);
        if isempty(mask1) || isempty(mask2)
            snrVal = NaN;
            return;
        end
        sigValues = double(layerImage(mask1));
        noiseValues = double(layerImage(mask2));
        if isempty(sigValues) || isempty(noiseValues)
            snrVal = NaN;
        else
            snrVal = (mean(sigValues) - mean(noiseValues)) / std(noiseValues);
        end
    end

    function cnrVal = calcCNR(array3D, layer, mask1, mask2)
        layerImage = array3D(:,:,layer);
        if isempty(mask1) || isempty(mask2)
            cnrVal = NaN;
            return;
        end
        sigValues = double(layerImage(mask1));
        bgValues = double(layerImage(mask2));
        if isempty(sigValues) || isempty(bgValues)
            cnrVal = NaN;
        else
            cnrVal = (mean(sigValues) - mean(bgValues)) / std(bgValues);
        end
    end

    function meanStruct = calcMEAN(array3D, layer, mask1, mask2)
        layerImage = array3D(:,:,layer);
        if isempty(mask1)
            meanStruct.signal = 'маска не выбрана';
        else
            sigValues = double(layerImage(mask1));
            if isempty(sigValues)
                meanStruct.signal = 'маска не выбрана';
            else
                meanStruct.signal = mean(sigValues);
            end
        end
        if isempty(mask2)
            meanStruct.background = 'маска не выбрана';
        else
            bgValues = double(layerImage(mask2));
            if isempty(bgValues)
                meanStruct.background = 'маска не выбрана';
            else
                meanStruct.background = mean(bgValues);
            end
        end
    end

%% Инструкция по добавлению новых функций
% Чтобы добавить новый тип расчёта:
% 1. Добавьте соответствующий тип (например, 'STD') в список mainForm.CalculationtypeListBox_2.
% 2. В конструкции switch-case в calculateCallback добавьте новый case:
%       case 'STD'
%           resultValue = calcSTD(array3D, layer, mask1);
%           txtResult.Value = {sprintf('STD (Layer %d): %.3f', layer, resultValue)};
% 3. Определите новую функцию в области Math functions, например:
%   function stdVal = calcSTD(array3D, layer, mask)
%       layerImage = array3D(:,:,layer);
%       if isempty(mask)
%           stdVal = NaN;
%       else
%           values = double(layerImage(mask));
%           if isempty(values)
%               stdVal = NaN;
%           else
%               stdVal = std(values);
%           end
%       end
%
% Добавление новых функций происходит просто – добавьте новый case и реализуйте функцию расчета.

end
