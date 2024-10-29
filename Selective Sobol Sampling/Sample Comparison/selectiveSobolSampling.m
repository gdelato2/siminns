function  selectedNum = selectiveSobolSampling(currentModel, scalingFunction, dataCurrent, sobolSet, increSize, lookAhead)
    warning('Selective Sobol Sampling was removed from public repo. Please contact Gerardo De La Torre for further details. ')
    randIndx = randperm(length(1:lookAhead));
    selectedNum = randIndx(1:increSize)';
end