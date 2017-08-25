function [bhat_table,ModelNames,VariableList,R2_table,sse_table, NumObs] = All_reg_panel_dummy5_dif_final_final(output,Case,DID)
% Includes regression for low sentiment, high sentiment as well as the
% whole sample
% This file fix beta and idiosyncratic ratio
    spot = output.spot;
     % Setup box
    bhat_table = NaN(20,200);
    R2_table = NaN(1,200);
    sse_table = NaN(1,200);
    NumObs = NaN(1,200);
    n_stocks = output.n_stocks;
    vol_type = output.vol_type;
	
        switch vol_type
            case 1
                index1 = 4; %total volatility
            case 2
                index1 = 8; %systematic volatility
            case 3
                index1 = 10; %idiosyncratic volatility
            case 4
                index1 = 12; % market volatility
        end
        index2 = index1+1;
        % in case spot volatility is negative

        logcm = 0.5*log(squeeze(spot(:,index1,:)));
        logcp = 0.5*log(squeeze(spot(:,index2,:)));
        % Now need all spot volatility larger than zero
        in1 = sum(squeeze(spot(:,index1,:))>0,2)==n_stocks - 1;
        in2 = sum(squeeze(spot(:,index2,:))>0,2)==n_stocks - 1;
        %volume
        logvm = log(squeeze(spot(:,14,:)));
        logvp = log(squeeze(spot(:,15,:)));
        cj_all = logcp - logcm;
        vj_all = logvp - logvm;
        
        if DID==1
             % Get cj and vj for event and control
            % Event
             cj = cj_all(output.treat_index,:);
             vj = vj_all(output.treat_index,:);
             in12 = in1(output.treat_index)&in2(output.treat_index);
             treattime = output.eventtime(output.treat_index,1);
            if size(output.control_index,2) == 1 %One day control

                % Control
                cj_control = cj_all(output.control_index,:);
                vj_control = vj_all(output.control_index,:);
            else %Premonth control
                cj_control = NaN(size(output.treat_index,1),n_stocks);
                vj_control = NaN(size(output.treat_index,1),n_stocks);
                in3 = NaN(size(cj_control,1),1);
                in4 = NaN(size(cj_control,1),1);
                for i = 1:size(output.control_index,1)
                    mm = output.control_index(i,:);
                    mm = mm(~isnan(mm));  %Take care of NaN;
                    in3(i) = sum(squeeze(mean(spot(mm,index1,:)))>0)==n_stocks-1;
                    in4(i) = sum(squeeze(mean(spot(mm,index2,:)))>0)==n_stocks-1;
                    logcm_control = 0.5*log(squeeze(mean(spot(mm,index1,:))));
                    logcp_control = 0.5*log(squeeze(mean(spot(mm,index2,:))));
                    logvm_control = log(squeeze(mean(spot(mm,14,:))));
                    logvp_control = log(squeeze(mean(spot(mm,15,:))));
                    cj_control(i,:) = logcp_control - logcm_control;
                    vj_control(i,:) = logvp_control - logvm_control;
                end;

             end;

            % Event - Control
            cj = cj - cj_control;
            vj = vj - vj_control;
        else
            cj = cj_all;
            vj = vj_all;
            treattime = output.eventtime(:,1);
        end;
        
        
           
        %% Regression Model
        %Fixed effect model
            %Control Variables
    Controls = output.Controls;
    Indi = Controls.Indi;
    Dayindex = Controls.Dayindex;
 
%     dispersion1 = Controls.Dispersion(Dayindex,9);  
%     dispersion2 = Controls.Dispersion_new(Dayindex,9);
%     dispersion3 = Controls.Dispersion_new(Dayindex,4);
%     dispersion4 = Controls.Dispersion_new(Dayindex,19);
%     dispersion5 = Controls.Dispersion_new2(Dayindex,14);
%     dispersion6 = dispersion4;
%     dispersion_all = [dispersion1,dispersion2,dispersion3,dispersion4,dispersion5,dispersion6];
%     dispersion = dispersion_all(:,Indi);
   % dispersions = [Controls.Dispersion_new_all(Dayindex,5),Controls.Dispersion_new_growth(Dayindex,[9,7,5]),Controls.Dispersion_new_all(Dayindex,12)];
    
    dailypolicy = Controls.DailyPolicy(Dayindex,2); % Weekly Policy
    %uncertainties = [Controls.DailyPolicy(Dayindex,2),Controls.Uncertainty_KK(Dayindex,[4,7]),Controls.NVIX(Dayindex,3)];
    
%     analysts_year = Controls.Analysts_yearly(Dayindex,:);
%     analysts_quarter = Controls.Analysts_quarterly(Dayindex,:);
%     % make up for missing value for analysts_quarter
%     analysts_quarter(isnan(analysts_quarter)) = analysts_year(isnan(analysts_quarter));

%     % One year ahead data scaled by mean
%     analysts_meanest = Controls.Analysts_meanest1(Dayindex,:);
%     
%     % WRDS dispersion scaled by MA mean
%     analyst_MA_dispersion = Controls.Analyst_MA_dispersion(Dayindex,:);
%     % First scaled by annual/quarterly mean estimate/actual value and then do moving
%     % average
%     analyst3 = Controls.Analyst_MA_Actual6(Dayindex,:);
%     % recommendation
%     analyst4 = Controls.recommend(Dayindex,:);
%     % One year ahead data scaled by actual
%     analyst5 = Controls.Analyst_MA_Meanest6(Dayindex,:);
    %Scaled by end-of-month price
    analysts_price = Controls.Analysts_scale_price(Dayindex,:);
    % One quarter ahead data scaled by actual
    analyst1 = Controls.Analysts_actual6(Dayindex,:);
    % One quarter ahead data scaled by mean
    analyst2 = Controls.Analysts_meanest6(Dayindex,:);
    % long term growth
    analyst_LTG = Controls.analyst_LTG(Dayindex,:);
    analysts_all = {analyst2,analyst1,analysts_price,analyst_LTG};
    
%     breadth = Controls.breadth(Dayindex,:);
%     dbreadth = Controls.dbreadth(Dayindex,:);
%     IO = Controls.IO(Dayindex,:);
%     dIO = Controls.dIO(Dayindex,:);
%     InOut_WRDS2 = Controls.InOut2(Dayindex,:);
%     InOut_WRDS = Controls.InOut(Dayindex,:);
%     LongShort_WRDS = Controls.LongShort(Dayindex,:);
%     
%     betas_quarter = Controls.betas_quarter(Dayindex,:);
%     betas_year = Controls.betas_year(Dayindex,:);
    
    negative = Controls.Negative;
   
%     betas_weekly = Controls.betas_weekly(Dayindex,:);
%     beta_monthly  = Controls.beta_monthly(Dayindex,:);
%     
%     %Ratio of idiosyncratic variance
% 
%     idio_ratio_monthly = Controls.idio_ratio_monthly(Dayindex,:);
%    
%    
%     
%     idio_w = Controls.idio_w(Dayindex,:);
%     idio_bw = Controls.idio_bw(Dayindex,:);
%     idio_w2 = Controls.idio_w2(Dayindex,:);
    
    idio_beta99 = Controls.idio_beta(Dayindex,:,3);
    idio_beta95 = Controls.idio_beta(Dayindex,:,2);
  
%     %Sentiments
%     NewsCount = Controls.NewsCount(Dayindex,:) ;
%     searchTrend = Controls.searchTrend(Dayindex,:);
%     sentiment_BW = Controls.sentiment_BW(Dayindex,3);
%     sentiment_BW_c = Controls.sentiment_BW(Dayindex,4);
%     
%     Uncertainty_Fin1 = Controls.Uncertainty_KK(Dayindex,3);
%     Uncertainty_Fin3 = Controls.Uncertainty_KK(Dayindex,4);
%     Uncertainty_Fin12 = Controls.Uncertainty_KK(Dayindex,5);
%     Uncertainty_Macro1 = Controls.Uncertainty_KK(Dayindex,6);
%     Uncertainty_Macro3 = Controls.Uncertainty_KK(Dayindex,7);
%     Uncertainty_Macro12 = Controls.Uncertainty_KK(Dayindex,8);
%     NVIX = Controls.NVIX(Dayindex,3);
   monthly_index = Controls.MonthlyPolicy(Dayindex,2);
    analysts_price2 = Controls.Analysts_scale_price2(Dayindex,:);
    
    %% Final Expalnatory variables
    uncertainty = Controls.uncertainty_dif_std(Dayindex,:,:); % WeeklyPolicy, MonthlyPolicy,  MonthlyIndex,  Finance3 Uncertainty, Macro3 Uncertainty, NIVX
    dispersion = Controls.dispersion_dif_std(Dayindex,:,:);
     gamma_beta_ratio_monthly = Controls.gamma_beta_ratio_monthly(Dayindex,:);
    % Unemp, RGDP growh, INDPROD growth, CPROF growth, CPI, CPI10
    % high all low
    indexes_all = Controls.indexes_all;
     dummy_case = output.dummy_case; %determines whether to include dummy variables
    FOMC = output.FOMC;
    sg = size(indexes_all,2);
    %%
    % Use only individual stocks;
    cj = cj(:,1:n_stocks-1);
    vj = vj(:,1:n_stocks-1);
    % length of control variables
    l = size(cj,1);
    % Get dummies and dummies$ct interactive terms
    if dummy_case
        dummy = output.Index_matrix;
        dummy_const = repmat(dummy,1,1,n_stocks-1);
        dummy_vol =  repmat(dummy,1,1,n_stocks-1).*repmat(reshape(cj,l,1,n_stocks-1),1,size(dummy,2),1);
    end;
    
   
    
    
    

     if Case ==1
    
       variables = {reshape(gamma_beta_ratio_monthly.*cj,l,1,n_stocks-1),reshape(uncertainty(:,:,6).*cj,l,1,n_stocks-1),...
            reshape(uncertainty(:,:,3).*cj,l,1,n_stocks-1),reshape(dispersion(:,:,1).*cj,l,1,n_stocks-1)};
        Names = { '+ Gamma-Beta-Ratio * Voj','+ NVIX * Voj','+ MonthlyIndex * Voj', '+ UNEMP Dispersion * Voj'};
    end;
    
   if Case ==2
    
       variables = {reshape(gamma_beta_ratio_monthly.*cj,l,1,n_stocks-1),reshape(uncertainty(:,:,6).*cj,l,1,n_stocks-1),...
           reshape(uncertainty(:,:,3).*cj,l,1,n_stocks-1),reshape(dispersion(:,:,2).*cj,l,1,n_stocks-1)};
        Names = { '+ Gamma-Beta-Ratio * Voj','+ NVIX * Voj', ' + MonthlyIndex * Voj', ' + RGDP Growth Dispersion* Voj'};
   end;
    

    
    if Case ==3
    
       variables = {reshape(gamma_beta_ratio_monthly.*cj,l,1,n_stocks-1),...
            reshape(uncertainty(:,:,1).*cj,l,1,n_stocks-1),reshape(dispersion(:,:,1).*cj,l,1,n_stocks-1)};
        Names = { '+ Gamma-Beta-Ratio * Voj',' + WeeklyPolicy  * Voj', '  + UNEMP Dispersion * Voj'};
    end;
    if Case ==4
    
       variables = {reshape(gamma_beta_ratio_monthly.*cj,l,1,n_stocks-1),...
          reshape(uncertainty(:,:,3).*cj,l,1,n_stocks-1),reshape(dispersion(:,:,5).*cj,l,1,n_stocks-1)};
        Names = { '+ Gamma-Beta-Ratio * Voj',' + MonthlyIndex * Voj', ' + CPI Dispersion * Voj'};
    end;
   
    
    if Case ==5
    
        variables = {reshape(gamma_beta_ratio_monthly.*cj,l,1,n_stocks-1),...
          reshape(uncertainty(:,:,6).*cj,l,1,n_stocks-1),reshape(dispersion(:,:,5).*cj,l,1,n_stocks-1)};
        Names = { '+ Gamma-Beta-Ratio * Voj','+ NVIX * Voj', ' + CPI Dispersion * Voj'};
    end;
    if Case ==6
    
         variables = {reshape(gamma_beta_ratio_monthly.*cj,l,1,n_stocks-1),...
          reshape(uncertainty(:,:,6).*cj,l,1,n_stocks-1),reshape(dispersion(:,:,6).*cj,l,1,n_stocks-1)};
        Names = { '+ Gamma-Beta-Ratio * Voj','+ NVIX * Voj', ' + CPI10 Dispersion * Voj'};
    end;
    
    if Case ==7
    
        variables = {reshape(gamma_beta_ratio_monthly.*cj,l,1,n_stocks-1),...
          reshape(uncertainty(:,:,2).*cj,l,1,n_stocks-1),reshape(dispersion(:,:,5).*cj,l,1,n_stocks-1)};
        Names = { '+ Gamma-Beta-Ratio * Voj','+ MonthlyPolicy * Voj', ' + CPI Dispersion * Voj'};
    end;
    if Case ==8
    
         variables = {reshape(gamma_beta_ratio_monthly.*cj,l,1,n_stocks-1),...
          reshape(uncertainty(:,:,4).*cj,l,1,n_stocks-1),reshape(dispersion(:,:,6).*cj,l,1,n_stocks-1)};
        Names = { '+ Gamma-Beta-Ratio * Voj','+ MonthlyPolicy * Voj', ' + CPI10 Dispersion * Voj'};
    end;
   if Case ==9
    
        variables = {reshape(gamma_beta_ratio_monthly.*cj,l,1,n_stocks-1),...
          reshape(uncertainty(:,:,3).*cj,l,1,n_stocks-1),reshape(dispersion(:,:,2).*cj,l,1,n_stocks-1)};
        Names = { '+ Gamma-Beta-Ratio * Voj','+ MonthlyIndex * Voj', ' + RGDP Growth Dispersion * Voj'};
    end;
 
    
    if FOMC
        variables = [{reshape(repmat(negative,1,n_stocks-1).*cj,l,1,n_stocks-1)},variables];
        Names = [{'+ Negative * Voj'}, Names];
    end;
        for k = 1:sg;
            for i = 1:2^(length(Names))
                if dummy_case;
                    RHS = [dummy_const,reshape(cj,l,1,n_stocks-1),dummy_vol,];
                    Name = 'Log-Volume Jump ~ FOCM + ISMM + ISMN + CC + Log-Volatility Jump + FOMC * Voj + ISMM * Voj + ISMN * Voj + CC * Voj ';
                else
                    RHS = reshape(cj,l,1,n_stocks-1);
                    Name = 'Log-Volume Jump ~ Log-Volatility Jump ';
                end;
                    VariableList = Name;
                signal = dec2bin(i-1);
                if length(signal)<length(Names)
                    signal = [repmat('0',1,length(Names)-length(signal)),signal];
                end;
                for j = 1:length(signal)
                    if str2num(signal(j))==1
                        RHS = horzcat(RHS,variables{j});
                        Name = strcat(Name,Names{j});
                    end;
                end;
                ModelNames{sg*(i-1)+k} = Name;
                [bhat_table(1:(size(RHS,2)),sg*(i-1)+k),R2_table(sg*(i-1)+k), sse_table(sg*(i-1)+k), NumObs(sg*(i-1)+k)] = panel_fixed_sse(reshape(vj(indexes_all{k},:),length(indexes_all{k}),1,n_stocks-1),RHS(indexes_all{k},:,:));  
            end;
        end;
        for j = length(Names):-1:1
            VariableList = strcat(VariableList,Names{j});
        end;
   