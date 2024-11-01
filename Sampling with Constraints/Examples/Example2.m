clear all
close all
addpath('../Samplers/')

%% Define Scope
% Define nominal limits for different parameters
nominalLimits = struct();
nominalLimits.("Inlet1") = struct("index", 1, "limits", [10, 100]);
nominalLimits.("Inlet2") = struct("index", 2, "limits", [10, 100]);
nominalLimits.("Inlet3") = struct("index", 3, "limits", [10, 100]);
nominalLimits.("Outlet") = struct("index", 4, "limits", [30, 300]);

% Set parameters
inlets = ["Inlet1", "Inlet2", "Inlet3"];
outlet = "Outlet";
numParameters = length(fieldnames(nominalLimits));
numSamples = 5000;

%% Simple Approach
% Define the simple normalization function, outlet is defined by sum
function sample = normalizeFunction(sample)
   sample.Outlet.value  = sample.Inlet1.value + sample.Inlet2.value + sample.Inlet3.value;
end
normalizeFun = @(x) normalizeFunction(x);

% Generate regular samples using Latin Hypercube Sampling (LHS) and the simple normalization function
[simpleSampleTable] = regularSampling(lhsdesign(numSamples, numParameters), nominalLimits, normalizeFun);
writetable(simpleSampleTable, 'example2_simpleSampleTable.csv');

%% Sampling with Constraints
% Define constraints function for constrained sampling
function [c, ceq, dc , deq] = sampleConstraint(x, idxInlets, idxOutlet)
    ceq = sum(x(idxInlets)) - x(4); %sum of inlets equal outlet
    deq = zeros(size(x))';
    deq(idxInlets) = 1;
    deq(idxOutlet) = -1;
    c = [];
    dc = [];
end
idxInlets = arrayfun(@(k) nominalLimits.(inlets(k)).index, 1:numel(inlets));
idxOutlet = nominalLimits.(outlet).index;
constraintFun = @(x) sampleConstraint(x, idxInlets, idxOutlet);

% Generate constrained samples
[constraintSampleTable] = constrainedSampling(lhsdesign(numSamples, numParameters), nominalLimits, constraintFun, [idxOutlet]);
writetable(constraintSampleTable, 'example2_constraintSampleTable.csv');

%% Plotting
% Set up figure for plotting histograms of the molar fractions
f = figure;
f.Position = [100 100 1800 500];

tiles = tiledlayout(1, 4, 'TileSpacing', 'tight', 'Padding', 'compact');
tiles.Title.String = 'Example 2: Uniformity in Composite Parameters';
titles = {'Inlet 1', 'Inlet 2', 'Inlet 3', 'Outlet'};

% Plot histograms for inlets/outlet
% Inlet 1
nexttile(tiles);
hold on;
minData = floor(20*min([nominalLimits.Inlet1.limits(1), min(simpleSampleTable.Inlet1), min(constraintSampleTable.Inlet1)]))/20;
maxData = ceil(20*max([nominalLimits.Inlet1.limits(2), max(simpleSampleTable.Inlet1), max(constraintSampleTable.Inlet1)]))/20;
h = histogram(simpleSampleTable.Inlet1, minData:5:maxData, 'Normalization', 'probability');
g = histogram(constraintSampleTable.Inlet1, h.BinEdges, 'Normalization','probability');
idxMin = find(h.BinEdges<=nominalLimits.Inlet1.limits(1), 1, 'last');
idxMax = find(h.BinEdges>=nominalLimits.Inlet1.limits(2), 1, 'first');
upper = ceil(20*max((g.BinCounts)/sum(g.BinCounts)))/20;
plot([h.BinEdges(idxMin), h.BinEdges(idxMin)], [0, upper], 'k--', 'LineWidth', 1.5)
xlim([h.BinEdges(idxMin) - 5, h.BinEdges(idxMax) + 5])
plot([h.BinEdges(idxMax), h.BinEdges(idxMax)], [0, upper], 'k--', 'LineWidth', 1.5)
grid on
box on
title(titles{1});
xlabel('Flow Rate (lpm)')
ylabel('Probability')

% Inlet 2
nexttile(tiles);
hold on;
minData = floor(20*min([nominalLimits.Inlet2.limits(1), min(simpleSampleTable.Inlet2), min(constraintSampleTable.Inlet2)]))/20;
maxData = ceil(20*max([nominalLimits.Inlet2.limits(2), max(simpleSampleTable.Inlet2), max(constraintSampleTable.Inlet2)]))/20;
h = histogram(simpleSampleTable.Inlet2, minData:5:maxData, 'Normalization', 'probability');
g = histogram(constraintSampleTable.Inlet2, h.BinEdges, 'Normalization','probability');
idxMin = find(h.BinEdges<=nominalLimits.Inlet2.limits(1), 1, 'last');
idxMax = find(h.BinEdges>=nominalLimits.Inlet2.limits(2), 1, 'first');
upper = ceil(20*max((g.BinCounts)/sum(g.BinCounts)))/20;
plot([h.BinEdges(idxMin), h.BinEdges(idxMin)], [0, upper], 'k--', 'LineWidth', 1.5)
xlim([h.BinEdges(idxMin) - 5, h.BinEdges(idxMax) + 5])
plot([h.BinEdges(idxMax), h.BinEdges(idxMax)], [0, upper], 'k--', 'LineWidth', 1.5)
grid on
box on
title(titles{2});
xlabel('Flow Rate (lpm)')
ylabel('Probability')

% Inlet 3
nexttile(tiles);
hold on;
minData = floor(20*min([nominalLimits.Inlet3.limits(1), min(simpleSampleTable.Inlet3), min(constraintSampleTable.Inlet3)]))/20;
maxData = ceil(20*max([nominalLimits.Inlet3.limits(2), max(simpleSampleTable.Inlet3), max(constraintSampleTable.Inlet3)]))/20;
h = histogram(simpleSampleTable.Inlet3, minData:5:maxData, 'Normalization', 'probability');
g = histogram(constraintSampleTable.Inlet3, h.BinEdges, 'Normalization','probability');
idxMin = find(h.BinEdges<=nominalLimits.Inlet3.limits(1), 1, 'last');
idxMax = find(h.BinEdges>=nominalLimits.Inlet3.limits(2), 1, 'first');
upper = ceil(20*max((g.BinCounts)/sum(g.BinCounts)))/20;
plot([h.BinEdges(idxMin), h.BinEdges(idxMin)], [0, upper], 'k--', 'LineWidth', 1.5)
xlim([h.BinEdges(idxMin) - 5, h.BinEdges(idxMax) + 5])
plot([h.BinEdges(idxMax), h.BinEdges(idxMax)], [0, upper], 'k--', 'LineWidth', 1.5)
grid on
box on
title(titles{3});
xlabel('Flow Rate (lpm)')
ylabel('Probability')

% Outlet
nexttile(tiles);
hold on;
minData = floor(20*min([nominalLimits.Outlet.limits(1), min(simpleSampleTable.Outlet), min(constraintSampleTable.Outlet)]))/20;
maxData = ceil(20*max([nominalLimits.Outlet.limits(2), max(simpleSampleTable.Outlet), max(constraintSampleTable.Outlet)]))/20;
h = histogram(simpleSampleTable.Outlet, minData:5:maxData, 'Normalization', 'probability');
histogram(constraintSampleTable.Outlet, h.BinEdges, 'Normalization','probability');
idxMin = find(h.BinEdges<=nominalLimits.Outlet.limits(1), 1, 'last');
idxMax = find(h.BinEdges>=nominalLimits.Outlet.limits(2), 1, 'first');
upper = ceil(20*max((h.BinCounts)/sum(h.BinCounts)))/20;
plot([h.BinEdges(idxMin), h.BinEdges(idxMin)], [0, upper], 'k--', 'LineWidth', 1.5)
idealProb = 1/((nominalLimits.Outlet.limits(2) - nominalLimits.Outlet.limits(1))/5);
plot([h.BinEdges(idxMin), h.BinEdges(idxMax)], [idealProb, idealProb], 'b--', 'LineWidth', 1.5)
xlim([h.BinEdges(idxMin) - 5, h.BinEdges(idxMax) + 5])
plot([h.BinEdges(idxMax), h.BinEdges(idxMax)], [0, upper], 'k--', 'LineWidth', 1.5)
grid on
box on
title(titles{4});
xlabel('Flow Rate (lpm)')
ylabel('Probability')
legend('Simple Sampling','Constrained Sampling','Nominal Limits', 'Ideal Probability')