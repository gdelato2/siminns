function [scores] = getConfidenceScores(knownInputs,sensorReadings,outputIdx,sigma,sp)

    % load the Surrogate Model
    if ~exist('parameter_small_mlp','var')
        addpath("./Surrogate Models")
        load('./Surrogate Models/small_model.mat');
    end
    
    % obtain base score
    [~, score_, ~, ~] = estimateParameters(knownInputs,sensorReadings,[],[],sigma,outputIdx);
    
    % get score for each source pressure at values given by sp
    scores = zeros(1,4);
    for idx = 1:4
        [~, score, ~, ~] = estimateParameters(knownInputs,sensorReadings,idx,sp(idx),sigma,outputIdx);
        scores(idx) = score-score_; %subtract base score
    end

end