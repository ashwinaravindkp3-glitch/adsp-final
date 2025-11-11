function [verdict, final_score, all_vis_data] = detect_with_all_visualizations(test_image_path)
%detect_with_all_visualizations Complete detection with ALL visualization outputs
%
%   This function runs the entire detection pipeline and collects
%   ALL intermediate visualizations for display in the GUI.
%
%   Outputs:
%       verdict         - 'GENUINE' or 'COUNTERFEIT'
%       final_score     - Fused score (0 to 1)
%       all_vis_data    - Struct containing ALL visualization data

    fprintf('\n=== DETECTION WITH VISUALIZATIONS ===\n');

    % Configuration
    ref_scanner_path = 'ref_scanner.png';
    ref_camera_path = 'ref_camera.png';

    weight_A = 0.35;  % Template matching + sharpness
    weight_B = 0.45;  % Color quality analysis
    weight_C = 0.20;  % Print quality + halftone detection
    decision_threshold = 0.55;  % Lower threshold for robustness

    % Initialize output structure
    all_vis_data = struct();
    all_vis_data.config.weights = [weight_A, weight_B, weight_C];
    all_vis_data.config.threshold = decision_threshold;
    all_vis_data.config.test_image_path = test_image_path;
    all_vis_data.config.ref_scanner_path = ref_scanner_path;
    all_vis_data.config.ref_camera_path = ref_camera_path;

    try
        % ====================================================================
        % PHASE 1: PREPROCESSING
        % ====================================================================
        fprintf('\n--- PHASE 1: PREPROCESSING ---\n');

        [aligned_image, vis_preprocessing] = warpImageAfterHomography_withVis(...
            test_image_path, ref_scanner_path);

        all_vis_data.preprocessing = vis_preprocessing;
        fprintf('✓ Preprocessing complete\n');

        % ====================================================================
        % PHASE 2: CHANNEL A - TEMPLATE MATCHING (uses ref_scanner)
        % ====================================================================
        fprintf('\n--- PHASE 2: CHANNEL A ---\n');

        [score_A, vis_channel_A] = run_channel_A_withVis(aligned_image);

        all_vis_data.channel_A = vis_channel_A;
        all_vis_data.scores.channel_A = score_A;
        fprintf('✓ Channel A complete: Score = %.4f\n', score_A);

        % ====================================================================
        % PHASE 3: CHANNEL B - COLOR/STRUCTURE (uses ref_camera)
        % ====================================================================
        fprintf('\n--- PHASE 3: CHANNEL B ---\n');

        [score_B, vis_channel_B] = run_channel_B_withVis(aligned_image, ref_camera_path);

        all_vis_data.channel_B = vis_channel_B;
        all_vis_data.scores.channel_B = score_B;
        fprintf('✓ Channel B complete: Score = %.4f\n', score_B);

        % ====================================================================
        % PHASE 4: CHANNEL C - TEXTURE (uses ref_camera)
        % ====================================================================
        fprintf('\n--- PHASE 4: CHANNEL C ---\n');

        [score_C, vis_channel_C] = run_channel_C_withVis(aligned_image, ref_camera_path);

        all_vis_data.channel_C = vis_channel_C;
        all_vis_data.scores.channel_C = score_C;
        fprintf('✓ Channel C complete: Score = %.4f\n', score_C);

        % ====================================================================
        % PHASE 5: DECISION FUSION
        % ====================================================================
        fprintf('\n--- PHASE 5: DECISION FUSION ---\n');

        final_score = (weight_A * score_A) + (weight_B * score_B) + (weight_C * score_C);

        all_vis_data.fusion.individual_scores = [score_A, score_B, score_C];
        all_vis_data.fusion.weights = [weight_A, weight_B, weight_C];
        all_vis_data.fusion.weighted_contributions = [weight_A * score_A, ...
                                                       weight_B * score_B, ...
                                                       weight_C * score_C];
        all_vis_data.fusion.final_score = final_score;

        % Final verdict
        if final_score >= decision_threshold
            verdict = 'GENUINE';
        else
            verdict = 'COUNTERFEIT';
        end

        all_vis_data.fusion.verdict = verdict;

        fprintf('  Channel A contribution: %.4f\n', weight_A * score_A);
        fprintf('  Channel B contribution: %.4f\n', weight_B * score_B);
        fprintf('  Channel C contribution: %.4f\n', weight_C * score_C);
        fprintf('  Final Score: %.4f\n', final_score);
        fprintf('  Verdict: %s\n', verdict);

        all_vis_data.success = true;
        all_vis_data.error_message = '';

    catch ME
        % Error handling
        fprintf('\n❌ ERROR: %s\n', ME.message);

        verdict = 'ERROR';
        final_score = 0;
        all_vis_data.success = false;
        all_vis_data.error_message = ME.message;
    end

    fprintf('\n=== DETECTION COMPLETE ===\n\n');

end
