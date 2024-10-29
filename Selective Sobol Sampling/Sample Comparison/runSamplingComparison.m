%runSamplingComparison
% 
%   This function performs a comparative analysis of different sampling strategies 
%   (e.g., random sampling, Latin Hypercube Sampling, Sobol sampling) for training 
%   a surrogate model. It supports cold and warm starts and selective Sobol sampling.
%
% Inputs:
%   - modelName:             String, name of the model for file naming.
%   - inputSamplingNames:    Cell array of strings, names of the input features.
%   - modelSamplingNames:    Cell array of strings, names of model outputs/features.
%   - inputSurrogateNames:   Cell array of strings, surrogate model input feature names.
%   - outputSurrogateNames:  Cell array of strings, surrogate model output feature names.
%   - modelFunction:         Handle, function to compute outputs given inputs.
%   - scalingFunction:       Handle, function used for scaling inputs/outputs.
%   - varargin:              Additional optional parameters like sampling settings and model training parameters.
%
% Outputs:
%   - Generates and stores results of different sampling strategies.
%   - Saves results as .fig, .png, and .mat files in a folder with a timestamp.
%
function runSamplingComparison(modelName, inputSamplingNames, modelSamplingNames, inputSurrogateNames, outputSurrogateNames, modelFunction, scalingFunction, varargin)

    %% Default Parameters and Setup
    % Sampling algorithm parameters
    p = inputParser;
    addParameter(p, 'lookAhead', 100000);
    addParameter(p, 'validationStart', 400000);
    addParameter(p, 'increaseSizeTraining', 100);
    addParameter(p, 'increaseSizeValidate', 20);
    addParameter(p, 'initialSizeMultiple', 1);
    addParameter(p, 'numRounds', 15);
    addParameter(p, 'numTesting', 2000);
    addParameter(p, 'plottingFlag', true);

    % Skipping Flags
    addParameter(p, 'skipRandom', false);
    addParameter(p, 'skipLHS', false);
    addParameter(p, 'skipColdStartSobol', false);
    addParameter(p, 'skipWarmStartSobol', false);
    addParameter(p, 'skipSSS', false);

    % Model training parameters
    addParameter(p, 'initLearningRate', 0.001);
    addParameter(p, 'maxNumEpochs', 15000);
    addParameter(p, 'minMiniBatchSize', 250);
    addParameter(p, 'maxNumIterationsPerEpoch', 10);
    addParameter(p, 'netWidthPerOutput', 50);
    addParameter(p, 'maxWidth', 150);
    addParameter(p, 'netNumLayers', 6);
    addParameter(p, 'pLearningRateThres', 250);
    addParameter(p, 'minLearningRate', 1e-8)
    addParameter(p, 'minTrainingLoss', 1e-4)
    addParameter(p, 'pStopThres', 600);
    addParameter(p, 'scalePredictTesting', false);

    % Parse optional inputs
    parse(p, varargin{:});

    %% Unpacking Parameters
    % Sampling parameters
    lookAhead = p.Results.lookAhead;
    validationStart = p.Results.validationStart;
    increaseSizeTraining = p.Results.increaseSizeTraining;
    increaseSizeValidate = p.Results.increaseSizeValidate;
    initialSizeMultiple = p.Results.initialSizeMultiple;
    numRounds = p.Results.numRounds;
    numTesting = p.Results.numTesting;
    plottingFlag = p.Results.plottingFlag;
    initialSizeTraining = increaseSizeTraining * initialSizeMultiple;
    initialSizeValidate = increaseSizeValidate * initialSizeMultiple;
    initialSize = initialSizeTraining + initialSizeValidate;
    increaseSize = increaseSizeTraining + increaseSizeValidate;

    % Skipping flags
    skipRandom = p.Results.skipRandom;
    skipLHS = p.Results.skipLHS;
    skipColdStartSobol = p.Results.skipColdStartSobol;
    skipWarmStartSobol = p.Results.skipWarmStartSobol;
    skipSSS = p.Results.skipSSS;

    % Model training parameters
    modelTrainingParams.initLearningRate = p.Results.initLearningRate;
    modelTrainingParams.maxNumEpochs = p.Results.maxNumEpochs;
    modelTrainingParams.minMiniBatchSize = p.Results.minMiniBatchSize;
    modelTrainingParams.maxNumIterationsPerEpoch = p.Results.maxNumIterationsPerEpoch;
    modelTrainingParams.netWidthPerOutput = p.Results.netWidthPerOutput;
    modelTrainingParams.maxWidth = p.Results.maxWidth;
    modelTrainingParams.netNumLayers = p.Results.netNumLayers;
    modelTrainingParams.pLearningRateThres = p.Results.pLearningRateThres;
    modelTrainingParams.minLearningRate = p.Results.minLearningRate;
    modelTrainingParams.minTrainingLoss = p.Results.minTrainingLoss;
    modelTrainingParams.pStopThres = p.Results.pStopThres;
    modelTrainingParams.scalePredictTesting = p.Results.scalePredictTesting;

    %% File Naming and Directories
    dateStamp = datetime('now', "Format", 'd_MM_y_HH_mm_ss');
    resultsDir = sprintf('./Results/%s_%s', modelName, dateStamp);
    figFileName = fullfile(resultsDir, 'plots.fig');
    pngFileName = fullfile(resultsDir, 'plots.png');
    matFileName = fullfile(resultsDir, 'results.mat');
    inputFileName = fullfile(resultsDir, 'DataFiles', sprintf('%s_input.csv', modelName));
    dataFileName = fullfile(resultsDir, 'DataFiles', sprintf('%s_data.csv', modelName));

    % Create directories for storing results
    mkdir(resultsDir);
    mkdir(fullfile(resultsDir, 'DataFiles'));

    %% Sobol Set Generation
    numInputs = length(inputSamplingNames);
    sobolSetTrainingandValidate = scramble(sobolset(numInputs), 'MatousekAffineOwen');
    sobolSetTesting = scramble(sobolset(numInputs), 'MatousekAffineOwen');

    %% Helper Functions (for CSV manipulation, model training, etc.)
    function createInputs(setName, inputCSV, data, rowNumbers, input_names)
        % Helper function to create and append data to input CSV
        numericData = [data, rowNumbers'];
        stringData = repmat(setName, size(numericData, 1), 1);
        inputTable = array2table([numericData, stringData], 'VariableNames', [input_names, {'data_set_number', 'data_set'}]);
        existingTable = readtable(inputCSV);
        updatedTable = [existingTable; inputTable];
        writetable(updatedTable, inputCSV);
    end

    function updateOutputs(inputCSV, outputCSV, modelSampler, inputNames, outputNames)
        % Helper function to compute and save model outputs
        modelSampler(inputCSV, outputCSV, inputNames, outputNames);
    end

    function dataToGet = getSet(name, outputCSV)
        % Helper function to get data from CSV based on dataset name
        gettingTable = readtable(outputCSV);
        if ~isempty(regexp(name, '_\d+$', 'once'))
            idx = strcmp(gettingTable.data_set, name);
        else
            idx = contains(gettingTable.data_set, name);
        end
        dataToGet = gettingTable(idx == 1, :);
    end

    function resultsStruct = updateResults(resultsStruct, model, error, data, index)
        % Helper function to update the results structure
        resultsStruct.model(index) = model;    
        resultsStruct.error(index) = error;
        resultsStruct.data(index) = data;
    end

    function [updatedResults, trainingData] = trainModel(results, dataFileName, trainingName, validateName, dataTest, inputNamesTraining, outputNamesTraining, newModelFlag, oldModel, numRound, trainingParams)
        % Function to train the model and update results
        dataTraining = getSet(trainingName, dataFileName);
        dataValidate = getSet(validateName, dataFileName);
        [model, errorStats, dataStats, trainingData] = modelTraining(dataTraining, dataValidate, dataTest, inputNamesTraining, outputNamesTraining, newModelFlag, oldModel, trainingParams);
        updatedResults = updateResults(results, model, errorStats, dataStats, numRound);
    end

    %% Initial Setup for Storing Results
    storeResultsStruct = struct('model', struct('net', [], 'meanX', [], 'stdX', [], 'meanY', [], 'stdY', [], 'inputNames', [], 'outputNames', []), ...
                                'error', struct('max', [], 'mean', [], 'std', []), ...
                                'data', struct('numTraining', [], 'numValidate', []), ...
                                'name', '', ...
                                'plotting', struct('plotType', [], 'color', []));

    selectiveSobolSamplingResults = storeResultsStruct;
    selectiveSobolSamplingResults.name = 'Selective Sobol Sampling';
    selectiveSobolSamplingResults.plotting.plotType = 'line';
    selectiveSobolSamplingResults.plotting.color = 'red';

    regularSobolResults = storeResultsStruct;
    regularSobolResults.name = 'Regular Sobol';
    regularSobolResults.plotting.plotType = 'scatter';
    regularSobolResults.plotting.color = 'black';

    warmStartSobolResults = storeResultsStruct;
    warmStartSobolResults.name = 'Warm Start Sobol';
    warmStartSobolResults.plotting.plotType = 'line';
    warmStartSobolResults.plotting.color = 'blue';

    lhsResults = storeResultsStruct;
    lhsResults.name = 'Latin Hypercube Sampling';
    lhsResults.plotting.plotType = 'scatter';
    lhsResults.plotting.color = 'green';

    randomResults = storeResultsStruct;
    randomResults.name = 'Random Sampling';
    randomResults.plotting.plotType = 'scatter';
    randomResults.plotting.color = 'magenta';

    %% Create empty CSV files to store inputs and outputs
    
    % Empty table to store inputs
    dataTable = table('Size', [0, length(inputSamplingNames) + 2], ...
                      'VariableTypes', [repmat({'double'}, 1, length(inputSamplingNames)), {'double'}, {'string'}], ...
                      'VariableNames', [inputSamplingNames, 'data_set_number', 'data_set']);
    writetable(dataTable, inputFileName);
    
    % Empty table to store inputs and outputs
    dataTable = table('Size', [0, length(modelSamplingNames) + 2], ...
                      'VariableTypes', [repmat({'double'}, 1, length(modelSamplingNames)), {'double'}, {'string'}], ...
                      'VariableNames', [modelSamplingNames, 'data_set_number', 'data_set']);
    writetable(dataTable, dataFileName);
    
    %% Generate Testing Data
    createInputs("Testing", inputFileName, sobolSetTesting(1:numTesting, :), 1:numTesting, inputSamplingNames);
    updateOutputs(inputFileName, dataFileName, modelFunction, inputSamplingNames, modelSamplingNames);
    dataTest = getSet("Testing", dataFileName);
    
    %% Initial Training: Regular, Warm Start, and Selective Sobol Sampling
    if ~skipColdStartSobol || ~skipWarmStartSobol || ~skipSSS
        % Define initial training and validation sets
        initTrainingSet = sobolSetTrainingandValidate(1:initialSizeTraining, :);
        numTrainingSet = 1:initialSizeTraining;
        initValdSet = sobolSetTrainingandValidate(initialSizeTraining + 1:initialSizeTraining + initialSizeValidate, :);
        numValdSet = initialSizeTraining + 1:initialSizeTraining + initialSizeValidate;
        
        % Create inputs for regular and selective Sobol training and validation
        createInputs("regularSobol_Training_0", inputFileName, initTrainingSet, numTrainingSet, inputSamplingNames);
        createInputs("regularSobol_Vald_0", inputFileName, initValdSet, numValdSet, inputSamplingNames);
        createInputs("selectiveSobolSampling_Training_0", inputFileName, initTrainingSet, numTrainingSet, inputSamplingNames);
        createInputs("selectiveSobolSampling_Vald_0", inputFileName, initValdSet, numValdSet, inputSamplingNames);
        
        % Compute outputs and get training data
        updateOutputs(inputFileName, dataFileName, modelFunction, inputSamplingNames, modelSamplingNames);
        sobolResults = storeResultsStruct;
        [sobolResults, initTrainingData] = trainModel(sobolResults, dataFileName, ...
                                                      "regularSobol_Training", "regularSobol_Vald", ...
                                                      dataTest, inputSurrogateNames, outputSurrogateNames, true, [], 1, ...
                                                      modelTrainingParams);
        
        % Store results for Sobol-based methods
        if ~skipColdStartSobol
            regularSobolResults.model = sobolResults.model;    
            regularSobolResults.error = sobolResults.error;
            regularSobolResults.data = sobolResults.data;
        end
        
        if ~skipWarmStartSobol
            warmStartSobolResults.model = sobolResults.model;    
            warmStartSobolResults.error = sobolResults.error;
            warmStartSobolResults.data = sobolResults.data;
        end
        
        if ~skipSSS
            selectiveSobolSamplingResults.model = sobolResults.model;    
            selectiveSobolSamplingResults.error = sobolResults.error;
            selectiveSobolSamplingResults.data = sobolResults.data;
        end
    end
    
    %% Random Sampling
    if ~skipRandom
        % Generate random training and validation inputs
        inputsRandTraining = rand(initialSizeTraining, length(inputSamplingNames));
        inputsRandVald = rand(initialSizeValidate, length(inputSamplingNames));
        
        createInputs("Rand_Training_0", inputFileName, inputsRandTraining, 1:size(inputsRandTraining, 1), inputSamplingNames);
        createInputs("Rand_Vald_0", inputFileName, inputsRandVald, 1:size(inputsRandVald, 1), inputSamplingNames);
        
        updateOutputs(inputFileName, dataFileName, modelFunction, inputSamplingNames, modelSamplingNames);
        randomResults = trainModel(randomResults, dataFileName, ...
                                   "Rand_Training_0", "Rand_Vald_0", ...
                                   dataTest, inputSurrogateNames, outputSurrogateNames, true, [], 1, ...
                                   modelTrainingParams);
    end
    
    %% Latin Hypercube Sampling
    if ~skipLHS
        % Generate LHS training and validation inputs
        inputsLHSTraining = lhsdesign(initialSizeTraining, length(inputSamplingNames));
        inputsLHSVald = lhsdesign(initialSizeValidate, length(inputSamplingNames));
        
        createInputs("LHS_Training_0", inputFileName, inputsLHSTraining, 1:size(inputsLHSTraining, 1), inputSamplingNames);
        createInputs("LHS_Vald_0", inputFileName, inputsLHSVald, 1:size(inputsLHSVald, 1), inputSamplingNames);
        
        updateOutputs(inputFileName, dataFileName, modelFunction, inputSamplingNames, modelSamplingNames);
        lhsResults = trainModel(lhsResults, dataFileName, ...
                                "LHS_Training_0", "LHS_Vald_0", ...
                                dataTest, inputSurrogateNames, outputSurrogateNames, true, [], 1, ...
                                modelTrainingParams);
    end
    
    %% Initial Plot
    if plottingFlag
        resultsArray = [selectiveSobolSamplingResults, regularSobolResults, warmStartSobolResults, lhsResults, randomResults];
        f = plotErrorMetrics(resultsArray);
    end
    
    %% Start Main Loop for Rounds
    for j = 2:numRounds
        %% Random Sampling
        if ~skipRandom
            % Generate random training and validation inputs for round j
            inputsRandTraining = rand(initialSizeTraining + (j-1)*increaseSizeTraining, length(inputSamplingNames));
            inputsRandVald = rand(initialSizeValidate + (j-1)*increaseSizeValidate, length(inputSamplingNames));
            
            createInputs("Rand_Training_" + num2str(j-1), inputFileName, inputsRandTraining, 1:size(inputsRandTraining, 1), inputSamplingNames);
            createInputs("Rand_Vald_" + num2str(j-1), inputFileName, inputsRandVald, 1:size(inputsRandVald, 1), inputSamplingNames);
            
            updateOutputs(inputFileName, dataFileName, modelFunction, inputSamplingNames, modelSamplingNames);
            randomResults = trainModel(randomResults, dataFileName, ...
                                       "Rand_Training_" + num2str(j-1), "Rand_Vald_" + num2str(j-1), ...
                                       dataTest, inputSurrogateNames, outputSurrogateNames, true, [], j, ...
                                       modelTrainingParams);
        end
        
        %% Latin Hypercube Sampling
        if ~skipLHS
            % Generate LHS training and validation inputs for round j
            inputsLHSTraining = lhsdesign(initialSizeTraining + (j-1)*increaseSizeTraining, length(inputSamplingNames));
            inputsLHSVald = lhsdesign(initialSizeValidate + (j-1)*increaseSizeValidate, length(inputSamplingNames));
            
            createInputs("LHS_Training_" + num2str(j-1), inputFileName, inputsLHSTraining, 1:size(inputsLHSTraining, 1), inputSamplingNames);
            createInputs("LHS_Vald_" + num2str(j-1), inputFileName, inputsLHSVald, 1:size(inputsLHSVald, 1), inputSamplingNames);
            
            updateOutputs(inputFileName, dataFileName, modelFunction, inputSamplingNames, modelSamplingNames);
            lhsResults = trainModel(lhsResults, dataFileName, ...
                                    "LHS_Training_" + num2str(j-1), "LHS_Vald_" + num2str(j-1), ...
                                    dataTest, inputSurrogateNames, outputSurrogateNames, true, [], j, ...
                                    modelTrainingParams);
        end
        
        %% Sobol Sampling
        if ~skipColdStartSobol || ~skipWarmStartSobol
            % Regular Sobol sampling for round j
            trainIdx = initialSize + (j-2)*increaseSize + 1 : initialSize + (j-2)*increaseSize + increaseSizeTraining;
            valdIdx = initialSize + (j-2)*increaseSize + increaseSizeTraining + 1 : initialSize + (j-2)*increaseSize + increaseSizeTraining + increaseSizeValidate;
            
            createInputs("regularSobol_Training_" + num2str(j-1), inputFileName, sobolSetTrainingandValidate(trainIdx, :), trainIdx, inputSamplingNames);
            createInputs("regularSobol_Vald_" + num2str(j-1), inputFileName, sobolSetTrainingandValidate(valdIdx, :), valdIdx, inputSamplingNames);
            
            updateOutputs(inputFileName, dataFileName, modelFunction, inputSamplingNames, modelSamplingNames);
            
            if ~skipColdStartSobol
                regularSobolResults = trainModel(regularSobolResults, dataFileName, ...
                                                 "regularSobol_Training", "regularSobol_Vald", ...
                                                 dataTest, inputSurrogateNames, outputSurrogateNames, true, [], j, ...
                                                 modelTrainingParams);
            end
            
            if ~skipWarmStartSobol
                warmStartSobolResults = trainModel(warmStartSobolResults, dataFileName, ...
                                                   "regularSobol_Training", "regularSobol_Vald", ...
                                                   dataTest, inputSurrogateNames, outputSurrogateNames, true, [], j, ...
                                                   modelTrainingParams);
            end
        end

        %% Selective Sobol Sampling 
        % Determine best samples
        if ~skipSSS
            % Initialize training data for the first round
            if j == 2
                selectiveTrainingData = initTrainingData;
            end
            selectedNum = selectiveSobolSampling(selectiveSobolSamplingResults.model(end),...
                                        scalingFunction,...
                                        selectiveTrainingData, sobolSetTrainingandValidate,...
                                        increaseSizeTraining, lookAhead);
            selectedSobol = sobolSetTrainingandValidate(selectedNum,:);
        
            % Generate data
            createInputs("selectiveSobolSampling_Training_" + num2str(j-1), inputFileName, selectedSobol, selectedNum', inputSamplingNames)
            valdIdx = validationStart + increaseSizeValidate*(j-2) + 1 : validationStart + increaseSizeValidate*j;
            createInputs("selectiveSobolSampling_Vald_" + num2str(j-1), inputFileName, sobolSetTrainingandValidate(valdIdx,:), valdIdx, inputSamplingNames)
            updateOutputs(inputFileName,dataFileName, modelFunction, inputSamplingNames, modelSamplingNames)
            [selectiveSobolSamplingResults, selectiveTrainingData] = trainModel(selectiveSobolSamplingResults, dataFileName,...
                                                                            "selectiveSobolSampling_Training", "selectiveSobolSampling_Vald",...
                                                                            dataTest, inputSurrogateNames, outputSurrogateNames, false, selectiveSobolSamplingResults.model(end), j,...
                                                                            modelTrainingParams);
        end
        %% Plot and save data in between rounds
        resultsArray = [selectiveSobolSamplingResults, regularSobolResults, warmStartSobolResults, lhsResults, randomResults];
        dataTable = readtable(dataFileName);
        save(matFileName, "resultsArray", "dataTable");
        if plottingFlag
            if exist('f','var')
                f = plotErrorMetrics(resultsArray, f);
            else
                f = plotErrorMetrics(resultsArray);
            end
        end
    
    end
    
    %% Plot to record final results
    resultsArray = [selectiveSobolSamplingResults, regularSobolResults, warmStartSobolResults, lhsResults, randomResults];
    plotErrorMetrics(resultsArray, f, figFileName, pngFileName);
    %% Save final data
    dataTable = readtable(dataFileName);
    save(matFileName, "resultsArray", "dataTable");
end