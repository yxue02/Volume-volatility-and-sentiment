%% Import tickers
clear;
filename = 'TickerList2.csv';
delimiter = '';
formatSpec = '%s%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
fclose(fileID);
TickerList = dataArray{:, 1};
clearvars filename delimiter formatSpec fileID dataArray ans;
if strcmpi(TickerList{1},'ticker');
    TickerList=TickerList(2:end);
end;
current_path = pwd();
replicateList = {};
MissedObs = {};

%% Import data
for j=1:length(TickerList)-1;
%for j = 1:1;
 ticker=TickerList{j};
 fprintf('Process ticker %s.\n', ticker);
    if strcmpi(ticker,'TRV')
        yearbegin = 2007;
    elseif strcmpi(ticker,'V')
        yearbegin = 2008;
    else
        yearbegin = 2001;
    end;
    for year=yearbegin:2014;
       
        filename =  strcat(current_path,'\OneMinuteData\',ticker,'_',num2str(year),'_Volnew.csv');
        delimiter = ',';
        startRow = 2;
        formatSpec = '%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
        
        %startRow = 2;
        fileID = fopen(filename,'r');
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);

        fclose(fileID);
        % Convert cells to matrix

        Data=dataArray{:, 2};
        for i=3 :length(dataArray);
            if iscellstr(dataArray{:, i});
                Data=[Data,str2num(char(dataArray{:, i}))];
            else
                Data=[Data,dataArray{:,i}];
            end;
        end;
        % put all files together
        
        if year == yearbegin;
            yearData = Data;
        else
            yearData = [yearData; Data];
        end;
    end;
% load Datetime to make up for missing price and volume information
    %Datetime = yearData(yearData(:,2)~=930,1:2);
    load('Datetime','Datetime');    
    %% check for replicates
    freq = 390;
    datesinData=unique(yearData(:,1));
    countdates=hist(yearData(:,1),datesinData);
    datesrep=datesinData(countdates>freq+1);
    if ~isempty(datesrep);
        replicatelist=[replicatelist,ticker];
    end;
        
    %% Get one minute intraday return and overnight return (and adjust for distribution codes)
    %Overnight return can directly be got from database
    data = yearData(:,1:2);
    data(2:end,3) = diff(log(yearData(:,3)./yearData(:,38)))*100;
    data(:,4) = sum(yearData(:,5:20),2).*yearData(:,39);
    data(:,5) = sum(yearData(:,21:36),2).*yearData(:,39);
    
    %% 
    % If distribution code belongs to 5000-5999 this may be a replicate of
    % stock split
    DISTCO = yearData(:,40);
    % Only the last 
    NoDiv = DISTCO>0 & yearData(:,2) ~= 1600;
    yearData(NoDiv,40:43) = 0;
     Dist = yearData(:,40)>0;
%     % Find the time of distribution
%     DistTime = find(Dist);
%     % 2k+1 minute window
%     k = 5;
%     WindowIndex = repmat(-k:k,length(DistTime),1)+repmat(DistTime,1,2*k+1);
%     WindowIndex = reshape(WindowIndex',length(DistTime)*(2*k+1),1);
%     md = yearData(WindowIndex,[1:4,38:43]);
    % The first time after execution
    Dist2 = lagmatrix(Dist,1);
    Dist2(1) = 0;
    data(Dist2>0,3) = (log(yearData(Dist2>0,3)+yearData(Dist,41))-log(yearData(Dist,3)))*100;
    % Only for now we only keep intraday returns 
   data = data(data(:,2)~=930,:);
   
  %%  Make up for missing observations
     if length(data)<length(Datetime) ;
         fprintf('Make up data for ticker %s.\n',ticker)
         StockIndex=FindIndex(data(:,1:2),Datetime,freq);
         data_makeup=MakeUpData(data(:,3:5),Datetime,StockIndex);
         data = [Datetime,data_makeup];
         MissedObs = [MissedObs, ticker];
     end;
     %% Get rid of IPO day of CVX, TRV and V
        if strcmpi(ticker,'CVX');
            data(data(:,1)==20011010,:) = NaN;
        end;
        if strcmpi(ticker,'TRV');
            data(data(:,1)==20070227,:) = NaN;
        end;
        if strcmpi(ticker,'V');
            data(data(:,1)==20080319,:) = NaN;
        end;
     if sum(data(:,1)~=Datetime(:,1))>0
         fprintf('The dates are not exactly the same for ticker %s.\n',ticker);
     end;
      %% Clean for half trading day
    load('InSample_Index','InSample');
    OneMinuteData = data(InSample>0,:);
%     figure;
%     subplot(2,1,1);
%     plot(OneMinuteData(:,3));
%     subplot(2,1,2);
%     plot(OneMinuteData(:,4));
%     title(ticker);
        %% Note: the data should have the following structure
        %Save data into structure
        field1 = 'Data'; 
        field2 = 'Variable_Names'; 
        field3 = 'Exchange_Code';
        Varname={'date' 'time'	'price_m'	'price_v''Volume_A'	'Volume_B'	'Volume_C'	'Volume_D'	'Volume_I'	'Volume_J'	'Volume_K' 'Volume_M'...
            'Volume_N'	'Volume_P''Volume_T' 'Volume_Q'		'Volume_W'	'Volume_X'	'Volume_Y'	'Volume_Z' 'NumTrade_A'	'NumTrade_B'...
            'NumTrade_C'	'NumTrade_D'	'NumTrade_I'	'NumTrade_J'	'NumTrade_K'	'NumTrade_M'	'NumTrade_N'	'NumTrade_P'...
            'NumTrade_T' 'NumTrade_Q'		'NumTrade_W'	'NumTrade_X'	'NumTrade_Y'	'NumTrade_Z'	'missing'	...
            'Cumulative Factor to Adjust Prices'	'Cumulative Factor to Adjust Shares/Vol''Distribution Code''Dividend' 'Factor to Adjust Price' 'Factor to Adjust Shares'};
        ExchangeList={'A' 'B' 'C' 'D' 'I' 'J' 'K' 'M' 'N' 'P' 'Q' 'T' 'W' 'X' 'Y' 'Z'};
        filename2 = strcat(current_path,'\Final_data\',ticker,'_1min');
        save(filename2,'OneMinuteData', 'Varname', 'ExchangeList');
end;
