function fomc_print_table_sd2_latex_all4(results,VariableList,senti_type, params)
% Number of cross-sectional variables
title_c = params.title_c;
label_c = params.label_c;
column_in = params.column_in;
if params.pt>0
    gap = 1;
else;
    gap = 2;
end;
headmake = repmat('&',1,gap);
if strfind(VariableList,'Analysts')
    num_cross = 2;
else
    num_cross = 1;
end;



% For tables


VariableNames=parsing(VariableList);
keys=VariableNames;
values=num2cell(1:length(VariableNames));
VariableMap = containers.Map(keys, values);


modelnames = results.ModelNames;
R2=results.R2(~isnan(results.R2));
if  isfield(results,'F')
    F=results.F(~isnan(results.R2(1:length(results.F))));
else
    F=zeros(size(R2));
end;
[nr,nc] = size(results.bhat);
column_in = column_in(column_in<=nc);
%find effective columns;
nc_effective=(sum(~isnan(results.bhat),1)>0);
nc_effectiveindex=find(nc_effective);
nc_sum=sum(nc_effective);
tmptable=NaN(2*length(VariableNames),nc_sum);
Sig_table=NaN(length(VariableNames),nc_sum);
for f = 1:nc_sum;   
    i=nc_effectiveindex(f);
    tmpbhat = results.bhat(:,i);
    tmpindex = ~isnan(tmpbhat);
    if sum(tmpindex) == 0;
        continue;
    end
    variables = parsing(modelnames{i});
    indexintable=NaN(length(variables),1);
    for j=1:length(variables);
            assert(isKey(VariableMap,variables{j}),'Variable %d for the Regression %d does not exist',j,f);
            indexintable(j)=VariableMap(variables{j});
    end;
    tmptable(2*indexintable-1,f) = tmpbhat(tmpindex);
    se=results.se(:,i);
     tmptable(2*indexintable,f)=se(tmpindex) ;
%     ci95=results.ci95(:,[2*i-1,2*i]) ;
%     sig95=tmpbhat(tmpindex).^2.*ci95(tmpindex,1).*ci95(tmpindex,2)>0; 
%     ci90=results.ci90(:,[2*i-1,2*i]) ;
%     sig90=tmpbhat(tmpindex).^2.*ci90(tmpindex,1).*ci90(tmpindex,2)>0; 
    sig99 = abs(tmpbhat(tmpindex)./se(tmpindex))>norminv(0.995,0,1);
    sig95 = abs(tmpbhat(tmpindex)./se(tmpindex))>norminv(0.975,0,1);
    Sig_table(indexintable,f)=sig99+sig95; %=2 if significant at 95% and =1 if significant at 90%
    Sig_table(isnan(Sig_table))=0;
end;


label_p = strsplit(label_c,'_');
event_notes = 'FOMC announcements';
if strcmpi(label_p{2},'dummy');
    event_notes = 'all announcements';
    if strcmpi(label_p{1},'all') | strcmpi(label_p{1},'industry');
        if strcmpi(label_p{1},'all')
            
           textwidth = 0.8;
        else
            textwidth = 0.9;
        end;
       
            index_r = [9,10,19:size(tmptable,1)];
            
       
      
    else
        textwidth = 0.6;
        index_r = [1,2,11,12,21:size(tmptable,1)];
    end;
else
    index_r = [1:size(tmptable,1)];
    textwidth = 1;

    %% Need to change this when we add more crosssectional variables. Put negative in front of crosssectional
    if strcmpi(label_p{1},'all') | strcmp(label_p{1},'industry');
        textwidth = 1;
        last2 = index_r(end-1:end);
        index_r(end-2*num_cross+1:end) = index_r(end-2*num_cross-1:end-2);
        index_r(end-2*num_cross-1:end-2*num_cross) =last2 ;
    end;
end;

if params.pt
    textwidth = 1;
end;
% Put negative in front of crosssectional measures

tmptable = tmptable(:,column_in);
Sig_table = Sig_table(:,column_in);
R2 = R2(:,column_in);
F = F(:,column_in);
nc_in = size(tmptable,2);



title_c;
for i = 1:length(VariableNames);
    if strfind(VariableNames{i},'*')>0;
        nana = strsplit(VariableNames{i},'*');
        VariableNames{i} = [headmake,nana{1}];
        if strfind(VariableNames{i},'INDPROD');
            VariableNames{i} = [VariableNames{i}, 'Dispersion'];
        end;
    else
        if strfind(lower(VariableNames{i}),lower('Jump'))>0
         VariableNames{i} = [headmake,' Elasticity ($b_0$)'];
        else
            if strfind(lower(VariableNames{i}),lower('Const'))>0
                VariableNames{i} = [headmake,' Constant ($a_0$)'];
            end;
        end;
    end;
end;


if senti_type ==5;
    start_n = 5;
else;
    start_n = 3;
end;

params.start_n = start_n;
params.index_r = index_r;
params.event_notes = event_notes;
params.nc_in = nc_in;
%% print table
print_table_latex_nosub(VariableNames,tmptable,Sig_table, R2, F, senti_type,params)
fclose all;

function output = parsing(modelname)
p1 = strsplit(modelname,'+');
p2 = strsplit(p1{1},'~');
if ~isempty(p1)
    output = [ strtrim(p2(2))  strtrim(p1(2:end))];
else
    output =  strtrim(p2(2));
end

