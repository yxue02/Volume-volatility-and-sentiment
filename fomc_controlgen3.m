function [isevent,treat_index,control_index,DaysNeeded] = fomc_controlgen3(Indicator,News,kn,n,Dates,controltype)
%% This control generates can only generate controls for four types of daily control 
%% But it can generate benchmarks using monthly average

%Set NumDays to 22;
    NumDays = 22;
    
    
   
    if strcmp(controltype,'PreviousMonth') || strcmp(controltype,'PreviousNoEventMonth');
        if strcmp(controltype,'PreviousMonth');
            CleanDate = 0;
        else
            CleanDate = 1;
        end;
            [control_indexes,Control_Vec, DaysNeeded]= GenerateBenchmark_Month(Indicator,News,kn,n,NumDays,CleanDate);
            control_indicator = zeros(size(Dates,1),1);
            control_indicator(control_indexes) = 1;
            isevent = Indicator | control_indicator;
            isevent_index = find(isevent);
            % For each row of Control_Vec, find the index of the control(on
            % that day)
            %Be careful with NaNs
            [~,treat_index]=ismember(find(Indicator),isevent_index);
            control_index = NaN(size(Control_Vec));
            for f = 1 : size(control_index,1);
                [~,jj]  = ismember(Control_Vec(f,~isnan(Control_Vec(f,:))),isevent_index);
                control_index(f,1:length(jj)) = jj;
            end;
                
            
    else
        % Create a dictionary to find the direction, the number of k and the control vectors to use
        control_type_list_full = {'PreviousDay','PreviousWeekday','PreviousNoEventDay','PreviousNoEventWeekday','NextDay','NextWeekday','NextNoEventDay','NextNoEventWeekday'};
        k_values={1,5,1,2,1,5,1,2};
        noevent_list={false,false,true,true,false,false,true,true};  %Whether we need noevent window
        direction_list={'Backward','Backward','Backward','Backward','Forward','Forward','Forward','Forward'};
        find_k = containers.Map(control_type_list_full, k_values);
        find_noevent=containers.Map(control_type_list_full,noevent_list);
        find_direction=containers.Map(control_type_list_full,direction_list);

        % use the dictionary to find k, tmp_contrl1 and tmp_control2
        k=find_k(controltype);
        noevent=find_noevent(controltype);
        direction=find_direction(controltype);
        %Generate control based on different types
        [Indicator_bench,Indicator_bench_clean,Index_bench_clean]= GenerateBenchmark(Indicator,News,kn,n,1,Dates,direction); %From now on lag is imposed to be 1
        if noevent;
            tmp_control=Indicator_bench_clean(:,k);
        else
            tmp_control=Indicator_bench(:,k);
        end;


            isevent = Indicator | tmp_control ;
            treat_index = find(Indicator(isevent));
            if noevent; 
                tmp_controlindex = Index_bench_clean(:,k);
                cumsum_isevent = cumsum(isevent);
                control_index = cumsum_isevent(tmp_controlindex);
            else
                control_index = find(tmp_control(isevent));
            end;
    end;


    %% This function generates daily control
    function [Indicator_bench,Indicator_bench_clean,Index_bench_clean]= GenerateBenchmark(Indicator,News,kn,n,lag,Dates,Direction)
        %Indicaotr: the indicator we want to study
        %News: all news announcements
        %kn: half window length, so the window will be [-kn,kn] with 2*kn+1 observations
        %n: number of observations per day
        %lag: lag of benchmark, which will be the number of column for the output table
        %% find weekday
        yy=floor(Dates/10000);
        mm=floor((Dates-10000*yy)/100);
        dd=Dates-10000*yy-100*mm;
        wkd=weekday(datenum(yy,mm,dd));
        %% Table1
        if strcmp(Direction,'Backward');
            lagsequence=-(1:lag)*n;
        else
            lagsequence=(1:lag)*n;
        end;
        Indicator_bench=lagmatrix(Indicator,lagsequence);
        Indicator_bench(isnan(Indicator_bench))=0;
        %% Table2
        % First find the indicator of "has news"
        NewsInd=sum(News,2)>0;
        %Avoid splitting over to other days so we need to know time in day
        Timeseq=repmat((1:n)',length(NewsInd)/n,1);


        %find the index of the indicators
        Indicator_index=find(Indicator);
        %We will try to find the indexes of the benchmarks
        Indicator_clean1=NaN(length(Indicator_index),1);
        Indicator_clean5=NaN(length(Indicator_index),1);

        for i=1:length(Indicator_index);
            index_i=Indicator_index(i); %The index of the i'th event
            wkd_i=wkd(index_i); %day of the weak 
            flag1=0; %=1 if the first day has been found
            flag5=0; %=1 if the first same weekday has been found
            if strcmp(Direction,'Backward');
                index_tofind=index_i-n;
            else
                index_tofind=index_i+n;
            end;
            while index_tofind>0 && index_tofind<=length(Indicator) && (flag1==0 ||flag5==0); 
                TimeinDate=Timeseq(index_tofind); %time in date for the control group index we want to investigate
                kn_l=min([kn,TimeinDate-1]); %The maximum window on the left
                kn_r=min([kn,n-TimeinDate]); %The maximum window on the right
                HasNoNews=sum(NewsInd(index_tofind-kn_l:index_tofind+kn_r))==0; %The window has no news announcement
                if HasNoNews; %pass the not in event window test 
                    if flag1==0; %not find first day yet yet
                        flag1=1;
                        Indicator_clean1(i)=index_tofind;
                    end;
                    if flag5==0 && wkd(index_tofind)==wkd_i %not find first weekday yet and the weekday matches
                        flag5=1;
                        Indicator_clean5(i)=index_tofind;
                    end;
                end;

                if strcmp(Direction,'Backward');
                     % look for the previous day;
                    index_tofind=index_tofind-n;
                else
                     % look for the next day;
                    index_tofind=index_tofind+n;
                end;
            end;
        end;

    % if on some days we cannot find the clean control group, we use the uncleaned control group (this might happen for the first few news announcements)
    if sum(isnan(Indicator_clean1))>0;
        Indicator_1=find(Indicator_bench(:,1)); %It is still possible that we cannot find a full Indicator_bench, what should we do then?
        Indicator_clean1(isnan(Indicator_clean1))=Indicator_1(isnan(Indicator_clean1));
    end

    if sum(isnan(Indicator_clean5))>0;
        if lag>=5;
            Indicator_5=find(Indicator_bench(:,5)); 
            Indicator_clean5(isnan(Indicator_clean5))=Indicator_5(isnan(Indicator_clean5));    
        else
            Indicator_clean5(isnan(Indicator_clean5))=Indicator_clean1(isnan(Indicator_clean5));
        end;
    end
    Indicator_bench_clean=zeros(length(Indicator),2);
    Indicator_bench_clean(Indicator_clean1,1)=1;
    Indicator_bench_clean(Indicator_clean5,2)=1;
    Index_bench_clean=[Indicator_clean1,Indicator_clean5];
    end



    function [control_indexes, Control_Vec, DaysNeeded]= GenerateBenchmark_Month(Indicator,News,kn,n,NumDays,CleanDate)
    %% Two different ways to construct spot variance and volume benchmark;
    % Use NumDays of days with or without (CleanDate = 0 or 1)news announcements to
    % generate averaged spot 
    % First find spot volume/variance and then average over all these days

    % It seems that we do not need to find the days that are clean, but we only
    % use the window that are clean

    % Parameters: Indicator,News,kn,n,Dates,NumDays, CleanDate;
    
    % control_indicator returns the (unique) indicator of control variables
    %% Load data and set tuning parameters
        
        NewsInd=sum(News,2)>0;
   
        %%
        %Avoid splitting over to other days so we need to know time in day
        Timeseq=repmat((1:n)',length(NewsInd)/n,1);
        index_all = find(Indicator);
        %Store days needed to find all the controls
        DaysNeeded = NaN(size(index_all));
        %Store the vector of control_vector: [PreVariance, PostVariance, PreVolume,
        %PostVolume];
        Control_Vec = NaN(length(index_all),NumDays);

        %Start from the first event
        for i = 1 : length(index_all);
            index_i = index_all(i);
            % Number of "Crude" Days to include to calculate benchmark
            DaysCount = min( floor(index_i/n),NumDays);
            %Index of the controls;
            if ~CleanDate;
                control_indexvec = repmat(index_i,DaysCount,1)-(1:DaysCount)'*n;
            else
                % Go into past to find clean controls until reach the first day or
                % maximum NumDays is reached;
                findcontrol = 0;
                control_index_clean = NaN(NumDays,1);

                index_tofind = index_i - n;
                j = 1;
                m = 0;

                while index_tofind>0 && index_tofind<=length(Indicator) && (findcontrol ==0); 
                    TimeinDate=Timeseq(index_tofind); %time in date for the control group index we want to investigate
                    kn_l=min([kn,TimeinDate-1]); %The maximum window on the left
                    kn_r=min([kn,n-TimeinDate]); %The maximum window on the right
                    HasNoNews=sum(NewsInd(index_tofind-kn_l:index_tofind+kn_r))==0; %The window has no news announcement
                    if HasNoNews; %pass the not in event window test 
                        control_index_clean(j)=index_tofind; %add to the control index list;
                        if j == NumDays;
                            findcontrol = 1;
                        end;
                        j = j + 1;
                    end;
                    index_tofind=index_tofind-n;
                    m = m + 1; %Count how many days are needed
                end;
                DaysNeeded(i) = m;
              %It's possible that no such control_index_clean is found, then we use the
              %not clean one to replace that
                 if sum(~isnan(control_index_clean)) == 0;
                     control_index_clean = repmat(index_i,size(DaysCount))-ones(size(DaysCount))*n;
                 else
                     control_index_clean = control_index_clean(~isnan(control_index_clean));
                 end;
                 %Unify the names
                 control_indexvec = control_index_clean;
            end;

            % Generate spot volatility and spot variance;
           
            Control_Vec(i,1:length(control_indexvec)) =  sort(control_indexvec);
     
        end;
               
            control_indexes = unique(Control_Vec(~isnan(Control_Vec)));
    end

end
