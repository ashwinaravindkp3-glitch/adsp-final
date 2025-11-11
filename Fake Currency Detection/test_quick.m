% Quick test of the redesigned detection system
fprintf('===== TESTING REDESIGNED DETECTION SYSTEM =====\n\n');

test_images = {
    'test_note_100_1.jpg', 'GENUINE';
    'test_note_100_2.jpg', 'GENUINE';
    'test_note_fake_colour.jpg', 'FAKE';
    'test_note_fake_1.jpg', 'FAKE';
};

results = {};

for i = 1:size(test_images, 1)
    img_path = test_images{i, 1};
    expected = test_images{i, 2};

    fprintf('\n--- Testing: %s (Expected: %s) ---\n', img_path, expected);

    try
        [verdict, score, vis_data] = detect_with_all_visualizations(img_path);

        % Check if verdict matches expected
        correct = strcmp(verdict, expected);
        status = 'PASS';
        if ~correct
            status = 'FAIL';
        end

        fprintf('  Result: %s (Score: %.4f) [%s]\n', verdict, score, status);
        fprintf('  Channels: A=%.4f, B=%.4f, C=%.4f\n', ...
            vis_data.scores.channel_A, vis_data.scores.channel_B, vis_data.scores.channel_C);

        results{end+1} = struct('image', img_path, 'expected', expected, ...
            'verdict', verdict, 'score', score, 'correct', correct);
    catch ME
        fprintf('  ERROR: %s\n', ME.message);
        results{end+1} = struct('image', img_path, 'expected', expected, ...
            'verdict', 'ERROR', 'score', 0, 'correct', false);
    end
end

% Summary
fprintf('\n\n===== SUMMARY =====\n');
correct_count = 0;
for i = 1:length(results)
    if results{i}.correct
        correct_count = correct_count + 1;
        status_str = '✓ PASS';
    else
        status_str = '✗ FAIL';
    end
    fprintf('%s: %s → %s [%s]\n', status_str, results{i}.image, results{i}.verdict, results{i}.expected);
end

fprintf('\nAccuracy: %d/%d (%.1f%%)\n', correct_count, length(results), 100*correct_count/length(results));
