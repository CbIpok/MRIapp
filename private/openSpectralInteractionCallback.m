function openSpectralInteractionCallback(listBox)
%OPENSPECTRALINTERACTIONCALLBACK Open the 4D spectrum interaction window.

parentFigure = ancestor(listBox, 'figure');
selectedItems = listBox.Value;

if isempty(selectedItems)
    uialert(parentFigure, 'Выберите один 4D массив.', 'Ошибка');
    return;
end

if iscell(selectedItems)
    if numel(selectedItems) ~= 1
        uialert(parentFigure, 'Для работы со спектром нужно выбрать ровно один массив.', 'Ошибка');
        return;
    end
    selectedItem = selectedItems{1};
else
    selectedItem = selectedItems;
end

varName = parseVolumeListItem(selectedItem);
info = getSpectralDatasetInfo(varName);
if ~info.isSpectral
    uialert(parentFigure, 'Кнопка доступна только для загруженных 4D спектральных массивов.', 'Ошибка');
    return;
end

openSpectralInteractionFigure(info);
end
