/*BIG MART SALES*/
/*https://datahack.analyticsvidhya.com/contest/practice-problem-big-mart-sales-iii/*/

/*data rg.train; set Train_UWu5bXk; run;*/
/*data rg.test; set Test_u94Q5KV; run;*/
/*data rg.sub; set SampleSubmission_TmnO39y; run;*/

/*1. data prep*/
data train; format flag $10.; set rg.train; flag = "train"; run;
data test; format flag $10.; set rg.test; flag = "test"; run; 
data sub; set rg.sub (drop=Item_Outlet_Sales); row_num = _n_; run;

/*2. master dataset*/
data rg.df; set train test; run;
%macro rg_bin (var);
proc sql; select &var., avg(Item_Outlet_Sales) as avg_sales
from rg.df where flag = "train" group by &var.; quit; 
%mend;

data rg.df (drop = Item_Weight Item_Fat_Content Item_Visibility Item_Type Item_MRP);
format IW best32.;
format IFC $10.;
format IT $100.;
format IM best32.;
set rg.df;
IW = round((Item_Weight / 2),1) * 2;
if Item_Fat_Content in ('LF','Low Fat','low fat') then IFC = "LF";
else if Item_Fat_Content in ('Regular','reg') then IFC = "REG";
else IFC = "Others";
IT = compress(upcase(Item_Type));
IM = round((Item_MRP / 10),1) * 10;
run;

data rg.df (drop = Outlet_Establishment_Year Outlet_Size Outlet_Location_Type Outlet_Type);
format OS $10.;
format OL $10.;
format OT $100.;
set rg.df;
OS = compress(upcase(Outlet_Size));
OL = compress(upcase(Outlet_Location_Type));
OT = compress(upcase(Outlet_Type));
run;

%rg_bin(IM);

/*3. cohorts*/
data train; set rg.df; where flag = "train"; run;
data test (drop=Item_Outlet_Sales); set rg.df; where flag = "test"; run;

proc sql;
create table cohorts as 
select IW, IFC, IT, IM, OS, OL, OT, avg(Item_Outlet_Sales) as cohort_Sales
from train
group by IW, IFC, IT, IM, OS, OL, OT;

create table Item as 
select IW, IFC, IT, IM, avg(Item_Outlet_Sales) as item_Sales
from train
group by IW, IFC, IT, IM;

create table Item_Price as 
select IFC, IT, avg(Item_Outlet_Sales) as item_Sales_Price, avg(IM) as avg_IM
from train
group by IFC, IT;

create table Outlet as 
select OS, OL, OT, avg(Item_Outlet_Sales) as outlet_Sales
from train
group by OS, OL, OT;

create table Item_Outlet as
select "test" as flag, avg(Item_Outlet_Sales) as avg_Sales
from train;
quit;

/*4. prediction*/
proc sql;
create table test as 
select a.*, b.cohort_Sales
from test as a left join cohorts as b
on a.IW = b.IW and a.IFC = b.IFC and a.IT = b.IT and a.IM = b.IM and a.OS = b.OS and a.OL = b.OL and a.OT = b.OT;

create table test as 
select a.*, b.item_Sales
from test as a left join Item as b
on a.IW = b.IW and a.IFC = b.IFC and a.IT = b.IT and a.IM = b.IM;

create table test as 
select a.*, b.item_Sales_Price, b.avg_IM
from test as a left join Item_Price as b
on a.IFC = b.IFC and a.IT = b.IT;

create table test as 
select a.*, b.outlet_Sales
from test as a left join Outlet as b
on a.OS = b.OS and a.OL = b.OL and a.OT = b.OT;

create table test as 
select a.*, b.avg_Sales
from test as a left join Item_Outlet as b
on a.flag = b.flag;
quit;

data test; set test;
if cohort_Sales ^= . then Item_Outlet_Sales = cohort_Sales;
run;

data test; set test;
if Item_Outlet_Sales = . then Item_Outlet_Sales = item_Sales * (outlet_Sales / avg_Sales);
run;

data test; set test;
if Item_Outlet_Sales = . then Item_Outlet_Sales = item_Sales_Price * (IM / avg_IM) * (outlet_Sales / avg_Sales);
run;

/*5. submission*/
proc sql;
create table sub as 
select a.*, b.Item_Outlet_Sales
from sub as a left join test as b
on a.Item_Identifier = b.Item_Identifier and a.Outlet_Identifier = b.Outlet_Identifier
order by row_num;
quit;

data sub; set sub (drop=row_num); run;