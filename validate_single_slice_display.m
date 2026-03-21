function validate_single_slice_display()
assignin('base', 'single_slice_demo', reshape(1:64, 8, 8, 1));

fig = uifigure('Visible', 'on');
listBox = uilistbox(fig, 'Items', {'single_slice_demo [8, 8, 1]'}, ...
    'Value', 'single_slice_demo [8, 8, 1]');

displaySelectedCallback(listBox, []);

pause(0.2);
delete(findall(groot, 'Type', 'figure'));
disp('single slice display ok');
end
