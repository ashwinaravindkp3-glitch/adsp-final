% run_full_detector.m
% The final master script that runs the entire detection pipeline and makes a decision.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Starting Full Detection Pipeline ---');
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

% --- Define Weights and Thresholds ---
wA = 0.2; % Weight for Channel A (Template Matching)
wB = 0.4; % Weight for Channel B (Color/Pattern)
wC = 0.4; % Weight for Channel C (Texture)
FINAL_THRESHOLD = 0.65; % Final threshold for "Genuine" verdict
max_expected_texture_energy = 25; % A typical value for a genuine note, for normalization

ref_img = imread(ref_filename);

fprintf('\n--- Processing All Banknotes ---\n\n');

% --- 2. Loop Through and Analyze Each Case ---
for i = 1:length(all_filenames)
    fprintf('===== Analyzing: %s =====\n', case_names{i});
    
    % Step 1: Preprocessing
    if i == 1
        processed_img = ref_img;
    else
        disp('Preprocessing...');
        processed_img = warpImageAfterHomography(all_filenames{i}, ref_filename);
    end
    
    % Step 2: Run All Channels
    disp('Running detection channels...');
    
    % Run Channel A (Template Matching)
    scoreA = run_channel_A(processed_img);
    
    % Run Channel B (Color/Pattern)
    scoresB = run_channel_B(processed_img);
    scoreB = (scoresB.thread + scoresB.lines) / 2; % Average the two sub-scores
    
    % Run Channel C (Texture)
    scoreC_raw = analyzeTexture(processed_img);
    % Normalize the texture score to a 0-1 range
    scoreC = min(scoreC_raw / max_expected_texture_energy, 1.0); 
    
    % Step 3: Decision Fusion
    disp('Fusing scores...');
    final_score = (wA * scoreA) + (wB * scoreB) + (wC * scoreC);
    
    % Step 4: Final Verdict
    if final_score >= FINAL_THRESHOLD
        verdict = 'GENUINE';
    else
        verdict = 'COUNTERFEIT';
    end
    
    % Display Results for this note
    fprintf('--- Results for %s ---\n', case_names{i});
    fprintf('  Channel A (Templates): \t%.4f\n', scoreA);
    fprintf('  Channel B (Color/Pattern): \t%.4f\n', scoreB);
    fprintf('  Channel C (Texture): \t\t%.4f\n', scoreC);
    fprintf('  -----------------------------------\n');
    fprintf('  FINAL FUSED SCORE: \t\t%.4f\n', final_score);
    fprintf('  VERDICT: \t\t\t\t%s\n\n', verdict);
end


% --- LOCAL HELPER FUNCTIONS ---

function final_score_A = run_channel_A(processed_img)
    % A simplified version of our Channel A test script.
    final_processed_gray = normalizeIllumination(processed_img);
    template_files = {'template_verysmall_100.jpg','template_sathyam.png','template_pattern.jpg','template_kuthira.jpg','template_ashoka.png','template_ashoka.jpg','template_devanagiri.jpg','template_rbi_seal.jpg','template_small100.jpg'};
    detection_threshold = 0.6; 
    
    num_found = 0;
    for i = 1:length(template_files)
        template_gray = convertToGrayscale(imread(template_files{i}));
        correlation_map = performNCC(final_processed_gray, template_gray);
        [score, ~] = analyzeNCCResult(correlation_map, size(template_gray));
        if score >= detection_threshold
            num_found = num_found + 1;
        end
    end
    % The score is the ratio of templates found.
    final_score_A = num_found / length(template_files);
end

% Include your other local functions here (run_channel_B, analyzeTexture, warpImageAfterHomography, etc.)
% ...