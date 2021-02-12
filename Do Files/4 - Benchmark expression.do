
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
local genders = "fem_cismen masc_ciswomen fem_ciswomen masc_m2f fem_m2f masc_f2m fem_f2m masc_non fem_non"	

**********************************************
  // 2) Save regression estimates to table
**********************************************

* Loop outcomes
local coltitle=""
foreach outcome in laborforce employ unemploy homemaker poverty { 
	
	* Index column
	local c = `c' + 1
	local colpost="`colpost' & (`c')"

	* Estimate regression
	reghdfe `outcome' `genders' [aweight=_llcpwt] , vce(cluster _psu) a($X)
	eststo col`c'
	estadd local blank=""	
	
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
		estadd local coltitle "Labor force"
	}
	if "`outcome'" == "employ"{
		estadd local coltitle "Employment"
	}
	if "`outcome'" == "unemploy"{
		estadd local coltitle "Unemployment"
	}
	if "`outcome'" == "homemaker"{
		estadd local coltitle "Homemaker"
	}
	if "`outcome'" == "poverty"{
		estadd local coltitle "Poverty"
	}
	
	
}



*******************************************
  // 3) Save benchmark estimates table
*******************************************


esttab col1 col2 col3 col4 col5	using Tables_and_Figures/benchmark_exp.tex,	///
	stats(																		///
		blank fem_cismen fem_cismen_se											/// Cismen rows
		blank masc_ciswomen masc_ciswomen_se fem_ciswomen fem_ciswomen_se		/// Ciswomen rows
		blank masc_m2f masc_m2f_se fem_m2f fem_m2f_se							/// M2F rows
		blank masc_f2m masc_f2m_se fem_f2m fem_f2m_se							/// F2M rows
		blank masc_non masc_non_se fem_non fem_non_se							/// Nonconforming rows
		coltitle N r2,															/// Bottom rows
		fmt(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2)				/// Rounding
		label(																	/// ROW LABELS
			"\underline{\textit{Cismen}}" 										/// ROW LABEL 1
			"\hspace{.25cm}Feminine expression"									/// ROW LABEL 2
			" "																	///
			"\underline{\textit{Ciswomen}}" 									/// 
			"\hspace{.25cm}Masculine expression"								///
			" "																	///
			"\hspace{.25cm}Feminine expression"									///
			" "																	///
			"\underline{\textit{Transwomen}}" 									/// 
			"\hspace{.25cm}Masculine expression"								///
			" "																	///
			"\hspace{.25cm}Feminine expression"									///
			" "																	///
			"\underline{\textit{Transmen}}" 									/// 
			"\hspace{.25cm}Masculine expression"								///
			" "																	///
			"\hspace{.25cm}Feminine expression"									///
			" "																	///
			"\underline{\textit{Gender Nonconforming}}" 						/// 
			"\hspace{.25cm}Masculine expression"								///
			" "																	///
			"\hspace{.25cm}Feminine expression"									///
			" "																	///
			"\midrule Dependent variable"										/// 
			"Observations"														/// 
			"\$R^2\$"															/// 
			)																	///
		)																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines nolines nonum		///
	prehead(\begin{tabular}{l*{11}{x{1.75cm}}}\toprule) 							///
	posthead(`colpost' \\\midrule)												/// COLUMN NUMBERS
	postfoot(\bottomrule \end{tabular}) 

