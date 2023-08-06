cd "${path}"
use "Data\DTA\final.dta", clear

local genders = "fem_cismen masc_ciswomen fem_ciswomen masc_m2f fem_m2f inc_m2f masc_f2m fem_f2m inc_f2m masc_non fem_non inc_non"	

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

* Program to save space
cap program drop _store
program _store
	syntax [, genders(varlist) outcome(varlist)]
	eststo
	
	* Save estimate for each gender
	foreach g in `genders' {
		local se = int(round(_se[`g']*1000))/1000
		local beta = int(round(_b[`g']*1000))/1000
		quietly test `g'
		pvalue r(p)
		local star=r(star)	
		estadd local `g' "`beta'`star'"
		estadd local `g'_se "(`se')"
	}
	
	* Column title
	if "`outcome'" == "laborforce"{
		estadd local coltitle "Labor force participation"
	}
	if "`outcome'" == "employed"{
		estadd local coltitle "Employment"
	}
	if "`outcome'" == "unemployed"{
		estadd local coltitle "Unemployment"
	}
	end

* Loop outcomes for each table
foreach var in laborforce employed unemployed{
	
	* Specification 1
	eststo clear
	reghdfe `var' `genders' [aweight=_llcpwt], vce(cluster _psu) noabsorb
	_store , genders(`genders') outcome(`var')
	local c=1
	estadd local col = "(`c')"
	estadd local cell = ""
	estadd local state = ""
	estadd local time = ""
	estadd local metro = ""
	estadd local race = ""
	estadd local age = ""
	estadd local edu = ""
	estadd local sexi = ""
	estadd local mari = ""
	
	* Specification 2
	reghdfe `var' `genders' [aweight=_llcpwt], vce(cluster _psu) 				///
	a(numadult#cellphone)
	_store , genders(`genders') outcome(`var')
	local c=`c'+1
	estadd local col = "(`c')"
	estadd local cell = "\checkmark"
	estadd local state = ""
	estadd local time = ""
	estadd local metro = ""
	estadd local race = ""
	estadd local age = ""
	estadd local edu = ""
	estadd local sexi = ""
	estadd local mari = ""
	
	* Specification 3
	reghdfe `var' `genders' [aweight=_llcpwt], vce(cluster _psu) 				///
	a(numadult#cellphone state time metro)
	_store , genders(`genders') outcome(`var')
	local c=`c'+1
	estadd local col = "(`c')"
	estadd local cell = "\checkmark"
	estadd local state = "\checkmark"
	estadd local time = "\checkmark"
	estadd local metro = "\checkmark"
	estadd local race = ""
	estadd local age = ""
	estadd local edu = ""
	estadd local sexi = ""
	estadd local mari = ""
	
	* Specification 4
	reghdfe `var' `genders' [aweight=_llcpwt], vce(cluster _psu) 				///
	a(numadult#cellphone state time metro race age education)
	_store , genders(`genders') outcome(`var')
	local c=`c'+1
	estadd local col = "(`c')"
	estadd local cell = "\checkmark"
	estadd local state = "\checkmark"
	estadd local time = "\checkmark"
	estadd local metro = "\checkmark"
	estadd local race = "\checkmark"
	estadd local age = "\checkmark"
	estadd local edu = "\checkmark"
	estadd local sexi = ""
	estadd local mari = ""
	
	* Specification 5
	reghdfe `var' `genders' [aweight=_llcpwt], vce(cluster _psu) 				///
	a(numadult#cellphone state time metro race age education sexuality marital)
	_store , genders(`genders') outcome(`var')
	local c=`c'+1
	estadd local col = "(`c')"
	estadd local cell = "\checkmark"
	estadd local state = "\checkmark"
	estadd local time = "\checkmark"
	estadd local metro = "\checkmark"
	estadd local race = "\checkmark"
	estadd local age = "\checkmark"
	estadd local edu = "\checkmark"
	estadd local sexi = "\checkmark"
	estadd local mari = "\checkmark"
		
	esttab est1 est2 est3 est4 est5 using Tables_and_Figures/`var'_controls.tex,		///
	stats(																		///
		col																		/// Column titles
		blank fem_cismen fem_cismen_se											/// Cismen row
		blank masc_ciswomen masc_ciswomen_se fem_ciswomen fem_ciswomen_se		/// Ciswomen row
		blank masc_m2f masc_m2f_se fem_m2f fem_m2f_se inc_m2f inc_m2f_se		/// M2F row
		blank masc_f2m masc_f2m_se fem_f2m fem_f2m_se inc_f2m inc_f2m_se		/// F2M rows
		blank masc_non masc_non_se fem_non fem_non_se inc_non inc_non_se		/// Nonconforming rows
		N cell state time metro race age edu sexi mari,							/// Bottom rows
		fmt(0)																	/// Rounding
		label(																	/// ROW LABELS
			" "																	///
			"\midrule\underline{\textit{Cismen}}" 								/// ROW LABEL 1
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine"						///
			" "																	///
			"\addlinespace[0.3cm]\underline{\textit{Ciswomen}}" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine"						///
			" "																	///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine"						///
			" "																	///
			"\addlinespace[0.3cm]\underline{\textit{Transwomen}}" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine"						///
			" "																	///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine"						///
			" "																	///
			"\addlinespace[0.1cm]\hspace{.25cm}Incongruent"						///
			" "																	///
			"\addlinespace[0.3cm]\underline{\textit{Transmen}}" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine"						///
			" "																	///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine"						///
			" "																	///
			"\addlinespace[0.1cm]\hspace{.25cm}Incongruent"						///
			" "																	///
			"\addlinespace[0.3cm]\underline{\textit{Gender nonconforming}}" 	/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Masculine"						///
			" "																	///
			"\addlinespace[0.1cm]\hspace{.25cm}Feminine"						///
			" "																	///
			"\addlinespace[0.1cm]\hspace{.25cm}Incongruent"						///
			" "																	///
			"\addlinespace[0.1cm]\midrule Observations"							/// 
			"Survey-adults interaction"											/// 
			"State fixed effects"												///
			"Time fixed effects"												/// 
			"Metropolitan status"												///
			"Race"																///
			"Age"																///
			"Education"															///
			"Sexuality"															///
			"Marital status"													///
			)																	///
		)																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines nolines nonum		///
	prehead(\begin{tabular}{l*{11}{x{2.5cm}}}\toprule) 							///
	postfoot(\bottomrule \end{tabular})  substitute(_ _ { { } } )

	
}

