function LauncherTemple()
    % LauncherTemple: fade‐in místico + menú de oráculos
    % Paso 1: cargamos la portada
    img = imread('assets/splash_bg.png');  
    
    % Creamos la figura
    fig = figure( ...
        'Name','Temple','NumberTitle','off', ...
        'MenuBar','none','ToolBar','none','Resize','off', ...
        'Color','black','Position',[600 300 600 450] ...
    );
    
    % Ejes invisibles ocupando toda la figura
    ax = axes('Parent',fig,'Position',[0 0 1 1]);
    imHandle = imshow(img,'Parent',ax);
    set(ax,'Visible','off');
    
    % Inicializamos alpha a 0 (totalmente transparente)
    imHandle.AlphaData = zeros(size(img,1),size(img,2));
    drawnow;
    
    % Paso 2: fundido: 100 pasos en 10s
    nSteps = 100;
    for k = 1:nSteps
        alphaVal = k/nSteps;
        imHandle.AlphaData(:,:) = alphaVal;
        pause(10/nSteps);
    end
    
         
    % Paso 3: botones interactivos
    btnOracle = uicontrol(fig,'Style','pushbutton', ...
        'String','🧿 Kymomatic Scibyl', ...
        'FontSize',14, ...
        'Units','normalized', ...
        'Position',[0.3 0.35 0.4 0.07], ...
        'Callback',@launchScibyl ...
    );
    
    btnCluster = uicontrol(fig,'Style','pushbutton', ...
        'String','🔮 Arcane Clustering', ...
        'FontSize',14, ...
        'Units','normalized', ...
        'Position',[0.3 0.25 0.4 0.07], ...
        'Callback',@launchCluster ...
    );
    
    % Callbacks
    function launchScibyl(~,~)
        close(fig);
        KymomaticScibyl();     % Invoca tu wizard de pendientes
    end

    function launchCluster(~,~)
        close(fig);
        ArcaneClustering();    % Lanza tu módulo de clustering
    end
end


