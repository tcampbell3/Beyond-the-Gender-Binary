
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

	* Save estimate for each gender
	foreach g in `genders' {
		
		* Beta (Standard error)
		local se = int(round(_se[`g']*1000))/1000
		local beta = int(round(_b[`g']*1000))/1000
		quietly test `g'
		pvalue r(p)
		local star=r(star)	
		estadd local `g' "`beta'`star' (`se')" 
		
	}
	
	* Test for expression gap in cis sample
	test (fem_cismen=0) (masc_ciswomen=fem_ciswomen)
	local f = int(round(r(F)*1000))/1000
	local df_r = r(df_r)
	local df = r(df)
	local df_exp "($ F_{`df', `df_r'} $)"
	pvalue r(p)
	local star=r(star)	
	estadd local exp "`f'`star'" 

	* Test for traditional cisgender wage gap in trans sample
	test (masc_f2m=fem_f2m) (masc_m2f=fem_m2f)	(masc_non=fem_non)
	local f = int(round(r(F)*1000))/1000
	local df_r = r(df_r)
	local df = r(df)
	local df_cisgap "($ F_{`df', `df_r'} $)"
	pvalue r(p)
	local star=r(star)	
	estadd local cisgap "`f'`star'" 
	
	* Test for incongruence penalty
	test inc_m2f inc_f2m inc_non
	local f = int(round(r(F)*1000))/1000
	local df_r = r(df_r)
	local df = r(df)
	local df_inc "($ F_{`df', `df_r'} $)"
	pvalue r(p)
	local star=r(star)	
	estadd local inc "`f'`star'" 
	
	* Test for dyphoria penalty
	test (masc_m2f) (fem_ciswomen=fem_f2m) 								// gender dysphoria (reject)
	local f = int(round(r(F)*1000))/1000
	local df_r = r(df_r)
	local df = r(df)
	local df_dys "($ F_{`df', `df_r'} $)"
	pvalue r(p)
	local star=r(star)	
	estadd local dys "`f'`star'" 
	
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

esttab col1 col2 col3 using Tables_and_Figures/baseline.tex,					///
	stats(																		///
		col coltitle															/// Column titles
		blank fem_cismen														/// Cismen row
		blank masc_ciswomen fem_ciswomen										/// Ciswomen row
		blank masc_m2f fem_m2f inc_m2f 											/// M2F row
		blank masc_f2m fem_f2m inc_f2m 											/// F2M rows
		blank masc_non fem_non inc_non											/// Nonconforming rows
		N exp cisgap inc dys,													/// Bottom rows
		fmt(0)																	/// Rounding
		label(																	/// ROW LABELS
			" "																	///
			"\midrule \textbf{Dependent variable:}"								///
			"\midrule\underline{\textit{Cismen}}" 								/// ROW LABEL 1
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine"						///
			"\addlinespace[0.3cm]\underline{\textit{Ciswomen}}" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine"						///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine"						///
			"\addlinespace[0.3cm]\underline{\textit{Transwomen}}" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine"						///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine"						///
			"\addlinespace[0.1cm]\hspace{.25cm}Incongruent"						///
			"\addlinespace[0.3cm]\underline{\textit{Transmen}}" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine"						///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine"						///
			"\addlinespace[0.1cm]\hspace{.25cm}Incongruent"						///
			"\addlinespace[0.3cm]\underline{\textit{Gender nonconforming}}" 	/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine"						///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine"						///
			"\addlinespace[0.1cm]\hspace{.25cm}Incongruent"						///
			"\addlinespace[0.1cm]\midrule Observations"							/// 
			"Test 1: Cisgender expression gap `df_exp'"							/// 
			"Test 2: Traditional gap `df_cisgap'"								///
			"Test 3: Incongruence penalty `df_inc'"								/// 
			"Test 4: Gender dysphoria penalty `df_dys'"							/// 
			)																	///
		)																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines nolines nonum		///
	prehead(\begin{tabular}{l*{11}{x{2.5cm}}}\toprule) 							///
	postfoot(\bottomrule \end{tabular})  substitute(_ _ { { } } )

