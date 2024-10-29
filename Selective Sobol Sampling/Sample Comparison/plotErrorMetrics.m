% This function takes an array of structs containing error metrics and 
% training sample sizes, and generates semilog plots for maximum, mean, 
% and standard deviation error metrics. The function can either create a 
% new figure or update an existing one. It also offers the option to save 
% the figure in both .fig and .png formats.
%
% Syntax:
%   f = plotErrorMetrics(resultsArray, f, figFileName, pngFileName)
%
% Inputs:
%   resultsArray  : A struct array, where each struct contains:
%                   - data: A struct with field numTraining (array of training sample sizes).
%                   - error: A struct with fields max, mean, and std (arrays of error metrics).
%                   - name: A string for the legend display.
%                   - plotType: A string specifying plot type ('line' or 'scatter').
%                   - color: A string representing the color for plotting.
%   f             : (Optional) A figure handle to update. If not provided, a new figure is created.
%   figFileName   : (Optional) A string for the filename to save the figure as a .fig file.
%   pngFileName   : (Optional) A string for the filename to save the figure as a .png file.
%
% Outputs:
%   f             : A figure handle for the created or updated figure.
%
% Examples:
%   f = plotErrorMetrics(resultsArray); % Creates a new figure with plots.
%
%   existingFig = figure;
%   f = plotErrorMetrics(resultsArray, existingFig, 'myFigure.fig', 'myFigure.png');

function f = plotErrorMetrics(resultsArray, f, figFileName, pngFileName)

    % Check if the resultsArray is not empty
    if isempty(resultsArray)
        error('Input array is empty');
    end
    % Create or use the provided figure
    if nargin < 2 || isempty(f) || ~isvalid(f)
        f = figure;
        f.Position = [100 100 1800 500];
    else
        clf(f); % Clear the existing figure
    end
    tiles = tiledlayout(1, 3, 'TileSpacing', 'tight', 'Padding', 'compact');

    % Error types
    errorTypes = {'max', 'mean', 'std'};
    titles = {'Max', 'Mean', 'Standard Deviation'};

    for i = 1:length(errorTypes)
        nexttile(tiles);
        hold on;
        legendHandles = [];
        
        % Plot each result in the array
        for j = 1:length(resultsArray)
            result = resultsArray(j);

            if isempty([result.error.(errorTypes{i})])
                continue
            end
            
            % Determine plotting method based on plotType
            if strcmp(result.plotting.plotType, 'line')
                p = semilogy([result.data.numTraining], [result.error.(errorTypes{i})], ...
                              '--', 'Color', result.plotting.color, ...
                              'MarkerFaceColor', result.plotting.color, ...
                              'DisplayName', result.name, 'Marker', 'o');
            elseif strcmp(result.plotting.plotType, 'scatter')
                p = scatter([result.data.numTraining], [result.error.(errorTypes{i})], ...
                             'filled', 'MarkerFaceColor', result.plotting.color, ...
                             'DisplayName', result.name);
            else
                warning('Unknown plot type for %s: %s', result.name, result.plotting.plotType);
                continue; % Skip to the next result
            end
            
            legendHandles = [legendHandles, p]; %#ok<AGROW> % Collect handles for legend
        end

        set(gca, 'yscale', 'log');
        title(titles{i});
        grid on;
        box on;
        xlabel('Number of Training Samples');

        if i == 1
            ylabel('Error Metric');
        end

    end

    % Create the legend
    hL = legend(legendHandles);
    hL.Layout.Tile = 'East';
    
    % Save the figure if filenames are provided
    if nargin >= 3 && ~isempty(figFileName)
        savefig(f, figFileName);
    end
    if nargin >= 4 && ~isempty(pngFileName)
        saveas(f, pngFileName, 'png');
    end
    pause(1);
end
