% Parameter identification for the deltawing plane

clear

%% setup
realtime_path = '/home/abarry/realtime/';
logfile_path = '/home/abarry/rlg/logs/2015-03-31-field-test/gps-logs/';

logfile_name = 'lcmlog_2015_03_31_11.mat';

% add log parsing scripts to path

addpath([realtime_path 'scripts/logs']);

% load data
dir = logfile_path;
filename = logfile_name;

loadDeltawing

% delay in ms from command to execution

% delay is zero because we are using servo_out, which is the message after
% it has come back from the APM to the CPU

warning('delay = -10 ms');
delay_ms = -10;


use_airspeed = true;

%% trim to flight times only and setup comparison to model output for orientation PEM

[start_time, end_time] = FindActiveTimes(est.logtime, est.pos.z, 9.0);

assert(length(start_time) == 1, 'Number of active times ~= 1');

%% temp %%

start_time = start_time + 50;
%end_time = start_time + 20;

%%

t_block = 1;

t_shift = 0;


t_start = (start_time : t_block : end_time) + t_shift;
t_end = start_time + t_block + t_shift : t_block : end_time;

dt = 1/140; % approximate servo rate

for i = 1 : min(length(t_start), length(t_end))
  airspeed_dat{i} = BuildIdDataRPYAirspeed(est, airspeed_unchecked, u, t_start(i), t_end(i), dt, delay_ms);
  
  
end

%if use_airspeed
    dat = airspeed_dat;
   
%end
%   
% for i = 1 : length(airspeed_dat)
%   plot(airspeed_dat{i})
%   title(i)
%   drawnow
%   pause
% end
% 

%merge_nums = [1, 2, 3, 4];
%merge_nums = [1, 2, 3];
%merge_nums = [100, 150, 200];

% interesting data: 4, 8, 9, 16, 20
merge_nums = [8, 16];



%merged_dat = merge(dat{:});

%merged_dat = merge(dat{3}, dat{4}, dat{5}, dat{6});
merged_dat = merge(dat{merge_nums});

merged_airspeed_dat = merge(airspeed_dat{merge_nums});
%merged_dat = dat{2};

%% run prediction error minimization 


file_name = 'tbsc_model_pem_wrapper';

if use_airspeed
  num_outputs = 4;
else
  num_outputs = 3;
end

num_inputs = 3;
num_states = 12;

order = [num_outputs, num_inputs, num_states];

%initial_states = repmat([0 0 0 0 0 0 10 0 0 0 0 0]', 1, 2);

% extract inital state guesses from the data
if iscell(merged_airspeed_dat.OutputData)
  
  for i = 1 : length(merged_airspeed_dat.OutputData)

    x0_dat{i} = merged_airspeed_dat.OutputData{i}(1,:);

  end
  num_data = length(merged_airspeed_dat.OutputData);
else
  x0_dat{1} = merged_airspeed_dat.OutputData(1,:);
  num_data = 1;
end

x0_dat_full{1} = zeros( 1, num_data);
x0_dat_full{2} = zeros( 1, num_data);
x0_dat_full{3} = zeros( 1, num_data);

x0_dat_full{4} = [];
x0_dat_full{5} = [];
x0_dat_full{6} = [];
x0_dat_full{7} = [];

for i = 1 : length(x0_dat)
  x0_dat_full{4} = [ x0_dat_full{4} x0_dat{i}(1) ];
  x0_dat_full{5} = [ x0_dat_full{5} x0_dat{i}(2) ];
  x0_dat_full{6} = [ x0_dat_full{6} x0_dat{i}(3) ];
  x0_dat_full{7} = [ x0_dat_full{7} x0_dat{i}(4) ];
end

%x0_dat_full{7} = [ 9.9607 11.3508 ];%zeros( 1, length(merged_dat.OutputData));

x0_dat_full{8} = zeros( 1, num_data);
x0_dat_full{9} = zeros( 1, num_data);

x0_dat_full{10} = zeros( 1, num_data);
x0_dat_full{11} = zeros( 1, num_data);
x0_dat_full{12} = zeros( 1, num_data);

  


%initial_states = { [0 0] [0 0] [0 0] [0 0] [0 0] [0 0] [10 10] [0 0] [0 0] [0 0] [0 0] [0 0] };


%parameters = [1.92; 1.84; 2.41; 0.48; 0.57; 0.0363];
parameters = [1; 1; 1; 1; 1; 0.036];

nlgr = idnlgrey(file_name, order, parameters, x0_dat_full);

nlgr.Parameters(1).Name = 'Jx';
nlgr.Parameters(2).Name = 'Jy';
nlgr.Parameters(3).Name = 'Jz';
nlgr.Parameters(4).Name = 'Elift';
nlgr.Parameters(5).Name = 'Edrag';
nlgr.Parameters(6).Name = 'Bx_dr';
% nlgr.Parameters(7).Name = 'By_dr';
% nlgr.Parameters(8).Name = 'Bz_dr';

nlgr.Parameters(1).Minimum = 0;
nlgr.Parameters(2).Minimum = 0;
nlgr.Parameters(3).Minimum = 0;
nlgr.Parameters(4).Minimum = 0;
nlgr.Parameters(5).Minimum = 0;
nlgr.Parameters(6).Minimum = 0.005;
% nlgr.Parameters(7).Minimum = 0;
% nlgr.Parameters(8).Minimum = 0;

nlgr.Parameters(1).Maximum = 20;
nlgr.Parameters(2).Maximum = 20;
nlgr.Parameters(3).Maximum = 20;
nlgr.Parameters(4).Maximum = 20;
nlgr.Parameters(5).Maximum = 20;
nlgr.Parameters(6).Maximum = 0.07;
% nlgr.Parameters(7).Maximum = 0.5;
% nlgr.Parameters(8).Maximum = 0.5;


nlgr.InitialStates(1).Name = 'x';
nlgr.InitialStates(2).Name = 'y';
nlgr.InitialStates(3).Name = 'z';
nlgr.InitialStates(4).Name = 'roll';
nlgr.InitialStates(5).Name = 'pitch';
nlgr.InitialStates(6).Name = 'yaw';

nlgr.InitialStates(7).Name = 'U';
nlgr.InitialStates(8).Name = 'V';
nlgr.InitialStates(9).Name = 'W';
nlgr.InitialStates(10).Name = 'P';
nlgr.InitialStates(11).Name = 'Q';
nlgr.InitialStates(12).Name = 'R';


nlgr = setinit(nlgr, 'Fixed', {true true true true true true true false false false false false });   % Estimate the initial state.
%nlgr.InitialStates(1).Fixed = [false false false false false false false false false false false false];
%nlgr.InitialStates(2).Fixed = [false false false false false false false false false false false false];
% nlgr = setinit(nlgr, 'Minimum', {-100 -100 -100 -100 -100 -100 9 -1 -1 -5 -5 -5 });
% nlgr = setinit(nlgr, 'Maximum', {100 100 100 100 100 100 15 1 1 5 5 5 });

% nlgr.InitialStates(7).Minimum = 9;
% nlgr.InitialStates(7).Maximum = 15;
% 
% nlgr.InitialStates(8).Minimum = -3;
% nlgr.InitialStates(8).Maximum = 3;
% 
% nlgr.InitialStates(9).Minimum = -5;
% nlgr.InitialStates(9).Maximum = 10;
% 
% nlgr.InitialStates(10).Minimum = -5;
% nlgr.InitialStates(10).Maximum = 5;
% 
% nlgr.InitialStates(11).Minimum = -5;
% nlgr.InitialStates(11).Maximum = 5;
% 
% nlgr.InitialStates(12).Minimum = -5;
% nlgr.InitialStates(12).Maximum = 5;

%% estimate initial states
% 
% disp('Estimating initial states...');
% 
% 
% nlgr.Algorithm.Display = 'full';
% 
% %x0 = zeros(num_states, length(merge_nums));
% 
% x0 = findstates(nlgr, merged_dat, x0_dat_full)
% % x0 = [0 0
% %          0         0
% %          0         0
% %    -0.1972   -0.2760
% %     0.4608    0.4951
% %    -0.1373   -0.1575
% %     9.1312    9.9785
% %    -0.1730   -0.0407
% %     1.5799    1.0444
% %    -0.5888   -0.7839
% %     0.1672    0.8154
% %    -0.0247   -0.3423];
% 
%  for i = 1 : length(merge_nums)
%    
% 
%    for j = 1 : num_states
%      nlgr.InitialStates(j).Value(i) = x0(j,i);
%    end
%  
%  end
% 
% 
% 
% nlgr = setinit(nlgr, 'Fixed', {true true true true true true true true true true true true});

%%


%nlgr.Algorithm.Regularization.Lambda = 0.01; % use regularization
%nlgr.Algorithm.Regularization.Nominal = 'model'; % attempt to keep parameters close to initial guesses
%  
%RR = [ones(length(parameters),1); 1e-5*ones(5,1)];
%RR(7,7) = RR(7,7)*10;
%nlgr.Algorithm.Regularization.R = RR;


% nlgr.Parameters(1).Minimum = 0.1;
% nlgr.Parameters(1).Maximum = 10;
% 
% nlgr.Parameters(2).Minimum = 0.1;
% nlgr.Parameters(2).Maximum = 10;
% 
% nlgr.Parameters(3).Minimum = 0.1;
% nlgr.Parameters(3).Maximum = 10;

% nlgr.Parameters(4).Minimum = 0.1;
% nlgr.Parameters(4).Maximum = 10;
% 
% nlgr.Parameters(5).Minimum = 0.1;
% nlgr.Parameters(5).Maximum = 10;

% weight the airspeed output less

roll_weight = 1;
pitch_weight = 1;
yaw_weight = 0.75;
airspeed_weight = 0.025;

output_weights = diag([roll_weight, pitch_weight, yaw_weight, airspeed_weight]);

nlgr.Algorithm.Weighting = output_weights;

%% plot data

disp('Plotting data...');
figure(25);
clf
plot(merged_dat);
%% run pem

disp('Running pem...');
nlgr_fit = pem(merged_dat, nlgr, 'Display', 'Full', 'MaxIter', 20);

%% display results

disp(' ------------- Initial States -------------');
DisplayNlgr(nlgr_fit.InitialStates);
disp(' ------------- Parameters  -------------');
DisplayNlgr(nlgr_fit.Parameters);
disp(' ---------------------------------------');



disp('Simulating...');


% get initial conditions

for i = 1 : num_states
  
  x0_out(i,:) = nlgr_fit.InitialStates(i).Value;
  
end

compare_options = compareOptions('InitialCondition',x0_out);

%[y_out, fit_out, x0_out] = compare(merged_dat, nlgr_fit);
figure;
compare(merged_dat, nlgr_fit, compare_options);

disp('done.');
