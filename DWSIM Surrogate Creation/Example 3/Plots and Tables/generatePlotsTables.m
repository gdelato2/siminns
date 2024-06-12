addpath("../Surrogate Model")
addpath("../Data")
load('naturalGasProcessingUnit_model.mat')

xtest = readtable('..\Data\test_Inputs.csv');
ytest = readtable('..\Data\test_Outputs.csv');
xtest = table2array(xtest);
ytest = table2array(ytest);
ypred_test = example3_inference(xtest',naturalGasProcessingUnit_mlp);
error_test = abs(ytest-ypred_test);
test_mean = mean(error_test);
test_std = std(error_test);

xvald = readtable('..\Data\vald_Inputs.csv');
yvald = readtable('..\Data\vald_Outputs.csv');
xvald = table2array(xvald);
yvald = table2array(yvald);
ypred_vald = example3_inference(xvald',naturalGasProcessingUnit_mlp);
error_vald = abs(yvald-ypred_vald);
vald_mean = mean(error_vald);
vald_std = std(error_vald);

xtrain = readtable('..\Data\train_Inputs.csv');
ytrain = readtable('..\Data\train_Outputs.csv');
xtrain = table2array(xtrain);
ytrain = table2array(ytrain);
ypred_train = example3_inference(xtrain',naturalGasProcessingUnit_mlp);
error_train = abs(ytrain-ypred_train);
train_mean = mean(error_train);
train_std = std(error_train);


% no change or trace 
%"product1_ethane_frac",...
%"product1_nbutane_frac",... 
%"product1_c02_frac",...
%"product1_npentane_frac",...
%"product1_isopentane_frac",...
%"product1_isobutane_frac",...
%"product1_propane_frac",...
%"product2_n2_frac",...
%"product2_npentane_frac",...
%"product3_n2_frac",...
%"product3_methane_frac",...
%"product4_methane_frac",...
%"product4_ethane_frac",...
%"product4_c02_frac",...
%"product4_n2_frac",...
    
output_names = ["Condenser1 Duty",
"Condenser2 Duty",
"Condenser3 Duty",
"Compresser Duty",
"Cooler Duty",
"Expander Duty",
"Heater Duty",
"Liquid Molar Flow",
"Product1 Methane Molar Fraction",
"Product1 Molar Flow",
"Product1 Nitrogen Molar Fraction",
"Product2 Carbon Dioxide Molar Fraction",
"Product2 Ethane Molar Fraction",
"Product2 Isobutane Molar Fraction",
"Product2 Isopentane Molar Fraction",
"Product2 Methane Molar Fraction",
"Product2 Molar Flow",
"Product2 N-butane Molar Fraction",
"Product2 Propane Molar Fraction",
"Product3 Carbon Dioxide Molar Fraction",
"Product3 Ethane Molar Fraction",
"Product3 Isobutane Molar Fraction",
"Product3 Isopentane Molar Fraction",
"Product3 Molar Flow",
"Product3 N-butane Molar Fraction",
"Product3 N-pentane Molar Fraction",
"Product3 Propane Molar Fraction",
"Product4 Isobutane Molar Fraction",
"Product4 Isopentane Molar Fraction",
"Product4 Molar Flow",
"Product4 N-butane Molar Fraction",
"Product4 N-pentane Molar Fraction",
"Product4 Propane Molar Fraction",
"Reboiler1 Duty",
"Reboiler2 Duty",
"Reboiler3 Duty",
 ];

output_units = ["kW","kW","kW","kW","kW","kW","kW",...
                "mol/s",...
                "-",...
                "mol/s",...
                "-","-","-","-","-","-",...
                "mol/s",...
                "-","-","-","-","-","-",...
                "mol/s",...
                "-","-","-","-","-",...
                "mol/s",...
                "-","-","-",...
                "kW","kW","kW"];

% create figures
for idx = 1:numel(output_names)
    fig = figure;
    set(gcf,'position',[1 49 1536 836.8000])
    hold on
    % customize the plot as needed
    title(strcat("Example 3: ", output_names(idx), " Predictions"),'FontSize',18);
    ylabel(strcat("Physics-Based ", output_names(idx)," (",output_units(idx),")"),'FontSize',18);
    xlabel(strcat("Surrogate Model ", output_names(idx)," (",output_units(idx),")"),'FontSize',18);
    scatter(ytrain(:,idx),ypred_train(:,idx), 7, 'k', 'filled')
    scatter(yvald(:,idx),ypred_vald(:,idx), 7, 'b', 'filled')
    scatter(ytest(:,idx),ypred_test(:,idx), 7, 'r', 'filled')
    ylim_ = ylim;
    plot([ylim_(1),ylim_(2)],[ylim_(1),ylim_(2)],'k--')
    axis tight
    legend(strcat("Train (error mean = ", num2str(train_mean(idx),'%.2e'), " (", output_units(idx), "), error std = ", num2str(train_std(idx),'%.2e')," (", output_units(idx), "))"),...
        strcat("Validate (error mean = ", num2str(vald_mean(idx),'%.2e'), " (", output_units(idx), "), error std = ", num2str(vald_std(idx),'%.2e')," (", output_units(idx), "))"),......
        strcat("Test (error mean = ", num2str(test_mean(idx),'%.2e'), " (", output_units(idx), "), error std = ", num2str(test_std(idx),'%.2e')," (", output_units(idx), "))"),......
        ['Perfect Prediction Reference, x=y'],...
        'FontSize',18,'Location','NorthWest');
    hAx = gca;
    hAx.XAxis.FontSize = 18;
    hAx.YAxis.FontSize = 18;
    grid on
    box on
    filename = strcat('Example3_',strrep(output_names(idx),' ',''),'_truthplot');
    saveas(gcf,strcat(filename,'.fig'))
    saveas(gcf,strcat(filename,'.png'))
end

column_names = ["Mean Error", "Std. Error","Sampled Mean","Sampled Max"];
data = [test_mean',test_std', mean(abs(ytest))',max(abs(ytest))'];
table = array2table(double(data),'VariableNames',column_names);
table.("Output") = output_names;
table.("Units") = output_units';
table = [table(:,end-1) table(:,end) table(:,1:end-2)];
reorderIdx = [1,34,2,35,3,36,4,5,6,7,10,9,11,17,16,13,18,12,15,14,19,...
    24,21,25,20,26,23,22,27,30,31,32,29,28,33,8];
table = table(reorderIdx,:);
writetable(table, 'resultsTable.csv');

rawData = readtable('..\Data\raw_Data.csv');
dwsim_time = mean(rawData.dwsim_time);

lower_bounds = [450,0.0,0.0872501-0.03,0.0523501-0.03,4.5,4.5,4.5,195,300,342,980880*0.85,784705*0.85,450000];
upper_bounds = [480,0.0,0.0872501+0.03,0.0523501+0.03,5.5,5.5,5.5,205,310,352,980880*1.15,784705*1.15,600000];
randomInputs = rand(10000,13).*(upper_bounds - lower_bounds) + lower_bounds;
randomInputs(:,2) = 0.8376 - randomInputs(:,4) - randomInputs(:,3);
tic;
for idx = 1:10000
    example3_inference(randomInputs(idx,:)',naturalGasProcessingUnit_mlp);
end
surrogate_single_eval = toc/10000;

lower_bounds = [450,0.6979997-0.06,0.0872501-0.03,0.0523501-0.03,4.5,4.5,4.5,195,300,342,980880*0.85,784705*0.85,450000];
upper_bounds = [480,0.6979997+0.06,0.0872501+0.03,0.0523501+0.03,5.5,5.5,5.5,205,310,352,980880*1.15,784705*1.15,600000];
randomInputs = rand(100000,13).*(upper_bounds - lower_bounds) + lower_bounds;
randomInputs(:,2) = 0.8376 - randomInputs(:,4)- randomInputs(:,3);
tic;
for idx = 0:99
    example3_inference(randomInputs(1+idx*1000:(1+idx)*1000,:)',naturalGasProcessingUnit_mlp);
end
surrogate_batch_eval = toc/100;

column_names = ["DWSIM time", "Surrogate Single Eval","Surrogate Batch Eval"];
data = [dwsim_time,surrogate_single_eval, surrogate_batch_eval];
table = array2table(double(data),'VariableNames',column_names);
writetable(table, 'timingTable.csv');