function [score, vis_data] = run_channel_A_withVis(aligned_image)
%run_channel_A_withVis Channel A: Security Feature Detection
%
%   Detects if security features (Ashoka, Devanagari, RBI seal) are present
%   AND sharp. Photocopies often blur these features.

    vis_data = struct();
    vis_data.input_image = aligned_image;

    % Convert to grayscale
    if size(aligned_image, 3) == 3
        gray = rgb2gray(aligned_image);
    else
        gray = aligned_image;
    end

    % Enhance contrast
    gray_enhanced = adapthisteq(gray);
    vis_data.step1_enhanced = gray_enhanced;

    % --- STEP 1: Template Matching with Sharpness Check ---
    template_files = {
        'template_ashoka.jpg', ...
        'template_devanagiri.jpg', ...
        'template_rbi_seal.jpg'
    };

    vis_data.templates = cell(length(template_files), 1);
    vis_data.correlation_maps = cell(length(template_files), 1);
    vis_data.max_corr_values = zeros(length(template_files), 1);
    vis_data.detected = false(length(template_files), 1);
    vis_data.sharpness_scores = zeros(length(template_files), 1);
    vis_data.template_names = template_files;

    total_score = 0;

    for i = 1:length(template_files)
        try
            % Load and prepare template
            template = imread(template_files{i});
            if size(template, 3) == 3
                template_gray = rgb2gray(template);
            else
                template_gray = template;
            end
            template_enhanced = adapthisteq(template_gray);

            vis_data.templates{i} = template_enhanced;

            % Normalized Cross-Correlation
            corr_map = normxcorr2(template_enhanced, gray_enhanced);
            max_corr = max(corr_map(:));

            vis_data.correlation_maps{i} = corr_map;
            vis_data.max_corr_values(i) = max_corr;

            % Find best match location
            [ypeak, xpeak] = find(corr_map == max_corr, 1);

            % Extract matched region for sharpness check
            [t_h, t_w] = size(template_enhanced);
            y_start = max(1, ypeak - t_h + 1);
            y_end = min(size(gray_enhanced, 1), y_start + t_h - 1);
            x_start = max(1, xpeak - t_w + 1);
            x_end = min(size(gray_enhanced, 2), x_start + t_w - 1);

            matched_region = gray_enhanced(y_start:y_end, x_start:x_end);

            % Measure sharpness using Laplacian variance
            laplacian = del2(double(matched_region));
            sharpness = std(laplacian(:));

            vis_data.sharpness_scores(i) = sharpness;

            % Score this template
            template_score = 0;

            % Correlation threshold (template found?)
            if max_corr >= 0.4
                template_score = template_score + 0.5;
                vis_data.detected(i) = true;
            end

            % Sharpness threshold (is it sharp enough?)
            % Genuine notes: sharpness > 0.03
            % Photocopies: sharpness < 0.02 (blurred)
            if sharpness >= 0.03
                template_score = template_score + 0.5;
            elseif sharpness >= 0.02
                template_score = template_score + 0.25;
            end

            total_score = total_score + template_score;

            fprintf('  Template %d (%s): Corr=%.3f, Sharp=%.4f → Score=%.2f\n', ...
                i, template_files{i}, max_corr, sharpness, template_score);

        catch ME
            vis_data.templates{i} = [];
            vis_data.correlation_maps{i} = [];
            vis_data.max_corr_values(i) = 0;
            vis_data.detected(i) = false;
            fprintf('  Template %d failed: %s\n', i, ME.message);
        end
    end

    % Final score: average across all templates (max = 1.0)
    score = total_score / length(template_files);
    vis_data.final_score = score;
    vis_data.num_detected = sum(vis_data.detected);

    fprintf('  Channel A Final: %.4f (detected %d/%d)\n', score, sum(vis_data.detected), length(template_files));

end
