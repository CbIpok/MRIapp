function updateSpectrumButtonState(listBox, buttonHandle)
%UPDATESPECTRUMBUTTONSTATE Enable the spectrum button only for 4D datasets.

if isempty(buttonHandle) || ~isvalid(buttonHandle)
    return;
end

if isempty(listBox) || ~isvalid(listBox)
    buttonHandle.Enable = 'off';
    return;
end

if isSpectralListSelection(listBox.Value)
    buttonHandle.Enable = 'on';
else
    buttonHandle.Enable = 'off';
end
end
