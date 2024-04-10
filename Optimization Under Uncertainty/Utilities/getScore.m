function score = getScore(z,paraModel,knownInputs,sensorReadings,sigma,outputIdx)
    x = zeros(9,size(knownInputs,2));   
    x(3,:) = z(1);
    x(5,:) = z(2);
    x(7,:) = z(3);
    x(9,:) = z(4);
    x([1,2:2:8],:) = knownInputs;
    y_= small_scale_inference(x,paraModel);
    y = squeeze(y_(:,outputIdx));
    score = (sum(((sensorReadings-y')'./sigma).^2,'all'));
end
