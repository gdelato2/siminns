input_bounds =  [];
input_bounds.('feed_pressure') = [175000, 225000];
input_bounds.('feed_molarflow') = [1250, 1650];
input_bounds.('n_hexane_isopentane_dev') = [-0.075, 0.075];
input_bounds.('reflux_ratio') = [0.7, 0.95];
input_bounds.('rebolier_temp') = [360, 370];
input_bounds.('top_pressure') = [140000, 200000];

% random inference, replace with desired inputs
x = zeros(7,1);
x(1) = rand()*(input_bounds.feed_pressure(2) - input_bounds.feed_pressure(1)) + input_bounds.feed_pressure(1);
x(2) = rand()*(input_bounds.feed_molarflow(2) - input_bounds.feed_molarflow(1)) + input_bounds.feed_molarflow(1);  
x(3) = 0.46 + rand()*(input_bounds.n_hexane_isopentane_dev(2) - input_bounds.n_hexane_isopentane_dev(1)) + input_bounds.n_hexane_isopentane_dev(1);
x(4) = 0.76 - x(3);
x(5) = rand()*(input_bounds.reflux_ratio(2) - input_bounds.reflux_ratio(1)) + input_bounds.reflux_ratio(1);
x(6) = rand()*(input_bounds.rebolier_temp(2) - input_bounds.rebolier_temp(1)) + input_bounds.rebolier_temp(1);
x(7) = rand()*(input_bounds.top_pressure(2) - input_bounds.top_pressure(1)) + input_bounds.top_pressure(1);

load('simpleColumn_model.mat')
[output_values] = example1_inference(x,simpleColumn_mlp);

output_names=[
"CondenserDuty",
"ReboilerDuty",
"TopMolarFlow",
"TopPropaneMolarFraction",
"TopIsobutaneMolarFraction",
"TopNhexaneMolarFraction",
"TopIsopentaneMolarFraction",
"TopNheptaneMolarFraction",
"BottomMolarFlow",
"BottomPropaneMolarFraction",
"BottomIsobutaneMolarFraction",
"BottomNhexaneMolarFraction",
"BottomIsopentaneMolarFraction",
"BottomNheptaneMolarFraction",
];

out = [];
for idx = 1:length(output_values)
    out.(output_names(idx)) = output_values(idx);
end
out