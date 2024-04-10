function x = getRandomInputs(source_pressure,numSamples)
    x = zeros(9,numSamples);   
    x(1,:) = rand(1,numSamples)*0.5 + 1.0;
    x(3,:) = source_pressure.source_pressure_1;
    x(5,:) = source_pressure.source_pressure_2;
    x(7,:) = source_pressure.source_pressure_3;
    x(9,:) = source_pressure.source_pressure_4;
    x(2,:) = rand(1,numSamples)*550 + 2450;
    x(4,:) = rand(1,numSamples)*550 + 2450;
    x(6,:) = rand(1,numSamples)*550 + 2450;
    x(8,:) = rand(1,numSamples)*550 + 2450;
end
