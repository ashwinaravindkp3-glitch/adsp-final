function [score, vis_data] = run_channel_A_withVis(aligned_image)
%run_channel_A_withVis Channel A: Template Matching ONLY
%
%   Simple template detection - do templates exist?

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

    num_found = 0;

    for i = 1:length(template_files)
        try
            template = imread(template_files{i});
            if size(template, 3) == 3
                template_gray = rgb2gray(template);
            else
                template_gray = template;
            end
            template_enhanced = adapthisteq(template_gray);

            vis_data.templates{i} = template_enhanced;

            % NCC
            corr_map = normxcorr2(template_enhanced, gray_enhanced);
            max_corr = max(corr_map(:));

            vis_data.correlation_maps{i} = corr_map;
            vis_data.max_corr_values(i) = max_corr;

            % Simple threshold
            if max_corr >= 0.35
                num_found = num_found + 1;
                vis_data.detected(i) = true;
            end

            if vis_data.detected(i)
                status_str = 'FOUND';
            else
                status_str = 'NOT FOUND';
            end
            fprintf('  Template %d: Corr=%.3f %s\n', i, max_corr, status_str);

        catch ME
            vis_data.templates{i} = [];
            vis_data.correlation_maps{i} = [];
            vis_data.max_corr_values(i) = 0;
            vis_data.detected(i) = false;
        end
    end

    % Score: how many templates found?
    score = num_found / length(template_files);
    vis_data.final_score = score;
    vis_data.num_detected = num_found;

    fprintf('  Channel A: Found %d/%d → Score=%.3f\n', num_found, length(template_files), score);

end
