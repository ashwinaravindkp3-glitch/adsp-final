% test_batch.m
% Batch test script for counterfeit currency detector
%
% This script tests the detector on multiple genuine and fake notes
% to validate the system performance.

clear; clc; close all;

fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('     BATCH TESTING - Counterfeit Currency Detector\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('\n');

% --- Test Cases ---
test_cases = {
    % Filename, Expected Label
    'test_note_100_1.jpg', 'GENUINE';
    'test_note_100_2.jpg', 'GENUINE';
    'test_note_100_3.jpg', 'GENUINE';
    'test_note_fake_1.jpg', 'COUNTERFEIT';
    'test_note_fake_2.jpg', 'COUNTERFEIT';
    'test_note_fake_3.jpg', 'COUNTERFEIT';
    'test_note_fake_colour.jpg', 'COUNTERFEIT';
};

num_tests = size(test_cases, 1);
results = cell(num_tests, 5);  % Store: filename, expected, actual, scores, correct?

% --- Run Tests ---
for i = 1:num_tests
    filename = test_cases{i, 1};
    expected = test_cases{i, 2};

    fprintf('\n');
    fprintf('───────────────────────────────────────────────────────────\n');
    fprintf('Test %d/%d: %s\n', i, num_tests, filename);
    fprintf('Expected: %s\n', expected);
    fprintf('───────────────────────────────────────────────────────────\n');

    try
        % Check if file exists
        if ~exist(filename, 'file')
            fprintf('❌ ERROR: File not found: %s\n', filename);
            results{i, 1} = filename;
            results{i, 2} = expected;
            results{i, 3} = 'ERROR';
            results{i, 4} = [0, 0, 0];
            results{i, 5} = false;
            continue;
        end

        % Run detector (capture output)
        [actual, scores] = run_detector_silent(filename);

        % Store results
        results{i, 1} = filename;
        results{i, 2} = expected;
        results{i, 3} = actual;
        results{i, 4} = scores;
        results{i, 5} = strcmp(expected, actual);

        % Print result
        if strcmp(expected, actual)
            fprintf('✓ CORRECT: Detected as %s\n', actual);
        else
            fprintf('✗ INCORRECT: Detected as %s (Expected: %s)\n', actual, expected);
        end

    catch ME
        fprintf('❌ ERROR: %s\n', ME.message);
        results{i, 1} = filename;
        results{i, 2} = expected;
        results{i, 3} = 'ERROR';
        results{i, 4} = [0, 0, 0];
        results{i, 5} = false;
    end
end

% --- Summary Report ---
fprintf('\n\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('                      SUMMARY REPORT\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('\n');

fprintf('%-30s | %-12s | %-12s | %s\n', 'Filename', 'Expected', 'Detected', 'Result');
fprintf('──────────────────────────────────────────────────────────────────────\n');

correct_count = 0;
for i = 1:num_tests
    filename = results{i, 1};
    expected = results{i, 2};
    actual = results{i, 3};
    is_correct = results{i, 5};

    if is_correct
        result_str = '✓';
        correct_count = correct_count + 1;
    else
        result_str = '✗';
    end

    fprintf('%-30s | %-12s | %-12s | %s\n', filename, expected, actual, result_str);
end

fprintf('──────────────────────────────────────────────────────────────────────\n');
fprintf('\n');
fprintf('Accuracy: %d/%d (%.1f%%)\n', correct_count, num_tests, (correct_count/num_tests)*100);
fprintf('\n');


% ============================================================================
% HELPER FUNCTION: Silent Detector
% ============================================================================
function [verdict, scores] = run_detector_silent(test_image_path)
%run_detector_silent Runs detector and returns verdict + scores without full output

    ref_image_path = 'ref_scanner.png';

    weight_A = 0.40;
    weight_B = 0.40;
    weight_D = 0.20;
    decision_threshold = 0.65;

    % Preprocessing
    aligned_image = warpImageAfterHomography(test_image_path, ref_image_path);

    % Run channels
    score_A = run_channel_A(aligned_image);
    score_B = run_channel_B(aligned_image);
    score_D = run_channel_D(aligned_image);

    % Fusion
    final_score = (weight_A * score_A) + (weight_B * score_B) + (weight_D * score_D);

    % Verdict
    if final_score >= decision_threshold
        verdict = 'GENUINE';
    else
        verdict = 'COUNTERFEIT';
    end

    scores = [score_A, score_B, score_D, final_score];
end
