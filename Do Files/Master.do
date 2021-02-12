********************************************************************************
************************							****************************
************************			Set Up			****************************
************************							****************************
********************************************************************************

* Clear and set working directory
macro drop _all
clear all
set more off
global path "C:\Users\travi\Dropbox\Beyond the Gender Binary"
cd "${path}"

* Define control groups for benchmark specifcation (X) and robustness checks
global X "i.(race sexuality age marital education) i.(state time metro cellphone)"
global g1 " "
global g2 "i.(state time cellphone)"
global g3 "i.(state time metro cellphone)"
global g4 "i.(race age education) i.(state time metro cellphone)"
global g5 "i.(race sexuality age marital education) i.(state time metro cellphone)"

* Define gender typical expression estimator 
global GTE_estimator = "nn_1_1"			// estimators: nn_X_Y, cvlasso, logit, ols, steplogit

* Define maximum portion of GTE predictor that can be imputed, drop if missing more than this number
global impute_cap = 30					

* Gender expression diagnostic thresholds
global thresh = .39


***********************************************************
******  	  Section 1: Individual Datasets 		 ******
***********************************************************

* Import BRFSS and define sample
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
	
* Map
do "Do Files/4 - Map.do"

* Summary statistics table
texdoc do "Do Files/4 - Summary Statistics"

* Lit Review Table
do "Do Files/4 - Lit Review"

* Estimate robustness checks subsetting controls tables
do "Do Files/4 - Robust Control Table.do"

* Cts table (note, controls are not interacted due to small sample size)
texdoc do "Do Files/4 - Results by Gender"

* Benchmark specification tables
do "Do Files/4 - Benchmark identity.do"
do "Do Files/4 - Benchmark expression.do"
do "Do Files/4 - Benchmark perception.do"

******    Figures    ******

cd "${path}"
foreach var in laborforce homemaker poverty unemployed employ{
	
	* Global outcome
	global outcome = "`var'"
	
	*Labels
	if "`var'" == "employ"{
		global ytitle "Employment rate"
	}
	if "`var'" == "homemaker"{
		global ytitle "Homemaking rate"
	}
	if "`var'" == "poverty"{
		global ytitle "Poverty rate"
	}
	if "`var'" == "laborforce"{
		global ytitle "Labor force participation rate"
	}
	if "`var'" == "unemployed"{
		global ytitle "Unemployment rate"
	}
	
	* Regression Figure by Identity
	global ytitle1 "${ytitle} relative to cismen"
	global ytitle2 ""
	global yaxis ""
	do "Do files/4 - Regression Figures Identity"

	* Regression Figures by Identity-Expression
	global ytitle1 "${ytitle} relative"
	global ytitle2 "to masculine cismen"
	global yaxis "ysc(titlegap(.5cm))"
	do "Do files/4 - Regression Figures Expression"
	
	* Regression Figures by Identity-Expression-Perception	
	global ytitle1 "${ytitle} relative"
	global ytitle2 "to masculine cismen"
	global yaxis "ysc(titlegap(.5cm))"
	do "Do files/4 - Regression Figures Perception"

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




