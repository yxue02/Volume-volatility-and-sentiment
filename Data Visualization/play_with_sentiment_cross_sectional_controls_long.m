 %% Set path, load data
clear; close all;
clc;
run('setup_path_and_plot2');
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
load('betas_by_year');
betas(:,31) = 1;

    
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
%ticnum_list_list{2} = [3,4,9,18,26];
ticnum_list_list{2} = [1:5,7:23,25:26,28:30]';
%ticnum_list_list{3} = [1,5,12,13,20,28,14,19,22,25];
ticnum_list_list{3} = [1:5,7:23,25:26,28:30]';
%ticnum_list_list{4} = [16,23,29,8,11,17,21];
ticnum_list_list{4} = [1:5,7:23,25:26,28:30]';
ticnum_list_list{5} = [1:5,7:23,25:26,28:30]';
ticnum_list_list{6} = [1:5,7:23,25:26,28:30]';

 %%   
Indi = 1;

ticnum_list = ticnum_list_list{Indi};
run('importData_normalize_dif_long')


%%
Dayindex = 1:length(Controls.Date);
dateplot = date_convert(Controls.Date(Dayindex));
sentiment_BW = Controls.sentiment_BW(Dayindex,3);
sentiment_BW_c = Controls.sentiment_BW(Dayindex,4);
   
 % Seperate into high and low sentiment periods
 high = find(sentiment_BW >= median(sentiment_BW));
 low = find(sentiment_BW < median(sentiment_BW));
 
 % Make them continuous time periods
 index_be = NaN(20,2);
 j=1;
 index_be(j,1)  = high(1);

 for i = 2:length(high)
     if high(i)-high(i-1)>1
         j = j+1;
         index_be(j-1,2)=high(i-1);
         index_be(j,1)=high(i);
     end;
 end;
 index_be = index_be(~isnan(index_be(:,1)),:);
 index_be(end,2) = high(end);
 
 % By observing the plot we get a new separation of the period
 index_be2 = [index_be(1,:);index_be(2,1),index_be(4,2);index_be(5,:)];
 index_list = {index_be, index_be2};
 dates = unique(MacroAnnouncement(:,1));
 
 %%
 vars_all = {Controls.Analysts_scale_price,Controls.analyst_LTG,Controls.NewsCount, Controls.betas_weekly, Controls.idio_w2,...
     gamma_beta_ratio_monthly1};
 vars_all_names = {'Analysts'' Dispersion Scaled by Price (in Percentage)',...
      'Analysts'' Dispersion in Long Term Growth Rate','NewsCount(in Hundreds)','Weekly Beta', 'Weekly Ratio of Idiosyncratic Variance',...
      '\gamma-\beta Ratio'};
      file_path = 'E:\Duke\TAQ\Slides\Slides_0724\';
    Tickers_in = TickerList(ticnum_list);
 for mm = 1:length(vars_all);
     dispersion = vars_all{mm};
     %% For dispersion measures

    % Three lines at a time
    numLine = 3;

    hFig = figure;
        set(gcf,'PaperPositionMode','auto')
        set(hFig, 'Position', [200 100 FigWidth FigHeight])
        numPic = ceil(length(Tickers_in)/numLine);
        numrow = 3;
    for j = 1:numPic;

        subplot(numrow,ceil(numPic)/numrow,j);
         vars = dispersion(:,(j-1)*numLine+1:j*numLine);
         vars_names = Tickers_in((j-1)*numLine+1:j*numLine)';

         label = 'ADP';   
         index_be = index_list{1};   
        plot_controls_sentiment_subplot(dates,vars,index_be, vars_names)  
          

    end;
     title_name = vars_all_names{mm};
     suptitle(title_name); 
      print('-depsc',strcat(file_path,'SentimentPeriods_',label,'_',num2str(mm),'.eps')); 
      
      %% Print the means and stds of the control variables
      % Use ttest for significance 
      hl = [sentiment_period{1}(1:390:end)>0,ones(size(sentiment_period{1}(1:390:end)>0))>0,sentiment_period{2}(1:390:end)>0];
      nsize = sum(hl>0);
vars = vars_all{mm};
means_all = [ mean(vars(hl(:,1),:));mean(vars(hl(:,2),:));mean(vars(hl(:,3),:))];
%stds_all = [ std(vars(hl(:,1),:))/sqrt(nsize(1));std(vars(hl(:,2),:))/sqrt(nsize(2));std(vars(hl(:,3),:))/sqrt(nsize(3))];
% stds_all = [ std(vars(hl(:,1),:));std(vars(hl(:,2),:));std(vars(hl(:,3),:))];
stds_all(:,:,1) = [quantile(vars(hl(:,1),:),0.975);quantile(vars(hl(:,2),:),0.975);quantile(vars(hl(:,3),:),0.975)];
stds_all(:,:,2) = [quantile(vars(hl(:,1),:),0.025);quantile(vars(hl(:,2),:),0.025);quantile(vars(hl(:,3),:),0.025)];

sigs_all = NaN(1,size(means_all,2));
for j = 1:length(sigs_all);
    %[h,p] = ttest2(vars(hl(:,1),j),vars(hl(:,3),j),'Vartype','unequal');
    %[h,p] = kstest2(vars(hl(:,1),j),vars(hl(:,3),j));
    
    p = ranksum(vars(hl(:,1),j),vars(hl(:,3),j));
    sigs_all(j) = p<0.05;
end;
numLine = 9;
    hFig = figure;
        set(gcf,'PaperPositionMode','auto')
        set(hFig, 'Position', [200 100 FigWidth FigHeight])
        numPic = ceil(length(Tickers_in)/numLine);
        numrow = 3;
    for j = 1:numPic;

         subplot(numrow,ceil(numPic)/numrow,j);
        xlabels = Tickers_in((j-1)*numLine+1:j*numLine)';
        means = means_all(:,(j-1)*numLine+1:j*numLine);
        stds = stds_all(:,(j-1)*numLine+1:j*numLine,:);
        sigs = sigs_all(:,(j-1)*numLine+1:j*numLine);
        plot_box_subplot(means, stds,sigs,0.95, xlabels,3,1)
    end;
    title_name = vars_all_names{mm};
    suptitle(title_name);
    if exist(file_path,'dir')>0
        print('-depsc',strcat(file_path,'controls_box_',label,'_',num2str(mm),'.eps'));
    end;
 end;

 %%
%%
 
 vars_all = {Controls.dispersion_dif_std(:,:,1),Controls.dispersion_dif_std(:,:,2),Controls.uncertainty_dif_std(:,:,3)};
 vars_all_names = {'Relative RGDP Growth Dispersion', 'Relative UNEMP Dispersion','MonthlyIndex'};
      file_path = 'E:\Duke\TAQ\Slides\Slides_0724\';
    Tickers_in = TickerList(ticnum_list);
 for mm = 1:length(vars_all);
     dispersion = vars_all{mm};
     %% For dispersion measures

    % Three lines at a time
    numLine = 3;

    hFig = figure;
        set(gcf,'PaperPositionMode','auto')
        set(hFig, 'Position', [200 100 FigWidth FigHeight])
        numPic = ceil(length(Tickers_in)/numLine);
        numrow = 3;
    for j = 1:numPic;

        subplot(numrow,ceil(numPic)/numrow,j);
         vars = dispersion(:,(j-1)*numLine+1:j*numLine);
         vars_names = Tickers_in((j-1)*numLine+1:j*numLine)';

         label = 'RDP';   
         index_be = index_list{1};   
        plot_controls_sentiment_subplot(dates,vars,index_be, vars_names)  
          

    end;
     title_name = vars_all_names{mm};
     suptitle(title_name); 
      print('-depsc',strcat(file_path,'SentimentPeriods_',label,'_',num2str(mm),'.eps')); 
      
      %% Print the means and stds of the control variables
      % Use ttest for significance 
      hl = [sentiment_period{1}(1:390:end)>0,ones(size(sentiment_period{1}(1:390:end)>0))>0,sentiment_period{2}(1:390:end)>0];
      nsize = sum(hl>0);
vars = vars_all{mm};
means_all = [ mean(vars(hl(:,1),:));mean(vars(hl(:,2),:));mean(vars(hl(:,3),:))];
%stds_all = [ std(vars(hl(:,1),:))/sqrt(nsize(1));std(vars(hl(:,2),:))/sqrt(nsize(2));std(vars(hl(:,3),:))/sqrt(nsize(3))];
% stds_all = [ std(vars(hl(:,1),:));std(vars(hl(:,2),:));std(vars(hl(:,3),:))];
stds_all(:,:,1) = [quantile(vars(hl(:,1),:),0.975);quantile(vars(hl(:,2),:),0.975);quantile(vars(hl(:,3),:),0.975)];
stds_all(:,:,2) = [quantile(vars(hl(:,1),:),0.025);quantile(vars(hl(:,2),:),0.025);quantile(vars(hl(:,3),:),0.025)];

sigs_all = NaN(1,size(means_all,2));
for j = 1:length(sigs_all);
    %[h,p] = ttest2(vars(hl(:,1),j),vars(hl(:,3),j),'Vartype','unequal');
    %[h,p] = kstest2(vars(hl(:,1),j),vars(hl(:,3),j));
    
    p = ranksum(vars(hl(:,1),j),vars(hl(:,3),j));
    sigs_all(j) = p<0.05;
end;
numLine = 9;
    hFig = figure;
        set(gcf,'PaperPositionMode','auto')
        set(hFig, 'Position', [200 100 FigWidth FigHeight])
        numPic = ceil(length(Tickers_in)/numLine);
        numrow = 3;
    for j = 1:numPic;

         subplot(numrow,ceil(numPic)/numrow,j);
        xlabels = Tickers_in((j-1)*numLine+1:j*numLine)';
        means = means_all(:,(j-1)*numLine+1:j*numLine);
        stds = stds_all(:,(j-1)*numLine+1:j*numLine,:);
        sigs = sigs_all(:,(j-1)*numLine+1:j*numLine);
        plot_box_subplot(means, stds,sigs,0.95, xlabels,3,1)
    end;
    title_name = vars_all_names{mm};
    suptitle(title_name);
    if exist(file_path,'dir')>0
        print('-depsc',strcat(file_path,'controls_box_',label,'_',num2str(mm),'.eps'));
    end;
 end;
