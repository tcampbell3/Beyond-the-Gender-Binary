set seed 19361939
cap frame change default
cap frame drop predictors
use "$path\Data\DTA\BRFSS_Pooled.dta", clear
append using "Data\DTA\BRFSS_2018", force

//Gender
rename trnsgndr trans
gen Cisman=(sex==1&trans>3)
	replace Cisman=. if sex==.
gen Ciswoman=(sex==2&trans>3)
	replace Ciswoman=. if sex==.
gen M2F=(trans==1)
gen F2M=(trans==2)
gen Non=(trans==3)
gen Cis=(Cisman==1|Ciswoman==1)
gen Masculine=(sex==1)
	replace Masculine=. if sex==.

************************************************************
				// 1) Create predictors
************************************************************

* combine variables that have been relabeled by hand, as indicated in table
g crgvprb = crgvprb1
	replace crgvprb = crgvprb2 if crgvprb== .
g crgvrel = crgvrel1
	replace crgvprb = crgvrel2 if crgvrel == .
replace _frutsum = _frutsu1 if _frutsum == .
replace _vegesum = _vegesu1 if _vegesum == .
replace frutda1_ = frutda2_ if frutda1_ == .
replace vegeda1_ = vegeda2_ if vegeda1_ == .
replace _drnkwek = _drnkdy4*7 if _drnkwek == .
replace hivrisk5 = hivrisk4 if hivrisk5 == .
replace usemrjna = usemrjn1 if usemrjna == .
replace cholchk = cholchk1 if cholchk == .
replace csrvtrt1 = csrvtrt2 if csrvtrt1 == .
destring pcdmdecn, replace

* reformat bloodsugar to daily
replace bldsugar = . if bldsugar > 500	// MissingCode
replace bldsugar =  (bldsugar-100) if bldsugar < 200
replace bldsugar =  (bldsugar-200)/7 if bldsugar >= 200 & bldsugar < 300
replace bldsugar =  (bldsugar-300)/30 if bldsugar >= 300 & bldsugar < 400
replace bldsugar =  (bldsugar-400)/365 if bldsugar >= 400 & bldsugar < 500

* create frame to speed up
	frame create predictors
	frame change predictors
		import excel "Data\Expression Predictors.xlsx", sheet("Sheet1") firstrow clear
		split Combine, parse(", ")
		replace Variable=Combine2 if Combine1=="Yes"
		drop if ConditionalonSex == "Yes"
		collapse (first) Description Zero MissingCode ConditionalZero Type, by(Variable)
		drop if Variable==""
		replace Variable = lower(Variable)
		replace ConditionalZero = lower(ConditionalZero)
		
* global all predictors
levelsof Variable, clean
global E=lower(r(levels))

* global all  continuous predictors
levelsof Variable if Type=="cts", clean
local cE=lower(r(levels))
global cE=""
foreach var in `cE'{
	global cE = "$cE `var'"
}

* global all categorical predictors
levelsof Variable if Type=="cat", clean
global iE_list=lower(r(levels))
global iE=""
foreach var in $iE_list {
	global iE = "$iE i.`var'"
}
		
* Code conditional zeros from predictor sheet
foreach var in $E {
	
	quietly{
	levelsof ConditionalZero if Variable == "`var'", clean
	local condition = r(levels)
	if  "`condition'"!="."{
		frame change default
			di "`condition'"
			replace `var' = 0 if `condition'
		frame change predictors
	}
	}
	
}

* Code zeros from predictor sheet
foreach var in $E {
	
	sum Zero if Variable == "`var'", meanonly
	local zero = r(mean)
	
	if `zero'!=.{
		frame change default
			replace `var' = 0 if `var'==`zero'
		frame change predictors
	}
	
}

* Code missing from predictor spreadsheet
split MissingCode, parse(", ")
local num=r(nvars)
forvalues i=1/`num'{
	replace MissingCode`i' = subinstr(MissingCode`i', "BLANK", "",.) 
	destring MissingCode`i', replace
}

foreach var in $E {
	forvalues i=1/`num'{
	
		quietly{
		
		sum MissingCode`i' if Variable == "`var'", meanonly
		local zero = r(mean)
		
		if `zero'!=.{
			frame change default
				replace `var' = . if `var'==`zero'
			frame change predictors
		}
		
		}
		
	}
}

* Clean up
frame change default
keep $E Masculine Cis ID _psu _llcpwt year _state

* impute mean for missing continuous
quietly{
foreach v in $cE {
	g `v'_imputed = `v'==.
	sum `v', mean
	replace `v' = r(mean) if `v'==.
}

* impute missing category for indicators
foreach v in $iE_list {
	g `v'_imputed = `v'==.
	replace `v' = 99 if `v'==.
}
}



************************************************************
				// 2) Split data
************************************************************

* Test data
preserve
	keep if year>=2018
	save Data/DTA/Test,replace
restore

* Training/Validation data
drop if year>=2018
save Data/DTA/Train_valid,replace


************************************************************
				// 3) Estimates
************************************************************

* Loop over missing caps
foreach m in 10 25 50{
	
	* drop <m% Missing
	use Data/DTA/Train_valid, clear
	foreach v in $cE {
		sum `v'_imputed, meanonly
		if r(mean)>=.`m'{
			drop `v' `v'_imputed
		}
		else{
			rename `v' x_cts_`v'
		}
	}
	foreach v in $iE_list {
		sum `v'_imputed, meanonly
		if r(mean)>=.`m'{
			drop `v' `v'_imputed
		}
		else{
			rename `v' x_cat_`v'
		}
	}

	* Regressions
	elasticnet logit Masculine x_cts_* i.(x_cat_*) [iw=_llcpwt], selection(cv) rseed(19361939) alpha(0 .1 .5 1)
	est save "Tables_and_Figures/elasticnet_`m'", replace

	elasticnet logit Masculine x_cts_* i.(x_cat_*) [iw=_llcpwt], selection(cv) rseed(19361939) alpha(0)
	est save "Tables_and_Figures/ridge_`m'", replace

	elasticnet logit Masculine x_cts_* i.(x_cat_*) [iw=_llcpwt], selection(cv) rseed(19361939) alpha(1)
	est save "Tables_and_Figures/lasso_`m'", replace

	logit Masculine x_cts_* i.(x_cat_*) [pw=_llcpwt] if Cis==1, vce(cluster _psu) difficult
	est save "Tables_and_Figures/logit_`m'", replace

}

* Open estimates
estimates use "Tables_and_Figures/elasticnet_10"
lassocoef,  display(coef , stand)
predict Express
replace Express = 1 if Express > 1
replace Express = 0 if Express < 0



* Save categorical regression estimates to prediction table
frame change predictors
	g est =.
	g p =.
frame change default
foreach v in $iE {

	* store estimate
	testparm i.`v'
	local est=round(r(F),.001)
	local p=r(p)
	local var = subinstr("i.`v'", "i.", "",.)
	
	* save estimate in prediction frame
	frame change predictors
		replace est = `est' if Variable == "`var'"
		replace p = `p' if Variable == "`var'"
	frame change default

}

* Save continuous regression estimates to prediction table
foreach v in $cE {

	* store estimate
	test `v'
	local est=_b[`v']
	local p=r(p)
	local var = subinstr("i.`v'", "i.", "",.)
	
	* save estimate in prediction frame
	frame change predictors
		replace est = `est' if Variable == "`var'"
		replace p = `p' if Variable == "`var'"
	frame change default

}

* format results
frame change predictors
g star=""
	replace star="*" if p<.1
	replace star="**" if p<.05
	replace star="***" if p<.001
cap drop Est
g Est = string(est, "%4.3f")
	replace Est = Est+star
keep Variable Description Type Est 
replace Type = "Categorical" if Type == "cat"
replace Type = "Continuous" if Type == "cts"
gen dummy1 = "$\texttt{"
gen dummy2 = "}$"
replace Variable = dummy1 + upper(Variable) + dummy2
replace Variable = subinstr(Variable, "_", "\_",.)
cap drop dummy*
sort Variable
export delimited using "Tables_and_Figures/Expression_Predictors.csv", replace	



* save text file of % correct cisgender classifications

// variable - Descrimption - % non-imputed - estimate - standard error
frame change default
keep ID Express*
compress
save "Data\DTA\Express.dta", replace	
