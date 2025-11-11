function WorkingGUI()
%WorkingGUI - Simple working GUI for currency detection
%
%   Just run: WorkingGUI

    % Create figure
    fig = figure('Name', 'Currency Detector', ...
                 'Position', [100 100 1400 800], ...
                 'MenuBar', 'none', ...
                 'NumberTitle', 'off', ...
                 'Color', [0.94 0.94 0.94]);

    % Store data
    setappdata(fig, 'test_image_path', '');
    setappdata(fig, 'vis_data', []);

    % ==== CONTROLS ====

    % Upload button
    uicontrol('Style', 'pushbutton', ...
              'String', 'UPLOAD IMAGE', ...
              'Position', [20 750 150 40], ...
              'FontSize', 11, ...
              'FontWeight', 'bold', ...
              'Callback', @uploadCallback);

    % Detect button
    uicontrol('Style', 'pushbutton', ...
              'String', 'RUN DETECTION', ...
              'Position', [190 750 150 40], ...
              'FontSize', 11, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.2 0.7 0.3], ...
              'ForegroundColor', 'white', ...
              'Callback', @detectCallback);

    % Path text
    uicontrol('Style', 'text', ...
              'String', 'No image loaded', ...
              'Position', [360 750 400 40], ...
              'FontSize', 10, ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94 0.94 0.94], ...
              'Tag', 'txtPath');

    % Verdict text
    uicontrol('Style', 'text', ...
              'String', 'AWAITING INPUT', ...
              'Position', [800 750 550 40], ...
              'FontSize', 16, ...
              'FontWeight', 'bold', ...
              'ForegroundColor', [0.3 0.3 0.3], ...
              'BackgroundColor', [0.94 0.94 0.94], ...
              'Tag', 'txtVerdict');

    % ==== CREATE 5 PANELS FOR TABS ====

    % Tab buttons
    btnTab1 = uicontrol('Style', 'pushbutton', 'String', '1. PREPROCESSING', ...
                        'Position', [20 710 260 30], 'Callback', @(s,e) showTab(1));
    btnTab2 = uicontrol('Style', 'pushbutton', 'String', '2. CHANNEL A', ...
                        'Position', [290 710 260 30], 'Callback', @(s,e) showTab(2));
    btnTab3 = uicontrol('Style', 'pushbutton', 'String', '3. CHANNEL B', ...
                        'Position', [560 710 260 30], 'Callback', @(s,e) showTab(3));
    btnTab4 = uicontrol('Style', 'pushbutton', 'String', '4. CHANNEL D', ...
                        'Position', [830 710 260 30], 'Callback', @(s,e) showTab(4));
    btnTab5 = uicontrol('Style', 'pushbutton', 'String', '5. RESULTS', ...
                        'Position', [1100 710 260 30], 'Callback', @(s,e) showTab(5));

    % Create panels (tabs)
    panel1 = uipanel(fig, 'Position', [0.01 0.01 0.98 0.87], 'Visible', 'on', 'Tag', 'panel1');
    panel2 = uipanel(fig, 'Position', [0.01 0.01 0.98 0.87], 'Visible', 'off', 'Tag', 'panel2');
    panel3 = uipanel(fig, 'Position', [0.01 0.01 0.98 0.87], 'Visible', 'off', 'Tag', 'panel3');
    panel4 = uipanel(fig, 'Position', [0.01 0.01 0.98 0.87], 'Visible', 'off', 'Tag', 'panel4');
    panel5 = uipanel(fig, 'Position', [0.01 0.01 0.98 0.87], 'Visible', 'off', 'Tag', 'panel5');

    % Create axes in each panel
    createAxes(panel1, panel2, panel3, panel4, panel5);

    % ==== NESTED FUNCTIONS ====

    function showTab(n)
        % Hide all panels
        set(findobj(fig, 'Tag', 'panel1'), 'Visible', 'off');
        set(findobj(fig, 'Tag', 'panel2'), 'Visible', 'off');
        set(findobj(fig, 'Tag', 'panel3'), 'Visible', 'off');
        set(findobj(fig, 'Tag', 'panel4'), 'Visible', 'off');
        set(findobj(fig, 'Tag', 'panel5'), 'Visible', 'off');

        % Show selected panel
        set(findobj(fig, 'Tag', ['panel' num2str(n)]), 'Visible', 'on');
    end

    function uploadCallback(src, ~)
        [file, path] = uigetfile({'*.jpg;*.jpeg;*.png', 'Image Files'}, 'Select Currency Image');
        if file ~= 0
            full_path = fullfile(path, file);
            setappdata(gcbf, 'test_image_path', full_path);

            % Update text
            txt = findobj(gcbf, 'Tag', 'txtPath');
            set(txt, 'String', ['Loaded: ' file], 'ForegroundColor', [0 0.5 0]);

            verdict = findobj(gcbf, 'Tag', 'txtVerdict');
            set(verdict, 'String', 'READY TO DETECT', 'ForegroundColor', [0 0 1]);
        end
    end

    function detectCallback(src, ~)
        test_path = getappdata(gcbf, 'test_image_path');

        if isempty(test_path)
            msgbox('Please upload an image first!', 'Error', 'error');
            return;
        end

        % Update verdict
        verdict_txt = findobj(gcbf, 'Tag', 'txtVerdict');
        set(verdict_txt, 'String', 'PROCESSING...', 'ForegroundColor', [1 0.5 0]);
        drawnow;

        try
            % Run detection
            fprintf('\n=== STARTING DETECTION ===\n');
            [verdict, score, vis_data] = detect_with_all_visualizations(test_path);

            % Store results
            setappdata(gcbf, 'vis_data', vis_data);

            % Update verdict
            if strcmp(verdict, 'GENUINE')
                set(verdict_txt, 'String', sprintf('✓ GENUINE (%.3f)', score), ...
                    'ForegroundColor', [0 0.6 0]);
            elseif strcmp(verdict, 'COUNTERFEIT')
                set(verdict_txt, 'String', sprintf('✗ COUNTERFEIT (%.3f)', score), ...
                    'ForegroundColor', [1 0 0]);
            else
                set(verdict_txt, 'String', 'ERROR', 'ForegroundColor', [1 0.5 0]);
            end

            % Update visualizations
            updateVisualizations(gcbf);

            msgbox(sprintf('Detection Complete!\nVerdict: %s\nScore: %.4f', verdict, score), ...
                   'Success', 'help');

        catch ME
            set(verdict_txt, 'String', 'ERROR', 'ForegroundColor', [1 0 0]);
            msgbox(['Error: ' ME.message], 'Detection Failed', 'error');
            fprintf('Error: %s\n', ME.message);
            fprintf('Stack:\n');
            for i = 1:length(ME.stack)
                fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
            end
        end
    end

end

% ========================================================================
% CREATE AXES
% ========================================================================

function createAxes(p1, p2, p3, p4, p5)
    % Panel 1: Preprocessing (6 subplots)
    subplot(2, 3, 1, 'Parent', p1, 'Tag', 'ax1_1'); title('Original');
    subplot(2, 3, 2, 'Parent', p1, 'Tag', 'ax1_2'); title('Rotated');
    subplot(2, 3, 3, 'Parent', p1, 'Tag', 'ax1_3'); title('Resized');
    subplot(2, 3, 4, 'Parent', p1, 'Tag', 'ax1_4'); title('Grayscale');
    subplot(2, 3, 5, 'Parent', p1, 'Tag', 'ax1_5'); title('Features');
    subplot(2, 3, 6, 'Parent', p1, 'Tag', 'ax1_6'); title('Aligned');

    % Panel 2: Channel A (4 subplots)
    subplot(2, 2, 1, 'Parent', p2, 'Tag', 'ax2_1'); title('Illumination Normalized');
    subplot(2, 2, 2, 'Parent', p2, 'Tag', 'ax2_2'); title('Histogram Equalized');
    subplot(2, 2, 3, 'Parent', p2, 'Tag', 'ax2_3'); title('Template + Detection');
    subplot(2, 2, 4, 'Parent', p2, 'Tag', 'ax2_4'); title('NCC Correlation Map');

    % Panel 3: Channel B (4 subplots)
    subplot(2, 2, 1, 'Parent', p3, 'Tag', 'ax3_1'); title('Security Thread ROI');
    subplot(2, 2, 2, 'Parent', p3, 'Tag', 'ax3_2'); title('a* Channel');
    subplot(2, 2, 3, 'Parent', p3, 'Tag', 'ax3_3'); title('Left Bleed Lines');
    subplot(2, 2, 4, 'Parent', p3, 'Tag', 'ax3_4'); title('Right Projection');

    % Panel 4: Channel D (4 subplots)
    subplot(2, 2, 1, 'Parent', p4, 'Tag', 'ax4_1'); title('Grayscale');
    subplot(2, 2, 2, 'Parent', p4, 'Tag', 'ax4_2'); title('Gabor Response');
    subplot(2, 2, 3, 'Parent', p4, 'Tag', 'ax4_3'); title('All Peaks');
    subplot(2, 2, 4, 'Parent', p4, 'Tag', 'ax4_4'); title('Significant Peaks');

    % Panel 5: Results (2 subplots)
    subplot(1, 2, 1, 'Parent', p5, 'Tag', 'ax5_1'); title('Channel Scores');
    subplot(1, 2, 2, 'Parent', p5, 'Tag', 'ax5_2'); title('Weighted Fusion');
end

% ========================================================================
% UPDATE VISUALIZATIONS
% ========================================================================

function updateVisualizations(fig)
    vis = getappdata(fig, 'vis_data');

    if isempty(vis) || ~vis.success
        return;
    end

    try
        % TAB 1: Preprocessing
        axes(findobj(fig, 'Tag', 'ax1_1')); imshow(vis.preprocessing.step1_original);
        axes(findobj(fig, 'Tag', 'ax1_2')); imshow(vis.preprocessing.step2_rotated);
        axes(findobj(fig, 'Tag', 'ax1_3')); imshow(vis.preprocessing.step3_resized);
        axes(findobj(fig, 'Tag', 'ax1_4')); imshow(vis.preprocessing.step4_gray_test);

        axes(findobj(fig, 'Tag', 'ax1_5'));
        imshow(vis.preprocessing.step4_gray_test); hold on;
        plot(vis.preprocessing.step7_matched_test.Location(:,1), ...
             vis.preprocessing.step7_matched_test.Location(:,2), 'g+', 'MarkerSize', 3);
        title(sprintf('%d matches', vis.preprocessing.step7_match_count));
        hold off;

        axes(findobj(fig, 'Tag', 'ax1_6')); imshow(vis.preprocessing.step9_aligned);
    catch ME
        fprintf('Error updating Tab 1: %s\n', ME.message);
    end

    try
        % TAB 2: Channel A
        axes(findobj(fig, 'Tag', 'ax2_1'));
        imshow(vis.channel_A.step1_illumination_normalized);

        axes(findobj(fig, 'Tag', 'ax2_2'));
        imshow(vis.channel_A.step2_histeq);

        axes(findobj(fig, 'Tag', 'ax2_3'));
        if ~isempty(vis.channel_A.templates{1})
            imshow(vis.channel_A.templates{1});
            title(sprintf('Template (%.3f) - %d/3 detected', ...
                  vis.channel_A.max_corr_values(1), vis.channel_A.num_detected));
        end

        axes(findobj(fig, 'Tag', 'ax2_4'));
        if ~isempty(vis.channel_A.correlation_maps{1})
            imagesc(vis.channel_A.correlation_maps{1}); colorbar;
            title(sprintf('NCC Map - Score: %.2f', vis.channel_A.final_score));
        end
    catch ME
        fprintf('Error updating Tab 2: %s\n', ME.message);
    end

    try
        % TAB 3: Channel B
        axes(findobj(fig, 'Tag', 'ax3_1'));
        imshow(vis.channel_B.method1_thread.roi_image);
        title(sprintf('Thread Score: %.3f', vis.channel_B.score_thread));

        axes(findobj(fig, 'Tag', 'ax3_2'));
        imagesc(vis.channel_B.method1_thread.lab_a); colorbar;
        title(sprintf('a*=%.2f (green<0)', vis.channel_B.method1_thread.avg_a_star));

        axes(findobj(fig, 'Tag', 'ax3_3'));
        imshow(vis.channel_B.method2_lines.roi_left_image, []);
        title(sprintf('Left: %d lines', vis.channel_B.method2_lines.left_count));

        axes(findobj(fig, 'Tag', 'ax3_4'));
        plot(vis.channel_B.method2_lines.right_analysis.projection_inverted);
        hold on;
        plot(vis.channel_B.method2_lines.right_analysis.peak_locations, ...
             vis.channel_B.method2_lines.right_analysis.peaks, 'ro', 'MarkerSize', 8);
        title(sprintf('Right: %d lines (Score: %.1f)', ...
              vis.channel_B.method2_lines.right_count, vis.channel_B.score_lines));
        hold off;
    catch ME
        fprintf('Error updating Tab 3: %s\n', ME.message);
    end

    try
        % TAB 4: Channel D
        axes(findobj(fig, 'Tag', 'ax4_1'));
        imshow(vis.channel_D.step1_grayscale);

        axes(findobj(fig, 'Tag', 'ax4_2'));
        imagesc(vis.channel_D.step3_gabor_magnitude); colorbar;

        axes(findobj(fig, 'Tag', 'ax4_3'));
        imshow(vis.channel_D.step4_peaks_mask);
        title(sprintf('All Peaks: %d', vis.channel_D.step4_total_peaks));

        axes(findobj(fig, 'Tag', 'ax4_4'));
        imshow(vis.channel_D.step5_significant_peaks_mask);
        title(sprintf('Significant: %d (Score: %.1f)', ...
              vis.channel_D.step5_peak_count, vis.channel_D.final_score));
    catch ME
        fprintf('Error updating Tab 4: %s\n', ME.message);
    end

    try
        % TAB 5: Results
        axes(findobj(fig, 'Tag', 'ax5_1'));
        scores = [vis.scores.channel_A, vis.scores.channel_B, vis.scores.channel_D];
        bar(scores);
        set(gca, 'XTickLabel', {'Channel A', 'Channel B', 'Channel D'});
        ylabel('Score'); ylim([0 1]); grid on;
        title('Individual Channel Scores');

        axes(findobj(fig, 'Tag', 'ax5_2'));
        contributions = vis.fusion.weighted_contributions;
        pie(contributions, {'A: Templates (40%)', 'B: Color (40%)', 'D: Texture (20%)'});
        title(sprintf('Final: %.4f - %s', vis.fusion.final_score, vis.fusion.verdict));
    catch ME
        fprintf('Error updating Tab 5: %s\n', ME.message);
    end

    fprintf('✓ All visualizations updated\n');
end
