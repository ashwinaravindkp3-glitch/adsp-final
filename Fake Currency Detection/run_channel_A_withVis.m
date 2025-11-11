function [score, vis_data] = run_channel_A_withVis(aligned_image)
%run_channel_A_withVis Channel A: NCC Template Matching
%
%   Normalized Cross-Correlation with security feature templates

    vis_data = struct();
    vis_data.input_image = aligned_image;

    % Convert to grayscale
    if size(aligned_image, 3) == 3
        gray = rgb2gray(aligned_image);
    else
        gray = aligned_image;
    end
    vis_data.step1_grayscale = gray;

    % Histogram equalization
    gray_eq = histeq(gray);
    vis_data.step2_histeq = gray_eq;

    % Templates
    template_files = {
        'template_ashoka.jpg', ...
        'template_devanagiri.jpg', ...
        'template_rbi_seal.jpg'
    };

    vis_data.templates = cell(length(template_files), 1);
    vis_data.correlation_maps = cell(length(template_files), 1);
    vis_data.max_corr_values = zeros(length(template_files), 1);
    vis_data.detected = false(length(template_files), 1);
    vis_data.template_names = template_files;

    threshold = 0.40;
    num_found = 0;

    for i = 1:length(template_files)
        try
            % Load template
            template = imread(template_files{i});
            if size(template, 3) == 3
                template_gray = rgb2gray(template);
            else
                template_gray = template;
            end
            template_eq = histeq(template_gray);

            vis_data.templates{i} = template_eq;

            % Normalized Cross-Correlation
            corr_map = normxcorr2(template_eq, gray_eq);
            max_corr = max(corr_map(:));

            vis_data.correlation_maps{i} = corr_map;
            vis_data.max_corr_values(i) = max_corr;

            % Detection
            if max_corr >= threshold
                num_found = num_found + 1;
                vis_data.detected(i) = true;
            end

            if vis_data.detected(i)
                status = 'DETECTED';
            else
                status = 'NOT DETECTED';
            end
            fprintf('  Template %d (%s): NCC=%.4f [%s]\n', i, template_files{i}, max_corr, status);

        catch ME
            vis_data.templates{i} = [];
            vis_data.correlation_maps{i} = [];
            vis_data.max_corr_values(i) = 0;
            vis_data.detected(i) = false;
            fprintf('  Template %d: ERROR - %s\n', i, ME.message);
        end
    end

    % Score
    score = num_found / length(template_files);
    vis_data.num_detected = num_found;
    vis_data.total_templates = length(template_files);
    vis_data.final_score = score;

    fprintf('  Channel A Score: %.4f (%d/%d templates found)\n', score, num_found, length(template_files));

end
