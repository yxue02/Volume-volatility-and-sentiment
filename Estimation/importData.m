ticker = 'SPY';

data = load(strcat(ticker,'_1min'));
data = data.OneMinuteData;

data_all = NaN(size(data,1),size(data,2),length(ticnum_list)+1);
data_all(:,:,length(ticnum_list)+1) = data;

% Time Series 
    % Dispersion Measures
    load('Dispersion_extend');
    load('dispersion_new');
    load('dispersion_new2');
    load('dispersion_new_all_extend');
    load('dispersion_new_all_growth_extend');
    load('dispersion_new_all_long_extend');
    % Daily Policy
    load('DailyPolicy_extend');
    load('MonthlyPolicy_extend');
    load('EPU_category_extend');
    % Negative measures
    load('LM_Count_extend');
    % Sentiment measure
    load('sentiment_BW');
    load('sentiment_BW_dif');
    load('sentiment_period');
    load('NewsCount')
    load('searchTrend');
    % Uncertainty measure
    load('Uncertainty_KK');
    load('NVIX');
% Analysts' forecasts
    % One year ahead data
    Analysts_dispersion_yearly = load('Analysts_dispersion_summary_1');
    Analysts_dispersion_yearly  = squeeze(Analysts_dispersion_yearly .Analysts_dispersion_list(:,3,:));
    % One quarter ahead data
    Analysts_dispersion_quarterly = load('Analysts_dispersion_summary_2');
    Analysts_dispersion_quarterly  = squeeze(Analysts_dispersion_quarterly .Analysts_dispersion_list(:,3,:));
    %Make up for missing value
    Analysts_dispersion_quarterly(1939:1961,15) = Analysts_dispersion_quarterly(1938,15);
    % Scaled by moving average mean estimates
    analyst_meanest_yearly = load('Analysts_dispersion_mat_MEANEST_1');
    analyst_meanest_yearly = analyst_meanest_yearly.dispersion_mat_MA;
    % Scaled by moving average mean actual value
    analyst_actual_yearly = load('Analysts_dispersion_mat_ACTUAL_1');
    analyst_actual_yearly = analyst_actual_yearly.dispersion_mat_MA;


    analyst_meanest_quarterly = load('Analysts_dispersion_mat_MEANEST_2');
    analyst_meanest_quarterly = analyst_meanest_quarterly.dispersion_mat_MA;
    % Scaled by moving average mean actual value
    analyst_actual_quarterly = load('Analysts_dispersion_mat_ACTUAL_2');
    analyst_actual_quarterly = analyst_actual_quarterly.dispersion_mat_MA;


    % Scaled by end-of-month price
    analyst_price = load('Analysts_dispersion_mat_price_1');
    analyst_price = analyst_price.dispersion_mat_price;
    
    % Dispersion measures from WRDS
    load('Dispersion_WRDS');
    %This has analysts' dispersion scaled by mean and price:
    %analyst_scale_mean, analyst_scale price
    load('WRDS_analyst_MA_dispersion');
    %analyst_MA_dispersion
    
    % First scaled by annual/quarterly mean estimate/actual value and then do moving
    % average
    load('analyst_MA_MEANEST1');
    load('analyst_MA_ACTUAL1');
    load('analyst_MA_MEANEST6');
    load('analyst_MA_ACTUAL6');

    load('recommend');
    load('analyst_LTG');

% Beta and other Idiosyncratic Risk measures
    % Beta and idiosyncratic risk
    load('betas_quarter_day');
    load('betas_year_day');
    %load('Decomposed_vol');
    load('Decomposed_vol_ma');
    load('Decomposed_vol_new','beta_weekly','idio_ratio_weekly');
    load('Decomposed_vol_new_nolag','beta_weekly_nolag');

    Decomposed_vol_w = squeeze(Decomposed_vol_w(:,5,:));
    Decomposed_vol_bw = squeeze(Decomposed_vol_bw(:,5,:));
    load('turnover_ma');
    load('turnover_month');
    
% Institutional holding measures    
    load('breadth_WRDS');
    load('InOut_WRDS2');
    load('InOut_WRDS');
    load('LongShort_WRDS');


    %% All variables into controls
Control_Var_List = {'Analysts_dispersion_yearly','Analysts_dispersion_quarterly','betas_quarter_day','betas_year_day',...
    'Decomposed_vol_w','Decomposed_vol_bw','turnover_w','turnover_m','analyst_actual_yearly','analyst_meanest_yearly', 'analyst_price','analyst_scale_price', 'breadth',...
    'dbreadth', 'institutional_ownership','institutional_ownership_diff','analyst_MA_dispersion', 'InOut_WRDS','analyst_MA_MEANEST1','analyst_MA_ACTUAL1',...
    'analyst_actual_quarterly','analyst_meanest_quarterly','analyst_MA_MEANEST6','analyst_MA_ACTUAL6', 'recommend','LongShort_WRDS','InOut_WRDS2'...
    'beta_weekly','beta_weekly_nolag','idio_ratio_weekly', 'NewsCount', 'searchTrend', 'analyst_LTG'};
Control_Var_List1 = cell(size(Control_Var_List));
num_lead = [0 0 2 1 0 0 0 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 0 0 0 1 2 2]; 

%Only pick the controls for the stocks we want
for k = 1:length(Control_Var_List)
    % New variable name is the original variable name plus 1
    v = matlab.lang.makeValidName(strcat(Control_Var_List{k},'1'));
    Control_Var_List1{k} = v;
    value_whole = eval(Control_Var_List{k});
    value_new = value_whole(:,ticnum_list+num_lead(k));
    eval([v '=value_new;']);
end;


fprintf('Load Data.\n');

for i = 1:length(ticnum_list)
    ticker = TickerList{ticnum_list(i)};
    load(strcat(ticker,'_1min'));
    data = OneMinuteData;
    data_all(:,:,i) = data;
end;

 Controls.Date = unique(data(:,1));
    
    %Normalize Dispersion
    Controls.Dispersion = Normalize(Dispersion);
    Controls.Dispersion_new = Normalize(dispersion_new);
    Controls.Dispersion_new2 = Normalize(dispersion_new2);
    Controls.Dispersion_new_all = Normalize(dispersion_new_all(:,:,2));
    Controls.Dispersion_new_growth = Normalize(dispersion_new_all_growth(:,:,2));
    %Uncertainty
    Controls.DailyPolicy = Normalize(DailyPolicy(:,2:size(DailyPolicy,2)));
    Controls.EPU_category = Normalize(EPU_category);
    Controls.MonthlyPolicy  = Normalize(MonthlyPolicy);
    Controls.Negative = Normalize(EventCount(:,1,1));
    
    %Analysts' dispersion
    Controls.Analysts_yearly = Analysts_dispersion_yearly1/100;
    Controls.Analysts_quarterly = Analysts_dispersion_quarterly1/100;
    Controls.Analysts_meanest1 = analyst_meanest_yearly1;
    Controls.Analysts_actual1 = analyst_actual_yearly1;
    Controls.Analysts_meanest6 = analyst_meanest_quarterly1;
    Controls.Analysts_actual6 = analyst_actual_quarterly1;
    Controls.Analysts_price = analyst_price1*100;
    Controls.Analysts_scale_price = analyst_scale_price1*100;
    Controls.Analyst_MA_dispersion = analyst_MA_dispersion1;
    Controls.Analyst_MA_Actual1 = analyst_MA_ACTUAL11;
    Controls.Analyst_MA_Meanest1 = analyst_MA_MEANEST11;
    Controls.Analyst_MA_Actual6 = analyst_MA_ACTUAL61;
    Controls.Analyst_MA_Meanest6 = analyst_MA_MEANEST61;
    Controls.recommend = recommend1;
    Controls.analyst_LTG = abs(analyst_LTG1/100);
    
    %Beta
    Controls.betas_quarter = betas_quarter_day1;
    Controls.betas_year = betas_year_day1;
    Controls.betas_weekly = beta_weekly1;
    
    %Ratio of idiosyncratic variance
    Controls.idio_w = Decomposed_vol_w1/100;  %Scale so that it is not a percentage 
    Controls.idio_bw = Decomposed_vol_bw1/100;
    Controls.idio_w2 = idio_ratio_weekly1;
    Controls.gamma = abs(Controls.betas_weekly) .* sqrt(Controls.idio_w2./(1-Controls.idio_w2));
    qlist = [0.9,0.95,0.99,1];
    Controls.idio_beta= NaN(size(Controls.idio_w,1),size(Controls.idio_w,2),4);
    for j = 1:4
        Controls.idio_beta(:,:,j) = winsorize(Controls.gamma./abs(Controls.betas_weekly),qlist(j));
    end;
    % Winsorize for extreme values 95%
    Controls.turnover_w = turnover_w1;
    Controls.turnover_m = turnover_m1;
    
    %Institutional Holding
    Controls.breadth = breadth1;
    Controls.dbreadth = dbreadth1;
    Controls.IO = institutional_ownership1;
    Controls.dIO = institutional_ownership_diff1;
    Controls.InOut = InOut_WRDS1;
    Controls.InOut2 = InOut_WRDS21;
    Controls.LongShort = LongShort_WRDS1;
    
    %Sentiment
    %100 News
    Controls.NewsCount = NewsCount1/100;
    Controls.sentiment_BW = Normalize(sentiment_BW); 
    Controls.sentiment_BW_dif = Normalize(sentiment_BW_dif); 
    Controls.searchTrend = searchTrend1;
    
    %Uncertainty
    Controls.Uncertainty_KK = Normalize(Uncertainty_KK);
    Controls.NVIX = Normalize(NVIX);
    
  beta_s = beta_weekly_nolag1;
  beta_s(:,length(ticnum_list)+1)=1;
