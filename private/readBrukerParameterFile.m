function parameters = readBrukerParameterFile(filename)
%READBRUKERPARAMETERFILE Read JCAMP-DX parameter records without evaluating code.
% Values remain text, including tuples/frame groups and array declarations.
% Numeric interpretation is performed only for fields needed by the reader.

parameters = struct();
contents = fileread(filename);
contents = regexprep(contents, '(?m)\$\$[^\r\n]*', '');
records = regexp(contents, ...
    '(?m)^##\$([A-Za-z][A-Za-z0-9_]*)\s*=([^\r\n]*(?:\r?\n(?!##)[^\r\n]*)*)', 'tokens');
for k = 1:numel(records)
    name = records{k}{1};
    if isfield(parameters, name)
        error('Bruker:InvalidMetadata', 'Duplicate parameter %s in %s.', name, filename);
    end
    parameters.(name) = strtrim(records{k}{2});
end
end
