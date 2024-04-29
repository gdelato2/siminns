function score = getScore(z,paraModel,knownInputs,sensorReadings,sigma,outputIdx)
    x = completeInput(z,knownInputs);
    y_= small_scale_inference(x,paraModel);
    y = squeeze(y_(:,outputIdx));
    diff = ((kron(ones(1,size(z,1)), sensorReadings)'-y)./sigma).^2;
    score = zeros(size(z,1),1);
    for ii =1:size(z,1)
        idx1 = (ii-1)*size(knownInputs,2)+1;
        idx2 = ii*size(knownInputs,2);
        score(ii) = sum(diff(idx1:idx2,:),'all');
    end
end