% Held-out LOOCV LASSO analysis for predicting DeltaYGTSS.
% Predictors: ALFF_sti_Pre, distance, FC_Pre_R4, ALFF_LGPi_Pre.

clear; clc; close all;
rng(20260625, 'twister');

%% 1. Load data
script_dir = fileparts(mfilename('fullpath'));
input_file = fullfile(script_dir, 'regreesion_test.xlsx');
if ~isfile(input_file)
    input_file = 'regreesion_test.xlsx';
end
if ~isfile(input_file)
    error('Input file not found. Put regreesion_test.xlsx in the script folder or the current MATLAB folder.');
end

data = readtable(input_file);

required_vars = {'TMSgroup', 'DeltaYGTSS', 'ALFF_sti_Pre', ...
    'distance', 'FC_Pre_R4', 'ALFF_LGPi_Pre'};
missing_vars = setdiff(required_vars, data.Properties.VariableNames);
if ~isempty(missing_vars)
    error('Missing required variable(s): %s', strjoin(missing_vars, ', '));
end

target_group = 2;
group_data = data(data.TMSgroup == target_group, :);
fprintf('Group code: %d\n', target_group);
fprintf('Raw sample size: %d\n', height(group_data));

%% 2. Extract response and predictors
Y = group_data.DeltaYGTSS;

X = [
    group_data.ALFF_sti_Pre, ...
    group_data.distance, ...
    group_data.FC_Pre_R4, ...
    group_data.ALFF_LGPi_Pre
];

var_names = {'ALFF_sti_Pre', 'distance', 'FC_Pre_R4', 'ALFF_LGPi_Pre'};
var_labels = {'ALFF\_sti\_Pre', 'distance', 'FC\_Pre\_R4', 'ALFF\_LGPi\_Pre'};

%% 3. Remove missing values
valid_idx = ~any(isnan([Y, X]), 2);
Y = Y(valid_idx);
X = X(valid_idx, :);

n = numel(Y);
p = size(X, 2);

if n < 4
    error('At least 4 complete observations are recommended for this LOOCV LASSO workflow.');
end

fprintf('Complete-case sample size: %d\n', n);
fprintf('Number of predictors: %d\n', p);

%% 4. Held-out LOOCV prediction
Y_pred_loocv = nan(n, 1);
lambda_loocv = nan(n, 1);
B_loocv = nan(p, n);
intercept_loocv = nan(n, 1);
selected_loocv = false(p, n);

fprintf('\n=== Held-out LOOCV LASSO prediction ===\n');
for test_idx = 1:n
    train_idx = true(n, 1);
    train_idx(test_idx) = false;

    X_train_raw = X(train_idx, :);
    X_test_raw = X(test_idx, :);
    Y_train = Y(train_idx);

    mu_X = mean(X_train_raw, 1);
    sd_X = std(X_train_raw, 0, 1);
    sd_X(sd_X == 0) = 1;

    X_train = (X_train_raw - mu_X) ./ sd_X;
    X_test = (X_test_raw - mu_X) ./ sd_X;

    Y_train_mean = mean(Y_train);
    Y_train_center = Y_train - Y_train_mean;

    [B_fold_all, FitInfo_fold] = lasso(X_train, Y_train_center, ...
        'CV', sum(train_idx), 'Standardize', false);
    idx_lambda = FitInfo_fold.IndexMinMSE;

    beta_fold = B_fold_all(:, idx_lambda);
    intercept_fold = FitInfo_fold.Intercept(idx_lambda);

    Y_pred_loocv(test_idx) = X_test * beta_fold + intercept_fold + Y_train_mean;
    lambda_loocv(test_idx) = FitInfo_fold.Lambda(idx_lambda);
    B_loocv(:, test_idx) = beta_fold;
    intercept_loocv(test_idx) = intercept_fold;
    selected_loocv(:, test_idx) = abs(beta_fold) > 1e-10;
end

SST = sum((Y - mean(Y)).^2);
SSE_loocv = sum((Y - Y_pred_loocv).^2);
R2_loocv = 1 - SSE_loocv / SST;
MSE_loocv = mean((Y - Y_pred_loocv).^2);
RMSE_loocv = sqrt(MSE_loocv);
[r_loocv, p_loocv] = corr(Y, Y_pred_loocv, 'Rows', 'complete', 'Type', 'Pearson');

selection_frequency = mean(selected_loocv, 2);
mean_beta = mean(B_loocv, 2);
sd_beta = std(B_loocv, 0, 2);

fprintf('Held-out LOOCV R2 = %.6f\n', R2_loocv);
fprintf('Held-out LOOCV MSE = %.6f\n', MSE_loocv);
fprintf('Held-out LOOCV RMSE = %.6f\n', RMSE_loocv);
fprintf('Held-out LOOCV Pearson r = %.6f, p = %.6f\n', r_loocv, p_loocv);

fprintf('\n=== LOOCV variable selection frequency ===\n');
for i = 1:p
    fprintf('%s: %.2f%%\n', var_names{i}, 100 * selection_frequency(i));
end

%% 5. Figure settings
fig_height_cm = 2.5;
fig_width_cm = 4.0;
fs = 6;
fname = 'Arial';
lw_axis = 0.5;
lw_line = 0.75;
ms = 3;

make_fig = @(w_cm, h_cm) figure('Units', 'centimeters', ...
    'Position', [2, 2, w_cm, h_cm], ...
    'PaperUnits', 'centimeters', ...
    'PaperSize', [w_cm, h_cm], ...
    'PaperPosition', [0, 0, w_cm, h_cm], ...
    'Color', 'w');

fig_handles = gobjects(3, 1);

%% 6. Held-out predicted vs actual scatter plot
fig_handles(1) = make_fig(fig_height_cm, fig_height_cm);
point_size = 8;
scatter(Y, Y_pred_loocv, point_size, 'filled', ...
    'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerFaceAlpha', 0.6);
hold on;
min_val = min([Y; Y_pred_loocv]);
max_val = max([Y; Y_pred_loocv]);
plot([min_val, max_val], [min_val, max_val], 'r--', 'LineWidth', lw_line);
set(gca, 'LineWidth', lw_axis, 'FontSize', fs, 'FontName', fname);
set(gca, 'TickDir', 'out', 'TickLength', [0.03 0.03]);
box off;
xlabel('Actual {\Delta}YGTSS', 'FontSize', fs, 'FontName', fname);
ylabel('LOOCV predicted {\Delta}YGTSS', 'FontSize', fs, 'FontName', fname);
axis equal;
xlim([min_val, max_val]);
ylim([min_val, max_val]);
text(0.05, 0.95, sprintf('r = %.2f', r_loocv), ...
    'Units', 'normalized', 'FontSize', fs, 'FontName', fname, ...
    'VerticalAlignment', 'top');

%% 7. Mean LOOCV coefficients
fig_handles(2) = make_fig(fig_width_cm, fig_height_cm);
bar(mean_beta, 'FaceColor', [0.3, 0.5, 0.8], 'EdgeColor', 'none', 'BarWidth', 0.7);
hold on;
errorbar(1:p, mean_beta, sd_beta, 'k.', 'LineWidth', 0.5, 'CapSize', 2);
yline(0, 'k-', 'LineWidth', lw_axis);
set(gca, 'XTick', 1:p, 'XTickLabel', var_labels, 'XTickLabelRotation', 45);
set(gca, 'LineWidth', lw_axis, 'FontSize', fs, 'FontName', fname);
set(gca, 'TickDir', 'out', 'TickLength', [0.02 0.02]);
box off;
ylabel('Mean std. coef.', 'FontSize', fs, 'FontName', fname);

%% 8. LOOCV selection frequency
fig_handles(3) = make_fig(fig_width_cm, fig_height_cm);
bar(100 * selection_frequency, 'FaceColor', [0.2, 0.6, 0.4], ...
    'EdgeColor', 'none', 'BarWidth', 0.7);
ylim([0, 100]);
set(gca, 'XTick', 1:p, 'XTickLabel', var_labels, 'XTickLabelRotation', 45);
set(gca, 'LineWidth', lw_axis, 'FontSize', fs, 'FontName', fname);
set(gca, 'TickDir', 'out', 'TickLength', [0.02 0.02]);
box off;
ylabel('Selection (%)', 'FontSize', fs, 'FontName', fname);

%% 9. Save figures and result files
figure_names = {'LASSO_LOOCV_prediction', 'LASSO_LOOCV_mean_coefficients', ...
    'LASSO_LOOCV_selection_frequency'};
for k = 1:numel(fig_handles)
    set(fig_handles(k), 'Renderer', 'painters');
    print(fig_handles(k), [figure_names{k} '.svg'], '-dsvg', '-painters');
end

coefficient_table = table(var_names', mean_beta, sd_beta, selection_frequency, ...
    'VariableNames', {'Variable', 'MeanCoefficient', 'SDCoefficient', 'SelectionFrequency'});
writetable(coefficient_table, 'LASSO_LOOCV_coefficients.xlsx');

prediction_table = table(Y, Y_pred_loocv, ...
    'VariableNames', {'Actual_DeltaYGTSS', 'Predicted_LOOCV'});
writetable(prediction_table, 'LASSO_LOOCV_predictions.xlsx');

save('LASSO_LOOCV_results.mat', 'Y', 'X', 'var_names', 'R2_loocv', ...
    'MSE_loocv', 'RMSE_loocv', 'r_loocv', 'p_loocv', 'Y_pred_loocv', ...
    'lambda_loocv', 'B_loocv', 'intercept_loocv', 'selected_loocv', ...
    'selection_frequency', 'mean_beta', 'sd_beta');

fprintf('\n=== Analysis complete ===\n');
fprintf('- LASSO_LOOCV_prediction.svg\n');
fprintf('- LASSO_LOOCV_mean_coefficients.svg\n');
fprintf('- LASSO_LOOCV_selection_frequency.svg\n');
fprintf('- LASSO_LOOCV_results.mat\n');
fprintf('- LASSO_LOOCV_coefficients.xlsx\n');
fprintf('- LASSO_LOOCV_predictions.xlsx\n');
