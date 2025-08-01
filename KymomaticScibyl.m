function KymomaticScibyl
% KymomaticScibyl: Wizard modular para análisis de perfiles por pendiente.
% Inspirado en códices, ciencia y símbolos antiguos.
doBack=false;
%% Bienvenida
    % Pantalla de bienvenida con imagen y cita
    showIntroScreen_Step0('assets/library_step0_bg.png');

    try
        [fileName, filePath] = uigetfile('*.csv', 'Select CSV with paired (Time, Height) profiles');
        if isequal(fileName, 0)
            disp('Operation cancelled.');
            return;
        end
        rawData = readmatrix(fullfile(filePath, fileName));
        rawData = validateInput(rawData);  % ← ahora devuelve los datos corregidos
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

function showIntroScreen_Step0(imagePath, titleText, subtitle)
    fig = figure('Name','Welcome','NumberTitle','off','MenuBar','none', ...
        'ToolBar','none','Resize','off','Units','normalized','Position',[0.1 0.05 0.75 0.88], ...
        'Color','black');

    img = imread(imagePath);
    ax = axes('Parent',fig, 'Position',[0 0 1 1]);
    imshow(img, 'Parent', ax);
    axis off;

    %Cita

     quotes = {
        ['“The important thing is not to stop questioning.” — Albert Einstein']
        ['“What I cannot create, I do not understand.” — Richard Feynman']
        ['“Somewhere, something incredible is waiting to be known.” — Carl Sagan']
        ['“Science is the great antidote to the poison of enthusiasm and superstition.” — Adam Smith']
        ['“Equipped with his five senses, man explores the universe around him.” — Edwin Hubble']
        ['“The good thing about science is that it’s true whether or not you believe in it.” — Neil deGrasse Tyson']
        ['“In questions of science, the authority of a thousand is not worth the humble reasoning of a single individual.” — Galileo Galilei']
        ['“If I have seen further it is by standing on the shoulders of Giants.” — Isaac Newton']
        ['“Science is a way of thinking much more than it is a body of knowledge.” — Carl Sagan']
        ['“The universe is under no obligation to make sense to you.” — Neil deGrasse Tyson']
    };

    % 🎲 Seleccionar una cita aleatoria
    idx = randi(numel(quotes));
    selectedQuote = quotes{idx};
% Número máximo de caracteres por línea
maxChars = 80;

% Si la cita es muy larga, dividirla en líneas
if strlength(selectedQuote) > maxChars
    words = split(selectedQuote);
    lines = strings(0);  % Inicializar como arreglo de strings
    currentLine = "";

    for i = 1:length(words)
        testLine = strtrim(currentLine + " " + words(i));
        if strlength(testLine) < maxChars
            currentLine = testLine;
        else
            lines(end+1) = strtrim(currentLine); %#ok<SAGROW>
            
            currentLine = words(i);

        end
    end
    lines(end+1) = strtrim(currentLine);
    selectedQuote = strjoin(lines, newline);
end
     % Ejes invisibles ocupando toda la figura
    ax = axes('Parent',fig,'Position',[0 0 1 1]);
    imHandle = imshow(img,'Parent',ax);
    set(ax,'Visible','off');
    
    % Inicializamos alpha a 0 (totalmente transparente)
    imHandle.AlphaData = zeros(size(img,1),size(img,2));
    drawnow;
    % 🧾 Mostrar cita en la parte superior
    % 🧾 Mostrar cita con transparencia real usando text()
axQuote = axes('Parent',fig, ...
    'Position',[0 0 1 1], ...
    'Color','none', ...
    'XColor','none','YColor','none', ...
    'HitTest','off');  % No interfiere con clics

text(axQuote, 0.5, 0.1, selectedQuote, ...
    'Units','normalized', ...
    'HorizontalAlignment','center', ...
    'FontSize',28, ...
    'FontAngle','italic', ...
    'FontName','Cardo', ...
    'Color',[1 1 1]);
 
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


%% STEP1 
  function showIntroScreen_Step1(imagePath, titleText, subtitle)
    fig = figure('Name','Welcome','NumberTitle','off','MenuBar','none', ...
        'ToolBar','none','Resize','off','Units','normalized', 'Position',[0.2 0.2 0.6 0.6], ...
        'Color','black');

    img = imread(imagePath);
    ax = axes('Parent',fig, 'Position',[0 0 1 1]);
    imshow(img, 'Parent', ax);
    axis off;

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
    % Paso 3: Guardar datos suavizados en smoothedData
    refreshSmoothingPreview();  % ← genera la gráfica inicial
    smoothedData = zeros(size(rawData))
    for k = 1:size(rawData,2)/2
       t = rawData(:,2*k-1);
       y = rawData(:,2*k);
       win = round(config.sgWindow);
    if mod(win,2)==0, win = win+1; 
    end
       ord = config.sgOrder;
       ySmooth = sgolayfilt(y, ord, win);
       smoothedData(:,2*k-1) = t;         % Tiempo (igual)
       smoothedData(:,2*k)   = ySmooth;   % Altura suavizada
    
       % Paso 4: resumen y exportación
    showSummaryUI(rawData, detectionIdx, deriv, config);
   end
   
function [config, smoothedData] = launchSGConfigUI(rawData, config)
    % Paso 1: configuración SG
    fig = figure('Name','Step 1: Smoothing Configuration', ...
        'NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Units','normalized','Position',[0.1 0.05 0.75 0.9], ...
        'Color',[0.97 0.97 0.97]);

    % Fondo decorativo
    axBg = axes('Parent',fig,'Position',[0 0 1 1]);
    bgImg = imread('assets/library_step1_bg.png');
    imshow(bgImg,'Parent',axBg);
    axis(axBg,'off'); uistack(axBg,'bottom');

    % Marco decorativo
    axFrame = axes('Parent',fig,'Units','normalized','Position',[0.28 0.35 0.5 0.6]);
    frameImg = imread('assets/golden_frame_volutes.png');
    imshow(frameImg, 'Parent', axFrame);
    axis(axFrame,'off'); uistack(axFrame,'bottom');

    % Ejes para preview
    axPreview = axes('Parent',fig,'Units','normalized','Position',[0.15 0.36 0.7 0.3]);
    box(axPreview,'off');
    title(axPreview, 'Smoothed vs Original','FontSize',18,'FontName','Cardo');

    % Sliders y dropdown
    hWin = uicontrol(fig,'Style','slider','Min',1,'Max',25,'Value',config.sgWindow, ...
        'SliderStep',[1/24 1/24],'Units','normalized','Position',[0.07 0.89 0.3 0.03]);
    hWinVal = uicontrol(fig,'Style','text','String',num2str(config.sgWindow), ...
        'FontName','Cardo','FontSize',11,'Units','normalized','Position',[0.38 0.89 0.03 0.02],'BackgroundColor','w');
    addlistener(hWin,'ContinuousValueChange',@(src,~) set(hWinVal,'String',num2str(round(src.Value))));

    hOrd = uicontrol(fig,'Style','popupmenu','String',{'2','3','4','5'}, ...
        'Value',find([2 3 4 5]==config.sgOrder), ...
        'FontName','Cardo','FontSize',11, ...
        'Units','normalized','Position',[0.85 0.9 0.05 0.05]);

    % Botones
    uicontrol(fig,'Style','pushbutton','String','🔄 Refresh', ...
        'FontSize',20,'FontName','Cardo','Units','normalized', ...
        'Position',[0.1 0.1 0.2 0.05],'Callback',@refreshPreview);

    uicontrol(fig,'Style','pushbutton','String','Continue →', ...
        'FontSize',20,'FontName','Cardo','Units','normalized', ...
        'Position',[0.4 0.1 0.2 0.05],'Callback',@confirmAndClose);

    uicontrol(fig,'Style','pushbutton','String','← Back', ...
        'FontSize',20,'FontName','Cardo','Units','normalized', ...
        'Position',[0.7 0.1 0.2 0.05],'Callback',@goBack);

    % Visualización automática al abrir
    previewSmoothedProfile(axPreview, rawData, config);

    uiwait(fig);  % espera a que el usuario cierre la ventana

    %% — Subfunciones ———————————————————————————————————————

    function refreshPreview(~,~)
        config.sgWindow = round(hWin.Value);
        if mod(config.sgWindow,2)==0, config.sgWindow = config.sgWindow + 1; end
        config.sgOrder  = str2double(hOrd.String{hOrd.Value});
        previewSmoothedProfile(axPreview, rawData, config);
    end

    function confirmAndClose(~,~)
        config.sgWindow = round(hWin.Value);
        if mod(config.sgWindow,2)==0, config.sgWindow = config.sgWindow + 1; end
        config.sgOrder  = str2double(hOrd.String{hOrd.Value});

        smoothedData = generateSmoothedData(rawData, config);
        close(fig);
    end

    function goBack(~,~)
        config = [];
        smoothedData = [];
        close(fig);
    end
end

%% Función modular: suavizado
function smoothedData = generateSmoothedData(rawData, config)
    nProfiles = size(rawData,2)/2;
    smoothedData = zeros(size(rawData));
    for k = 1:nProfiles
        t = rawData(:,2*k-1);
        y = rawData(:,2*k);
        win = config.sgWindow;
        if mod(win,2)==0, win = win+1; end
        ord = config.sgOrder;
        ySmooth = sgolayfilt(y, ord, win);
        smoothedData(:,2*k-1) = t;
        smoothedData(:,2*k)   = ySmooth;
    end
end

%% Función modular: preview inicial
function previewSmoothedProfile(ax, rawData, config)
    nProfiles = size(rawData,2)/2;
    k = randi(nProfiles);  % perfil aleatorio
    t = rawData(:,2*k-1);
    y = rawData(:,2*k);
    win = config.sgWindow;
    if mod(win,2)==0, win = win+1; end
    ord = config.sgOrder;
    ySmooth = sgolayfilt(y, ord, win);

    cla(ax); hold(ax,'on');
    plot(ax, t, y, '--', 'Color',[.5 .5 .5],'LineWidth',2);
    plot(ax, t, ySmooth, '-', 'Color',[.2 .2 .8],'LineWidth',3);
    legend(ax, 'Original','Smoothed','FontName','Cardo');
    xlabel(ax,'Time','FontName','Cardo');
    ylabel(ax,'Height','FontName','Cardo');
    hold(ax,'off');
end

    
    %% — STEP2 ———————————————————————————————————————
function [detectionIdx, doBack] = launchDetectionUI(smoothedData, smoothed, deriv, config)
    doBack = false;
    numProfiles  = size(smoothed,2)/2;
    methods      = config.methods;
    detectionIdx = cell(numProfiles,1);
    currentProf  = 1;

    fig = figure( ...
        'Name','Step 2: Slope Detection', ...
        'NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Units','normalized','Position',[0.05 0.05 0.85 0.85], ...
        'Color',[0.97 0.97 0.97] ...
    );

    % Fondo decorativo
    axBg = axes('Parent',fig,'Units','normalized','Position',[0 0 1 1]);
    imshow(imread('assets/library_step2_bg.png'),'Parent',axBg);
    axis(axBg,'off'); uistack(axBg,'bottom');

    % Gráficas superiores
    axPerfil = axes(fig, 'Units','normalized', 'Position',[0.05 0.55 0.28 0.40]);
    axHist   = axes(fig, 'Units','normalized', 'Position',[0.36 0.55 0.28 0.40]);
    axDetect = axes(fig, 'Units','normalized', 'Position',[0.67 0.55 0.28 0.40]);
    for ax = [axPerfil, axHist, axDetect]
        box(ax,'on'); uistack(ax,'top');
    end

    % Parámetros visuales
    yTxt = 0.40; ySl = 0.35; h = 0.05; w = 0.12; gap = 0.03; x0 = 0.05;

    % Sliders
    uicontrol(fig,'Style','text','String','Sensitivity:', 'Units','normalized', 'Position',[x0 yTxt w h],'FontName','Cardo');
    hSens = uicontrol(fig,'Style','slider','Units','normalized','Position',[x0 ySl w h],'Min',0.5,'Max',3,'Value',config.sensitivity);

    x1 = x0 + w + gap;
    uicontrol(fig,'Style','text','String','Min Thresh:', 'Units','normalized', 'Position',[x1 yTxt w h],'FontName','Cardo');
    hThr = uicontrol(fig,'Style','slider','Units','normalized','Position',[x1 ySl w h],'Min',0,'Max',0.05,'Value',config.minThreshold);

    x2 = x1 + w + gap;
    uicontrol(fig,'Style','text','String','Start Index:', 'Units','normalized', 'Position',[x2 yTxt w h],'FontName','Cardo');
    hStart = uicontrol(fig,'Style','slider','Units','normalized','Position',[x2 ySl w h],'Min',0,'Max',1,'Value',config.startPercent);

    % Ensemble y método
    yRow2 = 0.25; xb0 = 0.05;
    hEnsemble = uicontrol(fig,'Style','checkbox','String','Ensemble', 'Units','normalized','Position',[xb0 yRow2 0.12 h],'FontName','Cardo');
    xb1 = xb0 + 0.12 + gap;
    uicontrol(fig,'Style','text','String','Agree ≥','Units','normalized', 'Position',[xb1 yRow2 0.08 h],'FontName','Cardo','HorizontalAlignment','right');
    hConsensus = uicontrol(fig,'Style','edit','String','2','Units','normalized','Position',[xb1+0.08 yRow2 0.04 h],'FontName','Cardo');
    xb2 = xb1 + 0.08 + 0.04 + gap;
    uicontrol(fig,'Style','text','String','Min Dist (%):','Units','normalized','Position',[xb2 yRow2 0.12 h],'FontName','Cardo');
    hMinDist = uicontrol(fig,'Style','edit','String','5','Units','normalized','Position',[xb2+0.12 yRow2 0.05 h],'FontName','Cardo');
    xb3 = xb2 + 0.12 + 0.05 + gap;
    uicontrol(fig,'Style','text','String','Method:','Units','normalized','Position',[xb3 yRow2 0.08 h],'FontName','Cardo');
    hMethod = uicontrol(fig,'Style','popupmenu','String',methods,'Units','normalized','Position',[xb3+0.08 yRow2 0.12 h],'FontName','Cardo');

    % Botones de navegación
    yBtn = 0.10; btnW = 0.12; btnH = 0.06; totalB = 4 * btnW + 3 * gap; xbBtn = (1 - totalB)/2;
    uicontrol(fig,'Style','pushbutton','String','← Back','Units','normalized','Position',[xbBtn yBtn btnW btnH],'FontName','Cardo','Callback',@goBack);
    uicontrol(fig,'Style','pushbutton','String','🔄 Profile','Units','normalized','Position',[xbBtn+(btnW+gap) yBtn btnW btnH],'FontName','Cardo','Callback',@randomProfile);
    uicontrol(fig,'Style','pushbutton','String','🔄 Detect','Units','normalized','Position',[xbBtn+2*(btnW+gap) yBtn btnW btnH],'FontName','Cardo','Callback',@refreshAll);
    uicontrol(fig,'Style','pushbutton','String','→ Continue','Units','normalized','Position',[xbBtn+3*(btnW+gap) yBtn btnW btnH],'FontName','Cardo','Callback',@finalizeAndClose);

    % Primera ejecución
    refreshAll();
    uiwait(fig);
end
    %% — Subfunciones ———————————————————————————————————————
    function refreshAll(~,~)
        params.sensitivity   = hSens.Value;
        params.min_threshold = hThr.Value;
        params.start_index   = round(hStart.Value*size(deriv,1)) + 1;
        methodList = config.methods;
        method = methodList{hMethod.Value};
        useE   = hEnsemble.Value;
        k      = max(1,round(str2double(hConsensus.String)));
        nPts   = size(smoothedData,1);
        pct    = max(0,min(100,str2double(hMinDist.String)));
        winRad = ceil((pct/100*nPts)/2);

        % Reset gráfico
        cla(axPerfil); hold(axPerfil,'on');
        for m = 1:numProfiles
            t = smoothed(:,2*m-1);
            y = smoothed(:,2*m);
            plot(axPerfil, t, y, 'Color',[.7 .7 .7],'LineWidth',1.2);

            idx = detectModel(method, smoothedData(:,2*m), deriv(:,m), params);
            if isempty(idx)
                % Detección simulada
                yStart = mean(y(1:5)); yEnd = mean(y(end-4:end));
                tStart = t(1);         tEnd = t(end);
                [~, iStart] = min(abs(t - tStart));
                [~, iEnd]   = min(abs(t - tEnd));
                idx = [iStart; iEnd];
                colorMarker = [0.6 0.6 0.6];  % gris claro para simulados
            else
                colorMarker = [0.13 0.85 0.13]; % verde para detecciones reales
            end

            % Agrupamiento
            groups = {};
            if ~isempty(idx)
                curG = idx(1);
                for i = 2:numel(idx)
                    if idx(i) - curG(end) <= winRad
                        curG(end+1) = idx(i);
                    else
                        groups{end+1} = curG; curG = idx(i);
                    end
                end
                groups{end+1} = curG;
            end

            % Marcadores de grupo
            for g = 1:numel(groups)
                ci  = groups{g};
                mid = round(mean(ci));
                scatter(axPerfil, t(mid), y(mid), 60, colorMarker, 'filled');
            end
        end
        title(axPerfil,'All Smoothed Profiles + Grouped Detections','FontName','Cardo');
        xlabel(axPerfil,'Time','FontName','Cardo');
        ylabel(axPerfil,'Height','FontName','Cardo');
        hold(axPerfil,'off');

         % Histograma
        counts = zeros(nPts,1);
        for m = 1:numProfiles
            idx = detectModel(method, smoothedData(:,2*m), deriv(:,m), params);
            counts(idx) = counts(idx) + 1;
        end
        cla(axHist);
        bar(axHist, smoothedData(:,1), counts, 1, 'FaceColor',[0.2 0.6 0.8],'EdgeColor','none');
        xlim(axHist,[smoothedData(1,1) smoothedData(end,1)]);

        % Perfil único
        actualizarPerfilUnico();
    end

%%STEP3

function showSummaryUI(smoothedData, detectionIdx, deriv, config)
    fig = figure('Name','Step 3: Summary & Export', ...
        'MenuBar','none','ToolBar','none','NumberTitle','off', ...
        'Units', 'normalized', 'Position',[0.05 0.05 0.75 0.9], 'Color',[1 1 1]);
 
    % Fondo: escritorio visto desde arriba
    bg = axes('Parent',fig,'Position',[0 0 1 1]);
    img = imread('assets/desk_step3_bg.png');
    imshow(img, 'Parent', bg);
    uistack(bg, 'bottom');

    numProfiles = numel(detectionIdx);
    maxSegs = 0;
    slopeDiffs = cell(numProfiles,1);

    for k = 1:numProfiles
        t = smoothedData(:,2*k-1);
        y = smoothedData(:,2*k);
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
        t = smoothedData(:,2*k-1);
        y = smoothedData(:,2*k);
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
    hBack = uicontrol(fig, 'Style','pushbutton', 'String','← Back', ...
    'Units','normalized','Position',[xbBtn0- (btnW+gap) yBtn btnW btnH], ...
    'FontName','Cardo', 'Callback',@goBack);call
finl
    
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
function data = validateInput(data)
    [nRows, nCols] = size(data);

    % 1. Verifica que haya un número par de columnas
    if mod(nCols, 2) ~= 0
        error('El archivo debe tener un número par de columnas (parejas Tiempo–Altura).');
    end

    % 2. Verifica que no haya valores NaN
    if any(isnan(data), 'all')
        error('El archivo contiene valores NaN. Por favor, limpia los datos.');
    end

    % 3. Verifica que cada columna de tiempo esté ordenada
    for k = 1:2:nCols
        t = data(:,k);
        if ~issorted(t)
            warning('La columna %d (tiempo) no está ordenada. Se ordenará automáticamente.', k);
            % Ordenar ambas columnas (tiempo y altura) por tiempo
            pair = data(:,k:k+1);
            pair = sortrows(pair, 1);
            data(:,k:k+1) = pair;
        end
    end
end
function [smoothed, deriv] = preprocessProfiles(data, config)
    % PREPROCESSPROFILES   Suaviza y deriva cada perfil pareado (Time,Height)
    %   data:   matriz [nRows × (2·nProfiles)] con columnas alternas
    %           Tiempo, Altura
    %   config: struct con campos sgWindow y sgOrder
    %
    % Devuelve:
    %   smoothed: misma forma que data, con las alturas suavizadas
    %   deriv:    [nRows-1 × nProfiles] con derivadas 1ª

    [nRows, nCols] = size(data);
    nProfiles = nCols/2;

    smoothed = zeros(nRows, nCols);
    deriv    = zeros(nRows-1, nProfiles);

    for k = 1:nProfiles
        t = data(:,2*k-1);
        y = data(:,2*k);

        % 1) Suavizado Savitzky–Golay
        ySmooth = sgolayfilt(y, config.sgOrder, config.sgWindow);
        smoothed(:,2*k-1) = t;
        smoothed(:,2*k)   = ySmooth;

        % 2) Primera derivada
        dt = diff(t);
        dy = diff(ySmooth);
        deriv(:,k) = dy ./ dt;
    end
    
    function goBack(~,~)
    doBack = true;    % marca que queremos volver atrás
    detectionIdx = []; % no hay detecciones válidas
    close(fig);
    end

end
end
    indices = idx(idx >= params.start_index);
end
