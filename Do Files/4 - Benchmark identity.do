
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
local genders = "ciswomen m2f f2m non"	

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

esttab col1 col2 col3 using Tables_and_Figures/benchmark_iden.tex,				///
	stats(																		///
		col coltitle ciswomen ciswomen_se										/// Ciswomen rows
		m2f m2f_se																/// M2F rows
		f2m f2m_se																/// F2M rows
		non non_se																/// Nonconforming rows
		N r2,																	/// Bottom rows
		fmt(0 0 0 0 0 0 0 0 0 0 0 2)											/// Rounding
		label(																	/// ROW LABELS
			" "																	///
			"\midrule \textbf{Dependent variable:}"								/// 
			"\midrule Ciswomen" 												/// 
			" "																	///
			"Transwomen" 														/// 
			" "																	///
			"Transmen" 															/// 
			" "																	///
			"Gender Nonconforming"						 						/// 
			" "																	///
			"\midrule Observations"												/// 
			"\$R^2\$"															/// 
			)																	///
		)																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines nolines nonum		///
	prehead(\begin{tabular}{l*{11}{x{2.4cm}}}\toprule) 						///
	postfoot(\bottomrule \end{tabular}) 
