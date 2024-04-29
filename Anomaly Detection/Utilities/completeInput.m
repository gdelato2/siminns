% combine optimized inputs and static system parameters
function x = completeInput(z,knownInputs)
    x = zeros(9,size(knownInputs,2)*size(z,1));   
    for ii = 1:size(z,1)
        idx1 = 1 + (ii-1)*size(knownInputs,2); 
        idx2 = ii*size(knownInputs,2); 
        x(1,idx1:idx2) = knownInputs(1,:);
        x(3,idx1:idx2) = z(ii,1);
        x(5,idx1:idx2) = z(ii,2);
        x(7,idx1:idx2) = z(ii,3);
        x(9,idx1:idx2) = z(ii,4);
        x(2,idx1:idx2) = knownInputs(2,:);
        x(4,idx1:idx2) = knownInputs(3,:);
        x(6,idx1:idx2) = knownInputs(4,:);
        x(8,idx1:idx2) = knownInputs(5,:);
    end
end