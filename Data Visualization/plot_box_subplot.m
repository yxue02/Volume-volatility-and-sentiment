function plot_box_subplot(means, stds,sigs,c, xlabels,xlim_margin,has_legend,title_name)
%% xlim_margin is for larger right margin
%means : 2* n 
    %% Plot parameters
    set(0,'DefaultTextFontsize',10, ...
    'DefaultTextFontname','Times New Roman', ...
    'DefaultAxesFontname','Times New Roman')


    tsize = 12;
    lsize = 10;
    %mark size
    marksize = 5;
    markercolor = [0.6 0.6 0.6];

 if isempty(sigs)
    sigs = zeros(1,size(means,2));
end;
sigs(isnan(sigs))=0;
empha_text = {'\color{blue} ','\color{red} ','\color{black} ','\color{black} '};
empha = [0.25,0.25];    
NumCate = size(means,1);
numvar = size(means,2);
range = numvar*(NumCate+1);
if NumCate == 3;
    color_list = {'r','g','b'};
    llist = {'High Sentiment','Whole Sample','Low Sentiment'};
else
    color_list = {'r','b'};
    llist = {'High Sentiment','Low Sentiment'};
end;
xs = 0:range;
        y1 = means;
        y = NaN(length(xs),NumCate);
        for j = 1:NumCate;
            y(j:NumCate+1:range,j) = y1(j,:);
            y(j+1:NumCate+1:range,j) = y1(j,:);
        end;
        
        q = norminv((1+c)/2);
        if size(stds,3) ==1; % normal distribution
            y2 = NaN(2,size(means,1),size(means,2));
            y2(1,:,:) = means+ q*stds;
            y2(2,:,:) = means- q*stds;
        else; % quantile data
            y2(1,:,:) = stds(:,:,1);
            y2(2,:,:) = stds(:,:,2);
        end;
        tickLabels = cell(range+1,1);
        tickLabels(floor(NumCate/2):NumCate+1:range) = xlabels;
        
        plot(xs,y(:,1),'LineWidth',2,'Color',color_list{1});
        if size(y,2)>1
            hold on;
            for j = 2:size(y,2);
                plot(xs,y(:,j),'LineWidth',2,'Color',color_list{j});
            end;
        end;
        
        for i = 1:numvar
            if isnan(means(1,i))
                area([(NumCate+1)*i-NumCate-1,range+xlim_margin*NumCate],[abs(ymax),abs(ymax)],'FaceColor','w','EdgeColor','None')
                continue;
            end;
            % high sentiment, whole sample, low sentiment
            trans = empha(sigs(i)+1);
            for j = 1:NumCate;
                %fprintf('Start j= %d and i = %d.\n',j,i);
                if abs(y2(1,j,i))>abs(y2(2,j,i))
                    ymin = y2(2,j,i);
                    ymax = y2(1,j,i);
                else
                    ymin = y2(1,j,i);
                    ymax = y2(2,j,i);
                end;
                area([(NumCate+1)*i-(NumCate+1)+(j-1),(NumCate+1)*i-(NumCate+1)+j],[ymax,ymax],'FaceColor',color_list{j},'FaceAlpha',trans,'EdgeColor','None')
                if y2(2,j,i)*y2(1,j,i)>0
                    area([(NumCate+1)*i-(NumCate+1)+(j-1),(NumCate+1)*i-(NumCate+1)+j],[ymin,ymin],'FaceColor','w','EdgeColor','None')
                else
                    area([(NumCate+1)*i-(NumCate+1)+(j-1),(NumCate+1)*i-(NumCate+1)+j],[ymin,ymin],'FaceColor',color_list{j},'FaceAlpha',trans,'EdgeColor','None')
                end;
            end;
      
            
            % Just makes this plot more beautiful
            area([(NumCate+1)*i-1,(NumCate+1)*i],[y2(1,2,i),y2(1,2,i)],'FaceColor','w','EdgeColor','None')
        end;
        plot(0:(range+xlim_margin*NumCate),zeros(1,range+xlim_margin*NumCate+1),'LineWidth',0.5,'Color','k');
   
                ticklabels_new = cell(size(tickLabels));
              
                for i =1:length(sigs)
                    ticklabels_new{floor(NumCate/2)+(NumCate+1)*(i-1)} =...
                        [empha_text{2*(1-sigs(i))+1+(means(1,i)>means(2,i))} tickLabels{floor(NumCate/2)+(NumCate+1)*(i-1)}];
                end
                if numvar > 10;
                    xfontsize = 8;
                else;
                    xfontsize = 12;
                end;
                 set(gca,'XTick',1:range,'FontSize',xfontsize);
                set(gca, 'XTickLabel', ticklabels_new);
                if numvar>5 && length(ticklabels_new{1})>5
                    %xtickangle(30)
                end;
                %set(gca,'XtickL',TickerList(Tics));
                xticklabels(tickLabels);
                xlim([0,range+xlim_margin*NumCate])
                grid off
        box off;
             if has_legend ==1
                  l = legend(llist);
                set(l,'FontSize',8,  'Location','northeast');
                legend boxoff
        end;
                if nargin ==8;
                    if ischar(title_name)
                         t = title(strcat('Comparison of the', [' ',title_name],' when Sentiment is High and Low'));
                    end;
                    if iscell(title_name)
                        % t = title({strcat('Comparison of the', [' ',title_name{1}]),strcat(' when Sentiment is High and Low', [' ',title_name{2}])});
                         t = title(title_name);
                    end;
                         set(t, 'FontSize', 10, 'FontWeight','normal');
                end;
                
                 

