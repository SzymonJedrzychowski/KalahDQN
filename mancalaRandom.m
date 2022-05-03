classdef mancalaRandom < rl.env.MATLABEnvironment
    %mancalaRandom: Template for defining custom environment in MATLAB.    
    
    properties
        winReward = 1
        loseReward = -1
        drawReward = 0
        playReward = -0.02
        scoreReward = 0.1
    end
    
    properties
        State = [4;4;4;4;4;4;0;4;4;4;4;4;4;0];
    end
    
    properties(Access = protected)
        IsDone = false        
    end

    methods              
        function this = mancalaRandom()
            % Specify the game informations
            ObservationInfo = rlNumericSpec([14 1]);
            ObservationInfo.Name = 'Kalah State';
            ObservationInfo.Description = 'Player 1 - 6 pits, Player 1 - Store, Player 2 - 6 pits, Player 2 - Store';
               
            ActionInfo = rlFiniteSetSpec([1 2 3 4 5 6]);
            ActionInfo.Name = 'Kalah actions';
            
            this = this@rl.env.MATLABEnvironment(ObservationInfo, ActionInfo);
        end
        
        function [Observation, Reward, IsDone, LoggedSignals] = step(this, recommendedAction)
            LoggedSignals = [];
            
            scoreBeforeMove = this.State(7);
            [Observation, endTurn] = move(this, recommendedAction, 0);
            if Observation == this.State
                % The same state after move means that illegal move was 
                % made - finish the game.
                IsDone = true;
                this.IsDone = true;

                % If punishFactor is higher than 1, illegal moves will be
                % punished more than losing
                Reward = this.loseReward;
            else
                this.State = Observation;
                [Observation, IsDone] = ifTerminal(this, endTurn, 0);
                this.State = Observation;

                scoreAfterMove = this.State(7);
                
                if IsDone == false && endTurn
                    % Allow opponent to play if turn has ended and the game
                    % is not finished
                    endTurn = false;
                    while endTurn == false && this.IsDone == false
                        places = find(Observation(8:13)>0);
                        
                        % Find a random legal action and perform it
                        opponentAction = places(randperm(length(places), 1));
                        [Observation, endTurn] = move(this, opponentAction, 1);
                        this.State = Observation;
                        [Observation, IsDone] = ifTerminal(this, endTurn, 1);
                        this.IsDone = IsDone;
                    end
                    this.State = Observation;
                end
                % Get reward based on the state of the environment
                Reward = getReward(this);
                if Reward == 0 && IsDone == false
                    if scoreAfterMove > scoreBeforeMove
                        Reward = this.scoreReward*(scoreAfterMove-scoreBeforeMove);
                    else
                        Reward = this.playReward;
                    end
                end

            end

        end
        
        % Reset environment to initial state and output initial observation
        function InitialObservation = reset(this)

            InitialObservation = [4;4;4;4;4;4;0;4;4;4;4;4;4;0];
            this.State = InitialObservation;
            this.IsDone = false;
    
        end            
        
        % Perform a move on the board
        function [boardObservation, endTurn] = move(this, action, isPlayerTwo)
            endTurn = true;
            
            % Recreate the board
            boardObservation = zeros(14,1);
            for i = 1:14
                boardObservation(i) = this.State(i);
            end

            % Check if action is legal, if yes, perform move
            if boardObservation(action+isPlayerTwo*7) ~= 0
                %Grab stones
                action = action+isPlayerTwo*7;
                stones = boardObservation(action);
                boardObservation(action) = 0;
                pit = action;

                %Distribute stones
                while stones > 0
                    pit = pit + 1;
                    if pit == 15
                        pit = 1;
                    end
                    if pit ~= 14-7*isPlayerTwo
                        boardObservation(pit) = boardObservation(pit) + 1;
                        stones = stones - 1;
                    end
                end
                
                % Decide on additional turn or if additional stones can be
                % placed in the store
                if pit == isPlayerTwo*7+7 
                    endTurn = false;
                elseif boardObservation(pit) == 1 && pit < 7 && boardObservation(14-pit) > 0 && isPlayerTwo == 0
                    boardObservation(pit) = 0;
                    boardObservation(7) = boardObservation(7) + 1 + boardObservation(14-pit);
                    boardObservation(14-pit) = 0;
                    boardObservation(pit) = 0;
                elseif boardObservation(pit) == 1 && (pit > 7 && pit < 14) && boardObservation(14-pit) > 0 && isPlayerTwo == 1
                    boardObservation(pit) = 0;
                    boardObservation(14) = boardObservation(14) + 1 + boardObservation(14-pit);
                    boardObservation(14-pit) = 0;
                    boardObservation(pit) = 0;
                end
            end
        end

        % Print the board
        function printBoard(this)
            data2 = flip(reshape(this.State(8:14), [1,7]));
            data1 = reshape(this.State(1:7), [1,7]);
            disp("================ Player 2 ===============");
            fprintf("|    | %2i | %2i | %2i | %2i | %2i | %2i |    |\n", data2(2), data2(3), data2(4), data2(5), data2(6), data2(7));
            fprintf("| %2i |====|====|====|====|====|====| %2i |\n", data2(1), data1(7));
            fprintf("|    | %2i | %2i | %2i | %2i | %2i | %2i |    |\n", data1(1), data1(2), data1(3), data1(4), data1(5), data1(6));
            disp("================ Player 1 ===============");
        end
        
        % Check if current state is terminal
        function [boardObservation, isDone] = ifTerminal(this, endTurn, isPlayerTwo)
            isDone = false;
            
            % Recreate board
            boardObservation = zeros(14,1);
            for i = 1:14
                boardObservation(i) = this.State(i);
            end

            %Check all possible game ending scenarios
            if boardObservation(7) > 24 || boardObservation(14) > 24 || boardObservation(7)+boardObservation(14) == 48
                isDone = true;
            elseif isPlayerTwo == 0
                if sum(boardObservation(8:13)) == 0 && endTurn == true
                    isDone = true;
                    boardObservation(7) = boardObservation(7) + sum(boardObservation(1:6));
                    boardObservation(1:6) = zeros(6,1);
                elseif sum(boardObservation(1:6)) == 0 && endTurn == false
                    isDone = true;
                    boardObservation(14) = boardObservation(14) + sum(boardObservation(8:13));
                    boardObservation(8:13) = zeros(6,1);
                end
            elseif isPlayerTwo == 1
                if sum(boardObservation(1:6)) == 0 && endTurn == true
                    isDone = true;
                    boardObservation(14) = boardObservation(14) + sum(boardObservation(8:13));
                    boardObservation(8:13) = zeros(6,1);
                elseif sum(boardObservation(8:13)) == 0 && endTurn == false
                    isDone = true;
                    boardObservation(7) = boardObservation(7) + sum(boardObservation(1:6));
                    boardObservation(1:6) = zeros(6,1);
                end
            end
        end
        
        % Reward function
        function reward = getReward(this)
            reward = 0;
            if this.State(7) > 24
                reward = this.winReward;
            elseif this.State(14) > 24
                reward = this.loseReward;
            elseif this.State(7)+this.State(14) == 48
                reward = this.drawReward;
            end
        end
    end
end
