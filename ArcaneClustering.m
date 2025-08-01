function ArcaneClustering()
    %% — Pantalla de bienvenida —
        showIntroScreen_Step0('assets/Cloister_step0.png');
    %% Variables compartidas
    rawData = []; perfilesY = []; perfilesSuavizados = [];
    resultados = []; bestLabels = []; bestFeats = []; bestK = [];

    %% Selección de fichero y hoja
    [file,path] = uigetfile({'*.xlsx;*.csv'},'Select profile data file');
    if isequal(file,0), return; end
    fullFile = fullfile(path,file);
    [~,~,ext] = fileparts(file);
    if strcmp(ext,'.xlsx'), sheetList = sheetnames(fullFile);
    else, sheetList = {'Sheet1'}; end
    currSheet = 1;

    %% Figura principal con fondo visual
    fig = figure('Name','Arcane Clustering','Units','normalized', ...
        'Position',[0.05 0.05 0.9 0.9],'Color','white', ...
        'MenuBar','none','ToolBar','none','Resize','on');

    % 🎨 Fondo completo
    img = imread('assets/Cloister_step2.png');
    axFondo = axes('Parent',fig,'Units','normalized','Position',[0 0 1 1]);
    imshow(img,'Parent',axFondo); axis off;
    set(axFondo,'HitTest','off','HandleVisibility','off');
    uistack(axFondo,'bottom');

    % 🪟 Ejes transparentes para paneles
    axPanelL = axes('Parent',fig,'Units','normalized','Position',[0.01 0.01 0.28 0.98]);
    axPanelR = axes('Parent',fig,'Units','normalized','Position',[0.30 0.01 0.69 0.98]);
    for ax = [axPanelL, axPanelR]
        set(ax,'Visible','off','HitTest','off');
        imgObj = image(zeros(2),'Parent',ax); imgObj.AlphaData = 0;
    end

    %% Panel izquierdo con controles
   pnlC = uipanel(fig, 'Units','normalized', 'Position',[0.01 0.01 0.28 0.98], ...
    'BorderType','none', ...
    'BackgroundColor', fig.Color);  % ← usa color de fondo de la figura (blanco)

    % Navegación hojas
    uicontrol(pnlC,'Style','pushbutton','Units','normalized','Position',[0.02 0.93 0.45 0.05], ...
        'String','← Prev Sheet','Callback',@(~,~) changeSheet(-1));
    uicontrol(pnlC,'Style','text','Units','normalized','Position',[0.49 0.93 0.45 0.05], ...
        'String',sheetList{currSheet},'FontWeight','bold','Tag','sheetNameDisplay');
    uicontrol(pnlC,'Style','pushbutton','Units','normalized','Position',[0.02 0.86 0.45 0.05], ...
        'String','Next Sheet →','Callback',@(~,~) changeSheet(+1));
    uicontrol(pnlC,'Style','pushbutton','Units','normalized','Position',[0.02 0.10 0.93 0.08], ...
        'String','Show Groups in Detail','BackgroundColor',[0.80 0.90 1], ...
        'Callback',@(~,~) showGroupedCurves());
    % Parámetros
    uicontrol(pnlC,'Style','text','Units','normalized','Position',[0.02 0.78 0.45 0.04], ...
        'String','Segment length:');
    tramoBox = uicontrol(pnlC,'Style','edit','Units','normalized','Position',[0.50 0.78 0.45 0.05], ...
        'String','5');
    chkSmooth = uicontrol(pnlC,'Style','checkbox','Units','normalized','Position',[0.02 0.70 0.93 0.05], ...
        'String','Apply smoothing','Value',0);
    popMethod = uicontrol(pnlC,'Style','popupmenu','Units','normalized','Position',[0.02 0.62 0.93 0.05], ...
        'String',{'Moving average','Savitzky-Golay'});
    edtWindow = uicontrol(pnlC,'Style','edit','Units','normalized','Position',[0.02 0.54 0.45 0.05], ...
        'String','5');
    chkForceK = uicontrol(pnlC,'Style','checkbox','Units','normalized','Position',[0.02 0.46 0.93 0.05], ...
        'String','Force # clusters','Value',0);
    clusterKBox = uicontrol(pnlC,'Style','edit','Units','normalized','Position',[0.50 0.46 0.45 0.05], ...
        'String','3');

    % Botones
    hRefresh = uicontrol(pnlC,'Style','pushbutton','Units','normalized','Position',[0.02 0.34 0.45 0.08], ...
        'String','Refresh','BackgroundColor',[1 0.95 0.80],'Callback',@(~,~) refreshMain());
    hAuto = uicontrol(pnlC,'Style','pushbutton','Units','normalized','Position',[0.52 0.34 0.45 0.08], ...
        'String','Autocluster','BackgroundColor',[1 0.90 0.70],'Callback',@(~,~) autocluster());
    uicontrol(pnlC,'Style','pushbutton','Units','normalized','Position',[0.02 0.22 0.93 0.08], ...
        'String','Save Results','BackgroundColor',[1 0.85 0.60],'Callback',@(~,~) saveResults());
    uicontrol(pnlC, ...
        'Style','pushbutton', ...
        'Units','normalized', ...
        'Position',[0.32 0.02 0.28 0.08], ...
        'String','Save Deluxe', ...
        'BackgroundColor',[0.90 1.00 0.85], ...
        'FontWeight','bold', ...
        'Callback',@(~,~) saveDeluxeModule());
     chkSession = uicontrol(pnlC, ...
        'Style','checkbox', ...
        'Units','normalized', ...
        'Position',[0.62 0.02 0.15 0.08], ...
        'String','Session', ...
        'TooltipString','Guardar archivo .mat de la sesión');

    %% Panel derecho con gráficas
    pnlP = uipanel(fig, 'Units','normalized', 'Position',[0.30 0.01 0.69 0.98], ...
    'BorderType','none', ...
    'BackgroundColor', fig.Color);  % mismo truco

    tl = tiledlayout(pnlP,3,1,'TileSpacing','compact','Padding','compact');
    fig.SizeChangedFcn = @(~,~) adjustLayout(tl,fig);
    axProf      = nexttile(tl,1);
    axCurves    = nexttile(tl,2);
    axBox       = nexttile(tl,3);

    %% Carga inicial y autocluster automático
    loadCurrentSheet(); autocluster();

    %% — Funciones anidadas —

    function loadCurrentSheet()
        if strcmp(ext,'.xlsx')
            rawData = readmatrix(fullFile,'Sheet',sheetList{currSheet});
        else
            rawData = readmatrix(fullFile);
        end
        if mod(size(rawData,2),2)~=0, errordlg('Column count must be even'); return; end
        perfilesY = rawData(:,2:2:end);
        perfilesSuavizados = perfilesY;
        resultados = [];
        set(findobj(pnlC,'Tag','sheetNameDisplay'),'String',sheetList{currSheet});
        refreshMain();
    end

    function refreshMain()
        perfilesSuavizados = applySmoothing(perfilesY);
        cla(axProf); hold(axProf,'on');
        cols = lines(size(perfilesY,2));
        for i=1:size(perfilesY,2)
            plot(axProf, rawData(:,2*i-1), perfilesSuavizados(:,i),'Color',cols(i,:));
        end
        hold(axProf,'off');
        title(axProf,'Profiles'); xlabel(axProf,'X'); ylabel(axProf,'Y');
    end

   function autocluster()
    step = str2double(tramoBox.String);
    perfilesSuavizados = applySmoothing(perfilesY);
    feats = calculateSlopes(perfilesSuavizados, step);
    resultados = feats;

    if chkForceK.Value
        bestK = str2double(clusterKBox.String);
    else
        bestK = 2:min(8, floor(size(feats, 1) / 2));
        bestK = bestK(1);  % Selecciona uno por simplicidad
    end

    Z = zscore(feats);
    bestLabels = kmeans(Z, bestK, 'Replicates', 5);
    bestFeats = feats;

    % 🪶 Reorden de ejes: Curves antes de Boxplot
    cla(axCurves); hold(axCurves, 'on');
    colsCurves = lines(bestK);
    for g = 1:bestK
        for i = find(bestLabels == g)'
            plot(axCurves, perfilesSuavizados(:, i), ...
                'Color', colsCurves(g,:), 'LineWidth', 0.8);
        end
    end
    hold(axCurves, 'off');
    title(axCurves, 'Curves by Group'); xlabel(axCurves, 'Point'); ylabel(axCurves, 'Value');

    % 📊 Nuevo boxplot por cluster y segmento
    cla(axBox); hold(axBox, 'on');
    colsBox = lines(bestK);
    posShift = linspace(-0.25, 0.25, bestK);  % Desplazamientos para cada grupo
    for g = 1:bestK
        idx = find(bestLabels == g);
        dataG = resultados(idx, :);  % Filas del grupo g
          % Calcular medianas o medias
         centralTendency = median(dataG, 1);  % Usa mean(dataG,1) si prefieres medias

        % Posiciones X ajustadas con desplazamiento
         xLine = (1:size(resultados, 2)) + posShift(g);

        % Dibujar línea
        plot(axBox, xLine, centralTendency, '-o', ...
        'Color', colsBox(g,:), ...
        'LineWidth', 1.5, ...
        'DisplayName', sprintf('Group %d', g));  % ← para leyenda

        for s = 1:size(dataG, 2)
            %xVals = repmat(s + posShift(g), size(dataG(:, s))); %Boxplots
            %separados
            xVals = repmat(s, size(dataG(:, s)));  % Todos los grupos en el mismo X

            boxchart(axBox, xVals, dataG(:, s), ...
         'BoxFaceColor', colsBox(g,:), ...
         'BoxFaceAlpha', 0.5, ...  % ← transparencia para solapamiento
         'BoxWidth', 0.2, ...
         'Tag', sprintf('Group%d', g));
        end
    end
    hold(axBox, 'off');
    title(axBox, 'Slopes by Segment and Cluster');
    xlabel(axBox, 'Segment'); ylabel(axBox, 'Slope');
end

       function yout = applySmoothing(yin)
        yout = yin;
        if ~chkSmooth.Value, return; end
        w = str2double(edtWindow.String);
        if w < 3, w = 3; end
        if mod(w,2) == 0, w = w + 1; end
        for c = 1:size(yin,2)
            if popMethod.Value == 1
                yout(:,c) = movmean(yin(:,c), w);
            else
                yout(:,c) = sgolayfilt(yin(:,c), 3, w);
            end
        end
    end
    function showGroupedCurves()
        if isempty(bestLabels), warndlg('No clustering results available'); return; end
        figGroups = figure('Name','Detailed Group View','Color','white','Units','normalized', ...
                       'Position',[0.1 0.1 0.8 0.8]);
        tlg = tiledlayout(figGroups,bestK,1,'TileSpacing','compact','Padding','compact');
        cols = lines(bestK);
        for g = 1:bestK
            ax = nexttile(tlg);
            hold(ax,'on');
            idx = find(bestLabels == g);save
            for i = idx
                plot(ax, perfilesSuavizados(:,i), 'Color',cols(g,:), 'LineWidth',1);
            end
            hold(ax,'off');
            title(ax, sprintf('Group %d - %d curves', g, numel(idx)));
            xlabel(ax, 'Point'); ylabel(ax, 'Value');
        end
    end

    function S = calculateSlopes(Y, step)
        nC = size(Y,2);
        nR = size(Y,1);
        nS = floor(nR / step);
        S = zeros(nC, nS);
        for c = 1:nC
            x = rawData(:,2*c - 1);
            for s = 1:nS
                i1 = (s - 1) * step + 1;
                i2 = i1 + step - 1;
                if i2 > length(x), i2 = length(x); end
                p = polyfit(x(i1:i2), Y(i1:i2, c), 1);
                S(c, s) = p(1);
            end
        end
    end

    function changeSheet(dir)
        newIdx = currSheet + dir;
        if newIdx >= 1 && newIdx <= numel(sheetList)
            currSheet = newIdx;
            loadCurrentSheet();
        end
    end

    function saveResults()
        if isempty(resultados)
            warndlg('Run Autocluster first.');
            return;
        end
        T = array2table(resultados, ...
            'VariableNames', compose('Seg%d', 1:size(resultados,2)));
        [fn, fp] = uiputfile('slopes.xlsx', 'Save Slopes');
        if fn == 0, return; end
        writetable(T, fullfile(fp, fn));
        msgbox('Slopes saved.', 'Done');
    end
function saveDeluxeModule()
    [baseFile, basePath] = uiputfile('ArcaneSaveDeluxe','Save Deluxe Package');
    if baseFile == 0, return; end
    root = fullfile(basePath, erase(baseFile,'.txt'));
    mkdir(root); mkdir(fullfile(root,'images')); mkdir(fullfile(root,'data')); mkdir(fullfile(root,'subplots'));

    % ✅ Guardar imágenes principales
    exportgraphics(axCurves, fullfile(root,'images','group_curves.png'));
    exportgraphics(axBox, fullfile(root,'images','boxplot_clusters.png'));

    if exist('axHeat','var') && isgraphics(axHeat)
        exportgraphics(axHeat, fullfile(root,'images','heatmap.png'));
    end
    if exist('axDend','var') && isgraphics(axDend)
        exportgraphics(axDend, fullfile(root,'images','dendrogram.png'));
    end

    % 📄 Guardar archivo resumen .txt
    fid = fopen(fullfile(root,'Arcane_Report.txt'),'w');
    fprintf(fid,'=== Arcane Save Deluxe Report ===\n');
    fprintf(fid,'Date: %s\n\n', datestr(now));
    fprintf(fid,'Smoothing: %s (%s)\n', popMethod.String{popMethod.Value}, edtWindow.String);
    fprintf(fid,'Segment length: %s\n', tramoBox.String);
    fprintf(fid,'Forced Clusters: %s (%s)\n\n', bool2str(chkForceK.Value), clusterKBox.String);
    fprintf(fid,'Main Clustering Result:\n');
    fprintf(fid,'  Groups: %d\n', bestK);
    for g = 1:bestK
        fprintf(fid,'    Group %d: %d profiles\n', g, sum(bestLabels==g));
    end
    fclose(fid);

    % 📊 Guardar datos
    writematrix(resultados, fullfile(root,'data','slopes.csv'));
    save(fullfile(root,'data','slopes.mat'),'resultados');
    save(fullfile(root,'data','group_labels.mat'),'bestLabels');
    save(fullfile(root,'data','raw_profiles.mat'),'perfilesY','perfilesSuavizados');

    % 🔍 Exportar subplots si deseas
    choice = questdlg('¿Quieres guardar subplots de todos los métodos?', ...
                      'Guardar Subplots','Sí','No','Sí');
    if strcmp(choice,'Sí')
        methods = {'Silhouette','CalinskiHarabasz','DaviesBouldin','Gap'};
        for m = 1:4
           figTemp = figure('Visible','off');
            ax = axes(figTemp);
            setappdata(figTemp,'DC_HeatAx', ax);
            runSingleClustering(m, {'Silhouette','CH','DB','Gap'}, figTemp);

            exportgraphics(ax, fullfile(root,'subplots',sprintf('%s.png',methods{m})));
            close(figTemp);
        end
    end
    if chkSession.Value
    save(fullfile(root, 'ArcaneSession.mat'), ...
        'bestLabels','resultados','perfilesY','perfilesSuavizados', ...
        'tramoBox','edtWindow','popMethod','clusterKBox','chkForceK');
    end
    msgbox('Save Deluxe completado 🎉','Listo');
end

function s = bool2str(v)
    s = 'No'; if v, s = 'Sí'; end
end
%% —––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––—
%% 1) Botón “Deep Clustering” en el panel principal (pnlC)
monkIcon = imread('assets\monk_title.png');  % Asegúrate de guardar la imagen con este nombre
uicontrol(pnlC, ...
    'Style','pushbutton', ...
    'Units','normalized', ...
    'Position',[0.02 0.02 0.28 0.08], ...
    'CData', monkIcon, ...
    'TooltipString','Deep Clustering', ...
    'Callback', @(~,~) showDeepClusteringUI());

%% —––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––—
%% 2) Interfaz de Deep Clustering
    function showDeepClusteringUI()
    f = figure('Name','Deep Clustering','NumberTitle','off', ...
               'Units','normalized','Position',[0.15 0.15 0.7 0.7], ...
               'Color','white');

    % 🔧 Panel lateral
    p = uipanel(f,'Units','normalized','Position',[0 0 0.35 1],'BackgroundColor','white');
  % ——————————————————————————
    % Número de Clusters (K) manual
    % — Número de Clusters para Single Method —
uicontrol(p,'Style','text','Units','normalized', ...
    'Position',[0.05 0.72 0.9 0.03], ...
    'String','Clusters K','FontWeight','bold');
editKsingle = uicontrol(p,'Style','edit','Units','normalized', ...
    'Position',[0.05 0.68 0.9 0.05], 'String','3', ...
    'TooltipString','Número de clusters para Single Method');

    % Método individual
    uicontrol(p,'Style','text','Units','normalized','Position',[0.05 0.90 0.9 0.05], ...
        'String','Single Method','FontWeight','bold');
    dd = uicontrol(p,'Style','popupmenu','Units','normalized','Position',[0.05 0.85 0.9 0.06], ...
        'String',{'Silhouette','Calinski-Harabasz','Davies-Bouldin','Gap Statistic'});
    uicontrol(p,'Style','pushbutton','Units','normalized','Position',[0.05 0.60 0.9 0.06], ...
        'String','Run Single', ...
        'Callback', @(~,~) runSingleClustering(dd.Value, dd.String, f, editKsingle))

    % MultiClustering
    uicontrol(p,'Style','text','Units','normalized','Position',[0.05 0.65 0.9 0.05], ...
        'String','MultiClustering','FontWeight','bold');
    lb = uicontrol(p,'Style','listbox','Units','normalized','Position',[0.05 0.35 0.9 0.30], ...
        'String',{'Silhouette','Calinski-Harabasz','Davies-Bouldin','Gap Statistic'}, ...
        'Max',4,'Min',1);
    uicontrol(p,'Style','pushbutton','Units','normalized','Position',[0.05 0.25 0.9 0.06], ...
        'String','Run Multi','Callback',@(~,~) runMultiClustering(lb.Value, f));

    % Configuración Score vs K
    uicontrol(p,'Style','text','Units','normalized', ...
        'Position',[0.05 0.22 0.9 0.03], 'String','Values of K','FontWeight','bold');
    lbK = uicontrol(p,'Style','listbox','Units','normalized', ...
        'Position',[0.05 0.05 0.4 0.17], ...
        'String', arrayfun(@num2str,2:10,'UniformOutput',false), ...
        'Max',9,'Min',1, 'Value',2:5);

    uicontrol(p,'Style','text','Units','normalized', ...
        'Position',[0.48 0.15 0.4 0.03], 'String','Replicates','FontWeight','bold');
    editRep = uicontrol(p,'Style','edit','Units','normalized', ...
        'Position',[0.48 0.10 0.2 0.04], 'String','10');
    uicontrol(p,'Style','text','Units','normalized', ...
        'Position',[0.70 0.10 0.2 0.04], 'String','Max 1000');

    uicontrol(p,'Style','pushbutton','Units','normalized', ...
        'Position',[0.48 0.02 0.4 0.06], ...
        'String','Recalculate Score', ...
        'Callback', @(~,~) runScoreAnalysis(f, dd.Value, lbK, editRep));

    % 🔍 Ejes gráficos
    axHeat = axes('Parent',f,'Units','normalized','Position',[0.40 0.55 0.58 0.40]);
    axDend = axes('Parent',f,'Units','normalized','Position',[0.40 0.05 0.58 0.40]);
    axScore = axes('Parent',f,'Units','normalized','Position',[0.40 0.30 0.58 0.20]);

    styleAxis(axHeat); styleAxis(axDend); styleAxis(axScore);

    setappdata(f,'DC_HeatAx', axHeat);
    setappdata(f,'DC_DendAx', axDend);
    setappdata(f,'DC_ScoreAx', axScore);
end

function styleAxis(ax)
    set(ax, 'Box', 'on', 'FontSize', 11, 'LineWidth', 1);
end 
%% —––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––—
%% 3) Función Single Clustering
function runSingleClustering(methodIdx, methodNames, figH, editKsingle)
  
    ax = getappdata(figH,'DC_HeatAx');
    cla(ax); hold(ax,'on');
      % Lee K manual
    K = max(2, round(str2double(editKsingle.String)));  % K mínimo = 2
    % Prepara datos
    if isnan(K) || K < 2
    warndlg('Introduce un número válido de clusters (mínimo 2).');
    return;
    end
    step = str2double(tramoBox.String);
    feats = calculateSlopes(applySmoothing(perfilesY), step);
    Z = zscore(feats);
    labels = kmeans(Z, K, 'Replicates', 5);
   
%    %switch methodIdx
 %     %case 1
  %    %  labels = kmeans(Z,K,'Replicates',5);
   %   case 2
    %    eva = evalclusters(Z,'kmeans','CalinskiHarabasz','KList',K);
     %   labels = kmeans(Z,eva.OptimalK,'Replicates',5);
      %case 3
      %  eva = evalclusters(Z,'kmeans','DaviesBouldin','KList',K);
     % labels = kmeans(Z,eva.OptimalK,'Replicates',5);
    %case 4
   %    eva = evalclusters(Z,'kmeans','gap','KList',2:10);
  %    labels = kmeans(Z,eva.OptimalK,'Replicates',5);
%    end
%    cols = lines(max(labels));
 %   for g = 1:max(labels)
  %      for i = find(labels==g)'
   %         plot(ax, perfilesSuavizados(:,i), 'Color', cols(g,:), 'LineWidth',1.2);
   %     end
  %  end
 %   hold(ax,'off');
%     title(ax, sprintf('DeepClust: %s (K=%d)', methodNames{methodIdx},
%     max(labels)));
%    xlabel(ax,'Point'); ylabel(ax,'Value');

    cols = lines(K);
    for g = 1:K
        for i = find(labels==g)'
            plot(ax, perfilesSuavizados(:,i), ...
                 'Color', cols(g,:), 'LineWidth',1.2);
        end
    end
    hold(ax,'off');

    title(ax, sprintf('DeepClust: %s (K=%d)', ...
          methodNames{methodIdx}, K));
    xlabel(ax,'Point'); ylabel(ax,'Value');
end

%% —––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––—%% —––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––—
%% 5) Helper para obtener labels por método
function labels = getLabelsByMethod(mIdx, Z, K)
    reps = 10;  % ← puedes leer esto del campo de la interfaz si lo haces global
    switch mIdx
      case 1, labels = kmeans(Z,K,'Replicates',reps);
      case 2
        eva = evalclusters(Z,'kmeans','CalinskiHarabasz','KList',K);
        labels = kmeans(Z,eva.OptimalK,'Replicates',5);
      case 3
        eva = evalclusters(Z,'kmeans','DaviesBouldin','KList',K);
        labels = kmeans(Z,eva.OptimalK,'Replicates',5);
      case 4
        eva = evalclusters(Z,'kmeans','gap','KList',2:10);
        labels = kmeans(Z,eva.OptimalK,'Replicates',5);
    end
end
    function adjustLayout(lay, figH)
        pos = figH.Position;
        r = pos(3) / pos(4);
        if r < 1.2
            lay.TileSpacing = 'none';
            lay.Padding = 'none';
        else
            lay.TileSpacing = 'compact';
            lay.Padding = 'compact';
        end
    end
function runScoreAnalysis(figH, methodIdx, lbK, editRep)
    % Recuperar ejes
    ax = getappdata(figH,'DC_ScoreAx');
    cla(ax); hold(ax,'on');

    % Parámetros
    KList   = str2double(lbK.String(lbK.Value));
    reps    = min(1000, max(1, round(str2double(editRep.String))));
    feats   = calculateSlopes(applySmoothing(perfilesY), str2double(tramoBox.String));
    Z       = zscore(feats);

    % KMeans options con réplicas
   opts = statset('MaxIter',300);  % correcto
    % Calcular Score para cada K
    scores = zeros(numel(KList),1);
    switch methodIdx
      case 1  % Silhouette (media del silhouette individual)
        for i=1:numel(KList)
            labels = kmeans(Z, KList(i), 'Replicates', reps, 'Options', opts);
            s = silhouette(Z, labels);
            scores(i) = mean(s);
        end

      case 2  % Calinski-Harabasz
        eva = evalclusters(Z,'kmeans','CalinskiHarabasz','KList',KList, ...
                            'Options',opts);
        scores = eva.CriterionValues;

      case 3  % Davies-Bouldin
        eva = evalclusters(Z,'kmeans','DaviesBouldin','KList',KList, ...
                            'Options',opts);
        scores = eva.CriterionValues;
      case 4  % Gap Statistic
        eva = evalclusters(Z,'kmeans','gap','KList',KList, ...
                            'Options',opts, 'B', reps);
        scores = eva.CriterionValues;
    end

    % Dibujar curva
    plot(ax, KList, scores, '-o', 'LineWidth', 1.5);
    grid(ax,'on');
    xlabel(ax, 'K'); ylabel(ax, 'Score');
    methods = {'Silhouette','Calinski-Harabasz','Davies-Bouldin','Gap'}; 
    title(ax, sprintf('%s Score vs K (Replicates = %d)', methods{methodIdx}, reps));
    hold(ax,'off');
    end
 %% — Función de bienvenida —
    function showIntroScreen_Step0(imagePath)
        fig0 = figure('Name','Welcome','NumberTitle','off', ...
            'MenuBar','none','ToolBar','none','Resize','off', ...
            'Units','normalized','Position',[0.1 0.05 0.75 0.88], ...
            'Color','black');
        img = imread(imagePath);
        ax0 = axes(fig0,'Position',[0 0 1 1]);
        imshow(img,'Parent',ax0); axis off;
        pause(2); close(fig0);
    end
end
