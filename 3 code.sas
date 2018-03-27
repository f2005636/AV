libname rg '/ccr/ccar_secured/rg83892/in2016ye';

/*BIG MART SALES*/
/*https://datahack.analyticsvidhya.com/contest/practice-problem-big-mart-sales-iii/*/

/*data rg.train; set train_u6lujuX_CVtuZ9i; run;*/
/*data rg.test; set test_Y3wMUE5_7gLdaTN; run;*/
/*data rg.sub; set SAMPLE_SUBMISSION_ZAUTL8O_F_0000; run;*/

/*1. data prep*/
data train (drop=Loan_Status); format flag $10.; set rg.train; flag = "train"; 
if compress(upcase(Loan_Status)) = "Y" then target = 1; else target = 0; run;
data test; format flag $10.; set rg.test; flag = "test"; run; 
data sub; set rg.sub (drop=Loan_Status); row_num = _n_; run;

/*2. master dataset*/
data rg.df; set train test; run;
%macro rg_bin (var);
proc sql; select &var., avg(target) as avg_target, count(target) as cnt
from rg.df where flag = "train" group by &var.; quit; 
%mend;

data rg.df (drop = Gender Married Dependents Education Self_Employed
ApplicantIncome CoapplicantIncome LoanAmount Loan_Amount_Term Credit_History Property_Area);
format G $10.; format M $10.; format D $10.; format E $10.;
format C $10.; format L $20.; format H $10.; format P $10.;

set rg.df;
if compress(Gender) = "Male" then G = "b. M"; else G = "a. F";

if compress(Married) = "No" then M = "a. N"; else M = "b. Y";

if Dependents = 2 then D = "c. 2"; 
else if Dependents = 0 then D = "b. 0";
else D = "a. 1";

if compress(Education) = "Graduate" then E = "b. Y"; else E = "a. N";

if CoapplicantIncome > 0 then C = "b. Y"; else C = "a. N";

if LoanAmount = . then LoanAmount = 1000;
if LoanAmount <= 200 then L = "b. 0-200";
else L = "a. 200-inf";

if Credit_History = 0 then H = "a. N"; else H = "b. Y";

if compress(Property_Area) = "Semiurban" then P = "b. SU"; else P = "a. RU";
run;

%rg_bin(L);

/*3. reg*/
data train; set rg.df; where flag = "train"; run;
data test (drop=target); set rg.df; where flag = "test"; run;

proc logistic data=train desc outmodel=estimates;
class M E L H P/param=glm;
model target = M E L H P/link=logit lackfit;
output out=logit_model p=prob;
run;

/*4. prediction*/
proc logistic inmodel = estimates; score data = test out= scored_data (rename=(p_1 = prob)); run;
data scored_data; set scored_data; if prob > 0.5 then Loan_Status = "Y"; else Loan_Status = "N"; run;

/*5. submission*/
proc sql;
create table sub as 
select a.*, b.Loan_Status
from sub as a left join scored_data as b
on a.Loan_ID = b.Loan_ID
order by row_num;
quit;

data sub; set sub (drop=row_num); run;