********************************************************************************
************************							 ****************************
************************			 Set Up			 ****************************
************************ (Last ran from top: 7/2022) ****************************
********************************************************************************

* Clear and set working directory
macro drop _all
clear all
set more off
global path "C:\Users\travi\Dropbox\Beyond the Gender Binary"
cd "${path}"

* Define control groups for benchmark specifcation
global X "race sexuality age marital education state time metro numadult#cellphone"

* Define gender typical expression estimator 
global GTE_estimator = "nn_1_1"			// estimators: nn_X_Y, cvlasso, logit, ols, steplogit

* Define maximum portion of GTE predictor that can be imputed, drop if missing more than this number
global impute_cap = 30					

* Gender expression diagnostic thresholds
global thresh = .40


***********************************************************
******  	  Section 1: Individual Datasets 		 ******
***********************************************************

/* Import BRFSS and define sample
do "Do Files/1 - BRFSS.do"

* Poverty threshoolds  
do "Do Files/1 - Poverty thresholds.do"

* Map fips
do "Do Files/1 - Map fips.do"

* Region
do "Do Files/1 - Region.do"

* CPS Dataset for lit review table
do "Do Files/1 - CPS dataset.do"


***********************************************************
******  Section 2: Gender Typical Expression (GTE)   ******
***********************************************************

* Create annual training and validation data
do "Do Files/2 - Training and validation data.do"

* Estimate GTE regressions
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - GTE regression estimates.do"

* Estimate neural networks on seperate cores to save time
forvalues i=1/4{
	winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Neural net estimates `i'.do"
}
*/
* Final gender-typical expression estimate
do "Do Files/2 - Gender typical expression.do"

* ROC Plot
do "Do Files/2 - ROC plot.do"

* Neural network validation table
do "Do Files/2 - NN validation table.do"

* GTE estimator evaluation table
do "Do Files/2 - GTE estimator evaluation table.do"


***********************************************************
******     Section 3: Final dataset for analysis     ******
***********************************************************

* Define control variables
do "Do Files/3 - Variable Creation.do"


***********************************************************
******     			Section 4: 	Results			 	 ******
***********************************************************

* Lit Review Table
do "Do Files/4 - Lit Review"

* Map
do "Do Files/4 - Map.do"

* Summary statistics table
texdoc do "Do Files/4 - Summary Statistics"

* Baseline regression by gender identity and sex
do "Do files/4 - Regression Figures Identity"

* Baseline estimate table
do "Do Files/4 - Baseline estimates.do"
do "Do Files/4 - Baseline estimates (within).do"

* Robustness to only cellphone
do "Do Files/4 - Baseline estimates (cellphone).do"

* Estimate robustness checks subsetting controls tables
do "Do Files/4 - Robust Control Table.do"

* Estimate robustness checks using different combinations of gender identity, expression, and perception
do "Do Files/4 - Benchmark identity.do"
do "Do Files/4 - Benchmark expression.do"
do "Do Files/4 - Benchmark perception.do"
do "Do Files/4 - Benchmark expression perception.do"

* Cts table
texdoc do "Do Files/4 - Results by Gender"

* Other figures
foreach var in laborforce employed unemployed{
	
	* Global outcome
	global outcome = "`var'"
	
	*Labels
	if "`var'" == "employed"{
		global ytitle "Employment rate"
	}
	if "`var'" == "laborforce"{
		global ytitle "Labor force participation rate"
	}
	if "`var'" == "unemployed"{
		global ytitle "Unemployment rate"
	}

	* Baseline Regression Figures
	do "Do files/4 - Baseline Regression Figure"

	* Continuous Figures (Total)
	global color "red"
	global gender "Total"
	global outcome "`var'"
	do "Do Files/4 - Expression_plot"
	do "Do Files/4 - Expression_plot_controls"
	
	* Cismen
	global color "blue"
	global gender "cismen"
	global outcome "`var'"
	do "Do Files/4 - Expression_plot"
	do "Do Files/4 - Expression_plot_controls"

	* Ciswomen
	global color "purple"
	global gender "ciswomen"
	global outcome "`var'"
	do "Do Files/4 - Expression_plot"
	do "Do Files/4 - Expression_plot_controls"
	
	* M2F
	global color "orange_red"
	global gender "m2f"
	global outcome "`var'"
	do "Do Files/4 - Expression_plot"
	do "Do Files/4 - Expression_plot_controls"
	
	* F2M
	global color "dknavy"
	global gender "f2m"
	global outcome "`var'"
	do "Do Files/4 - Expression_plot"
	do "Do Files/4 - Expression_plot_controls"

	* Non
	global color "grey"
	global gender "non"
	global outcome "`var'"
	do "Do Files/4 - Expression_plot"
	do "Do Files/4 - Expression_plot_controls"
	
}