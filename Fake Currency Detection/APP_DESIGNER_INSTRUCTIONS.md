# How to Create App Designer GUI
## Alternative to SimpleCurrencyGUI.m

If you want to use MATLAB App Designer instead of the figure-based GUI, follow these steps:

---

## Option 1: Use Provided Figure-Based GUI (EASIEST)

**Just run:**
```matlab
SimpleCurrencyGUI
```

This works immediately - no App Designer needed!

---

## Option 2: Create in App Designer (If Required)

### Step 1: Open App Designer
```matlab
appdesigner
```

### Step 2: Create New Blank App
- Click "Blank App"
- Name it: `CurrencyDetectorApp`

### Step 3: Design Layout

#### Add Components:

**Buttons:**
1. **Upload Button**
   - Text: "Upload Test Image"
   - Tag: `btnUpload`
   - Callback: `btnUploadPushed`

2. **Detect Button**
   - Text: "RUN DETECTION"
   - Tag: `btnDetect`
   - Callback: `btnDetectPushed`
   - BackgroundColor: Green
   - FontWeight: Bold

**Labels:**
1. **Path Label**
   - Tag: `lblPath`
   - Text: "No image loaded"

2. **Verdict Label**
   - Tag: `lblVerdict`
   - Text: "AWAITING INPUT"
   - FontSize: 20
   - FontWeight: Bold

**Tab Group:**
1. Create `uitabgroup` named `tabGroup`
2. Add 5 tabs:
   - Tab 1: "PREPROCESSING"
   - Tab 2: "CHANNEL A"
   - Tab 3: "CHANNEL B"
   - Tab 4: "CHANNEL D"
   - Tab 5: "RESULTS"

**Axes:**
- Add `uiaxes` in each tab for visualizations
- Name them systematically: `ax1_1`, `ax1_2`, etc.

### Step 4: Add Properties

In Code View, add to properties section:

```matlab
properties (Access = private)
    test_image_path = '';
    vis_data = [];
end
```

### Step 5: Add Callbacks

#### Upload Callback:
```matlab
function btnUploadPushed(app, event)
    [file, path] = uigetfile({'*.jpg;*.jpeg;*.png'}, 'Select Image');
    if file ~= 0
        app.test_image_path = fullfile(path, file);
        app.lblPath.Text = ['Loaded: ' file];
        app.lblVerdict.Text = 'READY';
        app.lblVerdict.FontColor = [0 0 1];
    end
end
```

#### Detect Callback:
```matlab
function btnDetectPushed(app, event)
    if isempty(app.test_image_path)
        uialert(app.UIFigure, 'Please upload image!', 'Error');
        return;
    end

    % Show progress
    d = uiprogressdlg(app.UIFigure, 'Title', 'Processing...', ...
                      'Indeterminate', 'on');

    try
        % Run detection
        [verdict, score, vis_data] = detect_with_all_visualizations(app.test_image_path);

        app.vis_data = vis_data;

        % Update verdict
        if strcmp(verdict, 'GENUINE')
            app.lblVerdict.Text = sprintf('✓ GENUINE (%.3f)', score);
            app.lblVerdict.FontColor = [0 0.6 0];
        else
            app.lblVerdict.Text = sprintf('✗ COUNTERFEIT (%.3f)', score);
            app.lblVerdict.FontColor = [1 0 0];
        end

        % Update visualizations
        updateVisualization(app);

        close(d);

    catch ME
        close(d);
        uialert(app.UIFigure, ME.message, 'Error');
    end
end
```

#### Visualization Update:
```matlab
function updateVisualization(app)
    if isempty(app.vis_data)
        return;
    end

    vis = app.vis_data;

    % Tab 1: Preprocessing
    try
        imshow(vis.preprocessing.step1_original, 'Parent', app.ax1_1);
        imshow(vis.preprocessing.step2_rotated, 'Parent', app.ax1_2);
        imshow(vis.preprocessing.step3_resized, 'Parent', app.ax1_3);
        imshow(vis.preprocessing.step4_gray_test, 'Parent', app.ax1_4);

        axes(app.ax1_5);
        imshow(vis.preprocessing.step4_gray_test);
        hold on;
        plot(vis.preprocessing.step7_matched_test.Location(:,1), ...
             vis.preprocessing.step7_matched_test.Location(:,2), 'g+');
        title(sprintf('%d feature matches', vis.preprocessing.step7_match_count));
        hold off;

        imshow(vis.preprocessing.step9_aligned, 'Parent', app.ax1_6);
    catch
    end

    % Tab 2: Channel A
    try
        imshow(vis.channel_A.step1_illumination_normalized, 'Parent', app.ax2_1);
        imshow(vis.channel_A.step2_histeq, 'Parent', app.ax2_2);

        if ~isempty(vis.channel_A.templates{1})
            imshow(vis.channel_A.templates{1}, 'Parent', app.ax2_3);
        end

        if ~isempty(vis.channel_A.correlation_maps{1})
            imagesc(vis.channel_A.correlation_maps{1}, 'Parent', app.ax2_4);
            colorbar(app.ax2_4);
        end
    catch
    end

    % Tab 3: Channel B
    try
        imshow(vis.channel_B.method1_thread.roi_image, 'Parent', app.ax3_1);
        imagesc(vis.channel_B.method1_thread.lab_a, 'Parent', app.ax3_2);
        colorbar(app.ax3_2);

        imshow(vis.channel_B.method2_lines.roi_left_image, [], 'Parent', app.ax3_3);

        axes(app.ax3_4);
        plot(vis.channel_B.method2_lines.right_analysis.projection_inverted);
        hold on;
        plot(vis.channel_B.method2_lines.right_analysis.peak_locations, ...
             vis.channel_B.method2_lines.right_analysis.peaks, 'ro');
        hold off;
    catch
    end

    % Tab 4: Channel D
    try
        imshow(vis.channel_D.step1_grayscale, 'Parent', app.ax4_1);
        imagesc(vis.channel_D.step3_gabor_magnitude, 'Parent', app.ax4_2);
        colorbar(app.ax4_2);
        imshow(vis.channel_D.step4_peaks_mask, 'Parent', app.ax4_3);
        imshow(vis.channel_D.step5_significant_peaks_mask, 'Parent', app.ax4_4);
    catch
    end

    % Tab 5: Results
    try
        axes(app.ax5_1);
        scores = [vis.scores.channel_A, vis.scores.channel_B, vis.scores.channel_D];
        bar(scores);
        set(gca, 'XTickLabel', {'A', 'B', 'D'});
        ylim([0 1]);
        title('Channel Scores');

        axes(app.ax5_2);
        pie(vis.fusion.weighted_contributions);
        title(sprintf('Score: %.3f - %s', vis.fusion.final_score, vis.fusion.verdict));
    catch
    end
end
```

### Step 6: Save and Run
- Save as: `CurrencyDetectorApp.mlapp`
- Click "Run" button in App Designer

---

## ⚡ Quick Comparison

| Feature | SimpleCurrencyGUI | App Designer |
|---------|-------------------|--------------|
| **Setup Time** | 0 seconds | 30-60 minutes |
| **Ease of Use** | Very Easy | Moderate |
| **Customization** | Code-based | Visual drag-drop |
| **Deployment** | Just run .m file | Requires .mlapp |
| **Best For** | Quick demo, testing | Polished final product |

---

## 🎯 Recommendation

**For your 24-hour deadline:**

✅ **Use `SimpleCurrencyGUI.m`** - It works NOW and shows all visualizations

❌ **Don't spend time on App Designer** - Not worth the time investment

---

## 🚀 To Present Tomorrow:

1. Open MATLAB
2. Navigate to folder: `cd 'Fake Currency Detection'`
3. Run: `SimpleCurrencyGUI`
4. Upload test image
5. Click "RUN DETECTION"
6. Show professor all 5 tabs with visualizations
7. Explain each processing step

**Done!** ✓

---

## If Professor Specifically Requires App Designer:

Tell them:
- "I have a fully functional GUI using MATLAB figures"
- "All visualizations are working"
- "Can be converted to App Designer if needed"
- "Current version shows all required processing steps"

The functionality is identical - only the creation method differs.

---

## 💡 Pro Tip

The `SimpleCurrencyGUI.m` actually provides BETTER visualization flexibility than App Designer for image processing applications, as you have direct control over axes and can easily add custom visualizations.

**Focus on content, not packaging!**
