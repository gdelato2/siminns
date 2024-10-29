clear all
close all
addpath('Sample Comparison\')

modelName = 'MIMO';
outputNames = ["y1", "y2", "y3", "y4"];
inputNames = ["x1", "x2", "x3"];

% Model function that generates outputs based on inputs
function outputs = modelFunction(inputs)
    output1 = 1./(1+exp(-(3*inputs(:,1)+2.8*inputs(:,2)-5.0).*(10+48*sqrt( (inputs(:,1)-inputs(:,2)).^2 ))));
    output2 = 1./(1+exp(-(1.75*inputs(:,1)+2.85*inputs(:,3)-1.5).*(6+12*sqrt( (inputs(:,1)-inputs(:,3)).^2 ))));
    output3 = 3*inputs(:,2) + 1.5*inputs(:,3) + 0.89*inputs(:,2).^2 + 3.7*inputs(:,3).^2 + 4.5*inputs(:,3).*inputs(:,2);
    output3 = output3/13.5;
    output4 = 2.5*inputs(:,1) + 4.5*inputs(:,2) + 2.19*output3.^2 + 6.7*inputs(:,2).^2 + 3.48*inputs(:,1).*output3;
    output4 = output4/19.0;
    outputs = [output1, output2, output3, output4];
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
                        'numRounds', 24);