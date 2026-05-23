function valueMode = getSpectralValueMode(meta)
%GETSPECTRALVALUEMODE Return the configured spectral scalar mode.

valueMode = 'abs';
if nargin < 1 || ~isstruct(meta) || ~isfield(meta, 'currentSpectralValueMode')
    return;
end

rawMode = lower(strtrim(char(string(meta.currentSpectralValueMode))));
switch rawMode
    case 'abs'
        valueMode = 'abs';
    case {'re', 'real'}
        valueMode = 'real';
end

end
