function KymomaticScibyl
% KymomaticScibyl: Wizard modular para análisis de perfiles por pendiente.
% Inspirado en códices, ciencia y símbolos antiguos.

    % Pantalla de bienvenida con imagen y cita
    showIntroScreen_Step1('assets/library_step1_bg.png', ...
        'Kymomatic Scibyl', ...
        'In venatione texturae, veritas latent.');

    try
        [fileName, filePath] = uigetfile('*.csv', 'Select CSV with paired (Time, Height) profiles');
        if isequal(fileName, 0)
            disp('Operation cancelled.');
            return;
        end
        rawData = readmatrix(fullfile(filePath, fileName));
        validateInput(rawData);
    catch ME
        errordlg(ME.message, 'Error loading data');
        return;
    end

    config = struct( ...
        'sgWindow', 11, ...
        'sgOrder', 3, ...
        'sensitivity', 1.5, ...
        'minThreshold', 0.01, ...
        'startPercent', 0, ...
        'methods', {{ ...
            'First Derivative', 'Second Derivative', ...
            'Wavelet Transform', 'Clustering', ...
            'Kalman Filter', 'Spline Regression' ...
        }} ...
    );

    % Paso 1: configuración SG
    config = launchSGConfigUI(rawData, config);
    if isempty(config)
        return;
    end

    % Preprocesamiento: suavizado + derivadas
    [smoothed, deriv] = preprocessProfiles(rawData, config);

    % Paso 2: interfaz de detección
    detectionIdx = launchDetectionUI(rawData, smoothed, deriv, config);
    if isempty(detectionIdx)
        return;
    end

    % Paso 3: resumen y exportación
    showSummaryUI(rawData, detectionIdx, deriv, config);
end
function showIntroScreen_Step1(imagePath, titleText, subtitle)
    fig = figure('Name','Welcome','NumberTitle','off','MenuBar','none', ...
        'ToolBar','none','Resize','off','Position',[500 200 800 500], ...
        'Color','black');

    img = imread(imagePath);
    ax = axes('Parent',fig, 'Position',[0 0 1 1]);
    imshow(img, 'Parent', ax);
    axis off;

    % Título con relieve dorado
    uicontrol(fig,'Style','text','String',titleText, ...
        'FontSize',24,'FontWeight','bold','FontName','Cardo', ...
        'ForegroundColor',[0.95 0.85 0.4], ...
        'BackgroundColor','none', ...
        'Units','normalized','Position',[0.25 0.85 0.5 0.08]);

    % Cita
    uicontrol(fig,'Style','text','String',subtitle, ...
        'FontSize',12,'FontAngle','italic','FontName','Cardo', ...
        'ForegroundColor',[0.9 0.85 0.6], ...
        'BackgroundColor','none', ...
        'Units','normalized','Position',[0.25 0.05 0.5 0.05]);

    % Fade-in
    imgHandle = findall(fig,'Type','image');
    for alpha = linspace(0,1,40)
        pause(0.04);
        set(imgHandle, 'AlphaData', alpha);
        drawnow;
    end

    pause(2.5);
    close(fig);
end
    function showIntroScreen_Step2(imagePath, titleText, subtitle)
    fig = figure('Name','Welcome','NumberTitle','off','MenuBar','none', ...
        'ToolBar','none','Resize','off','Position',[500 200 800 500], ...
        'Color','black');

    img = imread(imagePath);
    ax = axes('Parent',fig, 'Position',[0 0 1 1]);
    imshow(img, 'Parent', ax);
    axis off;

    % Título con relieve dorado
    uicontrol(fig,'Style','text','String',titleText, ...
        'FontSize',24,'FontWeight','bold','FontName','Cardo', ...
        'ForegroundColor',[0.95 0.85 0.4], ...
        'BackgroundColor','none', ...
        'Units','normalized','Position',[0.25 0.85 0.5 0.08]);

    % Cita
    uicontrol(fig,'Style','text','String',subtitle, ...
        'FontSize',12,'FontAngle','italic','FontName','Cardo', ...
        'ForegroundColor',[0.9 0.85 0.6], ...
        'BackgroundColor','none', ...
        'Units','normalized','Position',[0.25 0.05 0.5 0.05]);

    % Fade-in
    imgHandle = findall(fig,'Type','image');
    for alpha = linspace(0,1,40)
        pause(0.02);
        set(imgHandle, 'AlphaData', alpha);
        drawnow;
    end

    pause(2.5);
    close(fig);
end
function config = launchSGConfigUI(data, config)
    fig = figure('Name','Step 1: Smoothing Configuration', ...
        'NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Position',[500 400 420 250], 'Color',[0.97 0.97 0.97]);

    % Fondo decorativo (opcional)
    bg = axes('Parent',fig,'Position',[0 0 1 1]);
    img = imread('assets/step1_table_overlay.png'); % imagen decorativa opcional
    imshow(img, 'Parent', bg);
    uistack(bg, 'bottom');

    % Controles
    uicontrol(fig,'Style','text','String','Window Length (odd)', ...
        'FontSize',10,'HorizontalAlignment','left', ...
        'Position',[30 180 150 30],'BackgroundColor','none');
    hWin = uicontrol(fig,'Style','slider','Min',5,'Max',21,'Value',config.sgWindow, ...
        'SliderStep',[1/16 1/16],'Position',[180 185 180 20]);
    hWinVal = uicontrol(fig,'Style','text','String',num2str(config.sgWindow), ...
        'Position',[370 180 40 20],'BackgroundColor','w');
    addlistener(hWin,'ContinuousValueChange',@(src,~) ...
        set(hWinVal,'String',num2str(round(src.Value))));

    uicontrol(fig,'Style','text','String','Polynomial Order', ...
        'FontSize',10,'HorizontalAlignment','left', ...
        'Position',[30 130 150 30],'BackgroundColor','none');
    hOrd = uicontrol(fig,'Style','popupmenu', ...
        'String',{'2','3','4','5'}, ...
        'Value',find([2 3 4 5]==config.sgOrder), ...
        'Position',[180 135 100 25]);

    uicontrol(fig,'Style','text', ...
        'String','Smoothing will apply to each profile before detecting slope changes.', ...
        'FontSize',9,'ForegroundColor',[.2 .2 .2], ...
        'Position',[30 80 360 30],'BackgroundColor','none');

    uicontrol(fig,'Style','pushbutton','String','Continue →', ...
        'FontSize',10,'Position',[150 20 120 40], ...
        'Callback',@confirmAndClose);

    uiwait(fig);

    function confirmAndClose(~,~)
        val = round(hWin.Value);
        if mod(val,2) == 0
            val = val + 1;
        end
        config.sgWindow = val;
        config.sgOrder = str2double(hOrd.String{hOrd.Value});
        close(fig);
    end
end
function detectionIdx = launchDetectionUI(rawData, smoothed, deriv, config)
    fig = figure('Name','Step 2: Slope Detection', ...
        'NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Position',[500 300 820 540]);

    % Fondo biblioteca crepuscular
    bg = axes('Parent',fig,'Position',[0 0 1 1]);
    img = imread('assets/library_step2_bg.png');
    imshow(img, 'Parent', bg);
    uistack(bg, 'bottom');

    numProfiles = size(smoothed,2)/2;
    methods = config.methods;
    detectionIdx = cell(numProfiles,1);

    axLeft  = axes('Parent',fig,'Position',[0.07 0.3 0.4 0.6]);
    axRight = axes('Parent',fig,'Position',[0.55 0.3 0.4 0.6]);

    uicontrol(fig,'Style','text','String','Detection Method:', ...
        'Position',[50 180 120 20],'HorizontalAlignment','left');
    hMethod = uicontrol(fig,'Style','popupmenu','String',methods, ...
        'Position',[180 180 160 25],'Value',1,'Callback',@refreshPlots);

    uicontrol(fig,'Style','text','String','Sensitivity:', ...
        'Position',[50 140 100 20],'HorizontalAlignment','left');
    hSens = uicontrol(fig,'Style','slider','Min',0.5,'Max',3,'Value',config.sensitivity, ...
        'Position',[150 145 200 20],'Callback',@refreshPlots);

    uicontrol(fig,'Style','text','String','Min Threshold:', ...
        'Position',[50 100 100 20],'HorizontalAlignment','left');
    hThr = uicontrol(fig,'Style','slider','Min',0,'Max',0.05,'Value',config.minThreshold, ...
        'Position',[150 105 200 20],'Callback',@refreshPlots);

    uicontrol(fig,'Style','text','String','Start Index (%)', ...
        'Position',[50 60 100 20],'HorizontalAlignment','left');
    hStart = uicontrol(fig,'Style','slider','Min',0,'Max',1,'Value',config.startPercent, ...
        'Position',[150 65 200 20],'Callback',@refreshPlots);

    uicontrol(fig,'Style','pushbutton','String','→ Continue', ...
        'FontSize',11,'Position',[330 15 130 40], ...
        'Callback',@finalizeAndClose);

    refreshPlots();
    uiwait(fig);

    function refreshPlots(~,~)
        method = methods{hMethod.Value};
        sens   = hSens.Value;
        minThr = hThr.Value;
        pStart = hStart.Value;

        axes(axLeft); cla; hold on;
        for k = 1:numProfiles
            t = smoothed(:,2*k-1);
            y = smoothed(:,2*k);
            plot(t, y, 'Color',[.7 .7 .7]);
        end
        title('Smoothed Profiles'); xlabel('Time'); ylabel('Height');
        hold off;

        axes(axRight); cla; hold on;
        t = smoothed(:,1); y = smoothed(:,2);
        idx = detectModel(method, y, deriv(:,1), struct( ...
            'sensitivity', sens, ...
            'min_threshold', minThr, ...
            'start_index', round(pStart * size(deriv,1)) + 1 ...
        ));
        plot(t, y, 'b'); scatter(t(idx), y(idx), 35, 'r', 'filled');
        title(['Sample Detection — ', method]); xlabel('Time'); ylabel('Height');
        hold off;
    end

    function finalizeAndClose(~,~)
        method = methods{hMethod.Value};
        sens   = hSens.Value;
        minThr = hThr.Value;
        pStart = hStart.Value;
        stIdx  = round(pStart * size(deriv,1)) + 1;

        for k = 1:numProfiles
            y  = smoothed(:,2*k);
            dY = deriv(:,k);
            idx = detectModel(method, y, dY, struct( ...
                'sensitivity', sens, ...
                'min_threshold', minThr, ...
                'start_index', stIdx ...
            ));
            detectionIdx{k} = idx;
        end

        config.sensitivity = sens;
        config.minThreshold = minThr;
        config.startPercent = pStart;

        close(fig);
    end
end
function showSummaryUI(rawData, detectionIdx, deriv, config)
    fig = figure('Name','Step 3: Summary & Export', ...
        'MenuBar','none','ToolBar','none','NumberTitle','off', ...
        'Position',[500 200 850 550], 'Color',[1 1 1]);

    % Fondo: escritorio visto desde arriba
    bg = axes('Parent',fig,'Position',[0 0 1 1]);
    img = imread('assets/desk_step3_bg.png');
    imshow(img, 'Parent', bg);
    uistack(bg, 'bottom');

    numProfiles = numel(detectionIdx);
    maxSegs = 0;
    slopeDiffs = cell(numProfiles,1);

    for k = 1:numProfiles
        t = rawData(:,2*k-1);
        y = rawData(:,2*k);
        idx = detectionIdx{k};
        if isempty(idx), idx = [1; length(t)]; end
        pts = [1; idx; length(t)];
        slopes = arrayfun(@(i) computeSlope(t(pts(i:i+1)), y(pts(i:i+1))), ...
                          1:numel(pts)-1)';
        slopeDiffs{k} = abs(diff(slopes));
        maxSegs = max(maxSegs, numel(slopeDiffs{k}));
    end

    % Gráfico 1: puntos detectados
    ax1 = axes('Parent',fig,'Position',[0.07 0.58 0.87 0.34]);
    hold(ax1,'on');
    for k = 1:numProfiles
        t = rawData(:,2*k-1);
        y = rawData(:,2*k);
        plot(ax1, t(detectionIdx{k}), y(detectionIdx{k}), '-o','LineWidth',1.5);
    end
    hold(ax1,'off');
    title(ax1,'Detected Points by Profile');
    xlabel(ax1,'Time'); ylabel(ax1,'Height');

    % Gráfico 2: boxplot de cambios de pendiente
    ax2 = axes('Parent',fig,'Position',[0.07 0.15 0.87 0.34]);
    matrixBox = NaN(numProfiles, maxSegs);
    for k = 1:numProfiles
        diffs = slopeDiffs{k};
        matrixBox(k,1:numel(diffs)) = diffs;
    end
    boxplot(ax2, matrixBox, ...
        'Labels', arrayfun(@num2str,1:maxSegs,'UniformOutput',false));
    title(ax2, 'Slope Change per Segment');
    xlabel(ax2, 'Segment'); ylabel(ax2, '|ΔSlope|');

    % Botón de exportación como sello de lacre
    uicontrol(fig,'Style','pushbutton','String','Export to XLSX', ...
        'FontSize',10,'Position',[360 20 120 40], ...
        'BackgroundColor',[0.8 0.2 0.2],'ForegroundColor','w', ...
        'FontWeight','bold','Callback',@exportResults);

    function exportResults(~,~)
        [fileName, pathName] = uiputfile('*.xlsx','Save results as');
        if isequal(fileName,0), return; end
        fname = fullfile(pathName, fileName);

        maxPts = max(cellfun(@numel,detectionIdx));
        outIdx = NaN(maxPts, numProfiles);
        for k = 1:numProfiles
            outIdx(1:numel(detectionIdx{k}),k) = detectionIdx{k};
        end
        writematrix(outIdx, fname, 'Sheet','DetectedPoints');
        writematrix(matrixBox, fname, 'Sheet','SlopeChanges');

        msgbox('Export completed successfully.','Success');
    end
end
function s = computeSlope(x, y)
    if numel(x) < 2
        s = 0;
    else
        p = polyfit(x, y, 1);
        s = p(1);
    end
end

function indices = detectModel(modelName, profile, derivative, params)
    switch modelName
        case 'First Derivative'
            thr = params.sensitivity * std(derivative);
            idx = find(abs(derivative) > max(thr, params.min_threshold));

        case 'Second Derivative'
            sd  = diff(derivative);
            thr = params.sensitivity * std(sd);
            idx = find(abs(sd) > max(thr, params.min_threshold)) + 1;

        case 'Wavelet Transform'
            [wt,~] = cwt(profile);
            coeff  = wt(round(size(wt,1)/2),:);
            thr    = params.sensitivity * std(coeff);
            idx    = find(abs(coeff) > max(thr, params.min_threshold));

        case 'Clustering'
            D = abs(derivative);
            [clust, centers] = kmeans(D, 2, 'Replicates', 5);
            target = find(centers == max(centers), 1);
            idx = find(clust == target);

        case 'Kalman Filter'
            pred = movmean(profile, 5);
            res  = abs(profile - pred);
            thr  = params.sensitivity * std(res);
            idx  = find(res > max(thr, params.min_threshold));

        case 'Spline Regression'
            pp = spline((1:numel(profile))', profile);
            est = ppval(pp, (1:numel(profile))');
            res = abs(profile - est);
            thr = params.sensitivity * std(res);
            idx = find(res > max(thr, params.min_threshold));

        otherwise
            idx = [];
    end

    indices = idx(idx >= params.start_index);
end
