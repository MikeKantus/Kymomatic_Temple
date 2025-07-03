function KymomaticScybil
    % KymomaticScybil: Sequential application for slope change analysis
    % Step 1: Savitzky–Golay Configuration
    % Step 2: Slope Detection Study
    % Step 3: Visualization of detected points and slope changes

    step1();
end

function step1()
    % STEP 1: Configure Savitzky–Golay filter parameters
    hFig1 = figure( ...
        'Name','Step 1: Savitzky–Golay Configuration', ...
        'NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Position',[100 100 500 400] ...
    );

    % Select data file
    [fileName, filePath] = uigetfile('*.csv', 'Select data file');
    if isequal(fileName,0)
        close(hFig1);
        return;
    end
    fullpath = fullfile(filePath, fileName);
    data = readmatrix(fullpath);
    [numRows, numCols] = size(data);

    if mod(numCols,2) ~= 0
        error('File must contain pairs of columns (Time, Height).');
    end
    numProfiles = numCols/2;

    % Slider: window length
    uicontrol('Parent',hFig1,'Style','text', ...
        'String','Number of SG points:','Units','normalized', ...
        'Position',[0.1 0.85 0.8 0.1],'FontSize',10);
    hSliderWindow = uicontrol('Parent',hFig1,'Style','slider', ...
        'Min',5,'Max',21,'Value',11,'SliderStep',[1/16,1/16], ...
        'Units','normalized','Position',[0.1 0.75 0.8 0.1]);
    hWindowVal = uicontrol('Parent',hFig1,'Style','text', ...
        'String','11','Units','normalized', ...
        'Position',[0.45 0.70 0.1 0.05],'FontSize',10);
    hSliderWindow.Callback = @(src,~) set(hWindowVal,'String',num2str(round(src.Value)));

    % Axes for profile preview
    hAxesProfile = axes('Parent',hFig1,'Position',[0.1 0.4 0.8 0.25]);
    title(hAxesProfile,'Random Profile (original & smoothed)');

    % Buttons: Refresh and Next
    uicontrol('Parent',hFig1,'Style','pushbutton','String','Refresh', ...
        'Units','normalized','Position',[0.1 0.3 0.35 0.08], ...
        'Callback',@refreshProfile);
    uicontrol('Parent',hFig1,'Style','pushbutton','String','Next', ...
        'Units','normalized','Position',[0.55 0.3 0.35 0.08], ...
        'Callback',@nextStep1);

    % Initial plot
    refreshProfile();

    function refreshProfile(~,~)
        windowLen = round(hSliderWindow.Value);
        if mod(windowLen,2) == 0
            windowLen = windowLen + 1;
        end
        polyOrder = 3;
        idx = randi(numProfiles);
        t = data(:,2*idx-1);
        y = data(:,2*idx);
        ySmooth = sgolayfilt(y, polyOrder, windowLen);

        axes(hAxesProfile); cla;
        plot(t, y, 'Color',[.6 .6 .6]); hold on;
        plot(t, ySmooth, 'b', 'LineWidth',1.5);
        title(sprintf('Profile %d – Window = %d', idx, windowLen));
        xlabel('Time'); ylabel('Height');
        legend('Original','Smoothed');
        hold off;
    end

    function nextStep1(~,~)
        windowLen = round(hSliderWindow.Value);
        if mod(windowLen,2) == 0
            windowLen = windowLen + 1;
        end
        polyOrder = 3;
        smoothedData = zeros(size(data));
        derivatives  = zeros(numRows-1, numProfiles);

        for k = 1:numProfiles
            t = data(:,2*k-1);
            y = data(:,2*k);
            ySmooth = sgolayfilt(y, polyOrder, windowLen);
            smoothedData(:,2*k-1) = t;
            smoothedData(:,2*k)   = ySmooth;
            derivatives(:,k) = diff(ySmooth)./diff(t);
        end

        close(hFig1);
        step2(data, smoothedData, derivatives);
    end
end

function step2(data, smoothedData, derivatives)
    % STEP 2: Slope detection
    hFig2 = figure( ...
        'Name','Step 2: Slope Detection Study', ...
        'NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Position',[100 100 800 600] ...
    );

    % Axes for profiles and detection
    hAxesAll = axes('Parent',hFig2,'Position',[0.05 0.35 0.45 0.6]);
    hAxesDet = axes('Parent',hFig2,'Position',[0.55 0.35 0.4 0.6]);

    % Sliders: sensitivity, threshold, start index
    uicontrol('Parent',hFig2,'Style','text','String','Sensitivity', ...
        'Units','normalized','Position',[0.05 0.28 0.15 0.05]);
    hSens = uicontrol('Parent',hFig2,'Style','slider', ...
        'Min',0.5,'Max',3,'Value',1.5,'Units','normalized', ...
        'Position',[0.05 0.23 0.15 0.05]);

    uicontrol('Parent',hFig2,'Style','text','String','Min Threshold', ...
        'Units','normalized','Position',[0.22 0.28 0.15 0.05]);
    hMinThr = uicontrol('Parent',hFig2,'Style','slider', ...
        'Min',0,'Max',0.05,'Value',0.01,'Units','normalized', ...
        'Position',[0.22 0.23 0.15 0.05]);

    uicontrol('Parent',hFig2,'Style','text','String','Start (%)', ...
        'Units','normalized','Position',[0.39 0.28 0.15 0.05]);
    hStart = uicontrol('Parent',hFig2,'Style','slider', ...
        'Min',0,'Max',1,'Value',0,'Units','normalized', ...
        'Position',[0.39 0.23 0.15 0.05]);

    % Popup: detection method
    methods = {'First Derivative','Second Derivative', ...
               'Wavelet Transform','Clustering', ...
               'Kalman Filter','Spline Regression'};
    uicontrol('Parent',hFig2,'Style','text','String','Method', ...
        'Units','normalized','Position',[0.05 0.15 0.2 0.05]);
    hMethod = uicontrol('Parent',hFig2,'Style','popupmenu', ...
        'String',methods,'Units','normalized', ...
        'Position',[0.05 0.1 0.25 0.05], ...
        'Callback',@refreshAll);

    % Buttons
    uicontrol('Parent',hFig2,'Style','pushbutton','String','Refresh Detection', ...
        'Units','normalized','Position',[0.32 0.1 0.15 0.05], ...
        'Callback',@refreshDet);
    uicontrol('Parent',hFig2,'Style','pushbutton','String','Update Profiles', ...
        'Units','normalized','Position',[0.05 0.01 0.15 0.05], ...
        'Callback',@refreshAll);
    uicontrol('Parent',hFig2,'Style','pushbutton','String','Next', ...
        'Units','normalized','Position',[0.55 0.1 0.15 0.05], ...
        'Callback',@gotoStep3);

    % Initial draw
    refreshAll();
    refreshDet();

    function refreshAll(~,~)
        updateGraph(hAxesAll, hSens, hMinThr, hStart, data, smoothedData, derivatives);
    end

    function refreshDet(~,~)
        t = data(:,1);
        y = data(:,2);
        params.sensitivity      = hSens.Value;
        params.min_threshold    = hMinThr.Value;
        params.start_index      = round(hStart.Value*size(derivatives,1)) + 1;
        methodName = methods{hMethod.Value};

        idx = detectModel(methodName, y, derivatives(:,1), params);

        axes(hAxesDet); cla;
        plot(t, y, 'b'); hold on;
        scatter(t(idx), y(idx), 25, 'r','filled');
        title(['Detection: ' methodName]);
        xlabel('Time'); ylabel('Height');
        hold off;
    end

    function gotoStep3(~,~)
        params.sensitivity   = hSens.Value;
        params.min_threshold = hMinThr.Value;
        params.start_index   = round(hStart.Value*size(derivatives,1)) + 1;
        methodName = methods{hMethod.Value};

        close(hFig2);
        step3(data, derivatives, methodName, params);
    end
end

function step3(data, derivatives, methodName, params)
    % STEP 3: Analysis summary and results export
    hFig3 = figure( ...
        'Name','Step 3: Analysis Summary', ...
        'NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Position',[100 100 900 600] ...
    );

    numProfiles = size(data,2)/2;
    allDetects = cell(numProfiles,1);
    changes    = cell(numProfiles,1);
    maxSegs    = 0;

    % Collect detections and compute slope changes
    for i = 1:numProfiles
        t = data(:,2*i-1);
        y = data(:,2*i);
        idx = detectModel(methodName, y, derivatives(:,i), params);
        if isempty(idx)
            idx = [1; length(t)];
        end
        allDetects{i} = idx;

        % Compute segment slopes
        pts = [1; idx; length(t)];
        segSlopes = zeros(length(pts)-1,1);
        for j = 1:length(pts)-1
            x0 = t(pts(j)); y0 = y(pts(j));
            x1 = t(pts(j+1)); y1 = y(pts(j+1));
            if pts(j) == pts(j+1)
                s = 0;
            else
                p = polyfit([x0; x1],[y0; y1],1);
                s = p(1);
            end
            segSlopes(j) = s;
        end

        diffs = diff(segSlopes);
        changes{i} = abs(diffs);
        maxSegs = max(maxSegs, length(diffs));
    end

    % Plot detected points per profile
    hAx1 = axes('Parent',hFig3,'Position',[0.05 0.55 0.9 0.4]);
    hold(hAx1,'on');
    for i = 1:numProfiles
        t = data(:,2*i-1);
        y = data(:,2*i);
        idx = allDetects{i};
        plot(hAx1, t(idx), y(idx), '-o','LineWidth',1.5);
    end
    hold(hAx1,'off');
    title(hAx1,'Detected Points by Profile');
    xlabel(hAx1,'Time'); ylabel(hAx1,'Height');

    % Prepare data for boxplot
    dataBox = NaN(numProfiles, maxSegs);
    for i = 1:numProfiles
        v = changes{i};
        dataBox(i,1:length(v)) = v;
    end

    % Boxplot of slope changes
    hAx2 = axes('Parent',hFig3,'Position',[0.05 0.05 0.9 0.4]);
    boxplot(dataBox, 'Labels', arrayfun(@num2str,1:maxSegs,'UniformOutput',false));
    title(hAx2,'Slope Change between Segments');
    xlabel(hAx2,'Segment'); ylabel(hAx2,'|Δ Slope|');

    % Save results button
    uicontrol('Parent',hFig3,'Style','pushbutton','String','Save Results', ...
        'Units','normalized','Position',[0.45 0.01 0.1 0.05], ...
        'Callback',@saveResults);

    function saveResults(~,~)
        [fileName, pathName] = uiputfile('*.xlsx','Save results as');
        if isequal(fileName,0)
            return;
        end
        fname = fullfile(pathName, fileName);
        % Sheet 1: Detected indices
        maxPts = max(cellfun(@length, allDetects));
        matPts = NaN(maxPts, numProfiles);
        for k = 1:numProfiles
            matPts(1:length(allDetects{k}), k) = allDetects{k};
        end
        writematrix(matPts, fname, 'Sheet','DetectedPoints');

        % Sheet 2: Slope change data
        writematrix(dataBox, fname, 'Sheet','SlopeChanges');
        msgbox('Save successful','Success');
    end
end

function updateGraph(hAxes, hSens, hMinThr, hStart, data, smoothedData, derivatives)
    % Refresh profile plots with base detection overlay
    umbral = hSens.Value * std(derivatives(:));
    minThr = hMinThr.Value;
    startIdx = round(hStart.Value * size(derivatives,1));
    startIdx = max(1, min(startIdx, size(derivatives,1)-1));
    C = abs(derivatives(startIdx:end,:)) > umbral & abs(derivatives(startIdx:end,:)) > minThr;
    [r,c] = find(C);
    r = r + startIdx - 1;

    axes(hAxes); cla; hold on;
    numProfiles = size(derivatives,2);
    for k = 1:numProfiles
        t = data(:,2*k-1);
        yS = smoothedData(:,2*k);
        plot(t, yS, 'b');
       
