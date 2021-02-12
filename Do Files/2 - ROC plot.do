
* set up
cd "${path}"
clear all
tempfile temp
cap frame change default


***********************************************************
******  	 Section 1: Expression Predictions		 ******
***********************************************************

* Create frame to stack annual estimates
frame create expression id expression_ols expression_logit expression_steplogit expression_cvlogit

* Estiamte gender-typical expression for each year for other estimators
forvalues y = 2014/2017{

	* Open full GTE predictor data
	use Data/DTA/GTE_full, clear
	keep if year==`y'

	* Loop estimators
	foreach e in ols logit steplogit cvlogit  {

		* Open neural net of column
		est use "Tables_and_Figures/`e'_`y'"

		* Predict outcome
		if "`e'"=="rlogit"{
			predict expression_`e',p
		}
		if "`e'"=="cvlogit"{
			predict expression_`e', p lopt
		}			
		if "`e'"!="cvlogit"&"`e'"!="rlogit"&{
			predict expression_`e'	
		}
		
	}
	
	* Stack
	keep expression* id _llcpwt masculine
	save `temp', replace
	frame expression: append using `temp'
}

* Merge neural network estimates to save time (dont have to re-estimate)
frame change expression
merge 1:1 id using "data\dta\expression.dta", nogen assert(3)
rename expression expression_nn
frame drop default


***********************************************************
******  			Section 2: ROC plot			 	******
***********************************************************

* Create frame to stack annual estimates
cap frame drop roc
frame create roc thresh true_nn false_nn true_ols false_ols true_logit false_logit ///
	true_steplogit false_steplogit true_cvlogit false_cvlogit
 
* Loop over cutoffs from 0 to 1
forvalues i = 0(.01)1{

	* Loop over estimators
	foreach e in nn ols logit steplogit cvlogit  {	
	
		* Count portion of true predictions for cismen at threshold i
		cap drop true
		g true = expression_`e'>`i' & inlist(masculine, 1)
		sum true [aw = _llcpwt] if inlist(masculine, 1), meanonly
		local true_`e' = r(mean)
		
		* Count portion of false predictions for ciswomen at threshold i
		cap drop false
		g false = expression_`e'>`i' & inlist(masculine, 0)
		sum false [aw = _llcpwt] if inlist(masculine, 0), meanonly
		local false_`e' = r(mean)	
		
	}
	
	* Append true and false positive rate for cutoff
	frame post roc (`i') (`true_nn') (`false_nn') (`true_ols') (`false_ols') (`true_logit') 	///
		(`false_logit') (`true_steplogit') (`false_steplogit') (`true_cvlogit') (`false_cvlogit') 

}

* Find median expression
sum expression_nn [aw=_llcpwt], d
local median = int(round(r(p50)*100))/100
local mean = int(round(r(mean)*100))/100

* Switch frames
frame change roc

* Find best threshold as closest to top left corner of figure and label, also label .5 and median
g distance = sqrt((1-true_nn)^2+(0-false_nn)^2)
sum distance, meanonly
g double mlabel_close = int(round(thresh*100))/100 if distance==r(min)
g double mlabel_half = int(round(thresh*100))/100 if thresh == .5
g double mlabel_median =  int(round(thresh*100))/100 if int(round(thresh*100))/100 == `median' 
g double mlabel_mean =  int(round(thresh*100))/100 if  int(round(thresh*100))/100 == `mean'

* Convert to string for labels
foreach v of varlist mlabel*{
	tostring `v', replace force
	replace `v' = "" if `v' == "."
}

* ROC plot
twoway 	(line true_nn false_nn, sort lp(solid) lc(blue%50))								///
		(line true_ols false_ols, lp(solid) lc(red%50)  lp(dash))						///
		(line true_logit false_logit, lp(solid) lc(green%50)  lp(shortdash))			///
		(line true_steplogit false_steplogit, lp(solid) lc(purple%50)  lp(longdash))	///
		(line true_cvlogit false_cvlogit, lp(solid) lc(maroon%50)  lp(dash dot))		///
		(function y=x, lp(dash)) 														///
		(scatter true_nn false_nn if mlabel_close!="", mlabel(mlabel_close) mlabp(11) 	///
			mc(blue%50) mlabc(blue) msize(small) mlabgap(5pt)) 							///
		(scatter true_nn false_nn if mlabel_half!="", mlabel(mlabel_half) mlabp(9) 		///
			mc(red%50) mlabc(red) msize(small) mlabgap(5pt)) 							///		
		(scatter true_nn false_nn if mlabel_median!="", mlabel(mlabel_median) mlabp(4) 	///
			mc(green%50) mlabc(green) msize(small)) 									///
		(scatter true_nn false_nn if mlabel_mean!="", mlabel(mlabel_mean) mlabp(11) 	///
			mc(purple%50) mlabc(purple) msize(small) mlabgap(5pt))						///
		, scheme(plotplain) legend(off) xtitle("False positive rate") ytitle("True positive rate")

graph export "Tables_and_Figures/ROC_plot.pdf", replace

* Clean up
clear all
