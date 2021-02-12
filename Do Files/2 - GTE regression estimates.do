* set up
mata: rseed(19361937)
set seed 19361937

* Loop over years
forvalues y=2014/2018{

	* Open training data
	use Data/DTA/Training_`y', clear
	
	* Remove collinear variables by hand
	_rmcoll x_cts_* x_cat_*, force
	local vars = r(varlist)
	
	* CV-lasso
	cvlassologit masculine `vars', maxi(10) strat seed(19361937) nfolds(5) lopt postres
	estimates save "Tables_and_Figures/cvlogit_`y'", replace	
	
	* Lasso logit with rigorous penalization
	rlassologit masculine `vars', maxi(10)
	estimates save "Tables_and_Figures/rlogit_`y'", replace
	
	* OLS
	reg masculine `vars', vce(cluster _psu)
	estimates save "Tables_and_Figures/ols_`y'", replace
	
	* Backward stepwise logistic regression
	stepwise, pr(.0001): logit masculine `vars', vce(cluster _psu) iter(10)
	estimates save "Tables_and_Figures/steplogit_`y'", replace

	* Logit
	logit masculine `vars', vce(cluster _psu) iter(10)
	estimates save "Tables_and_Figures/logit_`y'", replace
	
}

* Exit new instance of stata when finished
exit, STATA clear