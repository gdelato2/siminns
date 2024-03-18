function [sample_point, flag_] = sampleModel(model_parameters, sampled_parameters, inputs, modelName, sample_file, out_var)

    if  ~bdIsLoaded(modelName)
        load_system(modelName)
    end
    
    timeout_t = 50;
    flag_ = true;
    
    for idx = 1:length(sampled_parameters)
        parameter = sampled_parameters(idx);
        if parameter.type == "continuous"
            input_parameters.(parameter.name) = inputs(idx)*(parameter.limits(2) - parameter.limits(1)) + parameter.limits(1);
        elseif parameter.type == "binary"
            input_parameters.(parameter.name) = round(inputs(idx)*(parameter.limits(2) - parameter.limits(1)) + parameter.limits(1));
        end
    end

    for idx = 1:length(model_parameters.name)
        input_parameters.(model_parameters.name(idx)) = model_parameters.value(idx);
    end
    save(sample_file,"input_parameters")
    
    % Start the Simulink model
    set_param(modelName, 'SimulationCommand', 'start');
    
    % Check the status of the simulation
    simStatus = get_param(modelName, 'SimulationStatus');
    
    tic
    % Wait for the simulation to complete
    while strcmp(simStatus, 'running')
        pause(1);  % Wait for 1 second
        simStatus = get_param(modelName, 'SimulationStatus');
        if toc>timeout_t
            flag_ = false;
            break
        end
    end
    
    % Stop the Simulink model
    set_param(modelName, 'SimulationCommand', 'stop');
    
    % Process output
    output = evalin('base', out_var);
    
    % check for errors or warnings
    if numel(output.SimulationMetadata.ExecutionInfo.WarningDiagnostics)>0 || numel(output.ErrorMessage)>0
        flag_ = false;
        disp('Errors or Warnings in Simulinlk');
    end
    
    sample_point = [];
    if flag_
        sample_point.("sim_time") = output.SimulationMetadata.TimingInfo.TotalElapsedWallTime;
        
        output = output.signals;
        field_names = fieldnames(output);

        for idx1 = 1:length(field_names)
            if contains(field_names{idx1}, 'Subsystem_')
                subsystem = erase(field_names{idx1}, 'Subsystem_');
                lines = fieldnames(output.(field_names{idx1}));
                for idx2 = 1:length(lines)
                    line = erase(lines{idx2}, 'sensor_signals_');
                    parameters = fieldnames(output.(field_names{idx1}).(lines{idx2}));
                    for idx3 = 1:length(parameters)
                        sample_point.("output_"+subsystem + "_" + line + "_" + parameters{idx3}) = ...
                            output.(field_names{idx1}).(lines{idx2}).(parameters{idx3}).Data(end);
                        sample_point.("score_output_"+subsystem + "_" + line + "_" + parameters{idx3}) = ...
                            steadyStateScore(output.(field_names{idx1}).(lines{idx2}).(parameters{idx3}).Data,...
                                                output.(field_names{idx1}).(lines{idx2}).(parameters{idx3}).Time);
                    end
                end
            elseif contains(field_names{idx1}, 'Collector')
                parameters = fieldnames(output.Collector);
                for idx3 = 1:length(parameters)
                    sample_point.("output_collector_" + parameters{idx3}) = ...
                        output.Collector.(parameters{idx3}).Data(end);
                    sample_point.("score_output_collector_" + parameters{idx3}) = ...
                        steadyStateScore(output.Collector.(parameters{idx3}).Data,...
                                            output.Collector.(parameters{idx3}).Time);
                end
            end
        end
        
        field_names = fieldnames(input_parameters);
        for idx1 = 1:length(field_names)
            sample_point.("input_"+field_names{idx1}) = ...
                        input_parameters.(field_names{idx1});
        end
    end
end


function [score] = steadyStateScore(data, time)
    tf = time(end);
    idx_std = time>(tf*0.95);
    score = std(data(idx_std));
end