function tf = isSpectralListSelection(selectedItems)
%ISSPECTRALLISTSELECTION True only for a single selected spectral dataset.

tf = false;
if isempty(selectedItems)
    return;
end

if iscell(selectedItems)
    if numel(selectedItems) ~= 1
        return;
    end
    item = selectedItems{1};
else
    item = selectedItems;
end

varName = parseVolumeListItem(item);
info = getSpectralDatasetInfo(varName);
tf = info.isSpectral;
end
