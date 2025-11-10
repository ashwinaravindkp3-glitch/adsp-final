function run_final_detector(test_image_path)
%run_final_detector Main counterfeit currency detector for Indian ₹100 note
%
%   Complete detection pipeline using classical signal processing (NO ML).
%
%   ARCHITECTURE:
%   1. Preprocessing: warpImageAfterHomography (orientation, scale, homography)
%   2. Channel A: Template Matching (NCC with histeq)
%   3. Channel B: Color/Structure (security thread, bleed lines)
%   4. Channel D: Gabor Texture (paper integrity)
%   5. Decision Fusion: Weighted average → Final Verdict
%
%   Usage:
%       run_final_detector('test_note_100_1.jpg')
%
%   Inputs:
%       test_image_path - Path to test currency image

    fprintf('\n');
    fprintf('╔═══════════════════════════════════════════════════════╗\n');
    fprintf('║  COUNTERFEIT CURRENCY DETECTOR - Indian ₹100 Note    ║\n');
    fprintf('║  Classical Signal Processing (NO Machine Learning)   ║\n');
    fprintf('╚═══════════════════════════════════════════════════════╝\n');
    fprintf('\n');

    % --- CONFIGURATION ---
    ref_image_path = 'ref_scanner.png';

    % Fusion weights
    weight_A = 0.40;  % Template Matching
    weight_B = 0.40;  % Color/Structure
    weight_D = 0.20;  % Gabor Texture

    % Decision threshold
    decision_threshold = 0.65;

    fprintf('Test Image: %s\n', test_image_path);
    fprintf('Reference:  %s\n\n', ref_image_path);

    % ========================================================================
    % STEP 1: PREPROCESSING PIPELINE
    % ========================================================================
    fprintf('║ STEP 1: PREPROCESSING\n');
    fprintf('╚════════════════════════════════════════════════════════\n');

    try
        aligned_image = warpImageAfterHomography(test_image_path, ref_image_path);
    catch ME
        fprintf('\n❌ ERROR in preprocessing: %s\n', ME.message);
        fprintf('Cannot proceed with detection.\n');
        return;
    end

    % ========================================================================
    % STEP 2: DETECTION CHANNELS
    % ========================================================================
    fprintf('\n');
    fprintf('║ STEP 2: DETECTION CHANNELS\n');
    fprintf('╚════════════════════════════════════════════════════════\n');

    % --- Channel A: Template Matching ---
    try
        score_A = run_channel_A(aligned_image);
    catch ME
        fprintf('❌ ERROR in Channel A: %s\n', ME.message);
        score_A = 0.0;
    end

    % --- Channel B: Color & Structure ---
    try
        score_B = run_channel_B(aligned_image);
    catch ME
        fprintf('❌ ERROR in Channel B: %s\n', ME.message);
        score_B = 0.0;
    end

    % --- Channel D: Gabor Texture ---
    try
        score_D = run_channel_D(aligned_image);
    catch ME
        fprintf('❌ ERROR in Channel D: %s\n', ME.message);
        score_D = 0.0;
    end

    % ========================================================================
    % STEP 3: DECISION FUSION
    % ========================================================================
    fprintf('\n');
    fprintf('║ STEP 3: DECISION FUSION\n');
    fprintf('╚════════════════════════════════════════════════════════\n');

    % Weighted fusion
    final_score = (weight_A * score_A) + (weight_B * score_B) + (weight_D * score_D);

    fprintf('  Fusion Weights:\n');
    fprintf('    Channel A (Templates):  %.0f%%\n', weight_A * 100);
    fprintf('    Channel B (Color):      %.0f%%\n', weight_B * 100);
    fprintf('    Channel D (Texture):    %.0f%%\n', weight_D * 100);
    fprintf('\n');

    % Final verdict
    if final_score >= decision_threshold
        verdict = 'GENUINE';
        verdict_symbol = '✓';
    else
        verdict = 'COUNTERFEIT';
        verdict_symbol = '✗';
    end

    % ========================================================================
    % FINAL REPORT
    % ========================================================================
    fprintf('\n');
    fprintf('╔═══════════════════════════════════════════════════════╗\n');
    fprintf('║                    FINAL REPORT                       ║\n');
    fprintf('╠═══════════════════════════════════════════════════════╣\n');
    fprintf('║  Channel A (Template Matching):  %.4f               ║\n', score_A);
    fprintf('║  Channel B (Color/Structure):    %.4f               ║\n', score_B);
    fprintf('║  Channel D (Gabor Texture):      %.4f               ║\n', score_D);
    fprintf('║                                                       ║\n');
    fprintf('║  FUSED SCORE:                    %.4f               ║\n', final_score);
    fprintf('║  Threshold:                      %.4f               ║\n', decision_threshold);
    fprintf('╠═══════════════════════════════════════════════════════╣\n');
    fprintf('║                                                       ║\n');
    fprintf('║  VERDICT: %-43s ║\n', [verdict_symbol ' ' verdict]);
    fprintf('║                                                       ║\n');
    fprintf('╚═══════════════════════════════════════════════════════╝\n');
    fprintf('\n');
end
