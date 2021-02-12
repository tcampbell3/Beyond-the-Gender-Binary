* Setup
clear all
set more off
cd "${path}"

* Dummy regression to store results for table
use Data/DTA/Training_2014, clear
eststo clear
reg year _state
est store dummy

* Blank column
eststo col_blank

* Start counters
local c=0

* Loop Columns
foreach d in Training blank Validation{

if "`d'"=="blank"{

	local colpost="`colpost' & "
	
}
else{

foreach col in nn_1_1 nn_1_2 nn_2_1 nn_2_2 nn_3_1 nn_3_2 nn_4_1 nn_4_2 {
	
	* Index column
	local c=`c'+1
	est restore dummy
	eststo col`c'
	
	* Loop over year, save statistics
	forvalues year = 2014/2017{

		
		* Open dataset
		use Data/DTA/`d'_`year', clear
		
		* Open neural net of column
		brain load "Tables_and_Figures/`col'_`year'"
		
		* Predict outcome
		brain think yhat

		* Root Mean Squared Error
		g mse = (yhat-masculine)^2
		sum mse [aw=_llcpwt], meanonly
		estadd scalar rmse_`year' = int(round(sqrt(r(mean))*1000)) / 1000
		
		* Percent Correct Classifications
		g test = (yhat>${thresh})
		tab test masculine, matcell(test)
		estadd scalar pc_ciswomen_`year' = int(round(test[1,1]/(test[1,1]+test[2,1])*1000)) / 1000
		estadd scalar pc_cismen_`year' = int(round(test[2,2]/(test[1,2]+test[2,2])*1000)) / 1000
		estadd scalar pc_`year'=int(round((test[1,1]+test[2,2])/(test[1,1]+test[2,1]+test[1,2]+test[2,2])*1000))/1000
		
		* N
		tab masculine, matcell(obs)	
		estadd scalar N_ciswomen_`year' = obs[1,1]
		estadd scalar N_cismen_`year' = obs[2,1]
	}
	
	
	* Estimator
	if substr("`col'",1,2)=="nn"{
		estadd local estimator = "Neural network"
	}
	estadd local layers = substr("`col'",6,1)			// Number of hidden layers is saved as last number nn_X_Y
	local m = scalar(substr("`col'",4,1))					// Node multiplier is saved as first number	of nn_X_Y
	estadd scalar nodes1=round((colsof(input)+2)/2+1)*`m'		// (number of attributes + number of classes)/2 + 1
	estadd scalar nodes2=round(round((colsof(input)+2)/2+1)*`m'/2)
	
	* Data type
	estadd local data = "`d'"
	
	* Blank row for table labels 
	estadd local blank=""		
	local colpost="`colpost' & (`c')"
	local h_c = `c'/2		// use to add column header over each half of columns: "Training" and "Validation"
	local h_c_1 = `c'/2+1		// use to add column header over each half of columns: "Training" and "Validation"
	local h_c_2 = `c'/2+3	// use to add column header over each half of columns: "Training" and "Validation"
	local l_c = `c'+2
}

}

}

* Save Table
esttab col1 col2 col3 col4 col5 col6 col7 col8 col_blank col9 col10 col11 col12 col13 col14 col15 col16 using Tables_and_Figures/NN_validation.tex,	///
	stats(																		///
		blank rmse_2014 pc_2014 pc_ciswomen_2014 pc_cismen_2014 N_ciswomen_2014 N_cismen_2014	/// 2014 ROWS
		blank rmse_2015 pc_2015 pc_ciswomen_2015 pc_cismen_2015 N_ciswomen_2015 N_cismen_2015	/// 2015 ROWS
		blank rmse_2016 pc_2016 pc_ciswomen_2016 pc_cismen_2016 N_ciswomen_2016 N_cismen_2016	/// 2016 ROWS
		blank rmse_2017 pc_2017 pc_ciswomen_2017 pc_cismen_2017 N_ciswomen_2017 N_cismen_2017	/// 2017 ROWS
		estimator layers nodes1 nodes2,											///
		label(																	/// ROW LABELS
			"\addlinespace[0.3cm]\underline{\textit{2014}}" 					/// ROW LABEL 1
			"\addlinespace[0.1cm]\hspace{.25cm}$\sqrt{MSE}$" 					/// ROW LABEL 2
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct" 						/// ROW LABEL 3
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct ciswomen" 			/// 
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct cismen" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Observations ciswomen" 			/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Observations cismen" 			/// 			
			"\addlinespace[0.3cm]\underline{\textit{2015}}" 					///
			"\addlinespace[0.1cm]\hspace{.25cm}$\sqrt{MSE}$" 					///
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct" 						///
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct ciswomen" 			/// 
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct cismen" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Observations ciswomen" 			/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Observations cismen" 			/// 
			"\addlinespace[0.3cm]\underline{\textit{2016}}" 					///
			"\addlinespace[0.1cm]\hspace{.25cm}$\sqrt{MSE}$" 					///
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct" 						///
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct ciswomen" 			/// 
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct cismen" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Observations ciswomen" 			/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Observations cismen" 			/// 
			"\addlinespace[0.3cm]\underline{\textit{2017}}" 					///
			"\addlinespace[0.1cm]\hspace{.25cm}$\sqrt{MSE}$" 					///
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct" 						///
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct ciswomen" 			/// 
			"\addlinespace[0.1cm]\hspace{.25cm}\% Correct cismen" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Observations ciswomen" 			/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Observations cismen" 			/// 
			"\addlinespace[0.3cm] \midrule Estimator"							/// 
			"\addlinespace[0.1cm]Hidden layers"									/// 
			"\addlinespace[0.1cm]Nodes in first layer"							///
			"\addlinespace[0.1cm]Nodes in second layer"							/// 
			)																	///
		)																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines nolines nonum		///
	prehead(\begin{tabular}{l*{`h_c'}{x{1.25cm}}x{.25cm}*{`h_c'}{x{1.25cm}}} \toprule) 	///
	posthead( 																	///
		& \multicolumn{`h_c'}{c}{Training} & & \multicolumn{`h_c'}{c}{Validation}	/// COLUMN LABELS "TRAINING"/VALIDATION
		\\ \cmidrule(lr){2-`h_c_1'} \cmidrule(lr){`h_c_2'-`l_c'}					/// UNDERLINES "TRAINING" AND "VALIDATION" COLUMNS
		`colpost' \\\midrule)													/// COLUMN NUMBERS
	postfoot(\bottomrule \end{tabular}) 



