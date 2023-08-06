
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
local genders = "fem_cismen masc_ciswomen fem_ciswomen masc_m2f fem_m2f inc_m2f masc_f2m fem_f2m inc_f2m masc_non fem_non inc_non"	

**********************************************
  // 2) Save regression estimates to table
**********************************************

* Loop outcomes
local coltitle=""
foreach outcome in laborforce employed unemployed { 
	
	* Index column
	local c = `c' + 1

	* Estimate regression
	reghdfe `outcome' `genders' [aweight=_llcpwt] , vce(cluster _psu) a($X)
	eststo col`c'
	estadd local blank=""	
	estadd local col ="(`c')"

	* Cismen: Masc-Fem
	lincom fem_cismen
	local se = int(round(r(se)*1000))/1000
	local beta = int(round(r(estimate)*1000))/1000
	pvalue r(p)
	local star=r(star)	
	estadd local m_f_cism "`beta'`star' (`se')" 

	* Ciswomen: Masc-Fem
	lincom masc_ciswomen-fem_ciswomen
	local se = int(round(r(se)*1000))/1000
	local beta = int(round(r(estimate)*1000))/1000
	pvalue r(p)
	local star=r(star)	
	estadd local m_f_cisw "`beta'`star' (`se')" 
	
	foreach g in m2f f2m non{
		* `g': Masc-Fem
		lincom masc_`g'-fem_`g'
		local se = int(round(r(se)*1000))/1000
		local beta = int(round(r(estimate)*1000))/1000
		pvalue r(p)
		local star=r(star)	
		estadd local m_f_`g' "`beta'`star' (`se')" 	

		* `g': Masc-Inc
		lincom masc_`g'-inc_`g'
		local se = int(round(r(se)*1000))/1000
		local beta = int(round(r(estimate)*1000))/1000
		pvalue r(p)
		local star=r(star)	
		estadd local m_i_`g' "`beta'`star' (`se')" 		
		
		* `g': Masc-Inc
		lincom fem_`g'-inc_`g'
		local se = int(round(r(se)*1000))/1000
		local beta = int(round(r(estimate)*1000))/1000
		pvalue r(p)
		local star=r(star)	
		estadd local f_i_`g' "`beta'`star' (`se')" 
	}
	
	* column title
	if "`outcome'" == "laborforce"{
		estadd local coltitle "Labor force participation"
	}
	if "`outcome'" == "employed"{
		estadd local coltitle "Employment"
	}
	if "`outcome'" == "unemployed"{
		estadd local coltitle "Unemployment"
	}
	
}



*******************************************
  // 3) Save benchmark estimates table
*******************************************

esttab col1 col2 col3 using Tables_and_Figures/baseline_within.tex,				///
	stats(																		///
		col coltitle															/// Column titles
		blank m_f_cism															/// Cismen row
		blank m_f_cisw															/// Ciswomen row
		blank m_f_m2f m_i_m2f f_i_m2f 											/// M2F row
		blank m_f_f2m m_i_f2m f_i_f2m 											/// F2M rows
		blank m_f_non m_i_non f_i_non											/// Nonconforming rows
		N,																		/// Bottom rows
		fmt(0)																	/// Rounding
		label(																	/// ROW LABELS
			" "																	///
			"\midrule \textbf{Dependent variable:}"								///
			"\midrule\underline{\textit{Cismen}}" 								/// ROW LABEL 1
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine - Feminine"			///
			"\addlinespace[0.3cm]\underline{\textit{Ciswomen}}" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine - Feminine"			///
			"\addlinespace[0.3cm]\underline{\textit{Transwomen}}" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine - Feminine"			///
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine - Incongruent"			///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine - Incongruent"			///
			"\addlinespace[0.3cm]\underline{\textit{Transmen}}" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine - Feminine"			///
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine - Incongruent"			///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine - Incongruent"			///
			"\addlinespace[0.3cm]\underline{\textit{Gender nonconforming}}" 	/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine - Feminine"			///
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine - Incongruent"			///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine - Incongruent"			///
			"\addlinespace[0.1cm]\midrule Observations"							/// 
			)																	///
		)																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines nolines nonum		///
	prehead(\begin{tabular}{l*{11}{x{2.5cm}}}\toprule) 							///
	postfoot(\bottomrule \end{tabular})  substitute(_ _ { { } } )

