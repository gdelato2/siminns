clear all
close all
addpath('../Samplers/')

%% Define Scope
% Define nominal limits for different parameters
nominalLimits = struct();
nominalLimits.("MolarFraction1") = struct("index", 1, "limits", [0.2, 0.4]);
nominalLimits.("MolarFraction2") = struct("index", 2, "limits", [0.25, 0.55]);
nominalLimits.("MolarFraction3") = struct("index", 3, "limits", [0.25, 0.35]);
nominalLimits.("FlowRate") = struct("index", 4, "limits", [10, 25]);
nominalLimits.("Pressure") = struct("index", 5, "limits", [1058, 1584]);

% Set parameters
numParameters = length(fieldnames(nominalLimits));  % Count the number of parameters
parametersNormalize = ["MolarFraction1", "MolarFraction2", "MolarFraction3"];% Specify which parameters require normalization
numSamples = 5000;  % Set the number of samples to generate

%% Simple Approach
% Define the simple normalization function that scales values based on their sum
function sample = normalizeFunction(sample, parametersNormalize)
    sumFields = sum(arrayfun(@(k) sample.(parametersNormalize(k)).value, 1:numel(parametersNormalize)));
    for k = 1:numel(parametersNormalize)
        sample.(parametersNormalize{k}).value = sample.(parametersNormalize(k)).value / sumFields;
    end
end
normalizeFun = @(x) normalizeFunction(x, parametersNormalize);  % Create a handle to the normalization function

% Generate regular samples using Latin Hypercube Sampling (LHS) and the simple normalization function
[simpleSampleTable] = regularSampling(lhsdesign(numSamples, numParameters), nominalLimits, normalizeFun);
writetable(simpleSampleTable, 'example1_simpleSampleTable.csv');

%% Sampling with Constraints
% Define constraints function for constrained sampling
function [c, ceq, dc, deq] = sampleConstraint(x, idxNormalize)
    ceq = sum(x(idxNormalize)) - 1;  % Set constraint for normalized parameters to sum to 1
    deq = zeros(size(x))';
    deq(idxNormalize) = 1;  
    c = [];
    dc = [];
end
idxNormalize = arrayfun(@(k) nominalLimits.(parametersNormalize(k)).index, 1:numel(parametersNormalize));
constraintFun = @(x) sampleConstraint(x, idxNormalize);

% Generate constrained samples
[constraintSampleTable] = constrainedSampling(lhsdesign(numSamples, numParameters), nominalLimits, constraintFun, []);
writetable(constraintSampleTable, 'example1_constraintSampleTable.csv');

%% Plotting
% Set up figure for plotting histograms of the molar fractions
f = figure;
f.Position = [100 100 1800 500];

tiles = tiledlayout(1, 3, 'TileSpacing', 'tight', 'Padding', 'compact');
tiles.Title.String = 'Example 1: Summation Constraint';


titles = {'Molar Fraction 1', 'Molar Fraction 2', 'Molar Fraction 3'};

% Plot histograms for each molar fraction
% Molar Fraction 1
nexttile(tiles);
hold on;
minData = floor(20*min([nominalLimits.MolarFraction1.limits(1), min(simpleSampleTable.MolarFraction1), min(constraintSampleTable.MolarFraction1)]))/20;
maxData = ceil(20*max([nominalLimits.MolarFraction1.limits(2), max(simpleSampleTable.MolarFraction1), max(constraintSampleTable.MolarFraction1)]))/20;
h = histogram(simpleSampleTable.MolarFraction1, minData:0.01:maxData, 'Normalization', 'probability');
histogram(constraintSampleTable.MolarFraction1, h.BinEdges, 'Normalization','probability');
idxMin = find(h.BinEdges <= nominalLimits.MolarFraction1.limits(1), 1, 'last');
idxMax = find(h.BinEdges >= nominalLimits.MolarFraction1.limits(2), 1, 'first');
upper = ceil(10 * max(h.BinCounts / sum(h.BinCounts))) / 10;
plot([h.BinEdges(idxMin), h.BinEdges(idxMin)], [0, upper], 'k--', 'LineWidth', 1.5)
idealProb = 1 / ((nominalLimits.MolarFraction1.limits(2) - nominalLimits.MolarFraction1.limits(1)) / 0.01);
plot([h.BinEdges(idxMin), h.BinEdges(idxMax)], [idealProb, idealProb], 'b--', 'LineWidth', 1.5)
xlim([h.BinEdges(idxMin) - 0.1, h.BinEdges(idxMax) + 0.1])
plot([h.BinEdges(idxMax), h.BinEdges(idxMax)], [0, upper], 'k--', 'LineWidth', 1.5)
grid on
box on
title(titles{1});
xlabel('Molar Fraction (-)')
ylabel('Probability')

% Molar Fraction 2
nexttile(tiles);
hold on;
minData = floor(20*min([nominalLimits.MolarFraction2.limits(1), min(simpleSampleTable.MolarFraction2), min(constraintSampleTable.MolarFraction2)]))/20;
maxData = ceil(20*max([nominalLimits.MolarFraction2.limits(2), max(simpleSampleTable.MolarFraction2), max(constraintSampleTable.MolarFraction2)]))/20;
h = histogram(simpleSampleTable.MolarFraction2, minData:0.01:maxData, 'Normalization', 'probability');
histogram(constraintSampleTable.MolarFraction2, h.BinEdges, 'Normalization','probability');
idxMin = find(h.BinEdges <= nominalLimits.MolarFraction2.limits(1), 1, 'last');
idxMax = find(h.BinEdges >= nominalLimits.MolarFraction2.limits(2), 1, 'first');
upper = ceil(10 * max(h.BinCounts / sum(h.BinCounts))) / 10;
plot([h.BinEdges(idxMin), h.BinEdges(idxMin)], [0, upper], 'k--', 'LineWidth', 1.5)
idealProb = 1 / ((nominalLimits.MolarFraction2.limits(2) - nominalLimits.MolarFraction2.limits(1)) / 0.01);
plot([h.BinEdges(idxMin), h.BinEdges(idxMax)], [idealProb, idealProb], 'b--', 'LineWidth', 1.5)
xlim([h.BinEdges(idxMin) - 0.1, h.BinEdges(idxMax) + 0.1])
plot([h.BinEdges(idxMax), h.BinEdges(idxMax)], [0, upper], 'k--', 'LineWidth', 1.5)
grid on
box on
title(titles{2});
xlabel('Molar Fraction (-)')

% Molar Fraction 3
nexttile(tiles);
hold on;
minData = floor(20*min([nominalLimits.MolarFraction3.limits(1), min(simpleSampleTable.MolarFraction3), min(constraintSampleTable.MolarFraction3)]))/20;
maxData = ceil(20*max([nominalLimits.MolarFraction3.limits(2), max(simpleSampleTable.MolarFraction3), max(constraintSampleTable.MolarFraction3)]))/20;
h = histogram(simpleSampleTable.MolarFraction3, minData:0.01:maxData, 'Normalization', 'probability');
histogram(constraintSampleTable.MolarFraction3, h.BinEdges, 'Normalization','probability');
idxMin = find(h.BinEdges <= nominalLimits.MolarFraction3.limits(1), 1, 'last');
idxMax = find(h.BinEdges >= nominalLimits.MolarFraction3.limits(2), 1, 'first');
upper = ceil(10 * max(h.BinCounts / sum(h.BinCounts))) / 10;
plot([h.BinEdges(idxMin), h.BinEdges(idxMin)], [0, upper], 'k--', 'LineWidth', 1.5)
idealProb = 1 / ((nominalLimits.MolarFraction3.limits(2) - nominalLimits.MolarFraction3.limits(1)) / 0.01);
plot([h.BinEdges(idxMin), h.BinEdges(idxMax)], [idealProb, idealProb], 'b--', 'LineWidth', 1.5)
xlim([h.BinEdges(idxMin) - 0.1, h.BinEdges(idxMax) + 0.1])
plot([h.BinEdges(idxMax), h.BinEdges(idxMax)], [0, upper], 'k--', 'LineWidth', 1.5)
grid on
box on
title(titles{3});
xlabel('Molar Fraction (-)')

legend('Simple Normalization', 'Constrained Sampling', 'Nominal Limits', 'Ideal Probability')