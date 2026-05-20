%HAR SIMULATION
clear all
addpath(genpath('.'));

p.n_neurons = 100;
% p.n_inputs  = 1000;
p.train_size = 500; %450; 
p.test_size = 100;

%dataset
data = importdata('features_labels.mat');

% params for train_test_HAR.m
p.n_warmup = 0;
p.reg_term=0;


%% collect neurons

rng(47);
index = randperm(600);

%connectivity matrix NxNf
W_conn = 2*rand(p.n_neurons, 1359) -1; %50x1359

%input mask Nx1
M = 2*rand(p.n_neurons,1) - 1; 
M  = M*0.9; %Why 0.9? because on FPGA numbers are stored as fixed points....

alfa = 0.3; %feedback
beta = 0.3; %input
bias= 0; %mz bias

alfa_scan=alfa;
beta_scan=beta;
% alfa_scan = 0.05:0.05:2;%0.05:0.01:0.1
% beta_scan = 0.05:0.05:0.9;%1e-4:1e-4:0.05;

cnt_run=1;

cnt_alfa=1;
for alfa = alfa_scan
    cnt_beta=1;
 for beta = beta_scan
     %%collect neurons
  for sample_cnt= 1:(p.train_size + p.test_size)
        
        %shuffled dataset 
        i_sample =index(sample_cnt);  
        
        inputs = data{1, i_sample}; %1359x10
%         inputs_debug = inputs; %for debug
        inputs = W_conn*inputs; %50x10  
        inputs = reshape(inputs,1,[]); %1x500 (1xN*10)
        
        x = zeros(p.n_neurons, 10); %50x10
        
        for n = 2:10
             debug = (n-2)*50 + 1; 
             x(1,n+1) = sin(alfa*x(p.n_neurons, n-1) + beta*M(1)*inputs((n-2)*50 + 1 ) + bias) ;  
          for i=2:p.n_neurons 
             debug=(n-2)*50 + i; %this index because the input is updated for each neuron i that for each timestep n as in channel eq
             x(i,n+1) = sin(alfa*x(i-1, n) + beta*M(i)*inputs((n-2)*50 + i) + bias) ;        
          end      
        end 
        
        %now x is 50x11
       x = x(:,2:end); %50x11 --> 50x10  
        %TO DO --> maybe add a column  on the right so we get rid of the
        %left zero column?
       dd = data{2, i_sample};
       
        %collect all the states in a long matrix "collected_states"
        if sample_cnt == 1
            collected_states = [x];  
            patterns         = [dd];
        else
            collected_states = [collected_states x]; %50x10*sample_cnt
            patterns         = [patterns dd]; 
        end
        
%        sample_cnt 
        
    end
    
    %at the end we should have our matrix collected_states with all the
    %sampled states: ready for the weights computation!
    d.x = collected_states; %50x6000
    d.d = double(patterns); %1x6000 %for HAR dataset, the output are in uint8 format. so we convert them in double
    
%% train and test

[r.err_train(cnt_alfa, cnt_beta), r.err_test(cnt_alfa, cnt_beta), Y_test, D_test] = train_test_HAR(p, d);   


    fprintf('\n Run: %.0d / %.0d , Run Label (alfa, beta): %.0d %.0d\n', cnt_run,size(alfa_scan,2)*size(beta_scan,2), cnt_alfa, cnt_beta)
    fprintf('Alfa: %.2e , Beta: %.2e , Bias: %.2e \n', alfa, beta, bias)
    fprintf('Training error: %.2e. \n', r.err_train(cnt_alfa, cnt_beta))
    fprintf('Test error: %.2e. \n', r.err_test(cnt_alfa, cnt_beta));

cnt_run=cnt_run+1;
% fprintf('Alfa: %.2e.\n', alfa)
% fprintf('Beta: %.2e.\n', beta)
% fprintf('Training error: %.2e. \n', r.err_train(cnt_alfa, cnt_beta));
%         fprintf('Test error: %.2e. \n', r.err_test(cnt_alfa, cnt_beta));
        
cnt_beta=cnt_beta+1;
 end

 cnt_alfa = cnt_alfa+1;
end

% hold on 
% plot(D_test, 'b')
% plot(Y_test, 'r')
% legend('pattern','computed output''2016')
% 
% plot(Y_test == D_test)

% hold on
% plot(r.err_train,'o')
% plot(r.err_test,'x')

% plot(r.err_test,'x')

% hold on
% surf(r.err_train)
% surf(r.err_test)

% hold on
% colorbar
% surf(beta_scan, alfa_scan, r.err_test)
% xlabel('beta (inp)')
% ylabel('alfa (fb)')



