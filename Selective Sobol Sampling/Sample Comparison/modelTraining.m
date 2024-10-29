% modelTraining: Trains a neural network on the provided training data and parameters
%
% Inputs:
%   - dataTrain: Training data table
%   - dataValidate: Validation data table
%   - dataTest: Testing data table
%   - inputNames: Names of input variables
%   - outputNames: Names of output variables
%   - createNewNetwork: Boolean indicating whether to create a new network
%   - model: Existing model if not creating a new one
%   - params: Parameter struct
%
% Outputs:
%   - model: Trained model structure
%   - errorStats: Structure containing error statistics
%   - dataStats: Structure containing data statistics
%   - trainingData: Normalized training data

function [model, errorStats, dataStats, trainingData] = modelTraining(dataTrain, dataValidate, dataTest, inputNames, outputNames, createNewNetwork, model, params)

    %% Default Parameters Setup
    % Extracting key parameters for training
    initLearningRate = params.initLearningRate;
    maxNumEpochs = params.maxNumEpochs;
    minMiniBatchSize = params.minMiniBatchSize;
    maxNumIterationsPerEpoch = params.maxNumIterationsPerEpoch;
    netWidthPerOutput = params.netWidthPerOutput;
    maxWidth = params.maxWidth;
    netNumLayers = params.netNumLayers;
    pLearningRateThres = params.pLearningRateThres;
    minLearningRate = params.minLearningRate;
    minTrainingLoss = params.minTrainingLoss;
    pStopThres = params.pStopThres;
    scalePredictTesting = params.scalePredictTesting;

    %% Export
    trainingData = dataTrain;
    dataStats.numTraining = height(dataTrain);
    dataStats.numValidate = height(dataValidate);

    %% Data Preparation
    % Filter out unsolved entries if the 'solved' column exists
    if ismember('solved', dataTrain.Properties.VariableNames)
        dataTrain = dataTrain(strcmp(dataTrain.solved, 'True'), :);
        dataValidate = dataValidate(strcmp(dataValidate.solved, 'True'), :);
    end

    % Extract input and output data
    xTraining = table2array(dataTrain(:, inputNames));
    yTraining = table2array(dataTrain(:, outputNames)); 
    xValidate = table2array(dataValidate(:, inputNames));
    yValidate = table2array(dataValidate(:, outputNames)); 

    % Compute mean and standard deviation for normalization
    meanX = mean([xTraining; xValidate]);
    stdX = std([xTraining; xValidate]);
    meanY = mean([yTraining; yValidate]);
    stdY = std([yTraining; yValidate]);

    % Normalize training and validation data
    xTrainingNormalized = (xTraining - meanX) ./ stdX;
    yTrainingNormalized = (yTraining - meanY) ./ stdY;
    xValidateNormalized = (xValidate - meanX) ./ stdX;
    yValidateNormalized = (yValidate - meanY) ./ stdY;

    % Prepare data for training in dlarray format
    xv = dlarray(xValidateNormalized', 'CB');
    yv = dlarray(yValidateNormalized', 'CB');
    xt = dlarray(xTrainingNormalized', 'CB');
    yt = dlarray(yTrainingNormalized', 'CB');

    %% Network Construction
    if createNewNetwork
        % Define a new network if required
        netWidth = min(netWidthPerOutput * size(yTraining, 2), maxWidth);
        layers = [featureInputLayer(size(xTraining, 2), 'Name', 'Input')];

        for idx = 1:netNumLayers
            layers = [layers; fullyConnectedLayer(netWidth); reluLayer('Name', ['Layer ', num2str(idx)])]; %#ok<AGROW>
        end
        layers = [layers; fullyConnectedLayer(size(yTraining, 2))];
        net = dlnetwork(layers);
    else
        % Use the provided net
        net = model.net;
    end

    %% Mini-batch Size and Iteration Setup
    numObservations = size(xTrainingNormalized, 1);
    miniBatchSize = min(numObservations, max(floor(numObservations / maxNumIterationsPerEpoch), minMiniBatchSize));
    numIterationsPerEpoch = floor(numObservations / miniBatchSize);

    %% Training Loop
    trailingAvg = [];
    trailingAvgSq = [];
    idxLearningRate = 0;
    pLearningRate = 0;
    pStop = 0;
    minVLoss = inf;
    minTLoss = inf;
    learningRate = initLearningRate;

    for epoch = 1:maxNumEpochs

        % shuffle
        randIdx = randperm(size(xt,2));
        xt = xt(:, randIdx);
        yt = yt(:, randIdx);

        % shuffled mini-batch loop training
        for iteration = 1:numIterationsPerEpoch
            idx = numObservations - iteration*miniBatchSize + 1: numObservations - (iteration-1)*miniBatchSize;
            [~,gradients] = dlfeval(@modelLossGradient, net, xt(:,idx), yt(:,idx));
            [net,trailingAvg,trailingAvgSq] = adamupdate(net, gradients, trailingAvg, trailingAvgSq, iteration, learningRate, 0.9, 0.999, 1e-07);
        end
    
        vLoss = modelLoss(net, xv, yv);
        tLoss = modelLoss(net, xt, yt);
        idxLearningRate = idxLearningRate + 1;
        % add to counters
        if vLoss<minVLoss*0.99
            pLearningRate = 0;
            pStop = 0;
            minVLoss = vLoss;
        elseif tLoss<minTLoss*0.99
            pLearningRate = 0;
            pStop = 0;
            minTLoss = tLoss;
        else
            pLearningRate = pLearningRate + 1;
            pStop = pStop+1;
        end
        
        %action on counters
        if pLearningRate>pLearningRateThres
            learningRate = 0.5*learningRate;
            pLearningRate= 0;
            idxLearningRate = 0;
        end

        if (pStop>pStopThres && modelLoss(net, xt, yt) < minTrainingLoss) || learningRate<minLearningRate
            break
        end
    end

    %% Post-Training Testing and Error Evaluation
    if ismember('solved', dataTest.Properties.VariableNames)
        dataTest = dataTest(strcmp(dataTest.solved, 'True'), :);
    end

    xTesting = table2array(dataTest(:, inputNames));
    yTesting = table2array(dataTest(:, outputNames));

    % Normalize predictions if required
    if scalePredictTesting
        minYTesting = min(yTesting);
        maxYTesting = max(yTesting);
        yPredictTesting = net.predict(((xTesting - meanX) ./ stdX)) .* stdY + meanY;
        yPredictTesting = (yPredictTesting - minYTesting) ./ (maxYTesting - minYTesting);
        yTesting = (yTesting - minYTesting) ./ (maxYTesting - minYTesting);
    else
        yPredictTesting = net.predict(((xTesting - meanX) ./ stdX)) .* stdY + meanY;
    end

    % Calculate prediction errors
    predictionErrorTesting = abs(yTesting - yPredictTesting);

    % Error statistics
    errorStats.max = max(predictionErrorTesting, [], 'all');
    errorStats.mean = mean(predictionErrorTesting, 'all');
    errorStats.std = std(predictionErrorTesting, 0, 'all');

    %% Save the trained model with statistics
    model = struct('net', net, 'meanX', meanX, 'stdX', stdX, 'meanY', meanY, 'stdY', stdY, 'inputNames', inputNames, 'outputNames', outputNames);
end

%% Helper Functions
function [loss, gradientsNet] = modelLossGradient(net, X, T)
    Y = forward(net, X);
    loss = mean((Y - T).^2, "all");  
    gradientsNet = dlgradient(loss, net.Learnables);
end

function loss = modelLoss(net, X, T)
    Y = forward(net, X);
    loss = mean((Y - T).^2, "all");
end