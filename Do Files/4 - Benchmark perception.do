
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
local genders = "ciswomen masc_m2f fem_m2f masc_f2m fem_f2m masc_non fem_non"	
drop fem_* masc_*
g masc_m2f = (m2f == 1 & sex == 1)
g fem_m2f = (m2f == 1 & sex == 2)
g masc_f2m = (f2m == 1 & sex == 1)
g fem_f2m = (f2m == 1 & sex == 2)
g masc_non = (non == 1 & sex == 1)
g fem_non = (non == 1 & sex == 2)	

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
	
	* column title
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

esttab col1 col2 col3 using Tables_and_Figures/benchmark_perc.tex,				///
	stats(																		///
		col coltitle															/// Column tiles
		ciswomen ciswomen_se 													/// Ciswomen rows
		blank masc_m2f masc_m2f_se fem_m2f fem_m2f_se							/// M2F rows
		blank masc_f2m masc_f2m_se fem_f2m fem_f2m_se							/// F2M rows
		blank masc_non masc_non_se fem_non fem_non_se							/// Nonconforming rows
		N r2,																	/// Bottom rows
		fmt(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2)							/// Rounding
		label(																	/// ROW LABELS
			" "																	///
			"\midrule \textbf{Dependent variable:}"								/// 
			"\midrule Ciswomen" 												/// 
			" "																	///
			"\underline{\textit{Transwomen}}" 									/// 
			"\hspace{.25cm}Masculine perception"								///
			" "																	///
			"\hspace{.25cm}Feminine perception"									///
			" "																	///
			"\underline{\textit{Transmen}}" 									/// 
			"\hspace{.25cm}Masculine perception"								///
			" "																	///
			"\hspace{.25cm}Feminine perception"									///
			" "																	///
			"\underline{\textit{Gender Nonconforming}}" 						/// 
			"\hspace{.25cm}Masculine perception"								///
			" "																	///
			"\hspace{.25cm}Feminine perception"									///
			" "																	///
			"\midrule Observations"												/// 
			"\$R^2\$"															/// 
			)																	///
		)																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines nolines nonum		///
	prehead(\begin{tabular}{l*{11}{x{2.4cm}}}\toprule) 							///
	postfoot(\bottomrule \end{tabular}) 

