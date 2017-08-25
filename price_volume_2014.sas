/******************************************************************************************/
/* Acknowledgement: Part of this file is modified from Yuxing Yan's sample code from WRDS
/* It retrieves the one minute stock prices and volumes from year 2012 to 2014 (dates can be changed at the end of the file) */
/******************************************************************************************/

* Input stock list here;
%let stocks='AAPL' 'AXP' 'BA' 'CAT' 'CSCO' 'CVX' 'DD' 'DIS' 'GE' 'GS' 'HD' 'IBM' 'INTC' 'JNJ' 'JPM' 'KO' 'MCD' 'MMM' 'MRK' 'MSFT' 'NKE' 'PFE' 'PG' 'TRV' 'UNH' 'UTX' 'V' 'VZ' 'WMT' 'XOM' 'SPY';

libname mycurr '.';

data user_out_set;
attrib symbol length = $10. label = 'Ticker';
attrib date informat = 8. label = 'Date';
attrib time informat = 4. label = 'Time';
attrib price_m informat = 6.3 label='Median Price'
       price_v informat = 6.3 label='Volume Weighted Price';
attrib Volume_A informat = 10.;
attrib Volume_B informat = 10.
	   Volume_C informat = 10.
	   Volume_D informat = 10.
	   Volume_I informat = 10.
       Volume_J informat = 10.
       Volume_K informat = 10.
	   Volume_M informat = 10.
	   Volume_N informat = 10.
	   Volume_P informat = 10.
	   Volume_T informat = 10.
	   Volume_Q informat = 10.
	   Volume_W informat = 10.
	   Volume_X informat = 10.
	   Volume_Y informat = 10.
	   Volume_Z informat = 10.;
attrib NumTrade_A informat = 10.;
attrib NumTrade_B informat = 10.
	   NumTrade_C informat = 10.
	   NumTrade_D informat = 10.
	   NumTrade_I informat = 10.
       NumTrade_J informat = 10.
       NumTrade_K informat = 10.
	   NumTrade_M informat = 10.
	   NumTrade_N informat = 10.
	   NumTrade_P informat = 10.
	   NumTrade_T informat = 10.
	   NumTrade_Q informat = 10.
	   NumTrade_W informat = 10.
	   NumTrade_X informat = 10.
	   NumTrade_Y informat = 10.
	   NumTrade_Z informat = 10.
	   missing informat = 2. label = 'Missing data';
run;


data discard;
attrib symbol length = $10. label = 'Ticker';
attrib date informat = 8. label = 'Date';
attrib time informat = 4. label = 'Time';
attrib EX informat = $1. label = 'Exchange';
attrib price informat = 6.3 label='Price';
attrib Size informat = 10. label = 'Transaction size';
attrib cut informat = 4.5 label='shreshold'
       dev informat = 4.5 label='deviation'
	   meandev informat = 4.5 label='MA deviation'
	   meandev_adj informat = 4.5 label='MA deviation (self excluded)'
	   meanprice informat = 4.5 label='MA price'
	   meanprice_adj informat = 4.5 label='MA price (self excluded)';
run;

* Initialize time table;
data timetable;
attrib time informat = 4.;
do i = 930 to 1600;
   time=i; 
   remainder=mod(time,100);
   if remainder<60 then output;
end;
keep time;
run;
%macro w_taq_analyze(fdate,ldate);
%let fdated = %sysfunc(InputN(&fdate,yymmdd8.));
%let ldated = %sysfunc(InputN(&ldate,yymmdd8.));
%do date = &fdated %to &ldated;
	%let ndate= %sysfunc(PutN(&date,yymmddn8));
	%let wkday= %sysfunc(weekday(&date));
	%let dct = taq.ct_&ndate. ; /* TRADES */
	%let dcq = taq.cq_&ndate. ; /* QUOTES */
	%if %index(2 3 4 5 6,&wkday)>0
	%then %if %sysfunc(exist(&dct))
	%then
	%do;


		/********************************************************************* */
		/* Step 1: Input area                                                  */
		/********************************************************************* */
		%let cqtime1="9:30:00"t;    * First Quote Time;  
		%let time2="16:00:00"t;     * Ending time;  
		/* Trade Variables, from CT Datasets*/
		%let vars_in_ct=symbol date time price size cond corr ex;  
		%let interval_seconds =60;    * interval is 15*60 seconds (15 minutes);
		%let rwindow=50;
		%let generous=0;
		/* Home Library Name to save the final SAS dataset */
		libname myh '.';   
		 
		/* Select Period */
		

		%let period=&ndate.; options msglevel=i fullstimer;
		/* Specify Name of the output SAS dataset */
		%let out_ds=Lee_Ready_&period;
		 
		/********************************************************************* */
		/* Step 2: Get Trade Data with Filters, with Weighted Average Price    */
		/********************************************************************* */

		Title "Trade for period=&period";
		data trades(drop=corr cond);     
		     set taq.ct_&period(keep=&vars_in_ct);     
             *set Prices(keep=&vars_in_ct);  
		     where symbol in (&stocks) and time between &cqtime1 and &time2+&interval_seconds
		     and price>0 and size>0 
             and corr=0
			 /*and date=mdy(12,16,2013);*/
			 and cond not in ( "O" "Z" "B" "T" "L" "G" "W" "J" "K" ); 

		run; 

		data tradesp;
		set trades;
		where     EX in ( "A" "B" "C" "N" "P" "T" "Q" "X" "W" );
		run;

		/*********************************************************************************************************************/
		/*                 We need to give the prices at the same time different labels to use proc expand                   */
        /*********************************************************************************************************************/
data trademod;
set tradesp;
by symbol date time;
if first.time then lab=1;
else lab+1;
time1=time+1/1000000*lab;
drop lab;
run; 

/**********************************************************************************/
/*                     Calculate mean deviation from median                       */
/*        using 50 as the length of rolling window                                */
/**********************************************************************************/
data tradetest;
		set trademod;
		by symbol date time;
		if first.symbol and first.date;
		run;
%macro checknobs;
data _null_;
if nobs=0 then do;
call symput("obscount","0");
end;
else call symput("obscount",put(nobs,best12.));
stop;
set tradetest nobs=nobs;
run;
%if &obscount >0 %then %do;

proc sql noprint;
   create table trademod11 as
   select *, count(*) as NoB
   from trademod
   group by symbol
   order by symbol, date, time, time1;
quit;

proc expand DATA = trademod11 OUT = trademod1;
ID time1; 
by symbol;
Convert price = meanprice / METHOD = none TRANSFORMOUT = (NOMISS CMOVAVE &rwindow.);
run;

data trademod1;
set trademod1;
by symbol;
if first.symbol then Nul=1;
else Nul+1;
if Nul<=floor(&rwindow./2) then
meanprice_adj=(meanprice*(Nul+floor(&rwindow./2))-price)/(Nul+floor(&rwindow./2)-1);
else if NoB - Nul <= floor(&rwindow./2) then
meanprice_adj=(meanprice*(NoB-Nul+floor((&rwindow.+1)/2))-price)/(NoB-Nul+floor((&rwindow.+1)/2)-1);
else
meanprice_adj= (meanprice*&rwindow.-price)/(&rwindow-1);
dev=abs(price-meanprice_adj);
run;




*get the moving average of midpoint;
proc expand DATA = trademod1 OUT = trademod2;
ID time1; 
by symbol;
Convert dev=meandev / METHOD = none TRANSFORMOUT = (NOMISS cmovave &rwindow.);
run;

/**************************************************************************************************************************************/
/* Some cut can be 0 if prices keep stable for a long time, so we need to set generous at a value so that the price will not be killed*/
/**************************************************************************************************************************************/

data trademod2;
set trademod2;
by symbol;
if first.symbol then Nul=1;
else Nul+1;
if Nul<=floor(&rwindow./2) then
meandev_adj=(meandev*(Nul+floor(&rwindow./2))-dev)/(Nul+floor(&rwindow./2)-1);
else if NoB - Nul <= floor(&rwindow./2) then
meandev_adj=(meandev*(NoB-Nul+floor((&rwindow.+1)/2))-dev)/(NoB-Nul+floor((&rwindow.+1)/2)-1);
else
meandev_adj= (meandev*&rwindow.-dev)/(&rwindow-1);
cut=10*meandev_adj+&generous.;
if cut>10 then cut=10; /*does not make sense if cut is too large*/
drop Nul NoB;
run;
*The moving average needs to exclude itself;

proc sql; drop table trademod; quit; 


data screened;
set trademod2;
if dev>cut;
time1=hour(time)*100+minute(time);
date1=year(date)*10000+100*month(date)+day(date);
drop time date;
rename time1=time date1=date;
run;

data trademod1;
set trademod2;
if dev<=cut;
keep symbol date time price size;
run;
data makeup;
dd=1;
run;

data screened;
set screened makeup;
run;

proc append base=discard data=screened force; run;


		/********************************************************************* */
		/* Step 3: Get Volume Weighted Average Prices for Simultaneous Trades  */
		/*         (See Note 1 below )                                         */
		/********************************************************************* */
		 proc sql noprint;
		  create table trade1_1 as
		    select distinct SYMBOL,	DATE,  TIME, 
		    (SUM(price*size)/sum(size)) AS price_v
			from trademod1
			group by SYMBOL, DATE, time 
			order by SYMBOL, DATE, TIME
		    ;
		quit;
    proc sort data=trademod1;
	by symbol date time;
	run;
proc summary data=trademod1 nway;
        var price;
        class symbol date time;
        output out=trade1_2 (drop =_:) 
           median=price_m;
     run; 

data trade1;
merge trade1_1(in=a) trade1_2(in=b);
by symbol date time;
if a and b;
run;
/*Volume uses the full dataset*/
		

		
	/********************************************************************* */
		/* Step 4: Set the itime for all trades                            */
		/*         (See Note 1 below )                                         */
		/********************************************************************* */
		data trade2;  
		set trades(keep=symbol date time size ex);
     by symbol date time;
     retain itime rtime; *Carry time and price values forward;
        format itime rtime time12.;
     if first.symbol=1 or first.date=1 then do;
        */Initialize time and price when new symbol or date starts;*/;

        rtime=time;
        itime= &cqtime1;
     end;
     if time >= itime then do; /*Interval reached;*/
           *output; /*rtime and iprice hold the last observation values;*/
           itime = itime + &interval_seconds;
           do while(time >= itime); /*need to fill in all time intervals;*/
               *output;
               itime = itime + &interval_seconds;
           end;
    end;
    rtime=time;
    keep symbol date itime  size ex;
	rename itime=time;
run;

proc sql noprint;
  create table Volume as
    select distinct SYMBOL,	DATE,  TIME, ex, sum(SIZE) as volume, count(size) as NumTrade
	from trade2
	group by SYMBOL, DATE, time, ex 
	order by SYMBOL, DATE, TIME, ex
    ;
quit;

proc transpose data=volume out=volume1 prefix=Volume_;
var volume ;
id ex;
by symbol date time;
run;

proc transpose data=volume out=numtrade1 prefix=NumTrade_;
var NumTrade ;
id ex;
by symbol date time;
run;

data volumeandnumtrade;
merge volume1(in=a) numtrade1(in=b);
by symbol date time;
if a or b;
drop _name_;
run;



		/********************************************************************* */
		/* Step 5: Get Price                                                   */
		/*         (See Note 1 below )                                         */
		/********************************************************************* */

	 
*Calculate Price: The last price before each minute except for the beginning of the day which uses the first price available; 
data Price;
set trade1(keep=symbol date time price_m price_v);
     by symbol date time;
     retain itime rtime iprice_m iprice_v; *Carry time and price values forward;
        format itime rtime time12.;
     if first.symbol=1 or first.date=1 then do;
        */Initialize time and price when new symbol or date starts;*/;

        rtime=time;
        iprice_m=price_m;
		iprice_v=price_v;
        itime= &cqtime1;
     end;
     if time >= itime then do; /*Interval reached;*/
           output; /*rtime and iprice hold the last observation values;*/
           itime = itime + &interval_seconds;
           do while(time >= itime); /*need to fill in all time intervals;*/
               output;
               itime = itime + &interval_seconds;
           end;
    end;
    rtime=time;
    iprice_m=price_m;
	iprice_v=price_v;
    keep symbol date itime iprice_m iprice_v;
        rename iprice_m=price_m iprice_v=price_v itime=time;
run;
	/********************************************************************* */
		/* Step 5: Merge Price and Volume and Output                                      */
		/*         (See Note 1 below )                                         */

/********************************************************************* */
*Change time format;
data &out_ds;
merge Price(in=a) Volumeandnumtrade(in=b);
by symbol date time;
if a;
time1=hour(time)*100+minute(time);
drop time;
rename time1=time;
run;

data date;
set &out_ds;
by SYMBOL date;
if first.SYMBOL and first.date;
keep SYMBOL date;
run;

proc sql;
  create table timetable1 as
  select * 
  from date,timetable
  order by SYMBOL, date, time;
quit;
*Change the table to a time consecutive one;

data &out_ds;
merge &out_ds timetable1(in=b);
by symbol date time;
if b;
run;

*Make up for missing values: price retains while volume set to 0;
*data &out_ds;
data &out_ds;
set &out_ds;
by SYMBOL date time;
date1=year(date)*10000+100*month(date)+day(date);
if first.SYMBOL and first.date then do;
retain price_v1 price_m1;
end;
if price_m~=. then do ;
price_m1=price_m;
price_v1=price_v;
missing=0;
end; 
else do;
price_m=price_m1;
price_v=price_v1;
missing=1;
end;
drop price_m1 price_v1 date;
rename date1=date;
run;

* It should be unnecessary to make up for the prices at the beginning of each day;

/*
proc sort data=&out_ds;
by date descending time;
run;

data &out_ds;
set &out_ds;
retain price_v1 price_m1;
if price_m~=. then do ;
price_m1=price_m;
price_v1=price_v;
end; 
else do;
price_m=price_m1;
price_v=price_v1;
drop price_m1 price_v1;
end;
run;

proc sort data=&out_ds;
by date time;
run;
*/

%end;
%mend checknobs;
%checknobs

%if %sysfunc(exist(&out_ds))%then
%do;
proc append base=user_out_set data=&out_ds force; run;

*proc append base=user_out_set data=&out_ds; run;

 proc sql; drop table &out_ds; quit; 
 %end
		;
	%end;
%end;
data user_out_set;
set user_out_set;
if time~=.;
run;

*Replacing missing volumes to 0;


proc export data=user_out_set
   outfile='All_Volt_2014.csv
   dbms=csv
   replace;
run;

/*
data mycurr.All_volt_2014;
set user_out_set;
run;
*/

* Data that have been screened
data discardnew;
set discard;
if price~=.;
run;

proc export data=discardnew
   outfile='All_discardt_2014.csv'
   dbms=csv
   replace;
run;

/*
data mycurr.All_screened_2014;
set discardnew;
run;
*/
 proc sql; drop table user_out_set; quit; 
%mend;
%w_taq_analyze(20120101,20141231);
/* END */
/* END */


