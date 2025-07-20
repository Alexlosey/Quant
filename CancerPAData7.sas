/***************************************************************************************************************
*** Program: epi 612 data step 3 SAS code
*** Program /home/u63549695/Quantsas/Project/CancerPA.sas
***
*** Dataset: nhanes 2017-2018
*** Data location: /home/u63549695/Quantsas/Project/nh1718.sas7bdat
***
*** Purpose: Perform data management steps and run descriptive statistics for 
data step 3 using nhanes 2017-2018 data

*** Programmer: Alexander B. Losey
***
*** Revised: October 23, 2024
***
*** Notes: 
***		   
*************************************************************************************************************/ 

/*****************************************
*** read in dataset, subset by only those diagnosed with cancer ***
*****************************************/

*libname and check contents*;
libname nhanes "/home/u63549695/Quantsas/Project";
proc contents data="/home/u63549695/Quantsas/Project/nh1718.sas7bdat";
run;

*subset nhanes data so only those with cancer diagnosis are included*;
data nhanes.nh1718a;
set nhanes.nh1718;
where MCQ220 = 1;
run;

*view variables of interest - demographics, age at diagnosis, pa variables;
proc freq data=nhanes.nh1718a;
	tables riagendr ridageyr ridreth3 MCD240a PAQ650 PAQ665;

run;

/***********************************
*** recode variables of interest ***
***********************************/

*make binary physical activity variable - outcome*;
data nhanes.nh1718a;
set nhanes.nh1718a;
if PAQ650 = 1 then physact = 1;
else if PAQ665 = 1 then physact = 1;
else physact = 0;
if PAQ650 = . then physact = .;
else if PAQ665 = . then physact = .;
run;

*make binary age at diagnosis variable, cutoff - age 25 - exposure*;
data nhanes.nh1718a;
set nhanes.nh1718a;
if MCD240a in(16,17,18,19,20,21,22,23,24,25) then agedgnsis = 0;
else if MCD240a >= 26 and MCD240a <= 80 then agedgnsis = 1;
else agedgnsis = .;
run;


* create and apply formats for nhanes demographic veriables;
proc format lib=nhanes;
	
	value physactf
		1 = "Physically Active"
		0 = "Not Physically Active";
		
	value agedgnsisf
		1 = "Adult when Diagnosed"
		0 = "Youth when Diagnosed";
	
	value riagendrf
		1 = "Male"
		2 = "Female";

	value ridageyrf
		80 = "80+";

	value ridreth3f
		1 = "Mexican American"
		2 = "Other Hispanic"
		3 = "Non-Hispanic White"
		4 = "Non-Hispanic Black"
		6 = "Non-Hispanic Asian"
		7 = "Other Race - Including Multi-Racial";

run;

proc datasets;
	modify nhanes.nh1718a;

	format riagendr riagenderf. ridageyr ridageyr. ridreth3 ridreth3f. 
	agedgnsis agedgnsisf. physact physactf.;
run;


*check frequencies of new variables*;
proc freq data=nhanes.nh1718a;
tables agedgnsis physact;
run;

/******************************
*** descriptive statistics ***
*******************************/

* total analytic sample;
proc freq data=nhanes.nh1718a;
	tables riagendr ridreth3 agedgnsis physact;

proc means data=nhanes.nh1718a;
	var ridageyr;

run;
	
* among those who are physically active;
proc freq data=nhanes.nh1718a;
	tables riagendr ridreth3 agedgnsis;
	where physact = 1;

proc means data=nhanes.nh1718a;
	var ridageyr;
	where physact = 1;

run;

* among those not physically active*;
proc freq data=nhanes.nh1718a;
	tables riagendr ridreth3 agedgnsis physact;
	where physact = 0;

proc means data=nhanes.nh1718a;
	var ridageyr;
	where physact = 0;

run;

/***************************************************************************************************************
*** Program: epi 612 data step 4 SAS code
*** Program /home/u63549695/Quantsas/Project/CancerPA.sas
***
*** Dataset: nhanes 2017-2018
*** Data location: /home/u63549695/Quantsas/Project/nh1718.sas7bdat
***
*** Purpose: Perform data management steps for data step 4 using nhanes 2017-2018 data

*** Programmer: Alexander B. Losey
***
*** Revised: November 7, 2024
***
*** Notes: I changed the cutoff for age at diagnosis to 25 and younger
***		   
*************************************************************************************************************/ 

*restrict dataset by only nonmissing values for included variables*;
data nhanes.nh1718b;
set nhanes.nh1718a;
where not missing(physact)
and not missing(riagendr)
and not missing(ridreth3)
and not missing(agedgnsis)
and not missing(ridageyr);
run;

*create continuous variable for time since cancer diagnosis, using age at survey and age of diagnosis*;
data nhanes.nh1718b;
set nhanes.nh1718b;
yrssincedgn = ridageyr - MCD240a;
if MCD240a = "77777" or MCD240a = "99999" then yrssincedgn = ".";
run;

*check distribution of continuous age at survey variable with histogram*;
proc univariate data=nhanes.nh1718b;
var yrssincedgn;
histogram /normal;
run;

*categorize because this relationship is not linear*;
*create categorical variable for time since cancer diagnosis, using quartile ranges*;
data nhanes.nh1718b;
set nhanes.nh1718b;
if yrssincedgn ge 0 and yrssincedgn lt 3 then yrscat = 1;
else if yrssincedgn ge 3 and yrssincedgn lt 7 then yrscat = 2;
else if yrssincedgn ge 7 and yrssincedgn lt 15 then yrscat = 3;
else yrscat = 4;
if yrssincedgn = . then yrscat = .;

*check the new yrscat variable*;
proc freq data=nhanes.nh1718b;
tables yrscat;
run;

*redo table 1*;

* total analytic sample;
proc freq data=nhanes.nh1718b;
	tables riagendr ridreth3 agedgnsis physact yrscat;

run;

* among those not physically active*;
proc freq data=nhanes.nh1718b;
	tables riagendr ridreth3 agedgnsis physact yrscat;
	where physact = 0;

run;
	
* among those who are physically active;
proc freq data=nhanes.nh1718b;
	tables riagendr ridreth3 agedgnsis physact yrscat;
	where physact = 1;
	
run;

*assess linear relationship for continuous EM variable*;
*sort data by age since diagnosis*;
proc sort data=nhanes.nh1718b;
by yrssincedgn;
run;

*calculate the prevalence of physact by yrsdgnsis,
by making new dataset with proc means*;
proc means data=nhanes.nh1718b noprint;
by yrssincedgn;
var physact;
output out=nhanes.physact_by_yrs mean=pphysact;
run;

*make odds of mean yrs, then get the log of that, 
which will be a new varible in a new dataset*;
data nhanes.physact_by_yrs2;
set nhanes.physact_by_yrs;
odds = pphysact / (1 - pphysact);
log_odds = log(odds);
run;

*plot the log odds against years since diagnosis*;
proc gplot data=nhanes.physact_by_yrs2;
plot log_odds * yrssincedgn;
run;
quit;

*try to make table 2*;
*associations with outcome variable (physact) only*;
proc freq data=nhanes.nh1718b;
tables physact * (agedgnsis physact riagendr ridreth3 yrscat)/chisq;
run;

*try table 2b - each variable ran against the outcome.*;
*first var*;
proc freq data=nhanes.nh1718b;
tables physact * (agedgnsis)/chisq;
run;

proc freq data=nhanes.nh1718b;
tables physact * (riagendr)/chisq;
run;

proc freq data=nhanes.nh1718b;
tables physact * (ridreth3)/chisq;
run;

proc freq data=nhanes.nh1718b;
tables physact * (yrscat)/chisq;
run;



*BEGIN BACKWARDS ELIM TO PREP FOR TABLE 3*;
*start with complete model*;
proc logistic data=nhanes.nh1718b;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact = agedgnsis riagendr ridreth3 yrscat;
run;
*exposure OR = 2.347, type 3 p val for ethnicity is high, eliminate*;

*next model with no race/eth - FINAL ADJUSTED MODEL - table 3*;
proc logistic data=nhanes.nh1718b descending;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact = agedgnsis riagendr yrscat;
run;
*exposure OR = 2.131, % change is 9.2%* which is <10, remove race/eth;

*time to make unadjusted for table 3!!!*;
proc logistic data=nhanes.nh1718b descending;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact = agedgnsis;
run;

proc logistic data=nhanes.nh1718b descending;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact = riagendr;
run;

proc logistic data=nhanes.nh1718b descending;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact = yrscat;
run;


*assess goodness of fit of this model with the aggy lackfit*;
proc logistic data=nhanes.nh1718b;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact = agedgnsis riagendr yrscat/ scale=none aggregate lackfit;
run;

*I FORGOT TO ADD DESCENDING OPTION*;

*table 4!*;
*add new interaction term to assess effect modification*;
proc logistic data=nhanes.nh1718b;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact = agedgnsis riagendr yrscat yrscat*agedgnsis;
run;
*int term p value is 0.709 from joint test table*;

***Data 7 steps***
***applying sample weights***;

*create ccsample binary indicator of complete case sample*;
data nhanes.nh1718c;
set nhanes.nh1718b;
	if physact = '.' or agedgnsis = '.' or yrscat = '.' or riagendr = '.' or ridreth3 = '.'
	then ccsample = 0;
	else ccsample = 1;
	
run;

*proc survey to create table 1 with weights*;
*overall*;
proc surveyfreq data=nhanes.nh1718c;
	strata sdmvstra;
	cluster sdmvpsu;
	weight wtint2yr;
tables ccsample * (physact agedgnsis yrscat riagendr ridreth3)/row;
run;

*among pa 0*;
proc surveyfreq data=nhanes.nh1718c;
	strata sdmvstra;
	cluster sdmvpsu;
	weight wtint2yr;
	where physact = 0;
tables ccsample * (physact agedgnsis yrscat riagendr ridreth3)/row;
run;

*among pa 1*;
proc surveyfreq data=nhanes.nh1718c;
	strata sdmvstra;
	cluster sdmvpsu;
	weight wtint2yr;
	where physact = 1;
tables ccsample * (physact agedgnsis yrscat riagendr ridreth3)/row;
run;

*create table 2 with weights
*associations with outcome variable (physact) only*;
proc surveyfreq data=nhanes.nh1718c;
	strata sdmvstra;
	cluster sdmvpsu;
	weight wtint2yr;
tables ccsample * physact * (agedgnsis yrscat riagendr ridreth3)/col wllchisq;
run;

*backwards elimination*;
*try full model with weights and domain*;
proc surveylogistic data=nhanes.nh1718c;
	strata sdmvstra;
	cluster sdmvpsu;
	weight wtint2yr;
	domain ccsample;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact (event="1") = agedgnsis riagendr ridreth3 yrscat;
run;
*OR for agedgnsis: 1.101*;
*race/eth highest pvalue, try removing*;

*without race*;
proc surveylogistic data=nhanes.nh1718c;
	strata sdmvstra;
	cluster sdmvpsu;
	weight wtint2yr;
	domain ccsample;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact (event="1") = agedgnsis riagendr yrscat;
run;
*OR for agedgnsis: 1.028, less than 10% change, remove race*;
*next highest pval is sex;

*without race or sex*;
proc surveylogistic data=nhanes.nh1718c;
	strata sdmvstra;
	cluster sdmvpsu;
	weight wtint2yr;
	domain ccsample;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact (event="1") = agedgnsis yrscat;
run;
*OR for agedgnsis: 0.944, less than 10% change, remove sex*;
*this is the FINAL MODEL*;

*unadjusted model ORs*;
*just exposure*;
proc surveylogistic data=nhanes.nh1718c;
	strata sdmvstra;
	cluster sdmvpsu;
	weight wtint2yr;
	domain ccsample;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact (event="1") = agedgnsis;
run;

*just yrscat*;
proc surveylogistic data=nhanes.nh1718c;
	strata sdmvstra;
	cluster sdmvpsu;
	weight wtint2yr;
	domain ccsample;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact (event="1") = yrscat;
run;

*effect mod w yrscat*;
proc surveylogistic data=nhanes.nh1718c;
	strata sdmvstra;
	cluster sdmvpsu;
	weight wtint2yr;
	domain ccsample;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact (event="1") = agedgnsis yrscat yrscat*agedgnsis;
run;
*joint test p val = 0.1466*;

*check weight*;
proc univariate data=nhanes.nh1718a;
var wtint2yr;
run;

*create new weight variable*;
data nhanes.nh1718c1;
set nhanes.nh1718c;
newweight = wtint2yr*(588/26672057.8);
run;

*try it and see GOF*;
proc logistic data=nhanes.nh1718c1;
class agedgnsis(ref="1") physact(ref="0") riagendr(ref="1") ridreth3(ref="1") yrscat(ref="1")/ param=ref;
model physact (event="1") = agedgnsis yrscat/ scale=none aggregate lackfit;
	weight newweight;
run;
*all values significant, model does not fit data*;
