function SimpleCurrencyGUI()
%SimpleCurrencyGUI - Simple working GUI for currency detection with all visualizations
%
%   This creates a figure-based GUI that shows all processing steps
%   Perfect for ADSP project demonstration

    % Create main figure
    fig = figure('Name', 'Currency Detector - ADSP Project', ...
                 'Position', [50 50 1600 900], ...
                 'MenuBar', 'none', ...
                 'NumberTitle', 'off', ...
                 'Color', [0.94 0.94 0.94]);

    % Global storage
    handles = struct();
    handles.test_image_path = '';
    handles.vis_data = [];

    % ====================================================================
    % UI CONTROLS
    % ====================================================================

    % Upload button
    handles.btnUpload = uicontrol('Style', 'pushbutton', ...
                                  'String', 'Upload Image', ...
                                  'Position', [20 850 150 40], ...
                                  'FontSize', 12, ...
                                  'Callback', @uploadCallback);

    % Detect button
    handles.btnDetect = uicontrol('Style', 'pushbutton', ...
                                  'String', 'RUN DETECTION', ...
                                  'Position', [190 850 150 40], ...
                                  'FontSize', 12, ...
                                  'FontWeight', 'bold', ...
                                  'ForegroundColor', 'white', ...
                                  'BackgroundColor', [0.2 0.7 0.3], ...
                                  'Callback', @detectCallback);

    % Image path text
    handles.txtPath = uicontrol('Style', 'text', ...
                               'String', 'No image loaded', ...
                               'Position', [360 850 600 40], ...
                               'FontSize', 10, ...
                               'HorizontalAlignment', 'left');

    % Verdict text
    handles.txtVerdict = uicontrol('Style', 'text', ...
                                  'String', 'AWAITING INPUT', ...
                                  'Position', [1000 850 550 40], ...
                                  'FontSize', 18, ...
                                  'FontWeight', 'bold', ...
                                  'ForegroundColor', [0.3 0.3 0.3]);

    % ====================================================================
    % TAB GROUP
    % ====================================================================

    handles.tabgroup = uitabgroup(fig, 'Position', [0.01 0.01 0.98 0.88]);

    % Create tabs
    handles.tab1 = uitab(handles.tabgroup, 'Title', '1. PREPROCESSING');
    handles.tab2 = uitab(handles.tabgroup, 'Title', '2. CHANNEL A');
    handles.tab3 = uitab(handles.tabgroup, 'Title', '3. CHANNEL B');
    handles.tab4 = uitab(handles.tabgroup, 'Title', '4. CHANNEL D');
    handles.tab5 = uitab(handles.tabgroup, 'Title', '5. RESULTS');

    % Create axes in each tab
    createTabAxes(handles);

    % Store handles
    guidata(fig, handles);

    % ====================================================================
    % CALLBACKS
    % ====================================================================

    function uploadCallback(src, ~)
        h = guidata(src);
        [file, path] = uigetfile({'*.jpg;*.jpeg;*.png', 'Images'}, 'Select Image');
        if file ~= 0
            h.test_image_path = fullfile(path, file);
            h.txtPath.String = ['Loaded: ' file];
            h.txtPath.ForegroundColor = [0 0.5 0];
            h.txtVerdict.String = 'READY';
            h.txtVerdict.ForegroundColor = [0 0 1];
            guidata(src, h);
        end
    end

    function detectCallback(src, ~)
        h = guidata(src);

        if isempty(h.test_image_path)
            msgbox('Please upload an image first!', 'Error', 'error');
            return;
        end

        % Show wait message
        h.txtVerdict.String = 'PROCESSING...';
        h.txtVerdict.ForegroundColor = [1 0.5 0];
        drawnow;

        try
            % Run detection
            [verdict, score, vis_data] = detect_with_all_visualizations(h.test_image_path);

            % Store results
            h.vis_data = vis_data;

            % Update verdict
            if strcmp(verdict, 'GENUINE')
                h.txtVerdict.String = sprintf('✓ GENUINE (%.3f)', score);
                h.txtVerdict.ForegroundColor = [0 0.6 0];
            elseif strcmp(verdict, 'COUNTERFEIT')
                h.txtVerdict.String = sprintf('✗ COUNTERFEIT (%.3f)', score);
                h.txtVerdict.ForegroundColor = [1 0 0];
            else
                h.txtVerdict.String = '⚠ ERROR';
                h.txtVerdict.ForegroundColor = [1 0.5 0];
            end

            % Update visualizations
            updateAllVisualizations(h);

            guidata(src, h);

            msgbox(sprintf('Detection Complete!\nVerdict: %s\nScore: %.4f', verdict, score), ...
                   'Success', 'help');

        catch ME
            h.txtVerdict.String = 'ERROR';
            h.txtVerdict.ForegroundColor = [1 0 0];
            msgbox(['Error: ' ME.message], 'Detection Failed', 'error');
            guidata(src, h);
        end
    end

end

% ========================================================================
% CREATE AXES
% ========================================================================

function createTabAxes(h)
    % TAB 1: Preprocessing (6 subplots)
    h.ax1_1 = subplot(2, 3, 1, 'Parent', h.tab1); title('Original');
    h.ax1_2 = subplot(2, 3, 2, 'Parent', h.tab1); title('Rotated');
    h.ax1_3 = subplot(2, 3, 3, 'Parent', h.tab1); title('Resized');
    h.ax1_4 = subplot(2, 3, 4, 'Parent', h.tab1); title('Grayscale');
    h.ax1_5 = subplot(2, 3, 5, 'Parent', h.tab1); title('Features');
    h.ax1_6 = subplot(2, 3, 6, 'Parent', h.tab1); title('Aligned');

    % TAB 2: Channel A (4 subplots)
    h.ax2_1 = subplot(2, 2, 1, 'Parent', h.tab2); title('Illumination Normalized');
    h.ax2_2 = subplot(2, 2, 2, 'Parent', h.tab2); title('Histogram Equalized');
    h.ax2_3 = subplot(2, 2, 3, 'Parent', h.tab2); title('Templates');
    h.ax2_4 = subplot(2, 2, 4, 'Parent', h.tab2); title('Correlation Maps');

    % TAB 3: Channel B (4 subplots)
    h.ax3_1 = subplot(2, 2, 1, 'Parent', h.tab3); title('Security Thread ROI');
    h.ax3_2 = subplot(2, 2, 2, 'Parent', h.tab3); title('a* Channel');
    h.ax3_3 = subplot(2, 2, 3, 'Parent', h.tab3); title('Left Bleed Lines');
    h.ax3_4 = subplot(2, 2, 4, 'Parent', h.tab3); title('Right Bleed Lines');

    % TAB 4: Channel D (4 subplots)
    h.ax4_1 = subplot(2, 2, 1, 'Parent', h.tab4); title('Grayscale');
    h.ax4_2 = subplot(2, 2, 2, 'Parent', h.tab4); title('Gabor Response');
    h.ax4_3 = subplot(2, 2, 3, 'Parent', h.tab4); title('All Peaks');
    h.ax4_4 = subplot(2, 2, 4, 'Parent', h.tab4); title('Significant Peaks');

    % TAB 5: Results (2 subplots)
    h.ax5_1 = subplot(1, 2, 1, 'Parent', h.tab5); title('Scores');
    h.ax5_2 = subplot(1, 2, 2, 'Parent', h.tab5); title('Fusion');
end

% ========================================================================
% UPDATE VISUALIZATIONS
% ========================================================================

function updateAllVisualizations(h)
    if isempty(h.vis_data) || ~h.vis_data.success
        return;
    end

    vis = h.vis_data;

    % TAB 1: Preprocessing
    try
        imshow(vis.preprocessing.step1_original, 'Parent', h.ax1_1);
        imshow(vis.preprocessing.step2_rotated, 'Parent', h.ax1_2);
        imshow(vis.preprocessing.step3_resized, 'Parent', h.ax1_3);
        imshow(vis.preprocessing.step4_gray_test, 'Parent', h.ax1_4);

        % Feature matching visualization
        axes(h.ax1_5);
        imshow(vis.preprocessing.step4_gray_test);
        hold on;
        plot(vis.preprocessing.step7_matched_test.Location(:,1), ...
             vis.preprocessing.step7_matched_test.Location(:,2), 'g+');
        title(sprintf('Features (%d matches)', vis.preprocessing.step7_match_count));
        hold off;

        imshow(vis.preprocessing.step9_aligned, 'Parent', h.ax1_6);
    catch
    end

    % TAB 2: Channel A
    try
        imshow(vis.channel_A.step1_illumination_normalized, 'Parent', h.ax2_1);
        imshow(vis.channel_A.step2_histeq, 'Parent', h.ax2_2);

        % Show first template and correlation
        if ~isempty(vis.channel_A.templates{1})
            imshow(vis.channel_A.templates{1}, 'Parent', h.ax2_3);
            title(h.ax2_3, sprintf('Template (%.3f)', vis.channel_A.max_corr_values(1)));
        end

        if ~isempty(vis.channel_A.correlation_maps{1})
            imagesc(vis.channel_A.correlation_maps{1}, 'Parent', h.ax2_4);
            colorbar(h.ax2_4);
            title(h.ax2_4, sprintf('NCC: Detected=%d/3', vis.channel_A.num_detected));
        end
    catch
    end

    % TAB 3: Channel B
    try
        imshow(vis.channel_B.method1_thread.roi_image, 'Parent', h.ax3_1);
        title(h.ax3_1, sprintf('Thread Score: %.3f', vis.channel_B.score_thread));

        imagesc(vis.channel_B.method1_thread.lab_a, 'Parent', h.ax3_2);
        colorbar(h.ax3_2);
        title(h.ax3_2, sprintf('a* channel (avg: %.2f)', ...
              vis.channel_B.method1_thread.avg_a_star));

        % Bleed lines
        imshow(vis.channel_B.method2_lines.roi_left_image, [], 'Parent', h.ax3_3);
        title(h.ax3_3, sprintf('Left: %d lines', vis.channel_B.method2_lines.left_count));

        axes(h.ax3_4);
        plot(vis.channel_B.method2_lines.right_analysis.projection_inverted);
        hold on;
        plot(vis.channel_B.method2_lines.right_analysis.peak_locations, ...
             vis.channel_B.method2_lines.right_analysis.peaks, 'ro');
        title(sprintf('Right: %d lines', vis.channel_B.method2_lines.right_count));
        hold off;
    catch
    end

    % TAB 4: Channel D
    try
        imshow(vis.channel_D.step1_grayscale, 'Parent', h.ax4_1);

        imagesc(vis.channel_D.step3_gabor_magnitude, 'Parent', h.ax4_2);
        colorbar(h.ax4_2);
        title(h.ax4_2, 'Gabor Response');

        imshow(vis.channel_D.step4_peaks_mask, 'Parent', h.ax4_3);
        title(h.ax4_3, sprintf('All Peaks: %d', vis.channel_D.step4_total_peaks));

        imshow(vis.channel_D.step5_significant_peaks_mask, 'Parent', h.ax4_4);
        title(h.ax4_4, sprintf('Significant: %d (Score: %.1f)', ...
              vis.channel_D.step5_peak_count, vis.channel_D.final_score));
    catch
    end

    % TAB 5: Results
    try
        % Scores bar chart
        axes(h.ax5_1);
        scores = [vis.scores.channel_A, vis.scores.channel_B, vis.scores.channel_D];
        bar(scores);
        set(gca, 'XTickLabel', {'Channel A', 'Channel B', 'Channel D'});
        ylabel('Score');
        title('Individual Channel Scores');
        ylim([0 1]);
        grid on;

        % Fusion pie chart
        axes(h.ax5_2);
        contributions = vis.fusion.weighted_contributions;
        pie(contributions, {'A: Templates', 'B: Color', 'D: Texture'});
        title(sprintf('Final Score: %.4f - %s', ...
              vis.fusion.final_score, vis.fusion.verdict));
    catch
    end
end
