%% Model
clear all;

% Define the path to the results and data
path = '.\Results\Simple\';

% Load the results file
load([path, 'results.mat']);

% Create a public version of the results array
resultsArrayPublic = resultsArray;

% For SSS keep only the last model, error, and data entry for the first entry in the array
resultsArrayPublic(1).model = resultsArrayPublic(1).model(end);
resultsArrayPublic(1).error = resultsArrayPublic(1).error(end);
resultsArrayPublic(1).data = resultsArrayPublic(1).data(end);

% Save the modified results to a new file
save([path, 'resultsPublic.mat'], 'resultsArrayPublic');

%% Sampled Data
clear all;
path = '.\Results\Simple\';

% Load the public data table from CSV
dataTablePublic = readtable([path, 'DataFiles\Data.csv']);

% Anonymize the selective Sobol Sampling data sets in the public table
anonymizeDataset(dataTablePublic, 'selectiveSobolSampling_Vald', 'selectiveSobolSampling_Vald_XX');
anonymizeDataset(dataTablePublic, 'selectiveSobolSampling_Train', 'selectiveSobolSampling_Train_XX');

% Shuffle rows
dataTablePublic = dataTablePublic(randperm(height(dataTablePublic)), :);

% Save the anonymized and shuffled data table to a new CSV file
writetable(dataTablePublic, [path, 'DataFiles\dataPublic.csv']);

% Helper function to anonymize dataset names
function anonymizeDataset(table, originalPattern, replacement)
    idx = find(contains(table.data_set, originalPattern));
    for i = 1:length(idx)
        table.data_set{idx(i)} = replacement;
    end
end