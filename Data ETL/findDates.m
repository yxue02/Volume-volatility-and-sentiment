function InDate = findDates(dates,Dates)
%% This function find the corresponding index in "Dates" for each "date", using the closest "Date" 
% that is earlier than "date"
InDate = NaN (size(dates));
k = 2;
i = 1;
% The first a few are missing values if the first Dates is already later
% than the first dates
while dates(i) <= Dates(k-1)
    i = i+1;
end;

% Fill in the values
while k<=length(Dates) 
    while i<=length(InDate) && dates(i) > Dates(k-1) && dates(i) <=Dates(k)
        InDate(i) = k-1;
        i = i+1;
    end
    k = k+1;
end
% the last few values take the largest Date(k) if it is later than Date(k)
% (No boundary from later)
k = k-1;
while i<=length(dates)
    if dates(i) > Dates(k)
        InDate(i) = k;
    end;
    i = i+1;
end;