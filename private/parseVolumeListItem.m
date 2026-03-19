function varName = parseVolumeListItem(listItem)
%PARSEVOLUMELISTITEM Extract the workspace variable name from a list item.

if isstring(listItem)
    listItem = char(listItem);
end

tokens = strsplit(strtrim(listItem), ' ');
varName = tokens{1};
end
