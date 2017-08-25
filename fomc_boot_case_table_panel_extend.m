function [results, VariableList]= fomc_boot_case_table_panel_extend(EstimationProcedure,output,nboot,Case,DID)
% Acknowledgement: this file is modifies from Dr. Jia Li's
% nboot = 10;
% EstimationProcedure = @fomc_reg1;

% Compute the point estimates
[bhat,ModelNames,VariableList,R2, sse,NumObs]= EstimationProcedure(output,Case,DID);
[nr,nc] = size(bhat);
[d1,d2,d3] = size(output.spot);
bhat_boot = zeros(nr,nc,nboot);


% Compute the estimates in the bootstrap samples
parfor i = 1:nboot
%     if mod(i,10) == 0;
%         fprintf('Conducting the %d ''th bootstrap.\n',i);
%     end;
    output_boot = fomc_eventboot_panel(output);
    bhat_boot(:,:,i) = EstimationProcedure(output_boot,Case,DID);
end


% Compute some user-friendly summary.
    
se = zeros(nr,nc);
ci95 = zeros(nr,2*nc);
ci90 = zeros(nr,2*nc);
for i = 1:nr
    for j = 1:nc
        % The point estimate
        b = bhat(i,j); 
        % The estimate of the bootstrap sample
        tmpboot = bhat_boot(i,j,:);
        tmpboot = tmpboot(:);
        % Compute standard error
        se(i,j) = std(tmpboot(~isnan(tmpboot)) - b);
        % Compute 95 CIs using "basic bootstrap"
        b_sym = 2 * b - tmpboot;
        ci95(i,[2*j-1,2*j]) = prctile(b_sym,[2.5,97.5]);
        ci90(i,[2*j-1,2*j]) = prctile(b_sym,[5,95]);
    end
end
    
                                                                            % Output
                                                                            results.bhat = bhat;
                                                                            results.bhat_boot = bhat_boot;
                                                                            results.se = se;
                                                                            results.ci95 = ci95;
                                                                            results.ci90=ci90;
                                                                            results.ModelNames = ModelNames;
                                                                            results.R2=R2;
                                                                            results.sse=sse;
                                                                            results.NumObs = NumObs;
     
                                                                         
                                                                          
    

