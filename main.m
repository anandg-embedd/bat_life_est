close all;
clear all;
clc;

% 08/2020 Lisans Tezi - 1 (RNNler ile Zaman Serisi Analizi)


%   Gradients vanish if the length of TS is too long
%   on the other hand if TS is too short RNN is not 
%   able learn from long temporal sequences.
%   For Hénon we found 250 training samples to be enough for
%   demonstrating the capabilities of Vanilla RNN architecture
%   and also the problems and difficulties of training this model.


%   TO DO
%   Validation.
%   tBptt?
%   prediciton .


% t = [1:0.1:100];
% NumberOfInputs = 1;
% PredictHorizon = 100;
% LengthOfTimeSeries = length(t) - PredictHorizon;
% x = sin(t);

% Z = x;
% Zmin = min(Z); Zmax = max(Z);

% data = (x - [ones(size(x, 1), 1) * Zmin]) ./ ([ones(size(x, 1), 1) * Zmax] - [ones(size(x, 1), 1) * Zmin]);
% x_test = data(LengthOfTimeSeries + 1:LengthOfTimeSeries + PredictHorizon);

filename='Battery_RUL_head_removed.csv';
x = csvread( filename );
%x = x(1:5000,:);
NumberOfInputs = 7;
LengthOfTimeSeries =length(x)-100;
PredictHorizon = 100;
lambda = 0.0;
Z = x;
Zmin = min(Z); Zmax = max(Z);
data = (x -  repmat(Zmin,length(x),1)) ./ repmat((Zmax -  Zmin),length(x),1);
x_test = data(LengthOfTimeSeries + 1:LengthOfTimeSeries + PredictHorizon,2:end);
% Zmin = min(min(Z)); Zmax = max(max(Z));
% data = (x -  Zmin) ./ (Zmax -  Zmin);
% x_test = data(LengthOfTimeSeries + 1:LengthOfTimeSeries + PredictHorizon,2:end);

X = data(1:LengthOfTimeSeries,2:end-1);
y = data(1:LengthOfTimeSeries,end);



num_data = length(y);

train_index = 1:2:num_data;
val_index = 2:2:num_data;
train_in = X(train_index, :);
train_out = y(train_index, :);
val_in = X(val_index, :);
val_out = y(val_index, :);
num_trdata = size(train_in, 1);
num_valdata = size(val_in, 1);



d = size(X,2); % Her t adimda 1 input.
q = 1;
tau = 5; % tBPTT constant for unfolding

stop_condition = 6e-4;
fValBest = Inf;
N_max = num_trdata-1;
w_limit = sqrt(6/(2*num_trdata));
divider = 1.1;

for N = 1:N_max
    disp(N)
    
    % Whh = rand(N, N);  
    % Wih = rand(N, d);
    % Who = rand(q, N);
  
    learning_rate = 0.00001;

    %  --------- GLOROT UNIFROM WEIGHT INITILIZATION -----------
    Whh = unifrnd(-w_limit, w_limit, [N, N]); %Hidden-hidden arasi weight matrisi
    Wih = unifrnd(-w_limit, w_limit, [N, d]); %Input-hidden     ""     
    Who = unifrnd(-w_limit, w_limit, [q, N]); %Hidden-output    ""
    bh = rand(N,1);                           %hidden bias      ""

    Wih_old = Wih;
    Whh_old = Whh;
    Who_old = Who;
    bh_old = bh;

    Theta = [Wih, Whh, Who', bh]; % PARAMETERS TO TRAIN

    % --------- Forwardpass and initial error calculation -----------
    ht = zeros(N, 1); zt = []; o = [];
    for k = 1:num_trdata
        [o, ht, zt] = forward(train_in, Wih, Whh, Who, bh, ht, zt, o, k);
    end
    
    n = 2;
    n_max = 2000; % training iterasyon sayisi
    err = zeros(n_max,1);
    err(1) = sum((o - train_out).^2) / length(train_out);
    err_old = err(1);
    
    count = 0;
    % --------- TRAINING -----------
    if N < 2
        n_max = 200;
    end

    while n < n_max
        
        
        
        
        % % --------- Backpropagation Through Time -----------
        [dWih, dWhh, dWho, dbh, del_t] = bptt(Wih, Whh, Who, ht, zt, o, train_out, train_in, tau, k);

        dTheta = [dWih,dWhh,dWho',dbh];
        % --------- Gradient descent ile Parametre Update -----------
        [Theta] = gradDes(learning_rate, dTheta, Theta);

        Wih = Theta(:,1:d);
        Whh = Theta(:,d+1:d+N);
        Who = Theta(:,d+N+1)';
        bh = Theta(:,end);
        
        

    
        o = []; zt = []; ht = zeros(N, 1);

        for K = 1:num_trdata
            [o, ht, zt] = forward(train_in, Wih, Whh, Who, bh, ht, zt, o, K);
        end
    
        
        err(n) = sum((o - train_out).^2) / length(train_out);
        
        fprintf('MSE : %f \n', err(n));
        figure(1)      
        plot(o)
        hold on
        plot(train_out)
        title(['N = ', num2str(N), ', Iteration = ', num2str(n), ', Error (MSE) = ', num2str(err(n))]);         
        legend('Predicted', 'Desired');
        hold off
        
        
     
        if (err(n) > err_old)
            
            learning_rate = learning_rate/divider;
            count = count + 1;
            Wih = Wih_old;
            Whh = Whh_old;
            Who = Who_old;
            bh = bh_old;
            if count > 2
                divider = divider + 0.1;
            end
            
        elseif (isnan(err(n))) 
            break
        else
            count = 0;
            learning_rate = learning_rate * 1.01;
            err_old = err(n);
            Wih_old = Wih;
            Whh_old = Whh;
            Who_old = Who;
            bh_old = bh;
            
        end
        if count == 100
            n = n_max;
        end
        n = n + 1;
        

    end
    
    
    % --------- Training and Validation error calculation -----------
    
    count = 0;
    o = []; zt = []; ht = zeros(N, 1);
    for k = 1:num_trdata
        [o, ht, zt] = forward(train_in, Wih, Whh, Who, bh, ht, zt, o, k);
    end

    o_val = []; zt_val = []; ht_val = zeros(N, 1);
    for k = 1:num_valdata
        [o_val, ht_val, zt_val] = forward(val_in, Wih, Whh, Who, bh, ht_val, zt_val, o_val, k);
    end
    err_train(N) = sum((o - train_out).^2) / length(train_out);
    err_val(N) = sum((o_val - val_out).^2) / length(o_val);

    
  
    %   Stop Conditions

    if (err_val(N) < fValBest)
        count = count + 1;
        N_best = N;
        fValBest = err_val(N);
        Wih_best = Wih;
        Whh_best = Whh;
        Who_best = Who;
        bh_best = bh;

    else
        break
    end

    if err_train < stop_condition
        break
    end




   
    
    fprintf('MSE TRAINING: %f  MSE VALIDATION: %f \n', err_train(N), err_val(N));
end

figure(2)
plot(err_train, 'r')
hold on
plot(err_val, '--b')
title(['N = ', num2str(N), ', Training Error: ', num2str(err_train(N)), ', Valid Error = ', num2str(err_val(N))]);
legend('Training Error', 'Validation Error');
hold off
% --------- PREDICTION -----------

INPUT = x_test(:,1:end-1);

o = []; zt = []; ht = zeros(N_best, 1);
for k = 1:length(x_test)

    [o, ht, zt] = forward(INPUT, Wih_best, Whh_best, Who_best, bh_best, ht, zt, o, k);

end
err_test = sum((o - x_test(:,end)).^2) / length(x_test);
fprintf('MSE TEST: %f  \n', err_test);


figure(3)
plot(x_test(:,end))
hold on
plot(o)
title(['N = ', num2str(N_best), ',  Test Error (MSE) = ', num2str(err_test)]);
legend('desired','predicted');
hold off

save rnn_train.mat Wih_best Whh_best Who_best bh_best N_best Zmin Zmax

