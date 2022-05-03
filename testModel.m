function [randomScoresSave, minimaxScoresSave] = testModel(directoryName)

    % Choose mat files than need to be run
    listOfFiles = ["Agent1000.mat", "Agent2000.mat", "Agent3000.mat", ...
        "Agent4000.mat", "Agent5000.mat", "Agent6000.mat", ...
        "Agent7000.mat", "Agent8000.mat","Agent9000.mat", "Agent10000.mat"];

    % Variables for result saving
    randomScoresSave = zeros(length(listOfFiles),6);
    minimaxScoresSave = zeros(length(listOfFiles),6);

    % Run games for each of the files
    for i = 1:length(listOfFiles)
        % Load model and DNN
        modelName = directoryName + listOfFiles(i);
        load(modelName,'saved_agent');
        criticNet = getModel(getCritic(saved_agent));
        
        % Play games
        [randomScore, minimaxScore] = play(criticNet, modelName);
        
        % Save scores
        randomScoresSave(i, 1:6) = randomScore;
        minimaxScoresSave(i, 1:6) = minimaxScore;
    end

end

function [randomScore, minimaxScore] = play(criticNet, modelName)
    % Create environments and important variables
    randomEnvironment = mancalaRandom;
    minimaxEnvironment = mancalaMinimax(5);
    
    randomScore = [0,0,0,0,0,0];
    minimaxScore = [0,0,0,0,0,0];
    
    % Display name of currently running model (to monitor the progress)
    disp("Currently running model: "+modelName);

    for randomGames = 1:1000
        randomEnvironment.reset();
        
        IsDone = false;
        endTurn = false;
        if randomGames > 500
            % Make player 2 start games (thereafore player 2 is now player
            % 1 for the assessment statistics. This was done in order to
            % avoid rotating the state of the board before and after each move

            while endTurn == false && IsDone == false
                places = find(randomEnvironment.State(8:13)>0);
    
                % Find a random legal action and perform it
                opponentAction = places(randperm(length(places), 1));
                [Observation, endTurn] = move(randomEnvironment, opponentAction, 1);
                randomEnvironment.State = Observation;
                [Observation, IsDone] = ifTerminal(randomEnvironment, endTurn, 1);
            end

            randomEnvironment.State = Observation;

        end
        
        while IsDone == false

            qValues = predict(criticNet, dlarray(randomEnvironment.State, "CB"));
            availableMoves = find(randomEnvironment.State(1:6)>0);
            moveIndex = 1;

            % Get legal move with the highest Q-Value
            for i=1:length(availableMoves)
                if qValues(availableMoves(i)) > qValues(moveIndex)
                    moveIndex = availableMoves(i);
                end
            end
        
            [~,reward,IsDone,~] = randomEnvironment.step(moveIndex);
        end
        
        % Add reward (if played as player 1 or 2)
        if reward == -1
            if randomGames > 500
                randomScore(6) = randomScore(6)+1;
            else
                randomScore(3) = randomScore(3)+1;
            end
        elseif reward == 0
            if randomGames > 500
                randomScore(5) = randomScore(5)+1;
            else
                randomScore(2) = randomScore(2)+1;
            end
        elseif reward == 1
            if randomGames > 500
                randomScore(4) = randomScore(4)+1;
            else
                randomScore(1) = randomScore(1)+1;
            end
        end

    end
    
    for minimaxGames = 1:100
        minimaxEnvironment.reset();
        
        IsDone = false;
        endTurn = false;
        if minimaxGames > 50
            % Make player 2 start games (thereafore player 2 is now player
            % 1 for the assessment statistics. This was done in order to
            % avoid rotating the state of the board before and after each move

            while endTurn == false && IsDone == false
                places = find(minimaxEnvironment.State(8:13)>0);
    
                % Find a random legal action and perform it
                opponentAction = places(randperm(length(places), 1));
                [Observation, endTurn] = move(minimaxEnvironment, opponentAction, 1);
                minimaxEnvironment.State = Observation;
                [Observation, IsDone] = ifTerminal(minimaxEnvironment, endTurn, 1);
            end

            minimaxEnvironment.State = Observation;

        end

        while IsDone == false
            availableMoves = find(minimaxEnvironment.State(1:6)>0);
            if randi(100) <= 5
                % Make a random move with 5% chance
                moveIndex = availableMoves(randi(length(availableMoves), 1));
            else

                qValues = predict(criticNet, dlarray(minimaxEnvironment.State, "CB"));
                availableMoves = find(minimaxEnvironment.State(1:6)>0);
                moveIndex = 1;

                % Get legal move with the highest Q-Value
                for i=1:length(availableMoves)
                    if qValues(availableMoves(i)) > qValues(moveIndex)
                        moveIndex = availableMoves(i);
                    end
                end
            end
        
            [~,reward,IsDone,~] = minimaxEnvironment.step(moveIndex);
        end

        % Add reward (if played as player 1 or 2)
        if reward == -1
            if minimaxGames > 50
                minimaxScore(6) = minimaxScore(6)+1;
            else
                minimaxScore(3) = minimaxScore(3)+1;
            end
        elseif reward == 0
            if minimaxGames > 50
                minimaxScore(5) = minimaxScore(5)+1;
            else
                minimaxScore(2) = minimaxScore(2)+1;
            end
        elseif reward == 1
            if minimaxGames > 50
                minimaxScore(4) = minimaxScore(4)+1;
            else
                minimaxScore(1) = minimaxScore(1)+1;
            end
        end

    end

end
