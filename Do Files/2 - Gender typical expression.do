
* set up
cd "${path}"
clear all
set seed 19361939
tempfile temp

* create frame to stack annual estimates
cap frame change default
cap frame drop GTE
frame create GTE

* Estiamte gender-typical expression for each year
forvalues y = 2014/2017{

	* Open full GTE predictor data
	use Data/DTA/GTE_full, clear
	keep if year==`y'
	
	* Open neural net for year
	brain load "Tables_and_Figures/${GTE_estimator}_`y'"
	
	* Predict Outcome
	brain think expression

	* Save
	keep expression id
	save `temp', replace
	
	* Stack
	frame change GTE
	append using `temp'
	frame change default
	
}

* Save dataset
frame change GTE
sort id
compress
save Data/DTA/Expression, replace
clear all
