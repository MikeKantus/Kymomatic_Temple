function GayaDescriptorum()
    %% Bienvenida
    % Pantalla de bienvenida con imagen y cita
    showIntroScreen_Step0('assets/Gaya_1.png');

    % Lanzar la pantalla de análisis AFM después de la bienvenida
    afmGUI();

    % --- Welcome Screen Function ---
    function showIntroScreen_Step0(imagePath, titleText, subtitle)
        fig = figure('Name','Welcome','NumberTitle','off','MenuBar','none', ...
            'ToolBar','none','Resize','off','Units','normalized','Position',[0.1 0.05 0.75 0.88], ...
            'Color','black');

        img = imread(imagePath);
        ax = axes('Parent',fig, 'Position',[0 0 1 1]);
        imshow(img, 'Parent', ax);
        axis off;

        % Cita
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

        % Seleccionar una cita aleatoria
        idx = randi(numel(quotes));
        selectedQuote = quotes{idx};
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

        % Mostrar cita con transparencia real usando text()
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

    %% Force script
    function afmGUI()
        % Crear ventana
        fig = uifigure('Name', 'Gaya Descriptorum', 'Position', [100 100 800 600]);

        % Botón para cargar archivo
        btnLoad = uibutton(fig, 'push', 'Text', 'Cargar Archivo',...
            'Position', [20 540 120 30],...
            'ButtonPushedFcn', @(btn,event) cargarArchivo());

        % Campos para metadatos
        lblK = uilabel(fig, 'Text', 'Spring constant (N/m):', 'Position', [20 500 150 22]);
        kField = uieditfield(fig, 'numeric', 'Position', [170 500 100 22]);

        lblSens = uilabel(fig, 'Text', 'Sensitivity (nm/V):', 'Position', [20 470 150 22]);
        sensField = uieditfield(fig, 'numeric', 'Position', [170 470 100 22]);

        lblTip = uilabel(fig, 'Text', 'Tip radius (nm):', 'Position', [20 440 150 22]);
        tipField = uieditfield(fig, 'numeric', 'Position', [170 440 100 22]);

        % Ejes para gráfica
        ax = uiaxes(fig, 'Position', [300 200 470 350]);
        ax.Title.String = 'Fuerza vs Separación';

        % Botones de análisis
        btnCP = uibutton(fig, 'push', 'Text', 'Detectar Contact Point',...
            'Position', [20 380 150 30],...
            'ButtonPushedFcn', @(btn,event) detectarCP());

        btnPend = uibutton(fig, 'push', 'Text', 'Detectar Pendiente',...
            'Position', [20 340 150 30],...
            'ButtonPushedFcn', @(btn,event) detectarPendiente());

        % --- Internal Functions ---
        function cargarArchivo()
            [file, path] = uigetfile({'*.txt;*.csv','Datos AFM'}, 'Selecciona archivo de curva');
            if isequal(file,0), return; end
            fullpath = fullfile(path, file);
            data = readmatrix(fullpath);  % adaptarlo al formato real
            z = data(:,1); deflection = data(:,2);

            % Auto detectar metadatos si vienen incluidos
            % Aquí deberías implementar un parser que busque encabezados o tags

            % Graficar datos
            k = kField.Value; % Para usar en análisis
            force = k * deflection;
            separation = -(deflection + z);
            plot(ax, separation, force, 'b'); xlabel(ax, 'Separación (nm)'); ylabel(ax, 'Fuerza (nN)');
        end

        function detectarCP()
            % Aquí va la lógica de detección del punto de contacto
            % Ejemplo:
            % [contact_point, modulus, R2] = analyzeAFMcurve(z, deflection, k, alpha, fit_range_nm)
            % Implementa la función analyzeAFMcurve según tus necesidades
        end

        function detectarPendiente()
            % 🧠 Determinar región de ajuste
            % fit_start = CP_idx;
            % fit_end = min(length(separation), fit_start + round(fit_range_nm));
            % s_fit = separation(fit_start:fit_end);
            % f_fit = force(fit_start:fit_end);

            % 📐 Ajuste no lineal al modelo de Hertz modificado
            % hertzModel = @(params, s) ...
            %     (2 / pi) * tan(alpha) * params(1) ./ (1 - 0.5^2) .* (s - params(2)).^2;

            % Estimación inicial: [modulus, contact_point]
            % params0 = [1e4, separation(CP_idx)];

            % options = optimoptions('lsqcurvefit','Display','off');
            % [params,resnorm,~,~,~,~,J] = lsqcurvefit(hertzModel, params0, s_fit, f_fit, [], [], options);

            % contact_point = params(2); % nm
            % modulus = params(1);       % Pa

            % 📊 Cálculo de R²
            % SS_res = resnorm;
            % SS_tot = sum((f_fit - mean(f_fit)).^2);
            % R2 = 1 - SS_res / SS_tot;
        end
    end
end