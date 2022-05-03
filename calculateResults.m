% Define directory names with models
directoryNames = ["model1/", "model2/", "model3/", "model4/"];

% Create empty structures
player1Results = zeros(length(directoryNames), 4);
player2Results = zeros(length(directoryNames), 4);
rowNames = strings;

for directoryIndex = 1:length(directoryNames)
    % Test the model
    [randomScoresSave, minimaxScoresSave] = testModel(directoryNames(directoryIndex));
    rowNames(directoryIndex) = "model"+int2str(directoryIndex);
    
    % Calculate the results for the model
    player1Results(directoryIndex,1) = sum(randomScoresSave(:,1))/50;
    player1Results(directoryIndex,2) = max(randomScoresSave(:,1))/5;

    player1Results(directoryIndex,3) = sum(minimaxScoresSave(:,1))/5;
    player1Results(directoryIndex,4) = max(minimaxScoresSave(:,1))*2;

    player2Results(directoryIndex,1) = sum(randomScoresSave(:,4))/50;
    player2Results(directoryIndex,2) = max(randomScoresSave(:,4))/5;

    player2Results(directoryIndex,3) = sum(minimaxScoresSave(:,4))/5;
    player2Results(directoryIndex,4) = max(minimaxScoresSave(:,4))*2;
end

% Display the results

disp("Player 1 results");
disp(array2table(player1Results, "VariableNames", ...
    {'Average vs random (%)', 'Best vs random (%)', ...
    'Average vs minimax (%)', 'Best vs minimax (%)'}, ...
    "RowNames" , rowNames))

disp("Player 2 results");
disp(array2table(player2Results, "VariableNames", ...
    {'Average vs random (%)', 'Best vs random (%)', ...
    'Average vs minimax (%)', 'Best vs minimax (%)'}, ...
    "RowNames" , rowNames))

