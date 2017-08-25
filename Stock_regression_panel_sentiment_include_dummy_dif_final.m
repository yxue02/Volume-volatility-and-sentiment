%% The difference between sentiment is this file uses bootstrap to calculate the difference 
%% This file just does regressions one by one
% Also include the whole sample
%% in coefficients when sentiment is high and low.
%% This file also includes dummy variables
%% Set path, load data
% Try other dispersion measures
clear; close all;
clc;
currentpath = pwd();
cd('../..');
addpath(genpath(pwd()));
cd('..');
parent_path=pwd();
cd(currentpath);

if exist('E:\Duke\TAQ\Codes','dir')>0
    addpath(genpath('E:\Duke\TAQ\Codes'));
end;
if exist('/Users/yuanxue/Desktop/Volume_Cross/Data','dir')>0
    addpath(genpath('/Users/yuanxue/Desktop/Volume_Cross/Data'));
end;
load('TickerList');


% function_name1 = 'All_reg_panel_dummy';
% function_name1 = 'All_reg_panel_dummy_individual';
% function_name1 = 'All_reg_panel_dummy2';
function_name1 = 'All_reg_panel_dummy5_dif_final_final';
    
% suffix = strcat('panel_sentiment_dummy');
% suffix = strcat('panel_sentiment_dummy_individual');
% suffix = strcat('panel_sentiment_dummy2');
suffix = strcat('panel_sentiment_combined5_dif_final_final');

    %% Set tuning parameters
L = 0; % Left extension of event window
R = 0; % Right extension of event window
kn = 30; % Window upper bound for spot estimation
n = 390; % Number of returns per day (1-minute data)

load('MacroAnnouncements_extend');
% Delete all events in the morning of 20030102 since JPM 
MacroAnnouncement(MacroAnnouncement(:,1) ==20030102 & MacroAnnouncement(:,2) < 1200,3:end) =0;
%% load all data
% Do not load CVX, TRV or V since they have missing values


EventIndicatorList = constructEventIndicators2_full(MacroAnnouncement,kn,n);
IndicatorNames={'FOMC' ,'ISM Manufacture', 'ISM NonManufacture', 'Consumer Credit','Housing' , 'WholeSale'};
ticnum_list_list{1} = [1:5,7:23,25:26,28:30]';
%ticnum_list_list{1} = [1,3:5,7:9,11:14,16:23,25:26,28:30]';
%ticnum_list_list{2} = [3,4,9,18,26];
ticnum_list_list{2} = [1:5,7:23,25:26,28:30]';
%ticnum_list_list{3} = [1,5,12,13,20,28,14,19,22,25];
ticnum_list_list{3} = [1:5,7:23,25:26,28:30]';
%ticnum_list_list{4} = [16,23,29,8,11,17,21];
ticnum_list_list{4} = [1:5,7:23,25:26,28:30]';
ticnum_list_list{5} = [1:5,7:23,25:26,28:30]';
ticnum_list_list{6} = [1:5,7:23,25:26,28:30]';

caselist = [1 2 ];
%caselist = [5 6];



    %% Regressions for all events

    DID_type_list = {'PreviousNoEventMonth'};
    %Each row is a different category of announcement
     rlistvec=cell(5,2);
    vlistvec=cell(5,2);
 %%  

    for Indi = 1:1;
      %%
        ticnum_list = ticnum_list_list{Indi};
    run('importData_normalize_dif_long')
    
    un = 100 * ones(size(data,1),1,size(beta_s,2)); % Truncation threshold (here very large)
    T=length(data)/n;
    nboot = 1;
    
    datelist = data(:,1);
    News = MacroAnnouncement(:,3:end);
    CaseNames = {'Case1','Case2','Case3','Case4','Case5','Case6','Case7'};
  
    for vol_type = 1:1; % Total volatility and systematic volatility

       
        
            
            % Only includes events in high/low sentiment
%             event_indicator_high = EventIndicatorList{Indi} & sentiment_period{1}>0; 
%             negative_high = find(event_indicator_high(EventIndicatorList{Indi}>0));
%             event_indicator_low = EventIndicatorList{Indi} & sentiment_period{2}>0; 
%             negative_low = find(event_indicator_low(EventIndicatorList{Indi}>0));
            event_indicator = EventIndicatorList{Indi};
            Dayindex = floor((find(event_indicator)-1)/n)+1;
            sentiment_day = [sentiment_period{1}(1:n:end,:),sentiment_period{2}(1:n:end,:)];
            index_high = find(sentiment_day(Dayindex,1));
            index_low = find(sentiment_day(Dayindex,2));
            indexes_whole = union(index_high,index_low);
            Controls.indexes_all = {index_high,indexes_whole,index_low};
            Controls.Dayindex = Dayindex;
            Controls.Indi = Indi;
            
            rlist = cell(length(caselist),length(DID_type_list)+1);
            vlist = cell(length(caselist),length(DID_type_list)+1);
            %With DID
            for loop = 1:length(DID_type_list)
                control_type = DID_type_list{loop};
                %event_indicator=EventIndicatorList{Indi};
    
                [isevent,treat_index,control_index] = fomc_controlgen3(event_indicator,News,kn,n,datelist,control_type);
                output = volatility_decompose_eventgen_with_beta_all(data_all,isevent,n,L,R,kn,un,beta_s);
                % Store controls
                output.treat_index = treat_index;
                output.control_index = control_index;

                %Add other variables;
                output.Controls = Controls;
                output.vol_type = vol_type;
                output.dummy_case = false;
                output.FOMC = true;
         
                for j = 1:length(caselist)
                    fprintf('Case %d Regression for %s using %s as control when voltype is %d\n',caselist(j),IndicatorNames{Indi},control_type,vol_type);

                    
                        tic;
                            [rlist{j,loop+1},vlist{j,loop+1}]= fomc_boot_case_table_panel_extend(str2func(function_name1),output,nboot,caselist(j),1);  %With negative and other measures
                        toc;
                    
                end;
            end;

            rlistvec{Indi,vol_type} = rlist;
            vlistvec{Indi,vol_type} = vlist;
        
        end
    end;
    save(strcat('All_results_',suffix),'rlistvec','vlistvec');
%% dummy variables
     
EventIndicatorList = constructEventIndicators2_full(MacroAnnouncement,kn,n);
Index_matrix =  Construct_dummy_new(EventIndicatorList);
EventIndicatorList =  Construct_dummy(EventIndicatorList);
clear rlistvec vlistvec;
Indi = 1;
DID_type_list = {'PreviousNoEventMonth'};
for vol_type = 1:1; % Total volatility and systematic volatility


            
            % Only includes events in high/low sentiment
%             event_indicator_high = EventIndicatorList{Indi} & sentiment_period{1}>0; 
%             negative_high = find(event_indicator_high(EventIndicatorList{Indi}>0));
%             event_indicator_low = EventIndicatorList{Indi} & sentiment_period{2}>0; 
%             negative_low = find(event_indicator_low(EventIndicatorList{Indi}>0));
            event_indicator = EventIndicatorList{Indi};
            Dayindex = floor((find(event_indicator)-1)/n)+1;
            sentiment_day = [sentiment_period{1}(1:n:end,:),sentiment_period{2}(1:n:end,:)];
            index_high = find(sentiment_day(Dayindex,1));
            index_low = find(sentiment_day(Dayindex,2));
            indexes_whole = union(index_high,index_low);
            Controls.indexes_all = {index_high,indexes_whole,index_low};
            Controls.Dayindex = Dayindex;
            Controls.Indi = Indi;
           
            
            rlist = cell(length(caselist),length(DID_type_list)+1);
            vlist = cell(length(caselist),length(DID_type_list)+1);
            %With DID
            for loop = 1:length(DID_type_list)
                control_type = DID_type_list{loop};
                %event_indicator=EventIndicatorList{Indi};
                 fprintf('Start constructing output.\n');
                 tic;
                [isevent,treat_index,control_index] = fomc_controlgen3(event_indicator,News,kn,n,datelist,control_type);
                output = volatility_decompose_eventgen_with_beta_all(data_all,isevent,n,L,R,kn,un,beta_s);
                % Store controls
                output.treat_index = treat_index;
                output.control_index = control_index;

                %Add other variables;
                output.Controls = Controls;
                output.vol_type = vol_type;
                output.Index_matrix = Index_matrix; % dummy variables
                output.dummy_case = true;
                output.FOMC = false;
                toc;
                for j = 1:length(caselist)
                    fprintf('Case %d Regression for %s using %s as control when voltype is %d\n',caselist(j),'All events' ,control_type,vol_type);

                    
                        tic;
                            [rlist{j,loop+1},vlist{j,loop+1}]= fomc_boot_case_table_panel_extend(str2func(function_name1),output,nboot,caselist(j),1);  %With negative and other measures
                        toc;
                    
                end;
            end;

            rlistvec{Indi,vol_type} = rlist;
            vlistvec{Indi,vol_type} = vlist;
        
end

    save(strcat('All_dummy_',suffix),'rlistvec','vlistvec');
    
