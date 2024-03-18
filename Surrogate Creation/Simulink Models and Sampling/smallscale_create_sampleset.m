rng("shuffle") 
beep off

%% Define Static Input Parameters

%Collection Parameters
static_name_list = ["coll_pipe_length"]; % parameter ID
value = [12]; % lower limit for sampling 
static_name_list(end+1) = "coll_pipe_ele";
value(end+1) = 3; 

%Line 1 Parameters
static_name_list(end+1) = "pipe1_length_1";
value(end+1) = 41; 
static_name_list(end+1) = "pipe2_length_1";
value(end+1) = 153; 
static_name_list(end+1) = "pipe2_ele_1";
value(end+1) = 12; 

%Line 2 Parameters
static_name_list(end+1) = "pipe1_length_2";
value(end+1) = 61; 
static_name_list(end+1) = "pipe2_length_2";
value(end+1) = 126; 
static_name_list(end+1) = "pipe2_ele_2";
value(end+1) = 11; 

%Line 3 Parameters
static_name_list(end+1) = "pipe1_length_3";
value(end+1) = 52; 
static_name_list(end+1) = "pipe2_length_3";
value(end+1) = 162; 
static_name_list(end+1) = "pipe2_ele_3";
value(end+1) = 15; 

%Line 4 Parameters
static_name_list(end+1) = "pipe1_length_4";
value(end+1) = 55; 
static_name_list(end+1) = "pipe2_length_4";
value(end+1) = 150; 
static_name_list(end+1) = "pipe2_ele_4";
value(end+1) = 12.6; 

model_parameters.name = static_name_list;
model_parameters.value = value;

%% Define Sampled Input Parameters

%Collection Parameters
sampled_name_list = ["collector_pressure"]; % parameter ID
lower_limit = [1]; % lower limit for sampling 
upper_limit = [1.5]; % upper limit for sampling
type = ["continuous"]; %continuous or binary 

%Line 1,2,3 and 4 Parameters
for idx = 1:4
    sampled_name_list(end+1) = strcat("pump_speed_", int2str(idx));
    lower_limit(end+1) = 2450;
    upper_limit(end+1) = 3000;
    type(end+1) = "continuous";
    sampled_name_list(end+1) = strcat("source_pressure_", int2str(idx));
    lower_limit(end+1) = 0.5;
    upper_limit(end+1) = 1.5;
    type(end+1) = "continuous";
end
    
sampled_parameters = [];
for idx = 1:length(sampled_name_list)    
    sampled_parameters(idx).limits = [lower_limit(idx), upper_limit(idx)];
    sampled_parameters(idx).type = type(idx);
    sampled_parameters(idx).name = sampled_name_list(idx);
end

%% Create a Random Input Set
input_sample_set = lhsdesign(1000,length(sampled_name_list))';

%% Sample the Input Set
new_dataset = true;
modelname = 'smallWaterPumpingNetwork';
for input_sample = input_sample_set
    [sim_sample,flag] = sampleModel(model_parameters, sampled_parameters, input_sample, modelname, 'smallscale_sample.mat', 'smallscale_out');
    if flag
        if new_dataset
            newDataTable = struct2table(sim_sample, 'AsArray', true);
            writetable(newDataTable, '.\Samples\basicWaterPumpingNetworkSamples.csv');
            new_dataset = false;
        else
            existingData = readtable('.\Samples\basicWaterPumpingNetworkSamples.csv');
            newDataTable = struct2table(sim_sample, 'AsArray', true);
            updatedData = [existingData;newDataTable];
            writetable(updatedData, '.\Samples\basicWaterPumpingNetworkSamples.csv');
        end
    else
        disp('Sampling Error!')
    end
end