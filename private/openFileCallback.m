function openFileCallback(edt1, edt2, edt3, listBox)
    dimX = edt1.Value;
    dimY = edt2.Value;
    dimZ = edt3.Value;

    [fileName, pathName] = uigetfile( ...
        {'*.bin;*.dat;*.64;*.ser;*.*', ...
        'Volumes, spectra and Bruker 2dseq (*.bin, *.dat, *.64, *.ser, 2dseq, ...)'}, ...
        'Выберите файл объёма или спектра');

    if isequal(fileName, 0)
        disp('Файл не выбран.');
        return;
    end

    fullPath = fullfile(pathName, fileName);

    try
        [varName, array3D, extras, meta] = loadVolumeForApp(fullPath, dimX, dimY, dimZ);
    catch ME
        errordlg(ME.message, 'Ошибка');
        return;
    end

    if strcmp(meta.sourceKind, 'bruker2dseq')
        % Different reconstructions all share the filename 2dseq.
        existingNames = evalin('base', 'who');
        baseName = varName;
        suffix = 0;
        while any(ismember({varName, [varName '__raw'], [varName '__meta']}, existingNames))
            suffix = suffix + 1;
            varName = sprintf('%s_%d', baseName, suffix);
        end
        meta.workspaceVarName = varName;
        meta.rawVarName = [varName '__raw'];
        meta.metaVarName = [varName '__meta'];
    end

    assignin('base', varName, array3D);
    assignin('base', meta.metaVarName, meta);

    if isfield(extras, 'spectrum4D')
        assignin('base', meta.spectrumVarName, extras.spectrum4D);
    end
    if isfield(extras, 'rawData')
        assignin('base', meta.rawVarName, extras.rawData);
        if ~isempty(meta.notes)
            warning('Bruker:MetadataFallback', '%s', strjoin(meta.notes, ' '));
        end
    end

    newItem = sprintf('%s [%g, %g, %g]', ...
        varName, size(array3D, 1), size(array3D, 2), size(array3D, 3));

    items = listBox.Items;
    if isempty(items)
        items = {newItem};
    else
        items{end + 1} = newItem;
    end
    listBox.Items = items;

    if isfield(extras, 'spectrum4D')
        disp(['Переменная "', varName, '" создана как 3D интеграл спектра с размерностью [', ...
            num2str(size(array3D, 1)), ', ', num2str(size(array3D, 2)), ', ', num2str(size(array3D, 3)), ...
            ']. 4D спектр сохранён в "', meta.spectrumVarName, '".']);
    else
        disp(['Переменная "', varName, '" создана с размерностью [', ...
            num2str(size(array3D, 1)), ', ', num2str(size(array3D, 2)), ', ', num2str(size(array3D, 3)), '].']);
    end
end
