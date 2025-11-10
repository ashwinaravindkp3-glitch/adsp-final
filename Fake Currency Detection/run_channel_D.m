function peak_count = run_channel_D(test_image, reference_image)
%run_channel_D Analyzes texture by counting significant Gabor peaks
%              relative to a reference note's average.

    % --- 1. Gabor Filter Analysis ---
   
   % --- 1. Convert to grayscale ---
    ref_gray = convertToGrayscale(reference_image);
    test_gray = convertToGrayscale(test_image);

    % --- 2. Define and apply Gabor filter (same as script) ---
    wavelength = 4;
    orientation = 90; % vertical
    g_vert = gabor(wavelength, orientation);

    gabor_mag_ref = abs(imfilter(im2double(ref_gray), g_vert.SpatialKernel, 'conv'));
    gabor_mag_test = abs(imfilter(im2double(test_gray), g_vert.SpatialKernel, 'conv'));

    % --- 3. Average plane (from REFERENCE only) ---
    average_plane_height = mean(gabor_mag_ref(:));

    % --- 4. Peak analysis on TEST image ---
    peaks_test = imregionalmax(gabor_mag_test);
    significant_peaks_mask = gabor_mag_test(peaks_test) > average_plane_height;
    peak_count = sum(significant_peaks_mask);

end
