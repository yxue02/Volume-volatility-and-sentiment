function print_table_latex_nosub(VariableNames,tmptable,Sig_table, R2, F, senti_type,params)
index_r = params.index_r;
nc_in = params.nc_in;
StringList={'  &  %6.3f',' & %6.3f*','&  %6.3f**'};
sub = params.sub>0;
pt = params.pt>0;
start_n = params.start_n-pt;
panel_names = {'High Sentiment Periods', 'Whole Sample', 'Low Sentiment Periods', 'Difference between High and Low Sentiment Periods'};
% \begin{frame}
% \begin{table}[t]
% \centering
% {\tiny \ 
% \resizebox{1.0\textwidth}{!}{\begin{threeparttable}
% 					\caption{Volume-volatility elasticity estimates around Consumer Confidence}
% 					\label{table:fomc_neg2}
% 					\begin{tabular}{lllllllll} \hline\hline
% 						\multicolumn{6}{l}{\em{Baseline estimates:}} \\	


flag = 0; % Not print cross-sectional yet
flag_d = 0; % Not print disagreement yet
if params.head>0
    print_table_head_tail(1,senti_type,params)
end;

if pt 
     fprintf(' \\multicolumn{%d}{c}{\\em{%s}} \\\\ \\\\',nc_in+start_n, panel_names{senti_type});
     gap = 1;
else;
    gap = 2;
end;
fprintf('						\\multicolumn{%d}{l}{\\em{Baseline estimates:}} \\\\\n',nc_in-1);

     for k = 1:length(index_r);
        j = index_r(k);
        
        if mod(j,2)==1;
            m=floor((j+1)/2);
            m2=floor((index_r(min([k+2,length(index_r)]))+1)/2);
          row_name = VariableNames{m};
            %Construct strings that indicates significance;
            string1='%40s';
            for i=1:nc_in;
                if senti_type ==5 && mod(i,nc_in/3)==1 && i~=1
                    symat = '& ';
                else
                    symat = ' ';
                end;
                if isnan(tmptable(j,i));
                    string1 = strcat(string1, symat,' &');
                else   
                    string1=strcat(string1,symat,['  ',StringList{Sig_table(m,i)+1}]);
                end;
           
            end;
            string1=strcat(string1,'\\\\\n');
            %& Constant ($\beta_0$)& 0.328**     & 0.335**     & 0.323**     & 0.290**     & 0.224**     & 0.411**     & 0.217**     \\
        fprintf(string1,row_name,tmptable(j,~isnan(tmptable(j,:))));
        else
            string2 = '%40s';
            for i=1:nc_in;
                if senti_type ==5 && mod(i,nc_in/3)==1 && i~=1
                    symat = '& &';
                else
                    symat = '& ';
                end;
                if isnan(tmptable(j,i));
                    string2 = strcat(string2, symat);
                else   
                    string2=strcat(string2, symat,  '{(}%3.3f{)}');
                end;
           
            end;
            string2=strcat(string2,'\\\\\n');
%					 &                     & {[}0.015{]} & {[}0.015{]} & {[}0.015{]} & {[}0.018{]} & {[}0.029{]} & {[}0.050{]} & {[}0.031{]} \\

            fprintf(string2,repmat('&',1,gap),tmptable(j,~isnan(tmptable(j,:))));
            if strfind(row_name,'Elasticity')>0
                fprintf([repmat(' & ',1,nc_in+gap),' \\\\\n ']);
                %& \\multicolumn{8}{l}{\\em{Estimates for explanatory variables in elasticity} ($\\pmb{\\beta}_1$):} \\\\
                fprintf(' \\multicolumn{%d}{l}{\\em{Estimates for explanatory variables in elasticity} ($\\pmb{b}_1$):} \\\\ \n',nc_in);
            end	;
            if m2 <= length(VariableNames) && ~isempty(strfind(VariableNames{m2},'FOMC'))
                fprintf([repmat(' & ',1,nc_in+gap),' \\\\\n ']);
                % & \\multicolumn{8}{l}{\\em{Estimates for explanatory variables in elasticity} ($\\pmb{\\beta}_1$):} \\\\
                fprintf('& \\multicolumn{%d}{l}{\\em{News-category dummy variables:}} \\\\ \n',nc_in);
            end	;
             if sub && flag_d ==0 && m2 <= length(VariableNames) && ~isempty(strfind(lower(VariableNames{m2}),'dispersion'))  && isempty(strfind(lower(VariableNames{m2}),'analyst'))
                 fprintf([repmat(' & ',1,nc_in+gap),' \\\\\n ']);
                    flag_d = 1;
                    % & \\multicolumn{8}{l}{\\em{Estimates for explanatory variables in elasticity} ($\\pmb{\\beta}_1$):} \\\\
                    fprintf('& \\multicolumn{%d}{l}{\\em{Disagreement measures:}} \\\\ \n',nc_in);
             end;
             if  sub && m2 <= length(VariableNames) && ~isempty(strfind(lower(VariableNames{m2}),'analyst')>0)
                    fprintf([repmat(' & ',1,nc_in+gap),' \\\\\n ']);
                    % & \\multicolumn{8}{l}{\\em{Estimates for explanatory variables in elasticity} ($\\pmb{\\beta}_1$):} \\\\
                    fprintf('& \\multicolumn{%d}{l}{\\em{Cross-sectional explanatory variables:}} \\\\ \n',nc_in);
                    flag = 1;    
             else
                 if sub && flag ==0 && m2 <= length(VariableNames) && ~isempty(strfind(lower(VariableNames{m2}),'beta'))>0
                    fprintf([repmat(' & ',1,nc_in+gap),' \\\\\n ']);
                    % & \\multicolumn{8}{l}{\\em{Estimates for explanatory variables in elasticity} ($\\pmb{\\beta}_1$):} \\\\
                    fprintf('& \\multicolumn{%d}{l}{\\em{Cross-sectional explanatory variables:}} \\\\ \n',nc_in);        
                    flag = 1;
                 end;
             end;
            
           end	;
        end;
        
        
   if senti_type ~=4 ;
    %\\cline{3-9}

     string3=strcat('%40s'); 
     
     for i = 1:nc_in;
          if senti_type ==5 && mod(i,nc_in/3)==1 && i~=1
                symat = '& &';
            else
                symat = '& ';
          end;
          if senti_type == 5 && i> nc_in/3*2
              fmat = '  ';
          else
              fmat = '  %6.3f';
          end;
            string3 = strcat(string3, symat,fmat);
     end;
         string3 = strcat(string3,' \\\\ ');
         string4 = strcat(string3, '  \\hline \\\\');
         fprintf('\\cline{%d-%d} \\\\',2+gap, nc_in+start_n);
    %& $R^2$                 & 0.105       & 0.108       & 0.106       & 0.107       & 0.107       & 0.106       & 0.110               \\\\ \\hline\\hline
    if senti_type ==5;   
        fprintf(string3,strcat(repmat('&',1,gap),' $ R^2 $'),R2(1:nc_in/3*2));  
        fprintf(string4,strcat(repmat('&',1,gap),' $ \text{p value} $'),F(1:nc_in/3*2));  
    else;
        fprintf(string3,strcat(repmat('&',1,gap),' $ R^2 $'),R2(1:nc_in)); 
        fprintf(string4,strcat(repmat('&',1,gap),' $ \text{p value} $'),F(1:nc_in)); 
    end;
   
   end;

if params.tail>0
   
    print_table_head_tail(0,senti_type,params)
end;
