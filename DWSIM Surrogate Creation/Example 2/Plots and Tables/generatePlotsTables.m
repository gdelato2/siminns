addpath("../Surrogate Model")
addpath("../Data")
load('extractiveDistillation_model.mat')

xtest = readtable('..\Data\test_Inputs.csv');
ytest = readtable('..\Data\test_Outputs.csv');
xtest = table2array(xtest);
ytest = table2array(ytest);
ypred_test = example2_inference(xtest',extractiveDistillation_mlp);
error_test = abs(ytest-ypred_test);
test_mean = mean(error_test);
test_std = std(error_test);

xvald = readtable('..\Data\vald_Inputs.csv');
yvald = readtable('..\Data\vald_Outputs.csv');
xvald = table2array(xvald);
yvald = table2array(yvald);
ypred_vald = example2_inference(xvald',extractiveDistillation_mlp);
error_vald = abs(yvald-ypred_vald);
vald_mean = mean(error_vald);
vald_std = std(error_vald);

xtrain = readtable('..\Data\train_Inputs.csv');
ytrain = readtable('..\Data\train_Outputs.csv');
xtrain = table2array(xtrain);
ytrain = table2array(ytrain);
ypred_train = example2_inference(xtrain',extractiveDistillation_mlp);
error_train = abs(ytrain-ypred_train);
train_mean = mean(error_train);
train_std = std(error_train);

%"bottom2_ethanol_frac",... only trace <1e-9

output_names = [
"Column1 Condenser Duty",
"Column1 Reboiler Duty",
"Column2 Condenser Duty",
"Column2 Reboiler Duty",
"Cooler Duty",
"Top1 Molar Flow",
"Top1 Benzene Molar Fraction",
"Top1 Ethanol Molar Fraction",
"Top1 P-Xylene Molar Fraction",
"Top2 Molar Flow",
"Top2 Benzene Molar Fraction",
"Top2 Ethanol Molar Fraction",
"Top2 P-Xylene Molar Fraction",
"Bottom1 Molar Flow",
"Bottom1 Benzene Molar Fraction",
"Bottom1 Ethanol Molar Fraction",
"Bottom1 P-Xylene Molar Fraction",
"Bottom2 Molar Flow",
"Bottom2 Benzene Molar Fraction",
"Bottom2 P-Xylene Molar Fraction",
"Recycle Molar Flow",
"Recycle Benzene Molar Fraction",
"Recycle P-Xylene Molar Fraction",
];

output_units = ["kW","kW","kW","kW","kW",...
    "mol/s","-","-","-",...
    "mol/s","-","-","-",...
    "mol/s","-","-","-",...
    "mol/s","-","-",...
    "mol/s","-","-"];

% create figures
for idx = 1:numel(output_names)
    fig = figure;
    set(gcf,'position',[1 49 1536 836.8000])
    hold on
    % customize the plot as needed
    title(strcat("Example 2: ", output_names(idx), " Predictions"),'FontSize',18);
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
    filename = strcat('Example2_',strrep(output_names(idx),' ',''),'_truthplot');
    saveas(gcf,strcat(filename,'.fig'))
    saveas(gcf,strcat(filename,'.png'))
end

column_names = ["Mean Error", "Std. Error","Sampled Mean","Sampled Max"];
data = [test_mean',test_std', mean(abs(ytest))',max(abs(ytest))'];
table = array2table(double(data),'VariableNames',column_names);
table.("Output") = output_names;
table.("Units") = output_units';
table = [table(:,end-1) table(:,end) table(:,1:end-2)];
writetable(table, 'resultsTable.csv');

rawData = readtable('..\Data\raw_Data.csv');
dwsim_time = mean(rawData.dwsim_time);

lower_bounds = [20,0.4,0.0,0.05,1.5,385,5.0,395,315];
upper_bounds = [35,0.6,0.0,0.12,2.5,395,7.0,410,340];
randomInputs = rand(10000,9).*(upper_bounds - lower_bounds) + lower_bounds;
randomInputs(:,3) = 1.0 - randomInputs(:,2);
tic;
for idx = 1:10000
    example2_inference(randomInputs(idx,:)',extractiveDistillation_mlp);
end
surrogate_single_eval = toc/10000;

lower_bounds = [20,0.4,0.0,0.05,1.5,385,5.0,395,315];
upper_bounds = [35,0.6,0.0,0.12,2.5,395,7.0,410,340];
randomInputs = rand(100000,9).*(upper_bounds - lower_bounds) + lower_bounds;
randomInputs(:,3) = 1.0 - randomInputs(:,2);
tic;
for idx = 0:99
    example2_inference(randomInputs(1+idx*1000:(1+idx)*1000,:)',extractiveDistillation_mlp);
end
surrogate_batch_eval = toc/100;

column_names = ["DWSIM time", "Surrogate Single Eval","Surrogate Batch Eval"];
data = [dwsim_time,surrogate_single_eval, surrogate_batch_eval];
table = array2table(double(data),'VariableNames',column_names);
writetable(table, 'timingTable.csv');