
*****************************************************
  // 1) Open dataset and store dummy regression
*****************************************************

* Setup
clear all
set more off
cd "${path}"
eststo clear

* Program P-Value
cap program drop pvalue
program pvalue, rclass
	version 15
	syntax  anything
	local p=`1'
	local star=" "
	if `p'<=.1{
		local star="\$^{*}\$"
		}
	if `p'<=.05{
		local star="\$^{**}\$"
		}
	if `p'<=.01{
		local star="\$^{***}\$"
		}
	return local star="`star'"
	end	

* Open data
use "Data\DTA\final.dta", clear

* Start counters
local c=0

* Store genders
local genders = "fem_cismen masc_ciswomen fem_ciswomen masc_masc_m2f masc_fem_m2f fem_masc_m2f fem_fem_m2f masc_masc_f2m masc_fem_f2m fem_masc_f2m fem_fem_f2m masc_masc_non masc_fem_non fem_masc_non fem_fem_non"	
g masc_masc_m2f = (m2f == 1 & sex == 1 & express >${thresh})
g fem_masc_m2f = (m2f == 1 & sex == 1 & express <=${thresh})
g masc_fem_m2f = (m2f == 1 & sex == 2 & express >${thresh})
g fem_fem_m2f = (m2f == 1 & sex == 2 & express <=${thresh})
g masc_masc_f2m = (f2m == 1 & sex == 1 & express >${thresh})
g fem_masc_f2m = (f2m == 1 & sex == 1 & express <=${thresh})
g masc_fem_f2m = (f2m == 1 & sex == 2 & express >${thresh})
g fem_fem_f2m = (f2m == 1 & sex == 2 & express <=${thresh})
g masc_masc_non = (non == 1 & sex == 1 & express >${thresh})
g fem_masc_non = (non == 1 & sex == 1 & express <=${thresh})
g masc_fem_non = (non == 1 & sex == 2 & express >${thresh})
g fem_fem_non = (non == 1 & sex == 2 & express <=${thresh})	


**********************************************
  // 2) Save regression estimates to table
**********************************************

* Loop outcomes
local coltitle=""
foreach outcome in laborforce employ unemploy { 
	
	* Index column
	local c = `c' + 1

	* Estimate regression
	reghdfe `outcome' `genders' [aweight=_llcpwt] , vce(cluster _psu) a($X)
	eststo col`c'
	estadd local blank=""	
	estadd local col="(`c')"
	
	* Save estimate for each gender
	foreach g in `genders' {
		
		* Beta
		local beta = int(round(_b[`g']*1000))/1000
		quietly test `g'
		pvalue r(p)
		local star=r(star)	
		estadd local `g' "`beta'`star'" 
		
		* Standard error
		local se = int(round(_se[`g']*1000))/1000
		estadd local `g'_se "(`se')" 
		
	}
	
	* Column title
	if "`outcome'" == "laborforce"{
		estadd local coltitle "Labor force participation"
	}
	if "`outcome'" == "employ"{
		estadd local coltitle "Employment"
	}
	if "`outcome'" == "unemploy"{
		estadd local coltitle "Unemployment"
	}
	
}



*******************************************
  // 3) Save benchmark estimates table
*******************************************

esttab col1 col2 col3 using Tables_and_Figures/benchmark_exp_perc.tex,			///
	stats(																		///
		col coltitle															/// Column tiles
		blank fem_cismen fem_cismen_se											/// Cismen rows
		blank masc_ciswomen masc_ciswomen_se fem_ciswomen fem_ciswomen_se		/// Ciswomen rows
		blank masc_masc_m2f masc_masc_m2f_se masc_fem_m2f masc_fem_m2f_se 		///
			fem_masc_m2f fem_masc_m2f_se fem_fem_m2f fem_fem_m2f_se				/// M2F rows
		blank masc_masc_f2m masc_masc_f2m_se masc_fem_f2m masc_fem_f2m_se 		///
			fem_masc_f2m fem_masc_f2m_se fem_fem_f2m fem_fem_f2m_se				/// F2M rows
		blank masc_masc_non masc_masc_non_se masc_fem_non masc_fem_non_se 		///
			fem_masc_non fem_masc_non_se fem_fem_non fem_fem_non_se				/// Nonconforming rows
		N r2,																	/// Bottom rows
		fmt(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2)	/// Rounding
		label(																	/// ROW LABELS
			" "																	///
			"\midrule \textbf{Dependent variable:}"								/// 
			"\midrule \underline{\textit{Cismen}}" 								/// ROW LABEL 1
			"\hspace{.25cm}Feminine expression"									/// ROW LABEL 2
			" "																	///
			"\underline{\textit{Ciswomen}}" 									/// 
			"\hspace{.25cm}Masculine expression"								///
			" "																	///
			"\hspace{.25cm}Feminine expression"									///
			" "																	///
			"\underline{\textit{Transwomen}}" 									/// 
			"\hspace{.25cm}Masculine expression, masculine perception"			///
			" "																	///
			"\hspace{.25cm}Masculine expression, feminine perception"			///
			" "																	///
			"\hspace{.25cm}Feminine expression, masculine perception"			///
			" "																	///
			"\hspace{.25cm}Feminine expression, feminine perception"			///
			" "																	///
			"\underline{\textit{Transmen}}" 									/// 
			"\hspace{.25cm}Masculine expression, masculine perception"			///
			" "																	///
			"\hspace{.25cm}Masculine expression, feminine perception"			///
			" "																	///
			"\hspace{.25cm}Feminine expression, masculine perception"			///
			" "																	///
			"\hspace{.25cm}Feminine expression, feminine perception"			///
			" "																	///
			"\underline{\textit{Gender Nonconforming}}" 						/// 
			"\hspace{.25cm}Masculine expression, masculine perception"			///
			" "																	///
			"\hspace{.25cm}Masculine expression, feminine perception"			///
			" "																	///
			"\hspace{.25cm}Feminine expression, masculine perception"			///
			" "																	///
			"\hspace{.25cm}Feminine expression, feminine perception"			///
			" "																	///
			"\midrule Observations"												/// 
			"\$R^2\$"															/// 
			)																	///
		)																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines nolines nonum		///
	prehead(\begin{tabular}{l*{11}{x{2.4cm}}}\toprule) 							///
	postfoot(\bottomrule \end{tabular}) 

