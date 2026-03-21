function validate_z1_workflows()
assignin('base', 'z1_demo', reshape(1:80, 10, 8, 1));
assignin('base', 'mask_demo', true(10, 8));

volume = evalin('base', 'z1_demo');
assert(size(volume, 3) == 1, 'Expected one slice.');

sliceImage = volume(:, :, 1);
assert(isequal(size(sliceImage), [10, 8]), 'Single-slice indexing failed.');

meanVal = mean(sliceImage(evalin('base', 'mask_demo')));
assert(isfinite(meanVal), 'Mask-based access failed for z=1.');
disp('z=1 workflows ok');
end
