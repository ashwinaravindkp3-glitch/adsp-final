% Quick test of the advanced detection system
fprintf('Testing with test_note_fake_colour.jpg (photocopy)...\n\n');

[verdict, score, vis_data] = detect_with_all_visualizations('test_note_fake_colour.jpg');

fprintf('\n=== RESULTS ===\n');
fprintf('Verdict: %s\n', verdict);
fprintf('Final Score: %.4f\n', score);
fprintf('Channel A: %.4f\n', vis_data.scores.channel_A);
fprintf('Channel B: %.4f\n', vis_data.scores.channel_B);
fprintf('Channel C: %.4f\n', vis_data.scores.channel_C);
fprintf('\nThreshold: 0.65 (scores >= 0.65 = GENUINE, < 0.65 = COUNTERFEIT)\n');
