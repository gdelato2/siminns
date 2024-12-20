clear all
close all
addpath('Sample Comparison\')

modelName = 'Simple';
outputNames = "y1";
inputNames = ["x1", "x2"];

function outputs = modelFunction(inputs)
    outputs = 3*inputs(:,1) + 1.5*inputs(:,2) + 4.5*inputs(:,1).*inputs(:,2);
    outputs = outputs/9.0;
end

% Function to read input data, apply the model, and save the results
function modelSampler(model, inputCSV, outputCSV, inputNames, modelSamplingNames)
    % Read inputs from CSV file
    inputTable = readtable(inputCSV);
    inputs = table2array(inputTable(:, inputNames));
    
    % Generate outputs using the model function
    outputs = model(inputs);
    
    % Create a new table combining inputs and outputs
    ioTable = array2table([inputs, outputs], 'VariableNames', modelSamplingNames);
    newTable = [ioTable, inputTable(:, ["data_set_number", "data_set"])];
    
    % Append new data to the output CSV
    writetable(newTable, outputCSV, "WriteMode", "append");

    % Clear the input table rows but retain headers
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
                        'numRounds', 10);