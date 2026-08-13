function validate_phase_scope_ui_smoke()
nSpec = 64;
pointIndex = (1:nSpec).';
firstSpectrum = 1 ./ (1 + 1i .* ((pointIndex - 24) ./ 4));
secondSpectrum = 1 ./ (1 + 1i .* ((pointIndex - 40) ./ 5));
spectrum4D = zeros(nSpec, 2, 1, 1);
spectrum4D(:, 1, 1, 1) = applyPhaseCorrection(firstSpectrum, -25, -35, 24);
spectrum4D(:, 2, 1, 1) = applyPhaseCorrection(secondSpectrum, -15, -20, 40);
meta = struct( ...
    'phaseEnabled', false, ...
    'phaseMode', 'global', ...
    'phaseMaps', [], ...
    'currentSpectralValueMode', 'real', ...
    'phaseParams', struct('ph0Deg', 20, 'ph1Deg', 30, 'pivotIndex', 24));
info = struct( ...
    'varName', 'phase_scope_smoke', ...
    'metaVarName', 'phase_scope_smoke__meta', ...
    'spectrum4D', spectrum4D, ...
    'meta', meta);
openPhaseCorrectionFigure(info, [1, 1, 1], [1, nSpec], []);
drawnow;

scopeDropDown = findScopeDropDown();
manualButton = findall(groot, 'Text', 'Apply manual phase');
autoButton = findall(groot, 'Text', 'Auto phase');
assert(isscalar(scopeDropDown) && isscalar(manualButton) && isscalar(autoButton), ...
    'Phase scope controls were not created.');

scopeDropDown.Value = 'selected';
invokeButton(manualButton);
savedMeta = evalin('base', 'phase_scope_smoke__meta');
assert(strcmp(savedMeta.phaseMode, 'voxelwise'), ...
    'Selected manual phase must use voxel-wise mode.');
assert(savedMeta.phaseMaps.ph0Deg(1) == 20 && savedMeta.phaseMaps.ph0Deg(2) == 0, ...
    'Selected manual phase changed another voxel.');

scopeDropDown.Value = 'all';
invokeButton(manualButton);
savedMeta = evalin('base', 'phase_scope_smoke__meta');
assert(strcmp(savedMeta.phaseMode, 'global') && isempty(savedMeta.phaseMaps), ...
    'All-voxel manual phase must use global mode.');

scopeDropDown.Value = 'selected';
invokeButton(autoButton);
savedMeta = evalin('base', 'phase_scope_smoke__meta');
assert(strcmp(savedMeta.phaseMode, 'voxelwise'), ...
    'Selected automatic phase must use voxel-wise mode.');
assert(savedMeta.phaseMaps.ph0Deg(2) == 20 && savedMeta.phaseMaps.ph1Deg(2) == 30, ...
    'Selected automatic phase changed another voxel.');

scopeDropDown.Value = 'all';
invokeButton(autoButton);
savedMeta = evalin('base', 'phase_scope_smoke__meta');
assert(strcmp(savedMeta.phaseMode, 'voxelwise') ...
    && strcmp(savedMeta.autoPhaseSummary.scope, 'all') ...
    && savedMeta.autoPhaseSummary.totalVoxels == 2, ...
    'All-voxel automatic phase did not process the full volume.');

close(findall(groot, 'Type', 'figure'));
evalin('base', 'clear phase_scope_smoke phase_scope_smoke__meta');
disp('phase scope UI workflow ok');
end

function dropDown = findScopeDropDown()
dropDown = [];
candidates = findall(groot, 'Type', 'uidropdown');
for iCandidate = 1:numel(candidates)
    if any(strcmp(candidates(iCandidate).Items, 'Selected voxel'))
        dropDown = candidates(iCandidate);
        return;
    end
end
end

function invokeButton(button)
callback = button.ButtonPushedFcn;
callback(button, []);
drawnow;
end
