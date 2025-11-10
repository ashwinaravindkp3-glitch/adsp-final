% run_full_channel_A_test.m
% A script to run the full preprocessing and Channel A template matching
% on the complete set of real and fake notes.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Starting Full Channel A Test Suite ---');

% Define all image filenames
ref_filename = 'reference_note_100.png';
all_filenames = {
    'reference_note_100.png', ...
    'test_note_100_1.jpg', ...
    'test_note_100_2.jpg', ...
    'test_note_fake_colour.jpg', ...
    'test_note_fake_1.jpg', ...
    'test_note_fake_2.jpg'
};
case_names = {
    'Reference', 'Real Photo 1', 'Real Photo 2', ...
    'Fake (Photostat)', 'Fake (Edited 1)', 'Fake (Edited 2)'
};

% Define all the templates we want to search for.
template_files = {'template_ashoka.jpg','template_rbi_seal.jpg','template_devanagiri.jpg','template_small100.jpg'};
detection_threshold = 0.6; % A reasonably strict threshold

ref_img = imread(ref_filename);

fprintf('\n--- Processing All Banknotes ---\n\n');

% --- 2. Loop Through and Analyze Each Case ---
for i = 1:length(all_filenames)
    current_filename = all_filenames{i};
    current_casename = case_names{i};
    
    fprintf('===== Analyzing: %s =====\n', current_casename);
    
    % Step A: Preprocessing
    if i == 1 % The reference image doesn't need preprocessing
        processed_img = ref_img;
    else
        disp('Preprocessing...');
        % Use our robust, external helper function for alignment
        processed_img = warpImageAfterHomography(current_filename, ref_filename);
    end
    
    % Step B: Illumination Normalization
    final_processed_gray = normalizeIllumination(processed_img);
    
    % Step C: Run Channel A Template Matching
    disp('Running Channel A...');
    
    % Create a new figure for this specific case
    figure('Name', ['Channel A Results: ', current_casename], 'WindowState', 'maximized');
    imshow(final_processed_gray);
    hold on;
    title(['Detected Features for ', current_casename]);
    
    num_found = 0;
    for j = 1:length(template_files)
        template_name = template_files{j};
        
        % Load the template (do not preprocess it)
        template_gray = convertToGrayscale(imread(template_name));
        
        % Perform detection
        correlation_map = performNCC(final_processed_gray, template_gray);
        [score, location] = analyzeNCCResult(correlation_map, size(template_gray));
        
        % Draw bounding box on the image
        bbox = [location, size(template_gray, 2), size(template_gray, 1)];
        if score >= detection_threshold
            rectangle('Position', bbox, 'EdgeColor', 'g', 'LineWidth', 2);
            num_found = num_found + 1;
        else
            rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2);
        end
    end
    hold off;
    
    % Print a summary for this note
    fprintf('>>> %s: Found %d out of %d templates.\n\n', current_casename, num_found, length(template_files));
end

disp('--- Full Test Suite Complete ---');