% load MLP parameters
addpath("../Surrogate Models")
load('../Surrogate Models/small_model.mat');

% load input samples
train_inputs = table2array(readtable('..\Data Sets\small\train_smallWaterPumpingNetworkInputs.csv'));
vald_inputs = table2array(readtable('..\Data Sets\small\vald_smallWaterPumpingNetworkInputs.csv'));
test_inputs = table2array(readtable('..\Data Sets\small\test_smallWaterPumpingNetworkInputs.csv'));

% run predictions
train_prediction = small_scale_inference(train_inputs',parameter_small_mlp);
vald_prediction = small_scale_inference(vald_inputs',parameter_small_mlp);
test_prediction = small_scale_inference(test_inputs',parameter_small_mlp);

% load output samples
train_outputs = table2array(readtable('..\Data Sets\small\train_smallWaterPumpingNetworkOutputs.csv'));
vald_outputs = table2array(readtable('..\Data Sets\small\vald_smallWaterPumpingNetworkOutputs.csv'));
test_outputs = table2array(readtable('..\Data Sets\small\test_smallWaterPumpingNetworkOutputs.csv'));

% determine which columns to compare
columnsCompare = 4:3:size(test_outputs,2);
train_outputs = train_outputs(:,columnsCompare);
vald_outputs = vald_outputs(:,columnsCompare);
test_outputs = test_outputs(:,columnsCompare);
train_prediction = train_prediction(:,columnsCompare);
vald_prediction = vald_prediction(:,columnsCompare);
test_prediction = test_prediction(:,columnsCompare);

% find min and max
min_ = min([train_outputs(:);vald_outputs(:);test_outputs(:)])
max_ = max([train_outputs(:);vald_outputs(:);test_outputs(:)])

% compute errors
train_errors = train_outputs - train_prediction;
vald_errors = vald_outputs - vald_prediction;
test_errors = test_outputs- test_prediction;

% compute mean and std
train_errors = train_errors(:);
train_std = std(train_errors);
train_mean = mean(train_errors);
vald_errors = vald_errors(:);
vald_std = std(vald_errors);
vald_mean = mean(vald_errors);
test_errors = test_errors(:);
test_std = std(test_errors);
test_mean = mean(test_errors);

% create figure
fig = figure;
hold on
% customize the plot as needed
title('Small-Scale System: Pump Power Predictions at Lines 1 through 4','FontSize',18);
ylabel('Physics-Based Pump Power (W)','FontSize',18);
xlabel('Surrogate Prediction Pump Power (W)','FontSize',18);
scatter(train_prediction(:),train_outputs(:), 5, 'k', 'filled')
scatter(vald_prediction(:),vald_outputs(:), 5,'b','filled')
scatter(test_prediction(:),test_outputs(:), 5,'r', 'filled')
plot([-675,-250],[-675,-250],'k--')
legend(['Train (error mean = ' num2str(round(train_mean,2)) ' (W), error std = ', num2str(round(train_std,2)),' (W))'],...
    ['Validate (error mean = ' num2str(round(vald_mean,2)) ' (W), error std = ', num2str(round(vald_std,2)),' (W))'],...
    ['Test (error mean = ' num2str(round(test_mean,2)) ' (W), error std = ', num2str(round(test_std,2)),' (W))'],...
    ['Perfect Prediction Reference, x=y'],...
    'FontSize',18,'Location','NorthWest');
hAx = gca;
hAx.XAxis.FontSize = 18;
hAx.YAxis.FontSize = 18;
grid on
box on