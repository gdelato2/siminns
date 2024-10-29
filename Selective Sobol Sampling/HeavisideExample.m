clear all
close all
addpath('Sample Comparison\')

modelName = 'Heaviside';
outputNames = "y1";
inputNames = "x1";

function outputs = modelFunction(inputs)
    output1 = mod(floor(2*inputs(:,1)),2);
    outputs = output1;
end

function modelSampler(model, inputCSV, outputCSV, inputNames, modelSamplingNames)
    inputTable = readtable(inputCSV);
    inputs = table2array(inputTable(:, inputNames));
    outputs = model(inputs);
    ioTable = array2table([inputs, outputs], 'VariableNames', modelSamplingNames);
    newTable = [ioTable, inputTable(:, ["data_set_number","data_set"])];
    writetable(newTable, outputCSV, "WriteMode", "append");

    % Clear the rows in the input CSV but keep the header
    emptyTable = inputTable(1, :);
    emptyTable(2:end, :) = [];
    writetable(emptyTable, inputCSV);
end

runSamplingComparison(modelName,...
                        inputNames,...
                        [inputNames, outputNames],...
                        inputNames,...
                        outputNames,...
                        @(x,y,w,v) modelSampler(@modelFunction, x, y, w, v),...
                        [],...
                        'numRounds', 6,...
                        'increaseSizeTraining', 10,...
                        'increaseSizeValidate', 5,...
                        'initialSizeMultiple', 10,...
                        'minMiniBatchSize', 150);