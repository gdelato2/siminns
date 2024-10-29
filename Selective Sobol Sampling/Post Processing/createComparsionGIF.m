clear all;

% Define the path and load results data
path = '..\Results\Simple_23_10_2024_09_47_25\';
load([path, 'results.mat']);

% Set plot title and limits
mainTitle = "Motivating Example: Comparison of Convergence Rates";
graphLimits = [-0.1, 1.1];

% Extract input and output names from the first model
inputNames = resultsArray(1).model(1).inputNames;
outputNames = resultsArray(1).model(1).outputNames;

% Check if there are multiple outputs to decide if scaling is needed
scalePredictTesting = length(outputNames) > 1;

% Extract testing data from dataTable
dataTest = dataTable(strcmp(dataTable.data_set, 'Testing'), :);

% If the 'solved' column exists, filter for solved tests
if ismember('solved', dataTest.Properties.VariableNames)
    dataTest = dataTest(strcmp(dataTest.solved, 'True'), :);
end

% Extract input and output data for testing
xTesting = table2array(dataTest(:, inputNames));
yTesting = table2array(dataTest(:, outputNames));

% Scale output data if necessary
if scalePredictTesting
    minYTesting = min(yTesting);
    maxYTesting = max(yTesting);
    yTesting = (yTesting - minYTesting) ./ (maxYTesting - minYTesting);
end

% Method indices and dataset names for different sampling techniques
%1. Selective Sobol Sampling
%2. Regular Sobol
%3. Warm Start Sobol
%4. Latin Hypercube
%5. Random
idxMeth = [1, 3, 4];

% Check that all methods have the same number of models
lengths = cellfun(@(x) length(resultsArray(x).model), num2cell(idxMeth));
if ~all(lengths == lengths(1))
    error('Inconsistent number of models between methods');
end

% Set up GIF parameters
gifFileName = [path, 'convergenceComparison.gif'];
frameDelay = 2.0; % Delay between frames in seconds

% Loop through models and create plots
for i = 1:lengths(1)
    % Create figure and layout
    f = figure;
    f.Position = [100 100 1800 500];
    tiles = tiledlayout(1, length(idxMeth), 'TileSpacing', 'compact', 'Padding', 'compact');
    tiles.Title.String = mainTitle;

    % Iterate over methods and generate plots
    for j = 1:length(idxMeth)
        nexttile(tiles)

        % Extract model parameters
        net = resultsArray(idxMeth(j)).model(i).net;
        meanX = resultsArray(idxMeth(j)).model(i).meanX;
        stdX = resultsArray(idxMeth(j)).model(i).stdX;
        meanY = resultsArray(idxMeth(j)).model(i).meanY;
        stdY = resultsArray(idxMeth(j)).model(i).stdY;

        % Make predictions with scaling if necessary
        yPredictTesting = net.predict((xTesting - meanX) ./ stdX) .* stdY + meanY;
        if scalePredictTesting
            yPredictTesting = (yPredictTesting - minYTesting) ./ (maxYTesting - minYTesting);
        end

        % Plot predictions vs truth
        plot([-100, 100], [-100, 100], 'k--');
        hold on;
        scatter(yTesting, yPredictTesting, 'filled', 'SizeData', 5);
        grid on; box on;
        
        % Add title and labels
        title([resultsArray(idxMeth(j)).name, ': ', num2str(resultsArray(idxMeth(j)).data(i).numTraining), ' Training Samples']);
        xlabel('Surrogate Model Predictions');
        xlim(graphLimits); ylim(graphLimits);

        if j == 1
            ylabel('Truth Model');
        end
    end

    % Format legend
    legendOutputNames = strrep(['Ideal Fit', outputNames], '_', ' ');
    legendOutputNames = regexprep(legendOutputNames, '\<(\w)', '${upper($1)}');
    legendHandle = legend(legendOutputNames);
    legendHandle.Layout.Tile = 'East';

    % Capture frame for GIF
    frame = getframe(f);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);

    % Write frames to GIF
    if i == 1
        imwrite(imind, cm, gifFileName, 'gif', 'Loopcount', inf, 'DelayTime', frameDelay);
    else
        imwrite(imind, cm, gifFileName, 'gif', 'WriteMode', 'append', 'DelayTime', frameDelay);
    end

    % Add a delay at the end of the GIF
    if i == lengths(1)
        for k = 1:5
            imwrite(imind, cm, gifFileName, 'gif', 'WriteMode', 'append', 'DelayTime', frameDelay);
        end
    end

    close(f);    
end
