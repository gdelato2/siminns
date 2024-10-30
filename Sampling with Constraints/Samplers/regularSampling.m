function [table] = regularSampling(lhsSamples, parameterLimits, normalizeFunction)
    
    % Create an empty table with parameter names as columns
    parameterNames = fieldnames(parameterLimits);
    table = array2table(zeros(0, numel(parameterNames)), 'VariableNames', parameterNames');

    numSamples = size(lhsSamples,1);
    for j = 1:numSamples

        % Sample
        for idx = 1:numel(parameterNames)
            lims = parameterLimits.(parameterNames{idx}).limits;
            value = lhsSamples(j,idx)*(lims(2) - lims(1)) + lims(1); %apply bounds
            sample.(parameterNames{idx}) = struct("index", idx, "value", value);
        end
           
        % Apply the normalized function
        sample = normalizeFunction(sample);

        % Augment the table with the values in determinedSample
        newRow = arrayfun(@(k) sample.(parameterNames{k}).value, 1:numel(parameterNames));
        table = [table; array2table(newRow, 'VariableNames', parameterNames')]; %#ok<AGROW>
    end
end