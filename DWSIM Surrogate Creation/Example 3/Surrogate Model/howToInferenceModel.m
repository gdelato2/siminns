input_bounds =  [];
input_bounds.('produced_gas_molarflow') = [450, 480];
input_bounds.('produced_gas_dev_ethane') = [-0.03, 0.03];
input_bounds.('produced_gas_dev_propane') = [-0.03, 0.03]; 
input_bounds.('demethanizer_reflux_ratio') = [4.5, 5.5];
input_bounds.('deethaner_reflux_ratio') = [4.5, 5.5];
input_bounds.('debutanizer_reflux_ratio') = [4.5, 5.5];
input_bounds.('demethanizer_reboiler_temp') = [195, 205];
input_bounds.('deethaner_reboiler_temp') = [300, 310];
input_bounds.('debutanizer_reboiler_temp') = [342, 352];
input_bounds.('demethanizer_pressure') = [980880*0.85, 980880*1.15];
input_bounds.('deethaner_pressure') = [784705*0.85, 784705*1.15];
input_bounds.('debutanizer_pressure') = [450000, 600000];

% random inference, replace with desired inputs
x = zeros(13,1);
x(1) = rand()*(input_bounds.produced_gas_molarflow(2) - input_bounds.produced_gas_molarflow(1)) + input_bounds.produced_gas_molarflow(1);
x(3) = 0.0872501 + rand()*(input_bounds.produced_gas_dev_ethane(2) - input_bounds.produced_gas_dev_ethane(1)) + input_bounds.produced_gas_dev_ethane(1);
x(4) = 0.0523501 + rand()*(input_bounds.produced_gas_dev_propane(2) - input_bounds.produced_gas_dev_propane(1)) + input_bounds.produced_gas_dev_propane(1);
x(2) = 0.8376- x(3)- x(4);
x(5) = rand()*(input_bounds.demethanizer_reflux_ratio(2) - input_bounds.demethanizer_reflux_ratio(1)) + input_bounds.demethanizer_reflux_ratio(1);
x(6) = rand()*(input_bounds.deethaner_reflux_ratio(2) - input_bounds.deethaner_reflux_ratio(1)) + input_bounds.deethaner_reflux_ratio(1);
x(7) = rand()*(input_bounds.debutanizer_reflux_ratio(2) - input_bounds.debutanizer_reflux_ratio(1)) + input_bounds.debutanizer_reflux_ratio(1);
x(8) = rand()*(input_bounds.demethanizer_reboiler_temp(2) - input_bounds.demethanizer_reboiler_temp(1)) + input_bounds.demethanizer_reboiler_temp(1);
x(9) = rand()*(input_bounds.deethaner_reboiler_temp(2) - input_bounds.deethaner_reboiler_temp(1)) + input_bounds.deethaner_reboiler_temp(1);
x(10) = rand()*(input_bounds.debutanizer_reboiler_temp(2) - input_bounds.debutanizer_reboiler_temp(1)) + input_bounds.debutanizer_reboiler_temp(1);
x(11) = rand()*(input_bounds.demethanizer_pressure(2) - input_bounds.demethanizer_pressure(1)) + input_bounds.demethanizer_pressure(1);
x(12) = rand()*(input_bounds.deethaner_pressure(2) - input_bounds.deethaner_pressure(1)) + input_bounds.deethaner_pressure(1);
x(13) = rand()*(input_bounds.debutanizer_pressure(2) - input_bounds.debutanizer_pressure(1)) + input_bounds.debutanizer_pressure(1);

load('naturalGasProcessingUnit_model.mat')
[output_values] = example3_inference(x,naturalGasProcessingUnit_mlp);

output_names=["Condenser1Duty",
"Condenser2Duty",
"Condenser3Duty",
"CompresserDuty",
"CoolerDuty",
"ExpanderDuty",
"HeaterDuty",
"LiquidMolarFlow",
"Product1MethaneMolarFraction",
"Product1MolarFlow",
"Product1NitrogenMolarFraction",
"Product1CarbonDioxideMolarFraction",
"Product2EthaneMolarFraction",
"Product2IsobutaneMolarFraction",
"Product2IsopentaneMolarFraction",
"Product2MethaneMolarFraction",
"Product2MolarFlow",
"Product2NbutaneMolarFraction",
"Product2PropaneMolarFraction",
"Product3CarbonDioxideMolarFraction",
"Product3EthaneMolarFraction",
"Product3IsobutaneMolarFraction",
"Product3IsopentaneMolarFraction",
"Product3MolarFlow",
"Product3NbutaneMolarFraction",
"Product3NpentaneMolarFraction",
"Product3PropaneMolarFraction",
"Product4IsobutaneMolarFraction",
"Product4IsopentaneMolarFraction",
"Product4MolarFlow",
"Product4NbutaneMolarFraction",
"Product4NpentaneMolarFraction",
"Product4PropaneMolarFraction",
"Reboiler1Duty",
"Reboiler2Duty",
"Reboiler3Duty",
 ];

out = [];
for idx = 1:length(output_values)
    out.(output_names(idx)) = output_values(idx);
end
out