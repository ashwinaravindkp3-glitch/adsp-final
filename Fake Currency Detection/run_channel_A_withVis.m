function [score, vis_data] = run_channel_A_withVis(aligned_image)
%run_channel_A_withVis Channel A with visualization outputs
%
%   Returns score AND all intermediate visualizations

    vis_data = struct();
    vis_data.input_image = aligned_image;

    % --- STEP 1: Normalize Illumination ---
    processed_gray = normalizeIllumination(aligned_image);
    vis_data.step1_illumination_normalized = processed_gray;

    % --- STEP 2: Histogram Equalization ---
    processed_histeq = histeq(processed_gray);
    vis_data.step2_histeq = processed_histeq;

    % --- STEP 3: Template Matching ---
    template_files = {
        'template_ashoka.jpg', ...
        'template_devanagiri.jpg', ...
        'template_rbi_seal.jpg'
    };

    detection_threshold = 0.60;
    num_found = 0;

    vis_data.templates = cell(length(template_files), 1);
    vis_data.correlation_maps = cell(length(template_files), 1);
    vis_data.max_corr_values = zeros(length(template_files), 1);
    vis_data.detected = false(length(template_files), 1);
    vis_data.template_names = template_files;

    for i = 1:length(template_files)
        try
            % Load template
            template = imread(template_files{i});
            template_gray = rgb2gray(template);
            template_histeq = histeq(template_gray);

            vis_data.templates{i} = template_histeq;

            % Perform NCC
            corr_map = normxcorr2(template_histeq, processed_histeq);
            max_corr = max(corr_map(:));

            vis_data.correlation_maps{i} = corr_map;
            vis_data.max_corr_values(i) = max_corr;

            % Check detection
            if max_corr >= detection_threshold
                num_found = num_found + 1;
                vis_data.detected(i) = true;
            end

            % Find location of best match
            [ypeak, xpeak] = find(corr_map == max_corr);
            vis_data.match_locations{i} = [xpeak(1), ypeak(1)];

        catch ME
            vis_data.templates{i} = [];
            vis_data.correlation_maps{i} = [];
            vis_data.max_corr_values(i) = 0;
            vis_data.detected(i) = false;
        end
    end

    % --- STEP 4: Calculate Score ---
    score = num_found / length(template_files);
    vis_data.num_detected = num_found;
    vis_data.total_templates = length(template_files);
    vis_data.final_score = score;

end

function normalized_image = normalizeIllumination(image)
    if size(image, 3) == 3
        image_gray = rgb2gray(image);
    else
        image_gray = image;
    end

    I = im2double(image_gray);
    I_log = log(1 + I);
    I_fft = fft2(I_log);

    [M, N] = size(I);
    D0 = 15;
    n = 2;
    [X, Y] = meshgrid(1:N, 1:M);
    D = sqrt((X - N/2).^2 + (Y - M/2).^2);
    H = 1 ./ (1 + (D0./D).^(2*n));

    I_fft_filtered = fftshift(I_fft) .* H;
    I_filtered = real(ifft2(ifftshift(I_fft_filtered)));
    I_exp = exp(I_filtered) - 1;

    normalized_image = im2uint8(mat2gray(I_exp));
end
