function [score, vis_data] = run_channel_C_withVis(aligned_image, ref_image_path)
%run_channel_C_withVis Channel C: Gabor Filter Peak Counting
%
%   Applies Gabor filter and counts peaks
%   Compares peak count with reference image

    vis_data = struct();
    vis_data.input_image = aligned_image;

    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end

    % Load reference
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

    %% Gabor Filter Parameters
    wavelength = 4;
    orientation = 90;

    vis_data.gabor_wavelength = wavelength;
    vis_data.gabor_orientation = orientation;

    %% Apply Gabor Filter
    test_gabor = imgaborfilt(test_gray, wavelength, orientation);
    ref_gabor = imgaborfilt(ref_gray, wavelength, orientation);

    vis_data.step3_test_gabor = test_gabor;
    vis_data.step3_ref_gabor = ref_gabor;

    %% Peak Detection
    % Find local maxima in Gabor response

    % Test image peaks
    test_peaks = imregionalmax(abs(test_gabor));
    test_peak_count = sum(test_peaks(:));

    % Reference image peaks
    ref_peaks = imregionalmax(abs(ref_gabor));
    ref_peak_count = sum(ref_peaks(:));

    vis_data.step4_test_peaks_mask = test_peaks;
    vis_data.step4_ref_peaks_mask = ref_peaks;

    vis_data.step4_test_total_peaks = test_peak_count;
    vis_data.step4_ref_total_peaks = ref_peak_count;

    vis_data.step5_test_peak_count = test_peak_count;
    vis_data.step5_ref_peak_count = ref_peak_count;

    % Peak ratio
    peak_ratio = test_peak_count / ref_peak_count;
    vis_data.step5_peak_ratio = peak_ratio;

    fprintf('  Test peaks: %d\n', test_peak_count);
    fprintf('  Ref peaks:  %d\n', ref_peak_count);
    fprintf('  Peak ratio: %.4f\n', peak_ratio);

    %% Score based on peak ratio similarity
    % Closer to 1.0 = better match

    if peak_ratio >= 0.8 && peak_ratio <= 1.2
        score = 1.0;  % Very close
    elseif peak_ratio >= 0.6 && peak_ratio <= 1.4
        score = 0.8;  % Close
    elseif peak_ratio >= 0.4 && peak_ratio <= 1.6
        score = 0.6;  % Moderate
    elseif peak_ratio >= 0.2 && peak_ratio <= 1.8
        score = 0.4;  % Far
    else
        score = 0.2;  % Very different
    end

    vis_data.final_score = score;

    fprintf('  Channel C Score: %.4f\n', score);

end
