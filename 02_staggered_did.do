clear
version 16
set more off

* Usage: do 02_staggered_did.do [input_file] [output_directory]
args input_file output_dir
if `"`input_file'"' == "" local input_file "hrs_eventdata.csv"
if `"`output_dir'"' == "" local output_dir "."

*******************************************************
***************        Problem 1        ***************
*******************************************************
* Problem 1 Question 1
import delimited `"`input_file'"', clear

sort hhidpn wave

by hhidpn: gen first_occurrence = (_n == 1)
count if first_occurrence == 1

gen wave_hosp_id = wave_hosp*first_occurrence

tabulate wave_hosp if wave_hosp_id>0

histogram wave_hosp_id if wave_hosp_id>0, discrete

* There are 656 units. The time period is 5. Total observation is 3,280. 

* Problem 1 Question 2
* Five years
* There are 656 are treated, no never treated, no always treated.

* Problem 1 Question 3
gen treat = (wave>=wave_hosp)

eststo: reghdfe oop_spend treat, absorb(hhidpn wave) cluster(hhidpn)

esttab using `"`output_dir'/econ8833_ps3_q3.tex"', ///
   keep(treat)  ///
   b(3) se(3) ar2(3) star(* 0.10 ** 0.05 *** 0.01) ///
   title("The traditional static two-way fixed effects") ///
   nonumbers ///
   mtitles("Out-of-pocket spending")

eststo clear  


* Problem 1 Question 4
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

gen unittype = 0
replace unittype=1 if wave_hosp==8
replace unittype=2 if wave_hosp==9
replace unittype=3 if wave_hosp==10
replace unittype=4 if wave_hosp==11


reg oop_spend D_pre4 D_pre3 D_pre2 o.D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 ///
	ibn.wave ibn.unittype
estimates store basic_model

coefplot basic_model, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(4, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))

* Problem 1 Question 5
honestdid, pre(1/3) post(6/8) mvec(0.1(0.5)2)	
	
honestdid, pre(1/3) post(6/8) mvec(0.5(0.5)2) coefplot xtitle("M") ytitle("95% Robust CI")	
	
* Problem 1 Question 6
csdid oop_spend, ivar(hhidpn) time(wave) gvar(wave_hosp)	

estat event, estore(cs)
csdid_plot

* Problem 1 Question 7
reg oop_spend D_pre4 D_pre3 D_pre2 o.D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 ///
	ibn.wave ibn.unittype
estimates store basic_model
	
csdid oop_spend, ivar(hhidpn) time(wave) gvar(wave_hosp)	
estat event, estore(cs)

event_plot cs basic_model , ///
	stub_lag(Tp# D_post#) stub_lead(Tm# D_pre#) plottype(scatter) ///
ciplottype(rcap) ///
	together perturb(-0.325(0.13)0.325) trimlead(5) noautolegend ///
	graph_opt(title("Event study estimators in a simulated panel", size(medlarge)) ///
      xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-4(1)3)///
		legend(order(1 "Basic model" 2 "Callaway-Sant'Anna") rows(3) region(style(none))) ///
	/// the following lines replace default_look with something more elaborate
		xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal)) ///
	) ///
	lag_opt1(msymbol(+) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
	lag_opt2(msymbol(O) color(cranberry)) lag_ci_opt2(color(cranberry))

graph export `"`output_dir'/combine_estimators_example.png"', replace
	
*******************************************************
***************        Problem 2        ***************
*******************************************************
* Problem 2 Question 2
constraint define 1 1.unittype + 2.unittype = 0 
constraint define 2 D_pre2 + D_pre1 = 0

cnsreg oop_spend D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 ///
	ibn.wave i.unittype, nocons constraints(1 2) collinear 
estimates store constraint_2pre

coefplot constraint_2pre, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))
graph export `"`output_dir'/dataset_one_pre_period.pdf"', replace

* Problem 2 Question 3
constraint define 1 1.unittype + 2.unittype = 0 
constraint define 2  D_pre1 = 0  
constraint define 3  D_pre4 = D_pre3

cnsreg oop_spend D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 ///
	ibn.wave i.unittype, nocons constraints(1 2 3) collinear 
estimates store constraint_2pre

coefplot constraint_2pre, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))
graph export `"`output_dir'/dataset_cap_pre_period.pdf"', replace	

constraint define 1 1.unittype + 2.unittype = 0 
constraint define 2  D_pre1 = 0  
constraint define 3  D_pre4 = D_pre3
constraint define 4  D_post2 = D_post3

cnsreg oop_spend D_pre4 D_pre3 D_pre2 D_pre1 ///
	D_post0 D_post1 D_post2 D_post3 ///
	ibn.wave i.unittype, nocons constraints(1 2 3 4) collinear 
estimates store constraint_2pre

coefplot constraint_2pre, keep(D*) vertical omitted msymbol(diamond) ///
	xtitle("Relative Year") ytitle("Estimated Treatment Effects") ///
	yline(0,lcolor(gs12) lpattern(dash)) xline(10, lpattern(dash) lcolor(red)) ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white)) coeflabels(,angle(45))
graph export `"`output_dir'/dataset_cap_pre_period.pdf"', replace	

