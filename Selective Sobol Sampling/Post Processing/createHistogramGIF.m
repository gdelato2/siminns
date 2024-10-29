clear all

% Function to retrieve a dataset by name from the table
function dataToGet = getSet(name, gettingTable)
    % Determine if a specific set was requested (ends with "_" followed by an integer)
    if ~isempty(regexp(name, '_\d+$', 'once'))
        idx = strcmp(gettingTable.data_set, name); % Exact match
    else
        idx = contains(gettingTable.data_set, name); % Partial match
    end
    dataToGet = gettingTable(idx == 1, :); % Return matched data rows
end

% Load results data and setup basic parameters
path = '..\Results\Simple_23_10_2024_09_47_25\';
load([path, 'results.mat']) % Load results from MAT file
mainTitle = "Motivating Example: Comparison of Output Distributions";
graphLimits = [-6, 12]; % Limits for the graph axes

% Retrieve input and output names from the results structure
inputNames = resultsArray(1).model(1).inputNames;
outputNames = resultsArray(1).model(1).outputNames;

% Determine if scaling is needed for multiple outputs
scalePredictTesting = (length(outputNames) > 1);

% Get testing data from dataTable
testIdx = strcmp(dataTable.data_set, 'Testing');
dataTest = dataTable(testIdx == 1, :);

% Filter solved test cases, if 'solved' column exists
if ismember('solved', dataTest.Properties.VariableNames)
    solvedTestIdx = strcmp(dataTest.solved, 'True');
    dataTest = dataTest(solvedTestIdx, :);
end

% Extract input and output data from the test dataset
xTesting = table2array(dataTest(:, inputNames));
yTesting = table2array(dataTest(:, outputNames));

% Scale the testing outputs if required
if scalePredictTesting
    meanYTesting = mean(yTesting);
    stdYTesting = std(yTesting);
    yTesting = (yTesting - meanYTesting) ./ stdYTesting;
end

% Method indices and dataset names for different sampling techniques
%1. Selective Sobol Sampling
%2. Regular Sobol
%3. Warm Start Sobol
%4. Latin Hypercube
%5. Random
idxMeth = [1, 3, 4];
methodDataSetNames = ["selectiveSobolSampling_Training_",...
                        "regularSobol_Training_","regularSobol_Training_",...
                        "LHS_Training_", "Rand_Training_"];

% Ensure all methods have equal length
methodLengths = cellfun(@(x) length(resultsArray(x).model), num2cell(idxMeth));
if ~all(methodLengths == methodLengths(1))
    error('Error: Method lengths are not equal');
end

% Initialize parameters for GIF creation
gifFileName = [path, 'histogramComparison.gif'];
frameDelay = 2.0; % Delay between frames in seconds

% Loop through training samples to create the GIF
for i = 0:methodLengths(1)-1
    f = figure;
    f.Position = [100 100 1800 500]; % Set figure size
    tiles = tiledlayout(1, length(idxMeth), 'TileSpacing', 'compact', 'Padding', 'compact');
    tiles.Title.String = mainTitle;

    % Loop through each sampling method to plot histograms
    for j = 1:length(idxMeth)
        nexttile(tiles);

        % Gather data for the current method and training iteration
        if j < 4 % Sobols
            data = [];
            for ii = 0:i
                dataToGet = getSet(strcat(methodDataSetNames(j), num2str(ii)), dataTable);
                data = [data; dataToGet];
            end
        else %LHS and Rand
            data = getSet([methodDataSetNames(j), num2str(i)], dataTable);
        end

        % Extract output data and plot histogram
        outputs = data(:, outputNames);
        histogram(table2array(outputs), 25, 'Normalization', 'probability');
        grid on; box on; ylim([0, 1]);
        
        % Create title for each histogram
        titleString = [resultsArray(idxMeth(j)).name, ': ', ...
                       num2str(resultsArray(idxMeth(j)).data(i + 1).numTraining), ...
                       ' Training Samples'];
        title(titleString);
        xlabel('Output Value');
        if j == 1
            ylabel('Probability');
        end
    end

    % Capture and append the frame to the GIF
    frame = getframe(f);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);

    if i == 0
        imwrite(imind, cm, gifFileName, 'gif', 'Loopcount', inf, 'DelayTime', frameDelay);
    else
        imwrite(imind, cm, gifFileName, 'gif', 'WriteMode', 'append', 'DelayTime', frameDelay);
    end

    % Repeat the last frame multiple times to extend the GIF
    if i == methodLengths(1) - 1
        for k = 1:5
            imwrite(imind, cm, gifFileName, 'gif', 'WriteMode', 'append', 'DelayTime', frameDelay);
        end
    end

    close(f); % Close the figure after processing
end
