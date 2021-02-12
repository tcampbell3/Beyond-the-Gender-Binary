* set up
clear all
set maxvar 120000
set seed 19361939
cap frame change default
cap frame drop predictors

* Open data
use "$path\Data\DTA\BRFSS_Pooled.dta", clear
qui append using "Data\DTA\BRFSS_2018", force
replace id=_n if id==.
order id

************************************************************
				// 1) Create variables
************************************************************

* gender (only cigender sample)
replace sex=sex1 if sex==. // 2018 rename sex since it is now asked
rename trnsgndr trans
gen cisman=(sex==1&trans>3)
replace cisman=. if sex==.
gen ciswoman=(sex==2&trans>3)
replace ciswoman=. if sex==.
gen cis=(cisman==1|ciswoman==1)
gen masculine=(sex==1)
replace masculine=. if sex==.

*Region and division
g state = _state
merge m:1 state using "Data\region.dta", nogen keep (1 3)

* Year-month
egen year_month = group(year fmonth)

* Cellphone survey
gen cellphone=(qstver>=20)
replace cellphone=99 if qstver==.						//missing=99

* Marital status indicator
rename marital _marital
gen marital=_marital
replace marital=0 if inlist(_marital,1,6)				//couple=0
replace marital=1 if inlist(_marital,5) 				//single==1 (never married)
replace marital=2 if inlist(_marital,2,3,4,9) 			//other=2
replace marital=99 if _marital==. 						//missing=99
		
* Education indicator
rename _educag education
replace education=9 if education==.
	
* Race indicator
rename _racegr3 race
replace race=3 if race==4 								// 3 denotes "other" or "mix"
replace race=9 if race==.
	
* Sexuality indicator
gen sexuality = sxorient
replace sexuality=4 if inlist(sxorient,7,9)
replace sexuality=99 if sxorient==.

* Metro
gen metro=(mscode<5)
replace metro=99 if mscode==.

* Age (10 year)
gen age = floor((_ageg5yr-1) / 2) 

* Social norms
egen norm=group(division metro year)

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
global cE=lower(r(levels))

* global all categorical predictors
levelsof Variable if Type=="cat", clean
global iE=lower(r(levels))
		
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
keep $E masculine cis id _psu _llcpwt _ststr _strwt year fmonth year_month _state region division sexuality race education marital cellphone metro age norm


************************************************************
				// 2) Impute variables
************************************************************

* Impute missing data with random draw from K-nearest neighbors with nonmissing data
* See https://hdsr.mitpress.mit.edu/pub/dno70rhw/release/3 for description

* 1) Count portion missing
foreach v in $E {

	g `v'_imputed = `v'==.			// Indicate imputation
	sum `v'_imputed, meanonly
	g `v'_imputed_percent=r(mean)	// Percent imputation in full dataset
	
}


* 2) List variabes in order of missingness
preserve
	
	* Create list of variable names in order of missingness
	fcollapse *imputed
	ds 
	local vars = r(varlist)
	local i=1
	foreach v in `vars'{
		g name`i'="`v'"
		rename `v' x`i'
		local i=`i'+1
	}
	gen _i = 1
	reshape long name x , i(_i) j(_j)
	replace name = subinstr(name,"_imputed", "", .)
	keep if x<.$impute_cap
	sort x
	
	* Local list of variables to impute in order of least missing to most missing
	local impute_order = ""
	local l = _N
	forvalues d=1/`l'{
		local missing_var = name[`d']
		local impute_order = "`impute_order' `missing_var'"
	}
	
restore

* 3) Nearest Neighbore imputation
local imp_reg = ""											// stores imputed regressors to included iteratively
tempname neighbors											// temp frame name
local j=1													// keep track of number of variables
local J = wordcount("`impute_order'")						// display total number of variables left to impute
timer clear													// display time of each step
foreach v in `impute_order' {

	* Estimate propensity score
	logit `v'_imputed sexuality race education marital cellphone metro age year fmonth ///
		_state division region `imp_reg', iter(20)
	cap drop _p_score
	predict _p_score
	local imp_reg = "`imp_reg' `v'"
	
	* Index observations that need imputation
	gsort - `v'_imputed
	cap drop _index
	g _index = _n if `v'_imputed ==1
	
	* Find last observation that needs imputation. And index next 10 obs.
	sum _index
	local last=r(max)			// Last observation of missing data
	local last1 = `last'+1		// First observation of nonmissing data
	local last2 = `last'+5		// Defines the number neightbors, k, used to determine imputation statistic
	local last3 = _N			// Last line of data
	sort _index
		
	* Loop over missing data
	forvalues i=1/`last'{
		
		qui{
		timer on 1
		
		* Save propensity score of observation being imputed
		local pscore: di _p_score[`i'] 
		
		* Save difference (0 is perfect match)
		cap drop _diff
		g _diff = abs(_p_score-`pscore') in `last1'/`last3'	
		
		* Create frame with only closest .01% of nonmissing dataset (speeds up run time substantially)
		gquantiles _diff, _pctile percentiles(.1)								// requires gtools package
		cap frame drop `neighbors'
		frame put in `last1'/`last3' if _diff <= r(r1), into(`neighbors')
		
		* Median of nearest 10 neighbors, ties are randomly broken
		frame `neighbors'{
			g random_tiebreaker = runiform()
			sort _diff random_tiebreaker
			_pctile `v' in 1/10, p(50)
			local N=_N
		}
		
		* Save imputed value
		replace `v' = r(r1) in `i'
		
		timer off 1
		timer list 1
		local timer = int(round(r(t1)))
		
		}
		di in red "Variable: `j'/`J'| Observations: `i'/`last' | Potential Matches: `N' | Time: `timer' seconds"

	}
	local j=`j'+1

}

* 4) Only use continuous variables under missing threshold
foreach v in $cE {

	sum `v'_imputed_percent, meanonly
	if r(mean)<.$impute_cap {
		g x_cts_`v'=`v'
	}
	
}

* 5) Only use categroical variables under missing threshold
foreach v in $iE {
	
	sum `v'_imputed_percent, meanonly
	if r(mean)<.$impute_cap {
		tab `v', gen(x_cat_`v')
		g nn_cat_`v' = `v'
	}
}

* 6) Save full dataset to use to predict final GTE measure for both Cis and Trans
compress
save Data/DTA/GTE_full, replace


************************************************************
				// 3) Split data
************************************************************

* See https://machinelearningmastery.com/difference-test-validation-datasets/ for definitions

* See https://mypages.valdosta.edu/lichen/DS/Resampling.html for description of bootstrap sampling for validation

* Save training/validation data foreach year
forvalues y=2014/2018{

	* Open full sample
	use Data/DTA/GTE_full, clear
	
	* Only cisgnder sample in survey year
	keep if cis == 1 & year == `y'
	
	* Draw 75% random sample stratified by sex with replacement using BRFSS sampling design
	gsample 75 [aw=_llcpwt], percent strata(_ststr masculine) cluster(_psu) generate(training)
	expand training
	
	* Validation data (tuning hyper parameters)
	preserve
		keep if training==0
		save Data/DTA/Validation_`y',replace
	restore

	* Training data (tuning hyper parameters)
	preserve
		keep if training>=1
		save Data/DTA/Training_`y',replace
	restore

}


************************************************************
				// 4) Expresion Predictors Table
************************************************************

* Save imputation rate
frame change predictors
	g Imputation = .
frame change default

foreach v in $E{

	* store estimate
	sum `v'_imputed_percent,meanonly
	local imp = r(mean)
	
	* save estimate in prediction frame
	frame change predictors
		replace Imputation = `imp' if Variable == "`v'"
	frame change default

}

* format results
frame change predictors
keep Variable Description Type Imputation
replace Type = "Categorical" if Type == "cat"
replace Type = "Continuous" if Type == "cts"
gen dummy1 = "$\texttt{"
gen dummy2 = "}$"
replace Variable = dummy1 + upper(Variable) + dummy2
replace Variable = subinstr(Variable, "_", "\_",.)
cap drop dummy*
sort Variable
export delimited using "Tables_and_Figures/Expression_Predictors.csv", replace	
frame change default


