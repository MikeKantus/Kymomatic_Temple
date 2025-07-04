function setup_assets()
% SETUP_ASSETS – Verifies that all required visual and audio assets exist
% in the ./assets/ folder. If any are missing, it displays a warning.

    % Define expected files
    assetFolder = fullfile(pwd, 'assets');
    requiredFiles = {
        'stained_glass.png', ...
        'splash_tone.wav', ...
        'bell.wav', ...
        'library_step1_bg.png', ...
        'desk_step3_bg.png', ...
        'library_step2_bg.png'

    };

    % Header
    disp('🔍 Verifying Arcane Clustering assets...');
    missing = {};

    % Check each file
    for k = 1:numel(requiredFiles)
        f = fullfile(assetFolder, requiredFiles{k});
        if ~isfile(f)
            missing{end+1} = requiredFiles{k}; %#ok<AGROW>
        else
            fprintf('✅ %s found\n', requiredFiles{k});
        end
    end

    % Report result
    if isempty(missing)
        disp('✨ All arcane assets are present. The ritual may proceed.');
    else
        warning('⚠️ Missing assets detected:');
        for i = 1:numel(missing)
            fprintf('   - %s\n', missing{i});
        end
        disp('📜 Please place the missing files in the ./assets/ folder.');
    end
end