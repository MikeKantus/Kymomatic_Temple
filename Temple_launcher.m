function LauncherTemple()
    % LauncherTemple: fade‐in místico + menú de oráculos
    % Paso 1: cargamos la portada
    img = imread('assets/TempleLogo.png');  
    % 🌌 Frases célebres de científicos
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
maxChars = 50;

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
    % Creamos la figura
    fig = figure( ...
        'Name','Temple','NumberTitle','off', ...
        'MenuBar','none','ToolBar','none','Resize','off', ...
        'Color','black','Position',[400 50 1000 1000] ...
    );
    
    % Ejes invisibles ocupando toda la figura
    ax = axes('Parent',fig,'Position',[0 0 1 1]);
    imHandle = imshow(img,'Parent',ax);
    set(ax,'Visible','off');
    
    % Inicializamos alpha a 0 (totalmente transparente)
    imHandle.AlphaData = zeros(size(img,1),size(img,2));
    drawnow;
    
    % Paso 2: fundido: 100 pasos en 10s
    nSteps = 40;
    for k = 1:nSteps
        alphaVal = k/nSteps;
        imHandle.AlphaData(:,:) = alphaVal;
        pause(2/nSteps);
    end
  % 🧾 Mostrar cita en la parte superior
    % 🧾 Mostrar cita con transparencia real usando text()
axQuote = axes('Parent',fig, ...
    'Position',[0 0 1 1], ...
    'Color','none', ...
    'XColor','none','YColor','none', ...
    'HitTest','off');  % No interfiere con clics

text(axQuote, 0.5, 0.9, selectedQuote, ...
    'Units','normalized', ...
    'HorizontalAlignment','center', ...
    'FontSize',25, ...
    'FontAngle','italic', ...
    'FontName','Cardo', ...
    'Color',[0 0 0]);


    % Paso 3: botones interactivos con logos

% Cargar imágenes
imgScibyl = imread('assets/KymomaticOracleLogo.png');
imgCluster = imread('assets/ArcaneClusteringLogo.png');
imgKymobit = imread('assets/KymobitLogo.png');
imgGayaDescriptorum = imread('gayaDescriptorumLogo.png');

% Redimensionar si es necesario (opcional)
imgScibyl = imresize(imgScibyl, [250 250]);
imgCluster = imresize(imgCluster, [250 250]);
imgKymobit = imresize(imgKymobit, [250 250]);
imgGayaDescriptorum = imresize(imgGayaDescriptorum, [250 250]);

% Botón: Kymomatic Scibyl
btnOracle = uicontrol(fig,'Style','pushbutton', ...
    'CData', imgScibyl, ...
    'TooltipString','🧿 Kymomatic Scibyl', ...
      'Position',[0 10 250 250], ...
    'BackgroundColor','black', ...
    'Callback',@launchKymomaticScibyl);

% Botón: Arcane Clustering
btnCluster = uicontrol(fig,'Style','pushbutton', ...
    'CData', imgCluster, ...
    'TooltipString','🔮 Arcane Clustering', ...
    'Position',[250 10 250 250], ...
    'BackgroundColor','black', ...
    'Callback',@launchArcaneClustering);
% Button: Kymobit (Python)
btnKymobit = uicontrol(fig,'Style','pushbutton', ...
    'CData', imgKymobit, ...
    'TooltipString','⚡ Kymobit (Python)', ...
    'Position',[500 10 250 250], ...
    'BackgroundColor','black', ...
    'Callback',@launchKymobit);


% Botón: Gaya Descriptorum
btnGaya = uicontrol(fig,'Style','pushbutton', ...
    'CData', imgGayaDescriptorum, ...
    'TooltipString','🧙‍♀️ Gaya Descriptorum', ...
    'Position',[750 10 250 250], ...
    'BackgroundColor','black', ...
    'Callback',@launchGayaDescriptorum);  
         

    % Callbacks
    function launchKymomaticScibyl(~,~)
        close(fig);
        KymomaticScibyl();     % Invoca tu wizard de pendientes
    end

    function launchArcaneClustering(~,~)
        close(fig);
        ArcaneClustering();    % Lanza tu módulo de clustering
    end

    function launchKymobit(~,~)
        close(fig); % Optional: close launcher
        system('python Kymobit.py'); % Adjust path if needed
    end

    function launchGayaDescriptorum(~,~)
        close(fig);
        GayaDescriptorum();    % Lanza tu módulo de clustering
    end
end

