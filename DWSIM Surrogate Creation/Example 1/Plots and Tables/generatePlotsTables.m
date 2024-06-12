addpath("../Surrogate Model")
addpath("../Data")
load('simpleColumn_model.mat')

xtest = readtable('..\Data\test_Inputs.csv');
ytest = readtable('..\Data\test_Outputs.csv');
xtest = table2array(xtest);
ytest = table2array(ytest);
ypred_test = example1_inference(xtest',simpleColumn_mlp);
error_test = abs(ytest-ypred_test);
test_mean = mean(error_test);
test_std = std(error_test);

xvald = readtable('..\Data\vald_Inputs.csv');
yvald = readtable('..\Data\vald_Outputs.csv');
xvald = table2array(xvald);
yvald = table2array(yvald);
ypred_vald = example1_inference(xvald',simpleColumn_mlp);
error_vald = abs(yvald-ypred_vald);
vald_mean = mean(error_vald);
vald_std = std(error_vald);

xtrain = readtable('..\Data\train_Inputs.csv');
ytrain = readtable('..\Data\train_Outputs.csv');
xtrain = table2array(xtrain);
ytrain = table2array(ytrain);
ypred_train = example1_inference(xtrain',simpleColumn_mlp);
error_train = abs(ytrain-ypred_train);
train_mean = mean(error_train);
train_std = std(error_train);

output_names = [
"Condenser Duty",
"Reboiler Duty",
"Top Molar Flow",
"Top Propane Molar Fraction",
"Top Isobutane Molar Fraction",
"Top n-Hexane Molar Fraction",
"Top Isopentane Molar Fraction",
"Top n-Heptane Molar Fraction",
"Bottom Molar Flow",
"Bottom Propane Molar Fraction",
"Bottom Isobutane Molar Fraction",
"Bottom n-Hexane Molar Fraction",
"Bottom Isopentane Molar Fraction",
"Bottom n-Heptane Molar Fraction",
];

output_units = ["kW","kW","mol/s","-","-","-","-","-","mol/s","-","-","-","-","-"];

% create figures
for idx = 1:numel(output_names)
    fig = figure;
    set(gcf,'position',[1 49 1536 836.8000])
    hold on
    % customize the plot as needed
    title(strcat("Example 1: ", output_names(idx), " Predictions"),'FontSize',18);
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
    filename = strcat('Example1_',strrep(output_names(idx),' ',''),'_truthplot');
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

lower_bounds = [175000,1250,0.46-0.075,0,0.7,360,140000];
upper_bounds = [225000,1650,0.46+0.075,0,0.95,370,200000];
randomInputs = rand(10000,7).*(upper_bounds - lower_bounds) + lower_bounds;
randomInputs(:,4) = 0.76 - randomInputs(:,3);
tic;
for idx = 1:10000
    example1_inference(randomInputs(idx,:)',simpleColumn_mlp);
end
surrogate_single_eval = toc/10000;

lower_bounds = [175000,1250,0.46-0.075,0,0.7,360,140000];
upper_bounds = [225000,1650,0.46+0.075,0,0.95,370,200000];
randomInputs = rand(100000,7).*(upper_bounds - lower_bounds) + lower_bounds;
randomInputs(:,4) = 0.76 - randomInputs(:,3);
tic;
for idx = 0:99
    example1_inference(randomInputs(1+idx*1000:(1+idx)*1000,:)',simpleColumn_mlp);
end
surrogate_batch_eval = toc/100;

column_names = ["DWSIM time", "Surrogate Single Eval","Surrogate Batch Eval"];
data = [dwsim_time,surrogate_single_eval, surrogate_batch_eval];
table = array2table(double(data),'VariableNames',column_names);
writetable(table, 'timingTable.csv');