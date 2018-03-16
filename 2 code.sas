/*TIME SERIES*/
/*https://datahack.analyticsvidhya.com/contest/practice-problem-time-series-2/*/

/*data rg.train; set Train_SU63ISt; run;*/
/*data rg.test; set Test_0qrQsBZ; run;*/
/*data rg.sub; set Sample_Submission_QChS6c3; run;*/

/*1. import data*/
data train; format flag $10.; set rg.train; 
dp = datepart(Datetime); dpd = day(dp); dpm = month(dp); dpy = year(dp) + 1; dpc = year(dp) + 0;
tp = timepart(Datetime); tph = hour(tp); flag = "train"; run;
proc sort data=train (drop=dp tp); by Datetime; run;

data test; format flag $10.; set rg.test; 
dp = datepart(Datetime); dpd = day(dp); dpm = month(dp); dpy = year(dp); row_num = _n_;
tp = timepart(Datetime); tph = hour(tp); flag = "test"; run;
proc sort data=test (drop=dp tp); by Datetime; run;

/*2. master dataset*/
proc sql;
create table rg.df as 
select a.*, b.Count as Count
from test as a left join train as b
on a.dpd = b.dpd and a.dpm = b.dpm and a.dpy = b.dpy and a.tph = b.tph
order by Datetime;
quit;

data temp1; set train;  where datepart(Datetime) >= '10JAN2014'd and datepart(Datetime) <= '09DEC2014'd; run;
data temp2; set rg.df;  where datepart(Datetime) >= '10JAN2014'd and datepart(Datetime) <= '09DEC2014'd; run;

proc means data=temp1; var Count; run;
proc means data=temp2; var Count; run;

data rg.df; set rg.df; Count = (Count + 140.1) * 657.5 / 283.8; run;

/*3. submission*/
proc sort data=rg.df; by row_num; run;
data sub (keep = id Count); set rg.df; run;