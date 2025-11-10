function CurrencyDetectorGUI()
%CurrencyDetectorGUI Comprehensive GUI for counterfeit currency detection
%
%   Shows ALL intermediate processing steps with visualizations
%   for ADSP project demonstration

    % Create main figure
    fig = uifigure('Name', 'Counterfeit Currency Detector - ADSP Project', ...
                   'Position', [50 50 1400 900], ...
                   'Color', [0.94 0.94 0.94]);

    % Global data storage
    global APP_DATA;
    APP_DATA = struct();
    APP_DATA.test_image_path = '';
    APP_DATA.vis_data = [];
    APP_DATA.verdict = '';
    APP_DATA.score = 0;

    % ====================================================================
    % TOP PANEL - Controls
    % ====================================================================
    topPanel = uipanel(fig, 'Position', [10 820 1380 70], ...
                       'Title', 'Controls', 'FontSize', 12, 'FontWeight', 'bold');

    % Upload button
    btnUpload = uibutton(topPanel, 'push', ...
                        'Text', 'Upload Test Image', ...
                        'Position', [20 10 150 40], ...
                        'FontSize', 12, ...
                        'ButtonPushedFcn', @(btn,event) uploadImage());

    % Detect button
    btnDetect = uibutton(topPanel, 'push', ...
                        'Text', 'RUN DETECTION', ...
                        'Position', [190 10 150 40], ...
                        'FontSize', 12, ...
                        'FontWeight', 'bold', ...
                        'BackgroundColor', [0.2 0.7 0.3], ...
                        'FontColor', 'white', ...
                        'ButtonPushedFcn', @(btn,event) runDetection());

    % Image path label
    lblImagePath = uilabel(topPanel, ...
                          'Position', [360 10 600 40], ...
                          'Text', 'No image loaded', ...
                          'FontSize', 11, ...
                          'FontColor', [0.5 0.5 0.5]);

    % Verdict label (big)
    lblVerdict = uilabel(topPanel, ...
                        'Position', [1000 5 350 50], ...
                        'Text', 'AWAITING INPUT', ...
                        'FontSize', 20, ...
                        'FontWeight', 'bold', ...
                        'FontColor', [0.3 0.3 0.3], ...
                        'HorizontalAlignment', 'center');

    % ====================================================================
    % MAIN TABBED PANEL
    % ====================================================================
    tabGroup = uitabgroup(fig, 'Position', [10 10 1380 800]);

    % Create tabs
    tab1 = uitab(tabGroup, 'Title', '1. PREPROCESSING');
    tab2 = uitab(tabGroup, 'Title', '2. CHANNEL A - Templates');
    tab3 = uitab(tabGroup, 'Title', '3. CHANNEL B - Color/Structure');
    tab4 = uitab(tabGroup, 'Title', '4. CHANNEL D - Texture');
    tab5 = uitab(tabGroup, 'Title', '5. FINAL RESULTS');

    % ====================================================================
    % TAB 1: PREPROCESSING
    % ====================================================================
    createPreprocessingTab(tab1);

    % ====================================================================
    % TAB 2: CHANNEL A
    % ====================================================================
    createChannelATab(tab2);

    % ====================================================================
    % TAB 3: CHANNEL B
    % ====================================================================
    createChannelBTab(tab3);

    % ====================================================================
    % TAB 4: CHANNEL D
    % ====================================================================
    createChannelDTab(tab4);

    % ====================================================================
    % TAB 5: FINAL RESULTS
    % ====================================================================
    createFinalResultsTab(tab5);

    % ====================================================================
    % NESTED FUNCTIONS
    % ====================================================================

    function uploadImage()
        [file, path] = uigetfile({'*.jpg;*.jpeg;*.png', 'Image Files'}, ...
                                  'Select Currency Image');
        if file ~= 0
            APP_DATA.test_image_path = fullfile(path, file);
            lblImagePath.Text = ['Loaded: ' file];
            lblImagePath.FontColor = [0 0.5 0];
            lblVerdict.Text = 'READY TO DETECT';
            lblVerdict.FontColor = [0 0 1];
        end
    end

    function runDetection()
        if isempty(APP_DATA.test_image_path)
            uialert(fig, 'Please upload an image first!', 'No Image');
            return;
        end

        % Show progress
        d = uiprogressdlg(fig, 'Title', 'Processing...', ...
                         'Message', 'Running detection pipeline...', ...
                         'Indeterminate', 'on');

        try
            % Run detection
            [verdict, score, vis_data] = detect_with_all_visualizations(APP_DATA.test_image_path);

            % Store results
            APP_DATA.verdict = verdict;
            APP_DATA.score = score;
            APP_DATA.vis_data = vis_data;

            % Update verdict display
            if strcmp(verdict, 'GENUINE')
                lblVerdict.Text = '✓ GENUINE';
                lblVerdict.FontColor = [0 0.6 0];
            elseif strcmp(verdict, 'COUNTERFEIT')
                lblVerdict.Text = '✗ COUNTERFEIT';
                lblVerdict.FontColor = [1 0 0];
            else
                lblVerdict.Text = '⚠ ERROR';
                lblVerdict.FontColor = [1 0.5 0];
            end

            % Update all tabs
            updateAllTabs();

            close(d);

            uialert(fig, sprintf('Detection complete!\nVerdict: %s\nScore: %.4f', ...
                    verdict, score), 'Success', 'Icon', 'success');

        catch ME
            close(d);
            uialert(fig, ['Error: ' ME.message], 'Detection Failed', 'Icon', 'error');
        end
    end

    function updateAllTabs()
        % This function updates all visualizations
        % Called after detection completes
        updatePreprocessingTab();
        updateChannelATab();
        updateChannelBTab();
        updateChannelDTab();
        updateFinalResultsTab();
    end

    % Tab creation and update functions defined below...
    % (These will display the visualizations)

end

% ========================================================================
% TAB CREATION FUNCTIONS
% ========================================================================

function createPreprocessingTab(parent)
    % Create axes for preprocessing visualizations
    % These will be populated when detection runs

    % Title
    uilabel(parent, 'Position', [20 720 1000 30], ...
           'Text', 'STEP-BY-STEP PREPROCESSING VISUALIZATION', ...
           'FontSize', 14, 'FontWeight', 'bold');

    % Create subplot areas
    axes1 = uiaxes(parent, 'Position', [20 480 280 220]);
    title(axes1, '1. Original Image');

    axes2 = uiaxes(parent, 'Position', [320 480 280 220]);
    title(axes2, '2. After Rotation');

    axes3 = uiaxes(parent, 'Position', [620 480 280 220]);
    title(axes3, '3. After Resizing');

    axes4 = uiaxes(parent, 'Position', [920 480 280 220]);
    title(axes4, '4. Grayscale');

    axes5 = uiaxes(parent, 'Position', [20 200 560 260]);
    title(axes5, '5. Feature Matching');

    axes6 = uiaxes(parent, 'Position', [600 200 560 260]);
    title(axes6, '6. Final Aligned Image');

    % Info panel
    infoPanelPrep = uipanel(parent, 'Position', [20 20 1200 160], ...
                           'Title', 'Processing Information');

    uilabel(infoPanelPrep, 'Position', [20 110 300 25], ...
           'Text', 'ORB Features Detected:', 'FontSize', 11, 'FontWeight', 'bold');
    lblFeatTest = uilabel(infoPanelPrep, 'Position', [200 110 200 25], ...
                         'Text', '-', 'FontSize', 11);

    uilabel(infoPanelPrep, 'Position', [20 80 300 25], ...
           'Text', 'Feature Matches Found:', 'FontSize', 11, 'FontWeight', 'bold');
    lblMatches = uilabel(infoPanelPrep, 'Position', [200 80 200 25], ...
                        'Text', '-', 'FontSize', 11);

    uilabel(infoPanelPrep, 'Position', [20 50 300 25], ...
           'Text', 'Homography Inliers:', 'FontSize', 11, 'FontWeight', 'bold');
    lblInliers = uilabel(infoPanelPrep, 'Position', [200 50 200 25], ...
                        'Text', '-', 'FontSize', 11);
end

function createChannelATab(parent)
    uilabel(parent, 'Position', [20 720 1000 30], ...
           'Text', 'CHANNEL A: TEMPLATE MATCHING with NCC', ...
           'FontSize', 14, 'FontWeight', 'bold');

    % Axes for visualizations
    axes1 = uiaxes(parent, 'Position', [20 480 280 220]);
    title(axes1, 'Illumination Normalized');

    axes2 = uiaxes(parent, 'Position', [320 480 280 220]);
    title(axes2, 'Histogram Equalized');

    axes3 = uiaxes(parent, 'Position', [620 480 280 220]);
    title(axes3, 'Template 1: Ashoka');

    axes4 = uiaxes(parent, 'Position', [920 480 280 220]);
    title(axes4, 'NCC Map 1');

    axes5 = uiaxes(parent, 'Position', [20 200 280 220]);
    title(axes5, 'Template 2: Devanagari');

    axes6 = uiaxes(parent, 'Position', [320 200 280 220]);
    title(axes6, 'NCC Map 2');

    axes7 = uiaxes(parent, 'Position', [620 200 280 220]);
    title(axes7, 'Template 3: RBI Seal');

    axes8 = uiaxes(parent, 'Position', [920 200 280 220]);
    title(axes8, 'NCC Map 3');

    % Results panel
    resultPanel = uipanel(parent, 'Position', [20 20 1200 160], ...
                         'Title', 'Template Matching Results');

    % Score display
    uilabel(resultPanel, 'Position', [20 100 200 25], ...
           'Text', 'Templates Detected:', 'FontSize', 12, 'FontWeight', 'bold');
    lblTemplates = uilabel(resultPanel, 'Position', [200 100 150 25], ...
                          'Text', '- / -', 'FontSize', 12);

    uilabel(resultPanel, 'Position', [20 60 200 25], ...
           'Text', 'Channel A Score:', 'FontSize', 12, 'FontWeight', 'bold');
    lblScoreA = uilabel(resultPanel, 'Position', [200 60 150 25], ...
                       'Text', '-', 'FontSize', 12);

    % Detection status
    uilabel(resultPanel, 'Position', [400 100 150 25], ...
           'Text', 'Template 1:', 'FontSize', 11);
    lblT1 = uilabel(resultPanel, 'Position', [550 100 150 25], ...
                   'Text', '-', 'FontSize', 11);

    uilabel(resultPanel, 'Position', [400 70 150 25], ...
           'Text', 'Template 2:', 'FontSize', 11);
    lblT2 = uilabel(resultPanel, 'Position', [550 70 150 25], ...
                   'Text', '-', 'FontSize', 11);

    uilabel(resultPanel, 'Position', [400 40 150 25], ...
           'Text', 'Template 3:', 'FontSize', 11);
    lblT3 = uilabel(resultPanel, 'Position', [550 40 150 25], ...
                   'Text', '-', 'FontSize', 11);
end

function createChannelBTab(parent)
    uilabel(parent, 'Position', [20 720 1000 30], ...
           'Text', 'CHANNEL B: COLOR & STRUCTURE ANALYSIS', ...
           'FontSize', 14, 'FontWeight', 'bold');

    % Method 1: Security Thread
    uilabel(parent, 'Position', [20 660 400 25], ...
           'Text', 'METHOD 1: Security Thread (L*a*b* Color Analysis)', ...
           'FontSize', 12, 'FontWeight', 'bold', 'FontColor', [0 0 0.8]);

    axes1 = uiaxes(parent, 'Position', [20 420 280 220]);
    title(axes1, 'Thread ROI');

    axes2 = uiaxes(parent, 'Position', [320 420 280 220]);
    title(axes2, 'L* Channel');

    axes3 = uiaxes(parent, 'Position', [620 420 280 220]);
    title(axes3, 'a* Channel (Green-Red)');

    axes4 = uiaxes(parent, 'Position', [920 420 280 220]);
    title(axes4, 'Saturation');

    % Method 2: Bleed Lines
    uilabel(parent, 'Position', [20 380 400 25], ...
           'Text', 'METHOD 2: Bleed Lines (Projection Analysis)', ...
           'FontSize', 12, 'FontWeight', 'bold', 'FontColor', [0 0.6 0]);

    axes5 = uiaxes(parent, 'Position', [20 160 380 200]);
    title(axes5, 'Left Bleed Lines ROI');

    axes6 = uiaxes(parent, 'Position', [420 160 380 200]);
    title(axes6, 'Left Projection + Peaks');

    axes7 = uiaxes(parent, 'Position', [820 160 380 200]);
    title(axes7, 'Right Bleed Lines Analysis');

    % Results
    resultPanel = uipanel(parent, 'Position', [20 20 1200 120], ...
                         'Title', 'Channel B Results');

    uilabel(resultPanel, 'Position', [20 60 200 25], ...
           'Text', 'Thread Score:', 'FontSize', 11, 'FontWeight', 'bold');
    lblThreadScore = uilabel(resultPanel, 'Position', [150 60 100 25], ...
                            'Text', '-', 'FontSize', 11);

    uilabel(resultPanel, 'Position', [20 30 200 25], ...
           'Text', 'Bleed Lines Score:', 'FontSize', 11, 'FontWeight', 'bold');
    lblLinesScore = uilabel(resultPanel, 'Position', [150 30 100 25], ...
                           'Text', '-', 'FontSize', 11);

    uilabel(resultPanel, 'Position', [300 45 200 25], ...
           'Text', 'Channel B Final Score:', 'FontSize', 12, 'FontWeight', 'bold');
    lblScoreB = uilabel(resultPanel, 'Position', [480 45 100 25], ...
                       'Text', '-', 'FontSize', 12);
end

function createChannelDTab(parent)
    uilabel(parent, 'Position', [20 720 1000 30], ...
           'Text', 'CHANNEL D: GABOR TEXTURE ANALYSIS', ...
           'FontSize', 14, 'FontWeight', 'bold');

    % Visualizations
    axes1 = uiaxes(parent, 'Position', [20 400 380 300]);
    title(axes1, '1. Grayscale Input');

    axes2 = uiaxes(parent, 'Position', [420 400 380 300]);
    title(axes2, '2. Gabor Filter Response');

    axes3 = uiaxes(parent, 'Position', [820 400 380 300]);
    title(axes3, '3. Detected Peaks (All)');

    axes4 = uiaxes(parent, 'Position', [20 80 380 300]);
    title(axes4, '4. Significant Peaks (>threshold)');

    axes5 = uiaxes(parent, 'Position', [420 80 380 300]);
    title(axes5, 'Gabor Kernel Visualization');

    % Results
    resultPanel = uipanel(parent, 'Position', [820 80 380 300], ...
                         'Title', 'Texture Analysis Results');

    uilabel(resultPanel, 'Position', [20 230 300 25], ...
           'Text', 'Gabor Parameters:', 'FontSize', 12, 'FontWeight', 'bold');

    uilabel(resultPanel, 'Position', [20 200 150 20], ...
           'Text', 'Wavelength:', 'FontSize', 10);
    lblWavelength = uilabel(resultPanel, 'Position', [150 200 100 20], ...
                           'Text', '-', 'FontSize', 10);

    uilabel(resultPanel, 'Position', [20 175 150 20], ...
           'Text', 'Orientation:', 'FontSize', 10);
    lblOrientation = uilabel(resultPanel, 'Position', [150 175 100 20], ...
                            'Text', '-', 'FontSize', 10);

    uilabel(resultPanel, 'Position', [20 140 300 25], ...
           'Text', 'Peak Analysis:', 'FontSize', 12, 'FontWeight', 'bold');

    uilabel(resultPanel, 'Position', [20 110 150 20], ...
           'Text', 'Total Peaks:', 'FontSize', 10);
    lblTotalPeaks = uilabel(resultPanel, 'Position', [150 110 100 20], ...
                           'Text', '-', 'FontSize', 10);

    uilabel(resultPanel, 'Position', [20 85 150 20], ...
           'Text', 'Threshold:', 'FontSize', 10);
    lblThreshold = uilabel(resultPanel, 'Position', [150 85 100 20], ...
                          'Text', '-', 'FontSize', 10);

    uilabel(resultPanel, 'Position', [20 60 180 20], ...
           'Text', 'Significant Peaks:', 'FontSize', 10, 'FontWeight', 'bold');
    lblSigPeaks = uilabel(resultPanel, 'Position', [150 60 100 20], ...
                         'Text', '-', 'FontSize', 10, 'FontWeight', 'bold');

    uilabel(resultPanel, 'Position', [20 20 150 25], ...
           'Text', 'Channel D Score:', 'FontSize', 12, 'FontWeight', 'bold');
    lblScoreD = uilabel(resultPanel, 'Position', [150 20 150 25], ...
                       'Text', '-', 'FontSize', 12, 'FontWeight', 'bold');
end

function createFinalResultsTab(parent)
    uilabel(parent, 'Position', [20 720 1000 30], ...
           'Text', 'FINAL DECISION FUSION & VERDICT', ...
           'FontSize', 14, 'FontWeight', 'bold');

    % Scores visualization
    axesScores = uiaxes(parent, 'Position', [50 400 500 280]);
    title(axesScores, 'Channel Scores');

    % Fusion visualization
    axesFusion = uiaxes(parent, 'Position', [600 400 500 280]);
    title(axesFusion, 'Weighted Contributions');

    % Summary panel
    summaryPanel = uipanel(parent, 'Position', [50 80 1050 300], ...
                          'Title', 'DETECTION SUMMARY');

    % Scores
    uilabel(summaryPanel, 'Position', [40 220 300 30], ...
           'Text', 'INDIVIDUAL SCORES:', 'FontSize', 13, 'FontWeight', 'bold');

    uilabel(summaryPanel, 'Position', [40 180 200 25], ...
           'Text', 'Channel A (Templates):', 'FontSize', 11);
    lblFinalA = uilabel(summaryPanel, 'Position', [250 180 100 25], ...
                       'Text', '-', 'FontSize', 11);

    uilabel(summaryPanel, 'Position', [40 150 200 25], ...
           'Text', 'Channel B (Color):', 'FontSize', 11);
    lblFinalB = uilabel(summaryPanel, 'Position', [250 150 100 25], ...
                       'Text', '-', 'FontSize', 11);

    uilabel(summaryPanel, 'Position', [40 120 200 25], ...
           'Text', 'Channel D (Texture):', 'FontSize', 11);
    lblFinalD = uilabel(summaryPanel, 'Position', [250 120 100 25], ...
                       'Text', '-', 'FontSize', 11);

    % Fusion
    uilabel(summaryPanel, 'Position', [400 220 300 30], ...
           'Text', 'FUSION:', 'FontSize', 13, 'FontWeight', 'bold');

    uilabel(summaryPanel, 'Position', [400 180 200 25], ...
           'Text', 'Weights: [0.40, 0.40, 0.20]', 'FontSize', 10);

    uilabel(summaryPanel, 'Position', [400 140 150 25], ...
           'Text', 'Final Fused Score:', 'FontSize', 11, 'FontWeight', 'bold');
    lblFusedScore = uilabel(summaryPanel, 'Position', [560 140 100 25], ...
                           'Text', '-', 'FontSize', 11, 'FontWeight', 'bold');

    % Verdict
    uilabel(summaryPanel, 'Position', [40 50 150 35], ...
           'Text', 'FINAL VERDICT:', 'FontSize', 13, 'FontWeight', 'bold');
    lblFinalVerdict = uilabel(summaryPanel, 'Position', [200 40 400 50], ...
                             'Text', 'AWAITING DETECTION', ...
                             'FontSize', 24, 'FontWeight', 'bold', ...
                             'FontColor', [0.5 0.5 0.5]);
end

% ========================================================================
% UPDATE FUNCTIONS (to be implemented - populate with actual data)
% ========================================================================

function updatePreprocessingTab()
    % Update preprocessing visualizations with APP_DATA.vis_data.preprocessing
end

function updateChannelATab()
    % Update Channel A visualizations with APP_DATA.vis_data.channel_A
end

function updateChannelBTab()
    % Update Channel B visualizations with APP_DATA.vis_data.channel_B
end

function updateChannelDTab()
    % Update Channel D visualizations with APP_DATA.vis_data.channel_D
end

function updateFinalResultsTab()
    % Update final results with APP_DATA.vis_data.fusion
end
