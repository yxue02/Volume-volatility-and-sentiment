%%
for k = 1:length(varlist)
    filename = strcat(data_path,varlist{k},'.csv');
    delimiter = ',';
    startRow = 2;
    formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%s%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    fclose(fileID);
    Date = dataArray{:, 1};
    AAPL = dataArray{:, 2};
    AXP = dataArray{:, 3};
    BA = dataArray{:, 4};
    CAT = dataArray{:, 5};
    CSCO = dataArray{:, 6};
    CVX = dataArray{:, 7};
    DD = dataArray{:, 8};
    DIS = dataArray{:, 9};
    GE = dataArray{:, 10};
    GS = dataArray{:, 11};
    HD = dataArray{:, 12};
    IBM = dataArray{:, 13};
    INTC = dataArray{:, 14};
    JNJ = dataArray{:, 15};
    JPM = dataArray{:, 16};
    KO = dataArray{:, 17};
    MCD = dataArray{:, 18};
    MMM = dataArray{:, 19};
    MRK = dataArray{:, 20};
    MSFT = dataArray{:, 21};
    NKE = dataArray{:, 22};
    PFE = dataArray{:, 23};
    PG = dataArray{:, 24};
    TRV = dataArray{:, 25};
    UNH = dataArray{:, 26};
    UTX = dataArray{:, 27};
    V = dataArray{:, 28};
    VZ = dataArray{:, 29};
    WMT = dataArray{:, 30};
    XOM = dataArray{:, 31};

    clearvars filename delimiter startRow formatSpec fileID dataArray ans;
    %% 
    InDate = findDates(dates,Date);
    %Get values for tickers;
    values = NaN(length(Date),length(TickerList)-1);
    for i = 1:size(values,2)
        values(:,i) = eval(TickerList{i});
    end;
    value_all = [dates,Date(InDate),values(InDate,:)];
    % make up for missing value;
    for i = 2:size(value_all,2)
        value_all(:,i) = makeup_missing(value_all(:,i));
    end;
    v = matlab.lang.makeValidName(varlist{k});

    eval([v '= value_all;']);
filename_out = strcat(parent_path,'\Codes\library\data_cross\',v);
save(filename_out,v);

end;
