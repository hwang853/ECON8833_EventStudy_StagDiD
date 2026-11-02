clear all
version 16
set more off

* Usage: do 01_conventional_event_study.do [data_directory] [output_directory]
args data_dir output_dir
if `"`data_dir'"' == "" local data_dir "."
if `"`output_dir'"' == "" local output_dir "."

cap log close
local ctime: di  %tdYYNNDD date("$S_DATE", "DMY")  "_"  substr("$S_TIME",1,2)  substr("$S_TIME",4,2) substr("$S_TIME",7,2)
log using `"`output_dir'/`ctime'.log"', replace

***************************
* This analysis is based on an assignment written by Douglas Miller
** Goal: See effects of event study specification choices
********************************

/********************************************************************************
* Part 1 -- Load the Simulated Dataset, Create Leads and Lags
* Units are i, time is t, E_i is the event for unit i
********************************************************************************/

use `"`data_dir'/es_dataset_one.dta"', clear

/* make relative time variable */
gen reltime = (wave - wave_hosp)


/* lead and lag dummies */
/* For un treated observations notice these are all zero */
/* Labeling variables makes the graphs prettier later */
qui summ reltime
local mymin = r(min)
local mymax = r(max)
forvalues i = `mymin'/`mymax' {
	if `i' < 0 {
		local j = abs(`i')
		gen D_pre`j' = (reltime == `i')
		label var D_pre`j' "`i'"
	}
	if `i' >= 0 {
		gen D_post`i' = (reltime == `i')
		label var D_post`i' "`i'"
	}
}

/********************************************************************************
* Part 1b -- What if you didn't create leads and lags? Then you would only
use the treated observations and things look odd. 
********************************************************************************/

egen rel_group=group(reltime)

reg y o11.rel_group i.t i.unittype 
estimates store basic_model

coefplot basic_model, keep(*.rel_group) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))


/********************************************************************************
* Part 2 -- Estimate the sample models
********************************************************************************/

* a) Basic regression model, dropping D_pre1 to omit the -1 term

reg y D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 o.D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 i.t i.unittype 
estimates store basic_model

coefplot basic_model, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))


* b) Add constraints, first verify you can re-create the unconstrained model

/* 1, unit FE's among all average to zero */
/* 2 pre-treatment ES dummies average to zero */
constraint define 1 1.unittype + 2.unittype = 0 
constraint define 2  D_pre1 = 0  

cnsreg y D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 ibn.t ibn.unittype, nocons constraints(1 2) collinear 
estimates store constraint

coefplot constraint, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))
	
/* Happens to be the same as Stata's default here: */
constraint define 2  D_pre1 = 0  

cnsreg y D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 i.t i.unittype, constraints(2) collinear 
estimates store constraint

coefplot constraint, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))
graph export `"`output_dir'/dataset_one_pre1.pdf"', replace


/********************************************************************************
* Part 3 -- Add constraints, such that the average of all pre-period coefficients is zero	
********************************************************************************/
constraint define 1 1.unittype + 2.unittype = 0 
constraint define 2 D_pre10 + D_pre9 + D_pre8 + D_pre7 + D_pre6 + D_pre5 + ///
	D_pre4 + D_pre3 + D_pre2 + D_pre1 = 0

cnsreg y D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 ibn.t ibn.unittype, nocons constraints(1 2) collinear 
estimates store constraint_allpre

coefplot constraint_allpre, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))
graph export `"`output_dir'/dataset_one_pre_period.pdf"', replace



/********************************************************************************
* Part 4 - Switch to using es_dataset_two.dta. What problem can you diagnose?
********************************************************************************/


use `"`data_dir'/es_dataset_two.dta"', clear

/* make relative time variable */
gen reltime = (t - E_i)


/* lead and lag dummies */
/* For un treated observations notice these are all zero */
/* Labeling variables makes the graphs prettier later */
qui summ reltime
local mymin = r(min)
local mymax = r(max)
forvalues i = `mymin'/`mymax' {
	if `i' < 0 {
		local j = abs(`i')
		gen D_pre`j' = (reltime == `i')
		label var D_pre`j' "`i'"
	}
	if `i' >= 0 {
		gen D_post`i' = (reltime == `i')
		label var D_post`i' "`i'"
	}
}

/* 1, unit FE's among all average to zero */
/* 2  Relative year -1 equals zero */
constraint define 1 1.unittype + 2.unittype = 0 
constraint define 2  D_pre1 = 0  

cnsreg y D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 ibn.t ibn.unittype, nocons constraints(1 2) collinear 
estimates store es_two

coefplot es_two, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))

/********************************************************************************
* Part 5 - Modify the model to fix the problem
********************************************************************************/

**Adds time trend
gen time_trend = t * (unittype==2) 		


/* What happens if you add a time trend but don't specify constraints? */
/* Omits both unit type dummies */

reg y time_trend D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 o.D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 i.t i.unittype
estimates store es_two_reg

coefplot es_two_reg, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))
	
	
	
/* 1, unit FE's among all average to zero */
/* 2 pre-treatment ES dummies average to zero */
/* 3 Normalize so pre-period dummies average to zero */
/* 4 Normalizes for zero time trend */
constraint define 1 1.unittype + 2.unittype = 0 

constraint define 3 D_pre10 + D_pre9 + D_pre8 + D_pre7 + D_pre6 + D_pre5 + ///
	D_pre4 + D_pre3 + D_pre2 + D_pre1 = 0
	
constraint define 4 D_pre10*(10-5.5) + D_pre9*(9-5.5) + D_pre8*(8-5.5) + ///
	D_pre7*(7-5.5) + D_pre6*(6-5.5) + D_pre5*(5-5.5) + D_pre4*(4-5.5) ///
	+ D_pre3*(3-5.5) + D_pre2*(2-5.5) + D_pre1*(1-5.5) = 0  

cnsreg y time_trend D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 ibn.t ibn.unittype, nocons constraints(1 3 4) collinear 
estimates store es_two_zerotrend

coefplot es_two_zerotrend, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))
	

/********************************************************************************
* Part 6  - Use es_dataset_three.dta 
* Estimate the same model as in part (5) that normalizes the overall pre-period to be
* one. 
********************************************************************************/

use `"`data_dir'/es_dataset_three.dta"', clear

/* make relative time variable */
gen reltime = (t - E_i)

/* lead and lag dummies */
/* For un treated observations notice these are all zero */
/* Labeling variables makes the graphs prettier later */
qui summ reltime
local mymin = r(min)
local mymax = r(max)
forvalues i = `mymin'/`mymax' {
	if `i' < 0 {
		local j = abs(`i')
		gen D_pre`j' = (reltime == `i')
		label var D_pre`j' "`i'"
	}
	if `i' >= 0 {
		gen D_post`i' = (reltime == `i')
		label var D_post`i' "`i'"
	}
}


/* 1, unit FE's among all average to zero */
/* 2  Relative year -1 equals zero */
constraint define 1 1.unittype + 2.unittype = 0 
constraint define 2  D_pre1 = 0  

cnsreg y D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 ibn.t ibn.unittype, nocons constraints(1 2) collinear 
estimates store es_three

coefplot es_three, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))
	
**Adds time trend
gen time_trend = t * (unittype==2) 		

/* 1, unit FE's among all average to zero */
/* 2 pre-treatment ES dummies average to zero */
/* 3 Normalize so pre-period dummies average to zero */
/* 4 Normalizes for zero time trend */
constraint define 1 1.unittype + 2.unittype = 0 

constraint define 3 D_pre10 + D_pre9 + D_pre8 + D_pre7 + D_pre6 + D_pre5 + ///
	D_pre4 + D_pre3 + D_pre2 + D_pre1 = 0
	
constraint define 4 D_pre10*(10-5.5) + D_pre9*(9-5.5) + D_pre8*(8-5.5) + ///
	D_pre7*(7-5.5) + D_pre6*(6-5.5) + D_pre5*(5-5.5) + D_pre4*(4-5.5) ///
	+ D_pre3*(3-5.5) + D_pre2*(2-5.5) + D_pre1*(1-5.5) = 0  

cnsreg y time_trend D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 ibn.t ibn.unittype, nocons constraints(1 3 4) collinear 
estimates store es_three_zerotrend

coefplot (es_three, keep(D*) omitted msymbol(diamond)) ///
	(es_three_zerotrend, keep(D*) omitted msymbol(diamond)), vertical ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45)) ///
	legend(label(2 "Event Study") label(4 "Zero Pre Trend") )


/********************************************************************************
* Part 7 - Compare this to a "poor-man's trend controls", where you drop the 
* minus 1 and "minus large" dummies (you choose which one to drop)
********************************************************************************/
reg y time_trend D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 o.D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 i.t i.unittype
estimates store es_three_poorman

coefplot (es_three_poorman, keep(D*) omitted msymbol(diamond)) ///
	(es_three_zerotrend, keep(D*) drop(D_pre10) omitted msymbol(diamond)), vertical ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45)) ///
	legend(label(2 "Poor Man") label(4 "Zero Pre Trend") )

	
/********************************************************************************
* Part 8 -- What if you use regress, drop -1 and add a unit-type trend control, 
* but don't drop anything else (that is, you don't impose an extra restriction?)
* What happens in Stata?  Try changing the order of the trend control. 
********************************************************************************/
reg y time_trend D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 o.D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 i.t i.unittype
estimates store es_three_nodrop1

reg y D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 o.D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 i.t i.unittype time_trend 
estimates store es_three_nodrop2

coefplot (es_three_nodrop1, keep(D*) omitted msymbol(diamond)) ///
	(es_three_nodrop2, keep(D*) omitted msymbol(diamond)) ///
	(es_three_zerotrend, keep(D*) omitted msymbol(diamond)), vertical ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45)) ///
	legend(label(2 "Stata Drop 1") label(4 "Stata Drop 2") label(6 "Zero Pre Trend") )

/********************************************************************************
* Part 9 - End cap constraints
********************************************************************************/
constraint define 1 1.unittype + 2.unittype = 0 
constraint define 2  D_pre2 = 0  
constraint define 5  D_pre10 = D_pre9

cnsreg y time_trend D_pre10 D_pre9 D_pre8 D_pre7 D_pre6 D_pre5 D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 D_post4 D_post5 D_post6 D_post7 ///
	D_post8 D_post9 ibn.t ibn.unittype, nocons constraints(1 2 5) collinear 
estimates store es_three_endcap

coefplot (es_three_endcap, keep(D*) omitted msymbol(diamond)) ///
	(es_three_zerotrend, keep(D*) omitted msymbol(diamond)), vertical ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45)) ///
	legend(label(2 "End Cap") label(4 "Zero Pre Trend") )
	
	
log close
