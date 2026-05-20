function [ err_train , err_test, Y_test, D_test ] = train_test_HAR (p, d)
% perform the TRAINING and evaluate TRAIN and TEST error with datas taken from experiment
% Written by Enrico Picco, Mar 2021

% WARNING: matrixes sixes in comments refers for train size+test size = 500

% uses 6 linear regressors
% d.x is 50x250000, the code "extracts" 50x5000 neurons from 50x250000 neurons
% d.d is 1x5000

%% converting output pattern to "one hot" (from 1x5000 to 6x5000)
onehot = ones(6,size(d.d,2))-2; %matrix 6x5000, all values -1
for i = 1:size(onehot,2)
    onehot(d.d(i), i) = 1;
end

%% collecting "true" neurons (from 250000 to 5000)
% init=0;
% start = 301 + init;
% stop  = 310 + init;
% for i = 1:p.train_size+p.test_size
%     if i == 1
%             collected_states = [d.x(:, start:stop)];
% %             patterns         = [d.d(start:stop)]; %remove this line when d.d is 1x5000
%     else
%             collected_states = [collected_states d.x(:, start:stop)];
% %             patterns         = [patterns d.d(start:stop)]; %remove this line when d.d is 1x5000
%     end
%     start=start+500;
%     stop=stop+500;
% end

%ver 3.1
collected_states = d.x;

pattern = d.d;
% now we have 
% collected_states --> 50x5000 neurons
% onehot           --> 6x5000 outputs, for training (part of them)
% patterns         --> 1x2000 outputs, for errors evaluation

%% TRAIN
d.x        = collected_states(:,1:p.train_size*10);
d.d_onehot =           onehot(:,1:p.train_size*10);
d.d        =          pattern(:,1:p.train_size*10);

X = d.x(:, p.n_warmup+1:end);
D = d.d_onehot(:, p.n_warmup+1:end);
R = X*X' + p.reg_term*eye(size(X,1));
P = X * D';
w = P' * pinv(R); %6x50

y  = w * d.x; % 6x5000 % * p.y_amp; %this  p.y_amp comes from the eval_rc.m and I don't know why do we need it (maybe analog)

[max_val max_ind] = max(y);
y = max_ind;
start=1;
stop=10;
%convert computed output from 6x5000 to 1x5000 (for error evaluation)
for i = 1:p.train_size
    winner = mode(y(start:stop));
    y(start:stop)=winner;
    start=start+10;
    stop=stop+10;
end

Y = y(p.n_warmup+1:end);
D = d.d(p.n_warmup+1:end);

err_train = sum( Y ~= D ) / (p.train_size*10);   

Y_train = Y; %for debug
D_train = D; % for debug

% video_samples_correctly_identified_train = sum( Y(1:10:p.train_size*10) == D(1:10:p.train_size*10));

% subplot(1,2,1)
% title(sprintf('Train (error: %2.2f %%)', err_train*100))
% hold on
% plot(D)
% plot(Y,'r')

%% TEST
d.x        = collected_states(:, p.train_size*10+1 : (p.train_size+p.test_size)*10); 
d.d_onehot =           onehot(:, p.train_size*10+1 : (p.train_size+p.test_size)*10); 
d.d        =           pattern(:, p.train_size*10+1 : (p.train_size+p.test_size)*10);

y  = w * d.x;

[max_val max_ind] = max(y);
y = max_ind;
start=1;
stop=10;
for i = 1:p.test_size
    winner = mode(y(start:stop));
    y(start:stop)=winner;
    start=start+10;
    stop=stop+10;
end

Y = y(p.n_warmup+1:end);
D = d.d(p.n_warmup+1:end);

err_test = sum( Y ~= D ) / (p.test_size*10);  

Y_test = Y; %for debug
D_test = D; % for debug

% video_samples_correctly_identified_test = sum( Y(1:10:p.test_size*10) == D(1:10:p.test_size*10));

% subplot(1,2,2)
% title(sprintf('Test (error: %2.2f %%)', err_test*100))
% hold on
% plot(D)
% plot(Y,'r')

end