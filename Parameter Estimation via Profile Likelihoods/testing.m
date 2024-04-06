addpath("./Parameter Estimation/")
addpath(".\Surrogate Models")
load('.\Surrogate Models\small_model.mat');

% set-up figure for results viewing
close all
f = figure;
set(gcf, 'Position', [100, 100, 750, 450]);

%loop through different parameter estimations set-ups
numLoops = 1500;
scores = zeros(4*numLoops,1);

%create a gif with the saved plots
idx_movie = 0;
createGif = true;

% the set-up of each loop is completely random
% number of samples, operational points, and source pressures are random
for idx = 1:numLoops
    
    % random number of samples
    numSamples = ceil(rand()*25);
    z = ones(9,numSamples);

    % random collector pressure and pump speeds
    z(1,:) = rand(numSamples,1)*0.5 + 1.0;
    z(2,:) = rand(numSamples,1)*550 + 2450;
    z(4,:) = rand(numSamples,1)*550 + 2450;
    z(6,:) = rand(numSamples,1)*550 + 2450;
    z(8,:) = rand(numSamples,1)*550 + 2450;

    % random source pressures
    sp = rand(4,1)*0.8+0.6;
    z(3,:) = sp(1);
    z(5,:) = sp(2);
    z(7,:) = sp(3);
    z(9,:) = sp(4);
    sigma = [rand()*0.4+0.01,rand()*0.4+0.01,rand()*0.4+0.01,rand()*0.4+0.01];

    % line pressures sensors
    outputIdx = [3,6,9,12];

    % pump speeds are known
    knownInputs = z([1,2,4,6,8],:);

    % simulate input sampples
    out = small_scale_inference(z,parameter_small_mlp);

    % add noise to output to create sensor signals
    sensorReadings = out(:,outputIdx) + randn(numSamples,numel(outputIdx)).*sigma;

    % get scores for the actual source pressures
    % scores measure how confident we are that the parameter equals the
        % actual value.
    [scores_] = getConfidenceScores(knownInputs,sensorReadings,outputIdx,sigma,sp);
    scores(idx*4-3:idx*4,:)  = scores_;

    % update plot at regular interval
    if mod(idx,25)==0
        plot(linspace(0,1,numel(scores(1:idx*4))),sort(scores(1:idx*4)),'LineWidth',1.5)
        hold on
        plot(linspace(0,1,1000),chi2inv(linspace(0,1,1000),1),'--','LineWidth',1.5)
        hold off
        yticks([chi2inv(0.50,1),chi2inv(0.75,1),chi2inv(0.9,1),chi2inv(0.98,1)]);
        yticklabels({'50%',  '75%', '90%','98%'});
        xticks([0.5,0.75,0.9,0.98]);
        xticklabels({'0.5','0.75','0.9','0.98'});
        grid on
        xlim([0,0.99])
        ylim([0,chi2inv(0.99,1)])
        title([num2str(4*idx) ' Parameter Estimations: Confidence Level Spread of True Value'],'FontSize',10);
        ylabel('Confidence Level','FontSize',10);
        xlabel('Fraction of Samples','FontSize',10);
        legend('Sample Distribution','Theoretical Distribution','FontSize',10);
        hAx = gca;
        hAx.XAxis.FontSize = 10;
        hAx.YAxis.FontSize = 10;
        pause(0.2) 
        if createGif
            idx_movie = idx_movie + 1;
            exportgraphics(f,['./movie_figures/fig_' num2str(idx_movie) '.png'], 'Resolution',300)
        end
    end
end

if createGif
    % Define file names of the figures to be loaded
    figureFiles = cell(idx_movie,1);
    for ii = 1:idx_movie
        figureFiles(ii) = {['./movie_figures/fig_' num2str(ii) '.png']};
    end
    
    % Load each figure from file
    figs = cell(1, numel(figureFiles));
    for i = 1:numel(figureFiles)
        figs{i} = imread(figureFiles{i});
    end
    
    % Combine the images into a GIF
    gifFileName = 'testingplot.gif';
    delayTime = 0.15; % Adjust as needed
    for idx = 1:1:numel(figs)
        [A,map] = rgb2ind(figs{idx},128);
        if idx == 1
            imwrite(A,map,gifFileName,'gif','LoopCount',Inf,'DelayTime',delayTime);
        else
            imwrite(A,map,gifFileName,'gif','WriteMode','append','DelayTime',delayTime);
        end
    end
end