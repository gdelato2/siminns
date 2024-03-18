rng("shuffle") 
beep off

%% Define Static Input Parameters

%Collection Parameters
static_name_list = ["coll_pipe_length"]; % parameter ID
value = [12]; % lower limit for sampling 
static_name_list(end+1) = "coll_pipe_ele";
value(end+1) = 3; 

static_name_list(end+1) = "p1_pipe_length";
value(end+1) = 12; 
static_name_list(end+1) = "p2_pipe_length";
value(end+1) = 14; 
static_name_list(end+1) = "p3_pipe_length";
value(end+1) = 15; 
static_name_list(end+1) = "p4_pipe_length";
value(end+1) = 11; 
static_name_list(end+1) = "p5_pipe_length";
value(end+1) = 12; 
static_name_list(end+1) = "p6_pipe_length";
value(end+1) = 3; 
static_name_list(end+1) = "p7_pipe_length";
value(end+1) = 5; 
static_name_list(end+1) = "p8_pipe_length";
value(end+1) = 4; 

%pipe1_lengths = rand(40,1)*20+35;
%pipe2_lengths = rand(40,1)*45+125;
%pipe2_eles = rand(40,1)*3+3;
pipe1_lengths = [38.0283,44.6643,52.3948,44.3357,52.2285,50.2190,43.0376,...
    40.0983,40.5911,49.1295,51.3490,45.5015,43.6681,44.3854,53.9596,...
    47.3208,51.7563,38.6878,54.2809,53.9845,48.4688,41.9756,43.6330,...
    44.2076,39.6577,47.1054,46.9801,53.9567,47.3592,36.1984,38.1523,...
    54.4119,54.1433,44.7075,51.0056,37.8377,43.4352,53.3147,50.8441,54.1898];
pipe2_lengths = [131.2844,149.4540,166.3627,128.9834,126.0385,139.7968,...
    157.9847,157.7173,142.3775,133.0498,159.6840,154.4212,168.7360,...
    156.8843,153.3783,166.4856,143.3478,155.5166,156.6212,157.1001,...
    162.1607,126.8768,155.4488,156.4926,168.2776,158.5084,146.8886,...
    149.5578,164.4024,135.9422,154.5083,126.6070,163.2108,167.0297,...
    155.5431,159.0983,158.4410,142.6502,154.4965,132.7034];
pipe2_eles = [5.8559,3.0761,5.0454,4.1172,4.9248,4.6616,3.9653,4.5469,...
    4.0670,4.4698,3.5598,4.8202,5.6585,4.6812,5.1158,5.4391,4.7450,...
    4.6785,4.8333,4.4734,3.4884,3.4237,5.7353,3.1240,5.1748,5.8929,...
    3.5225,4.4844,3.9711,5.4526,3.9042,4.8631,5.3754,5.0000,4.0326,...
    4.4320,3.1200,3.2230,3.2279,5.2940];

%Line Parameters
for idx = 1:40
    static_name_list(end+1) = strcat("pipe1_length_", int2str(idx));
    value(end+1) = pipe1_lengths(idx); 
    static_name_list(end+1) = strcat("pipe2_length_", int2str(idx));
    value(end+1) = pipe2_lengths(idx); 
    static_name_list(end+1) = strcat("pipe2_ele_", int2str(idx));
    value(end+1) = pipe2_eles(idx); 
end
model_parameters.name = static_name_list;
model_parameters.value = value;

%% Define Sampled Input Parameters

%Collection Parameters
sampled_name_list = ["collector_pressure"]; % parameter ID
lower_limit = [1]; % lower limit for sampling 
upper_limit = [1.5]; % upper limit for sampling
type = ["continuous"]; %continuous or binary 

%Line Parameters
for idx = 1:40
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
modelname = 'largeWaterPumpingNetwork';
for input_sample = input_sample_set
    [sim_sample,flag] = sampleModel(model_parameters, sampled_parameters, input_sample, modelname, 'largescale_sample.mat', 'largescale_out');
    if flag
        if new_dataset
            newDataTable = struct2table(sim_sample, 'AsArray', true);
            writetable(newDataTable, '.\Samples\largeWaterPumpingNetworkSamples.csv');
            new_dataset = false;
        else
            existingData = readtable('.\Samples\largeWaterPumpingNetworkSamples.csv');
            newDataTable = struct2table(sim_sample, 'AsArray', true);
            updatedData = [existingData;newDataTable];
            writetable(updatedData, '.\Samples\alt_largeWaterPumpingNetworkSamples.csv');
        end
    else
        disp('Sampling Error!')
    end
end