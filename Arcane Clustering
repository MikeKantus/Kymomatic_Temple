function ArcaneClustering()
    %% Preload audio
    [splashTone, fsTone] = audioread('splash_tone.wav');
    [bellSound,   fsBell] = audioread('bell.wav');

    %% Run splash animation
    runSplash(splashTone, fsTone);

    %% File selection & sheet list
    [file,path] = uigetfile({'*.xlsx;*.csv'}, 'Select profile data file');
    if isequal(file,0), disp('Canceled'); return; end
    fullFile = fullfile(path,file);
    [~,~,ext] = fileparts(file);
    if strcmp(ext,'.xlsx')
        sheetList = sheetnames(fullFile);
    else
        sheetList = {'Sheet1'};
    end
    currSheet = 1;

    %% Initial data load
    loadCurrentSheet();

    %% Create main GUI
    fig = figure( ...
        'Name','Arcane Clustering – Profiles Analyzer', ...
        'Position',[100 100 900 400], ...
        'Color',[1 1 1], ...
        'MenuBar','none', ...
        'ToolBar','none' ...
    );
    % Navigation buttons & label
    hPrev = uicontrol(fig,'Style','pushbutton', ...
        'Position',[20 350 100 30], ...
        'String','← Prev Sheet', ...
        'BackgroundColor',[0.95 0.94 0.90], ...
        'Callback',@(~,~) changeSheet(-1));
    uicontrol(fig,'Style','text', ...
        'Position',[130 350 200 30], ...
        'String',sheetList{currSheet}, ...
        'FontWeight','bold', ...
        'Tag','sheetNameDisplay', ...
        'BackgroundColor',[1 1 1]);
    hNext = uicontrol(fig,'Style','pushbutton', ...
        'Position',[340 350 100 30], ...
        'String','Next Sheet →', ...
        'BackgroundColor',[0.95 0.94 0.90], ...
        'Callback',@(~,~) changeSheet(+1));

    %% Analysis controls
    uicontrol(fig,'Style','text', ...
        'Position',[20 300 140 20], ...
        'String','Segment length:', ...
        'BackgroundColor',[1 1 1]);
    tramoBox = uicontrol(fig,'Style','edit', ...
        'Position',[170 300 60 25], ...
        'String','5');

    chkSmooth = uicontrol(fig,'Style','checkbox', ...
        'Position',[250 300 150 20], ...
        'String','Apply smoothing', ...
        'BackgroundColor',[1 1 1], ...
        'Value',0);
    popMethod = uicontrol(fig,'Style','popupmenu', ...
        'Position',[410 300 140 25], ...
        'String',{'Moving average','Savitzky-Golay'});
    edtWindow = uicontrol(fig,'Style','edit', ...
        'Position',[560 300 50 25], ...
        'String','5');

    chkForceK = uicontrol(fig,'Style','checkbox', ...
        'Position',[630 300 160 20], ...
        'String','Force # clusters', ...
        'BackgroundColor',[1 1 1], ...
        'Value',0);
    clusterKBox = uicontrol(fig,'Style','edit', ...
        'Position',[800 300 60 25], ...
        'String','3');

    %% Action buttons
    hRefresh = uicontrol(fig,'Style','pushbutton', ...
        'Position',[20 250 120 30], ...
        'String','Refresh', ...
        'BackgroundColor',[1 0.95 0.80], ...
        'Callback',@(~,~) refresh());
    hAuto = uicontrol(fig,'Style','pushbutton', ...
        'Position',[160 250 120 30], ...
        'String','Autocluster', ...
        'BackgroundColor',[1 0.90 0.70], ...
        'Callback',@(~,~) autocluster());
    hSave = uicontrol(fig,'Style','pushbutton', ...
        'Position',[300 250 120 30], ...
        'String','Save', ...
        'BackgroundColor',[1 0.85 0.60], ...
        'Callback',@(~,~) saveResults());

    %% Setup hover sounds
    btns = [hPrev, hNext, hRefresh, hAuto, hSave];
    for b = btns, b.UserData = false; end
    fig.WindowButtonMotionFcn = @onHover;

    %% Nested functions

    function runSplash(tone, fs)
        figS = figure('MenuBar','none','ToolBar','none', ...
                      'Color',[0.1 0.1 0.1], ...
                      'Position',[400 250 600 400]);
        im = imshow('stained_glass.png','InitialMagnification','fit');
        im.AlphaData = 0;
        for a = 0:0.05:1
            im.AlphaData = a;
            pause(0.05);
            drawnow;
        end
        sound(tone, fs);
        pause(0.6);
        close(figS);
    end

    function loadCurrentSheet()
        if strcmp(ext,'.xlsx')
            rawData = readmatrix(fullFile, 'Sheet', sheetList{currSheet});
        else
            rawData = readmatrix(fullFile);
        end
        if mod(size(rawData,2),2)~=0
            errordlg('Column count must be even ([X Y] pairs).');
            return;
        end
        perfilesY = rawData(:,2:2:end);
        resultados = [];
        perfilesSuavizados = [];
    end

    function changeSheet(dir)
        newIdx = currSheet + dir;
        if newIdx>=1 && newIdx<=numel(sheetList)
            currSheet = newIdx;
            loadCurrentSheet();
            txt = findobj(fig,'Tag','sheetNameDisplay');
            txt.String = sheetList{currSheet};
        end
    end

    function Ys = applySmoothing(Ys)
        if ~chkSmooth.Value, return; end
        w = str2double(edtWindow.String);
        if w<3, w=3; end
        if mod(w,2)==0, w=w+1; end
        for c = 1:size(Ys,2)
            y = Ys(:,c);
            if popMethod.Value==1
                Ys(:,c) = movmean(y,w);
            else
                Ys(:,c) = sgolayfilt(y,2,w);
            end
        end
    end

    function S = calculateSlopes(Y,step)
        nC = size(Y,2); nR = size(Y,1);
        nS = floor(nR/step); S = zeros(nC,nS);
        for c = 1:nC
            x = rawData(:,2*c-1);
            for s = 1:nS
                i1 = (s-1)*step+1; i2 = i1+step-1;
                p = polyfit(x(i1:i2),Y(i1:i2,c),1);
                S(c,s) = p(1);
            end
        end
    end

    function refresh()
        step = str2double(tramoBox.String);
        if isnan(step)||step<2
            warndlg('Segment length must be ≥2'); return;
        end
        perfilesSuavizados = applySmoothing(perfilesY);
        resultados = calculateSlopes(perfilesSuavizados,step);
        figure('Name','Boxplot — All Profiles');
        boxplot(resultados,'Labels',compose('Seg %d',1:size(resultados,2)));
        title(sprintf('Slopes (step=%d)',step));
        xlabel('Segment'); ylabel('Slope');
    end

    function autocluster()
        step = str2double(tramoBox.String);
        perfilesSuavizados = applySmoothing(perfilesY);
        feats = calculateSlopes(perfilesSuavizados,step);

        if chkForceK.Value
            kList = str2double(clusterKBox.String);
        else
            kList = 2:min(8,floor(size(feats,1)/2));
        end
        bestScore = -Inf;
        for k = kList
            Z = zscore(feats);
            try
                idx = kmeans(Z,k,'Replicates',5);
                sil = mean(silhouette(Z,idx));
                if sil>bestScore
                    bestScore = sil;
                    bestK = k;
                    bestLabels = idx;
                    bestFeats = feats;
                end
            catch, end
        end

        figure('Name','Boxplot by Group'); hold on
        cols = lines(bestK);
        for g = 1:bestK
            subplot(1,bestK,g);
            boxplot(bestFeats(bestLabels==g,:), ...
                    'Labels',compose('S%d',1:size(bestFeats,2)));
            title(sprintf('Group %d (n=%d)',g,sum(bestLabels==g)));
        end

        figure('Name','Curves by Group'); hold on
        for g = 1:bestK
            for i = find(bestLabels==g)'
                plot(perfilesSuavizados(:,i), ...
                     'Color',cols(g,:),'LineWidth',0.8);
            end
        end
        title('Profiles clustered'); xlabel('Point'); ylabel('Value');
    end

    function saveResults()
        if isempty(resultados)
            warndlg('Run Refresh or Autocluster first.'); return;
        end
        [nC,nS] = size(resultados);
        names = {};
        for c = 1:nC
            for s = 1:nS
                names{end+1} = sprintf('Stiffness%d-%d',c,s);
            end
        end
        linS = reshape(resultados',[],1);
        T = table(linS,'RowNames',names');
        [fname,fpath] = uiputfile('slopes.xlsx','Save Results');
        if fname==0, return; end
        xfile = fullfile(fpath,fname);
        writetable(T,xfile,'WriteRowNames',true,'Sheet','Slopes');

        if exist('bestLabels','var')
            resp = questdlg( ...
                'Save clustered curves & map?', ...
                'Clustering Data','Yes','No','Yes');
            if strcmp(resp,'Yes')
                % GroupedCurves
                GC = [];
                for g = 1:max(bestLabels)
                    GC = [GC, perfilesSuavizados(:,bestLabels==g)];
                end
                writematrix(GC, xfile,'Sheet','GroupedCurves');

                % ClusterMap
                pm = (1:numel(bestLabels))';
                CM = table(pm,bestLabels, ...
                            'VariableNames',{'Profile','Group'});
                writetable(CM,xfile,'Sheet','ClusterMap');
            end
        end
        msgbox('Data saved.','Done');
    end

    function onHover(~,~)
        pt = fig.CurrentPoint;
        for b = btns
            pos = b.Position;
            inside = pt(1)>=pos(1) && pt(1)<=pos(1)+pos(3) && ...
                     pt(2)>=pos(2) && pt(2)<=pos(2)+pos(4);
            if inside && ~b.UserData
                sound(bellSound,fsBell);
                b.UserData = true;
            elseif ~inside
                b.UserData = false;
            end
        end
    end
end
