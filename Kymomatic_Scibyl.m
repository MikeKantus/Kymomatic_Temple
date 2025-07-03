function KymomaticWizard()
    % KymomaticWizard: Aplicación secuencial para el análisis de cambios en la pendiente.
    % Paso 1: Configuración de Savitzky–Golay
    % Paso 2: Estudio de detección de la pendiente
    % Paso 3: Visualización de puntos detectados y cambios de pendiente

    step1();
end

function step1()
    hFig1 = figure(...
        'Name','Paso 1: Configuración de Savitzky–Golay', ...
        'NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Position',[100 100 500 400]);

    % Selección de archivo
    [archivo, ruta] = uigetfile('*.csv', 'Selecciona el archivo de datos');
    if archivo == 0
        close(hFig1);
        return;
    end
    fullpath = fullfile(ruta, archivo);
    datos = readmatrix(fullpath);
    [num_filas, num_columnas] = size(datos);
    if mod(num_columnas,2)~=0
        error('El archivo debe contener pares de columnas (Tiempo, Altura).');
    end
    num_perfiles = num_columnas/2;

    % Slider ventana SG
    uicontrol('Parent',hFig1,'Style','text', ...
        'String','Nº puntos Savitzky–Golay:','Units','normalized', ...
        'Position',[0.1 0.85 0.8 0.1],'FontSize',10);
    hSliderWindow = uicontrol('Parent',hFig1,'Style','slider', ...
        'Min',5,'Max',21,'Value',11,'SliderStep',[1/16,1/16], ...
        'Units','normalized','Position',[0.1 0.75 0.8 0.1]);
    hWindowVal = uicontrol('Parent',hFig1,'Style','text', ...
        'String','11','Units','normalized','Position',[0.45 0.70 0.1 0.05],'FontSize',10);
    hSliderWindow.Callback = @(src,~) set(hWindowVal,'String',num2str(round(src.Value)));

    % Eje perfil aleatorio
    hAxesProfile = axes('Parent',hFig1,'Position',[0.1 0.4 0.8 0.25]);
    title(hAxesProfile,'Perfil Aleatorio (original y suavizado)');

    % Botones Refresh y Next
    uicontrol('Parent',hFig1,'Style','pushbutton','String','Refresh', ...
        'Units','normalized','Position',[0.1 0.3 0.35 0.08], ...
        'Callback',@refreshProfile);
    uicontrol('Parent',hFig1,'Style','pushbutton','String','Next', ...
        'Units','normalized','Position',[0.55 0.3 0.35 0.08], ...
        'Callback',@nextStep1);

    % Primer dibujo
    refreshProfile();

    function refreshProfile(~,~)
        ventana = round(hSliderWindow.Value);
        if mod(ventana,2)==0, ventana=ventana+1; end
        orden_pol = 3;
        idx = randi(num_perfiles);
        t = datos(:,2*idx-1);
        y = datos(:,2*idx);
        yS = sgolayfilt(y,orden_pol,ventana);
        axes(hAxesProfile);
        cla;
        plot(t,y,'Color',[.6 .6 .6]); hold on;
        plot(t,yS,'b','LineWidth',1.5);
        title(sprintf('Perfil %d – Ventana = %d', idx,ventana));
        xlabel('Tiempo'); ylabel('Altura');
        legend('Original','Suavizado');
        hold off;
    end

    function nextStep1(~,~)
        ventana = round(hSliderWindow.Value);
        if mod(ventana,2)==0, ventana=ventana+1; end
        orden_pol = 3;
        datos_suav = zeros(size(datos));
        deriv = zeros(num_filas-1,num_perfiles);
        for k=1:num_perfiles
            t = datos(:,2*k-1);
            y = datos(:,2*k);
            yS = sgolayfilt(y,orden_pol,ventana);
            datos_suav(:,2*k) = yS;
            datos_suav(:,2*k-1) = t;
            deriv(:,k) = diff(yS)./diff(t);
        end
        close(hFig1);
        step2(datos,datos_suav,deriv);
    end
end

function step2(datos,datos_suav,deriv)
    hFig2 = figure(...
        'Name','Paso 2: Detección de pendiente','NumberTitle','off', ...
        'MenuBar','none','ToolBar','none','Position',[100 100 800 600]);

    % Ejes
    hAxesAll = axes('Parent',hFig2,'Position',[0.05 0.35 0.45 0.6]);
    hAxesDet = axes('Parent',hFig2,'Position',[0.55 0.35 0.4 0.6]);

    % Sliders
    uicontrol('Parent',hFig2,'Style','text','String','Sensibilidad', ...
        'Units','normalized','Position',[0.05 0.28 0.15 0.05]);
    hSens = uicontrol('Parent',hFig2,'Style','slider','Min',0.5,'Max',3,'Value',1.5, ...
        'Units','normalized','Position',[0.05 0.23 0.15 0.05]);
    uicontrol('Parent',hFig2,'Style','text','String','Umbral mínimo', ...
        'Units','normalized','Position',[0.22 0.28 0.15 0.05]);
    hUmbral = uicontrol('Parent',hFig2,'Style','slider','Min',0,'Max',0.05,'Value',0.01, ...
        'Units','normalized','Position',[0.22 0.23 0.15 0.05]);
    uicontrol('Parent',hFig2,'Style','text','String','Inicio (%)', ...
        'Units','normalized','Position',[0.39 0.28 0.15 0.05]);
    hRango = uicontrol('Parent',hFig2,'Style','slider','Min',0,'Max',1,'Value',0, ...
        'Units','normalized','Position',[0.39 0.23 0.15 0.05]);

    % Desplegable método
    models = {'First Derivative','Second Derivative', ...
        'Wavelet Transform','Clustering','Kalman Filter','Spline Regression'};
    uicontrol('Parent',hFig2,'Style','text','String','Método', ...
        'Units','normalized','Position',[0.05 0.15 0.2 0.05]);
    hMethod = uicontrol('Parent',hFig2,'Style','popupmenu','String',models, ...
        'Units','normalized','Position',[0.05 0.1 0.25 0.05], ...
        'Callback',@refreshAll);

    % Botones
    uicontrol('Parent',hFig2,'Style','pushbutton','String','Refresh Detección', ...
        'Units','normalized','Position',[0.32 0.1 0.15 0.05], ...
        'Callback',@refreshDet);
    uicontrol('Parent',hFig2,'Style','pushbutton','String','Actualizar Perfiles', ...
        'Units','normalized','Position',[0.05 0.01 0.15 0.05], ...
        'Callback',@refreshAll);
    uicontrol('Parent',hFig2,'Style','pushbutton','String','Next', ...
        'Units','normalized','Position',[0.55 0.1 0.15 0.05], ...
        'Callback',@gotoStep3);

    % Inicial
    refreshAll();
    refreshDet();

    function refreshAll(~,~)
        actualizarGrafico(hAxesAll,hSens,hUmbral,hRango,datos,datos_suav,deriv);
    end

    function refreshDet(~,~)
        t = datos(:,1);
        y = datos(:,2);
        params.sensitivity = hSens.Value;
        params.min_threshold = hUmbral.Value;
        params.start_index = round(hRango.Value*size(deriv,1))+1;
        m = models{hMethod.Value};
        idx = detectModel(m,y,deriv(:,1),params);
        axes(hAxesDet); cla;
        plot(t,y,'b'); hold on;
        scatter(t(idx),y(idx),25,'r','filled');
        title(['Detección: ' m]);
        xlabel('Tiempo'); ylabel('Altura');
        hold off;
    end

    function gotoStep3(~,~)
        params.sensitivity = hSens.Value;
        params.min_threshold = hUmbral.Value;
        params.start_index = round(hRango.Value*size(deriv,1))+1;
        m = models{hMethod.Value};
        close(hFig2);
        step3(datos,deriv,m,params);
    end
end

function step3(datos,deriv,method,params)
    hFig3 = figure(...
        'Name','Paso 3: Resumen del análisis','NumberTitle','off', ...
        'MenuBar','none','ToolBar','none','Position',[100 100 900 600]);

    num_perfiles = size(datos,2)/2;
    allDetects = cell(num_perfiles,1);
    % Recolectar detecciones
    for i=1:num_perfiles
        t = datos(:,2*i-1);
        y = datos(:,2*i);
        idx = detectModel(method,y,deriv(:,i),params);
        if isempty(idx)
            idx = [1; length(t)];
        end
        allDetects{i} = idx;
    end

    % Gráfico 1: puntos conectados
    hAx1 = axes('Parent',hFig3,'Position',[0.05 0.55 0.9 0.4]);
    hold(hAx1,'on');
    for i=1:num_perfiles
        t = datos(:,2*i-1);
        y = datos(:,2*i);
        idx = allDetects{i};
        plot(hAx1,t(idx),y(idx),'-o','LineWidth',1.5);
    end
    hold(hAx1,'off');
    title(hAx1,'Puntos detectados por perfil');
    xlabel(hAx1,'Tiempo'); ylabel(hAx1,'Altura');

    % Calcular cambios de pendiente
    changes = {};
    maxSegs = 0;
    for i=1:num_perfiles
        t = datos(:,2*i-1);
        y = datos(:,2*i);
        idx = allDetects{i};
        segments = cell(size(idx,1)+1,1);
        pts = [1; idx; length(t)];
        segSlopes = [];
        for j=1:length(pts)-1
            x0 = t(pts(j)); y0 = y(pts(j));
            x1 = t(pts(j+1)); y1 = y(pts(j+1));
            if pts(j)==pts(j+1)
                s = 0;
            else
                p = polyfit([x0;x1],[y0;y1],1);
                s = p(1);
            end
            segSlopes(end+1) = s;  %#ok<AGROW>
        end
        diffs = np.diff(segSlopes));
        changes{i} = diffs;
        maxSegs = max(maxSegs,length(diffs));
    end

    % Organizar datos para boxplot
    dataBox = NaN(num_perfiles,maxSegs);
    for i=1:num_perfiles
        v = changes{i};
        dataBox(i,1:length(v)) = v;
    end

    % Gráfico 2: boxplots por segmento
    hAx2 = axes('Parent',hFig3,'Position',[0.05 0.05 0.9 0.4]);
    boxplot(dataBox,'Labels',arrayfun(@num2str,1:maxSegs,'UniformOutput',false));
    title(hAx2,'Cambios de pendiente entre segmentos');
    xlabel(hAx2,'Segmento');
    ylabel(hAx2,'|Δ pendiente|');

    % Botón guardar resultados
    uicontrol('Parent',hFig3,'Style','pushbutton','String','Guardar Resultados', ...
        'Units','normalized','Position',[0.45 0.01 0.1 0.05], ...
        'Callback',@saveResults);

    function saveResults(~,~)
        [file,path] = uiputfile('*.xlsx','Guardar resultados');
        if isequal(file,0), return; end
        fname = fullfile(path,file);
        % Puntos detectados
        maxPts = max(cellfun(@length,allDetects));
        matPts = NaN(maxPts,num_perfiles);
        for k=1:num_perfiles
            matPts(1:length(allDetects{k}),k) = allDetects{k};
        end
        writematrix(matPts,fname,'Sheet','PuntosDetectados');
        % Cambios de pendiente
        writematrix(dataBox,fname,'Sheet','CambiosDePendiente');
        msgbox('Guardado exitoso','Éxito');
    end
end

function actualizarGrafico(hAxes, hSens, hUmbral, hRango, datos, datos_suav, deriv)
    umbral = hSens.Value * std(deriv(:));
    minThr = hUmbral.Value;
    ir = round(hRango.Value*size(deriv,1));
    ir = max(1, min(ir,size(deriv,1)-1));
    C = abs(deriv(ir:end,:))>umbral & abs(deriv(ir:end,:))>minThr;
    [r,c] = find(C);
    r = r+ir-1;
    axes(hAxes); cla; hold on;
    np = size(deriv,2);
    for k=1:np
        t = datos(:,2*k-1);
        yS = datos_suav(:,2*k);
        plot(t,yS,'b');
        scatter(t(r(c==k)),yS(r(c==k)),20,'r','filled');
    end
    hold(hAxes,'off');
    title(hAxes,'Perfiles y detección base');
    xlabel(hAxes,'Tiempo'); ylabel(hAxes,'Altura');
end

function indices = detectModel(modelName, profile, derivative, params)
    switch modelName
        case 'First Derivative'
            thr = params.sensitivity * std(derivative);
            idx = find(abs(derivative)>max(thr,params.min_threshold));
        case 'Second Derivative'
            sd = diff(derivative);
            thr = params.sensitivity * std(sd);
            idx = find(abs(sd)>max(thr,params.min_threshold)) + 1;
        case 'Wavelet Transform'
            [wt,~] = cwt(profile);
            sc = round(size(wt,1)/2);
            coeff = wt(sc,:);
            thr = params.sensitivity * std(coeff);
            idx = find(abs(coeff)>max(thr,params.min_threshold));
        case 'Clustering'
            D = abs(derivative);
            [cl,cents] = kmeans(D,2,'Replicates',5);
            tgt = find(cents==max(cents),1);
            idx = find(cl==tgt);
        case 'Kalman Filter'
            pred = movmean(profile,5);
            res  = abs(profile-pred);
            thr  = params.sensitivity * std(res);
            idx  = find(res>max(thr,params.min_threshold));
        case 'Spline Regression'
            pp  = spline((1:length(profile))',profile);
            est = ppval(pp,(1:length(profile))');
            res = abs(profile-est);
            thr = params.sensitivity * std(res);
            idx = find(res>max(thr,params.min_threshold));
        otherwise
            idx = [];
    end
    % filtra según el índice mínimo
    indices = idx(idx >= params.start_index);
end

end   % cierra KymomaticWizard (función principal)
