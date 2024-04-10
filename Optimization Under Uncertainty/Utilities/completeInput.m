function x = completeInput(z,sourcePressures)
    x = zeros(9,size(sourcePressures,1));   
    x(1,:) = z(1);
    x(3,:) = sourcePressures(:,1);
    x(5,:) = sourcePressures(:,2);
    x(7,:) = sourcePressures(:,3);
    x(9,:) = sourcePressures(:,4);
    x(2,:) = z(2);
    x(4,:) = z(3);
    x(6,:) = z(4);
    x(8,:) = z(5);
end