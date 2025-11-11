function [score, vis_data] = run_channel_C_withVis(aligned_image, ref_image_path)
%run_channel_C_withVis Channel C: Paper Texture Analysis (Detects Printer Artifacts)
%
%   **KEY CHANGE**: Analyzes texture QUALITY, not just quantity
%   Photocopies lack natural paper fiber patterns

    vis_data = struct();
    vis_data.input_image = aligned_image;

    % Load reference image
    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end
    ref_image = imread(ref_image_path);
    ref_image = imresize(ref_image, size(aligned_image(:,:,1)));
    vis_data.reference_image = ref_image;

    % Convert to grayscale
    if size(aligned_image, 3) == 3
        test_gray = rgb2gray(aligned_image);
    else
        test_gray = aligned_image;
    end

    if size(ref_image, 3) == 3
        ref_gray = rgb2gray(ref_image);
    else
        ref_gray = ref_image;
    end

    vis_data.step1_test_grayscale = test_gray;
    vis_data.step1_ref_grayscale = ref_gray;

    % --- Apply Multiple Gabor Filters (different orientations) ---
    wavelength = 4;
    orientations = [0, 45, 90, 135];  % Multiple directions

    test_responses = [];
    ref_responses = [];

    for ori = orientations
        g = gabor(wavelength, ori);

        test_resp = abs(imfilter(im2double(test_gray), g.SpatialKernel, 'conv'));
        ref_resp = abs(imfilter(im2double(ref_gray), g.SpatialKernel, 'conv'));

        test_responses = [test_responses; mean(test_resp(:))];
        ref_responses = [ref_responses; mean(ref_resp(:))];
    end

    % Store main vertical orientation for visualization
    g_vert = gabor(wavelength, 90);
    test_gabor_mag = abs(imfilter(im2double(test_gray), g_vert.SpatialKernel, 'conv'));
    ref_gabor_mag = abs(imfilter(im2double(ref_gray), g_vert.SpatialKernel, 'conv'));

    vis_data.gabor_wavelength = wavelength;
    vis_data.gabor_orientation = 90;
    vis_data.gabor_kernel = g_vert.SpatialKernel;
    vis_data.step3_test_gabor = test_gabor_mag;
    vis_data.step3_ref_gabor = ref_gabor_mag;

    % --- Calculate Texture Anisotropy (genuine notes have directional patterns) ---
    % Photocopies are more isotropic (same in all directions)
    test_anisotropy = std(test_responses) / mean(test_responses);
    ref_anisotropy = std(ref_responses) / mean(ref_responses);

    aniso_ratio = test_anisotropy / ref_anisotropy;

    % --- Peak Analysis (for visualization) ---
    test_peaks_mask = imregionalmax(test_gabor_mag);
    ref_peaks_mask = imregionalmax(ref_gabor_mag);

    test_peak_count = sum(test_peaks_mask(:));
    ref_peak_count = sum(ref_peaks_mask(:));
    peak_ratio = test_peak_count / ref_peak_count;

    vis_data.step4_test_peaks_mask = test_peaks_mask;
    vis_data.step4_ref_peaks_mask = ref_peaks_mask;
    vis_data.step4_test_total_peaks = test_peak_count;
    vis_data.step4_ref_total_peaks = ref_peak_count;

    vis_data.step5_test_peak_count = test_peak_count;
    vis_data.step5_ref_peak_count = ref_peak_count;
    vis_data.step5_peak_ratio = peak_ratio;

    % --- Calculate texture uniformity (photocopies are too uniform) ---
    test_uniformity = mean2(stdfilt(test_gray, ones(25)));
    ref_uniformity = mean2(stdfilt(ref_gray, ones(25)));

    uniformity_ratio = test_uniformity / ref_uniformity;

    % --- SCORING ---
    % Combine anisotropy and uniformity
    score = 0;

    % Anisotropy score (should be similar to reference)
    if aniso_ratio >= 0.6 && aniso_ratio <= 1.4
        aniso_score = 1.0;
    elseif aniso_ratio >= 0.4 && aniso_ratio <= 1.6
        aniso_score = 0.5;
    else
        aniso_score = 0.0;
    end

    % Uniformity score (should be similar to reference)
    if uniformity_ratio >= 0.7 && uniformity_ratio <= 1.3
        uniform_score = 1.0;
    elseif uniformity_ratio >= 0.5 && uniformity_ratio <= 1.5
        uniform_score = 0.5;
    else
        uniform_score = 0.0;
    end

    % Combined score
    score = (aniso_score + uniform_score) / 2;

    vis_data.test_anisotropy = test_anisotropy;
    vis_data.ref_anisotropy = ref_anisotropy;
    vis_data.aniso_ratio = aniso_ratio;
    vis_data.test_uniformity = test_uniformity;
    vis_data.ref_uniformity = ref_uniformity;
    vis_data.uniformity_ratio = uniformity_ratio;
    vis_data.final_score = score;

    fprintf('  Channel C: Aniso=%.2f, Uniform=%.2f → Score=%.1f\n', ...
            aniso_ratio, uniformity_ratio, score);

end
