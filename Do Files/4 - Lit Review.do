
*****************************************************
  // 1) Open dataset and store dummy regression
*****************************************************

* Setup
clear all
set more off
cd "${path}"

* List state-years in BRFSS sample
use "Data\DTA\final.dta", clear
keep state year
duplicates drop
tempfile temp
save `temp'

* Open CPS, remove state-year not in BRFSS sample
use "Data/DTA/CPS.dta", clear
merge m:1 state year using `temp', keep(3)

* Dummy regression to store results for table
eststo clear
reg year
est store dummy

* Blank column
eststo col_blank

* Start counters
local c=0

******************************
  // 2) Save CPS estimates
******************************

* Loop Gender
local col=9
foreach gender in cismen ciswomen { 
	
	* Index column
	local c = `c' + 1
	local col=`col'+1
	est restore dummy
	eststo col`c'
	estadd local col="(`col')"
	estadd local blank=""	
		
	* Loop indicators rows
	foreach var in disabled employed unemployed no_lfp _18 _25 _45 _64 hispanic	///
	white black native asian biracial lt_high_school high_school some_college	///
	college graduate marital {
	
		* Save Percent
		sum `var' [aw=pwsswgt] if `gender' == 1, meanonly
		estadd scalar `var' = int(round(r(mean)*1000)) / 10
		
	}
	
	* Loop over continuous
	foreach var in children age {
	
		* Save Mean
		sum `var' [aw=pwsswgt] if `gender' == 1
		estadd scalar `var' = int(round(r(mean)*10)) / 10
		
		* Save Standard deviation
		tempname scs
		local sd = int(round(r(sd)*10)) / 10
		estadd local `var'_sd = "(`sd')"

	}	

	* Save Count of cismen and women
	sum `gender' [aw=pwsswgt] if `gender' == 1
	estadd scalar obs = r(N)
	
	* Years and source
	estadd local years = "2014-2017"
	estadd local source = "Author"
	local g = proper("`gender'")
	estadd local gender = "`g'"

}

*******************************************************
  // 3) BRFSSS variables to match previous research
*******************************************************

use "Data/DTA/BRFSS_Pooled.dta", clear

* Gender identity
rename trnsgndr trans
gen cismen=(sex==1&trans>3)
replace cismen=. if sex==.
gen ciswomen=(sex==2&trans>3)
replace ciswomen=. if sex==.
gen m2f=(trans==1)
gen f2m=(trans==2)
gen non=(trans==3)
gen cis=(cismen==1|ciswomen==1)

/* Gender Incongruence */
g incongruence = (f2m == 1 & sex == 2 | m2f == 1 & sex ==1)
replace incongruence = . if sex == 9 | sex == .

/* Employment */
gen homemaker = (employ1 == 5)
replace homemaker=. if inlist(employ1, 9, .)
gen employed = inlist(employ1,1,2)
replace employed=. if inlist(employ1, 9, .)
gen laborforce = inlist(employ1, 1, 2, 3, 4)
replace laborforce = . if inlist(employ1, 9, .)
gen unemployed = inlist(employ1, 3, 4)
replace unemployed = . if inlist(employ1, 9, .)
g no_lfp = inlist(laborforce, 0)
replace no_lfp = . if inlist(laborforce, 9, .)

/* Age */
g _18 = ( _ageg5yr == 1 )
g _25 = ( _ageg5yr == 2 | _ageg5yr == 3 | _ageg5yr == 4 | _ageg5yr == 5 )
g _45 = ( _ageg5yr == 6 | _ageg5yr == 7 | _ageg5yr == 8 | _ageg5yr == 9 )
g _64 = ( _ageg5yr >= 10 )
foreach v in _18 _25 _45 _64 {
	replace `v' = . if _ageg5yr == .
}
rename _age80 age

/* Race */
g white = _race == 1
g black = _race == 2
g native = _race == 3
g asian = _race == 4 | _race == 5
g biracial = _race == 6 | _race == 7
g hispanic = _race == 8
foreach v in white black native asian biracial hispanic{
	replace `v' = . if _race == .
}

/* Education */
g lt_high_school = ( _educag == 1 )
g high_school = ( _educag == 2 )
g some_college = ( _educag == 3 )
g college = ( _educag == 4 )
foreach v in lt_high_school high_school some_college college {
	replace `v' = . if _educag == .
}

/* Marital Status */
recode marital (2/9=0)

/* Children */
recode children (88=0) (99=.)

*****************************************
  // 4) Save BRFSS Estimates to table
*****************************************

* Loop Gender
local col=0
foreach gender in cismen ciswomen m2f f2m non { 
	
	* Index column
	local c = `c' + 1
	local col=`col'+1
	est restore dummy
	eststo col`c'
	estadd local col="(`col')"
	estadd local blank=""	
	
	* Loop indicators rows
	foreach var in employed unemployed no_lfp _18 _25 _45 _64 hispanic white 	///
	black native asian	biracial lt_high_school high_school some_college 		///
	college marital {
	
		* Save Percent
		sum `var' [aw=_llcpwt] if `gender' == 1, meanonly
		estadd scalar `var' = int(round(r(mean)*1000)) / 10
		
	}
	
	* Incongruence only defined for binary trans respondents in brfss
	if "`gender'"=="m2f" | "`gender'"=="f2m" {
		sum incongruence [aw=_llcpwt] if `gender' == 1, meanonly
		estadd scalar incongruence = int(round(r(mean)*1000)) / 10
	}
	
	* Loop over continuous
	foreach var in children age {
	
		* Save Mean
		sum `var' [aw=_llcpwt] if `gender' == 1
		estadd scalar `var' = int(round(r(mean)*10)) / 10
		
		* Save Standard deviation
		tempname scs
		local sd = int(round(r(sd)*10)) / 10
		estadd local `var'_sd = "(`sd')"

	}	

	* Save Count by gender identity
	sum `gender' [aw=_llcpwt] if `gender' == 1
	estadd scalar obs = r(N)
	
	* Years and source
	estadd local years = "2014-2017"
	estadd local source = "Author"
	local g = proper("`gender'")
	estadd local gender = "`g'"
}


******************************************************
  // 5) Save Leppel (2016, 2019) estimate to table
******************************************************

/***** NDTS Transwomen *****/

* Index column
local c = `c' + 1
local col=`col'+1
est restore dummy
eststo col`c'
estadd local col="(`col')"
estadd local blank=""

* Employment
estadd scalar no_lfp =  22
estadd scalar unemployed = 11 
estadd scalar employed = 67

* Race
estadd scalar native = 6.2
estadd scalar asian = 3.5
estadd scalar black = 5.1
estadd scalar hispanic = 4.9

* Education
estadd scalar nobach = 56.6
estadd scalar college = 24.2
estadd scalar graduate = 19.2

* Other
estadd scalar disabled = 30.0
estadd scalar marital = 39.2
estadd scalar incongruence = 18.1 
estadd scalar children = 0.365
estadd local children_sd = "(0.8)"
estadd scalar age = 42.2
estadd local age_sd = "(13.2)"
estadd scalar obs = 1948
estadd local years = "2008"
estadd local source = "Leppel (2016)"
estadd local gender = "M2F"

/***** NDTS Transmen *****/

* Index column
local c = `c' + 1	
local col=`col'+1
est restore dummy
eststo col`c'
estadd local col="(`col')"
estadd local blank=""

* Employment
estadd scalar no_lfp = 15
estadd scalar unemployed = 10
estadd scalar employed = 75

* Race
estadd scalar native = 5.9
estadd scalar asian = 3.6
estadd scalar black = 5.7
estadd scalar hispanic = 7.7

* Education
estadd scalar nobach = 48.6
estadd scalar college = 29.9
estadd scalar graduate = 21.5

* Other
estadd scalar disabled = 29.9
estadd scalar marital = 56.5
estadd scalar incongruence = 15.4
estadd scalar children = 0.222
estadd local children_sd = "(0.7)"
estadd scalar age = 31.8
estadd local age_sd = "(9.7)"
estadd scalar obs = 1323
estadd local years = "2008"
estadd local source = "Leppel (2016)"
estadd local gender = "F2M"

/***** USTS Transwomen *****/

* Index column
local c = `c' + 1
local col=`col'+1
est restore dummy
eststo col`c'
estadd local col="(`col')"
estadd local blank=""

* Employment
estadd scalar no_lfp = 21.9
estadd scalar unemployed = 12.2
estadd scalar employed = 65.9

* Age
estadd scalar _18 = 22.6
estadd scalar _25 = 43.7
estadd scalar _45 = 27.8
estadd scalar _64 = 5.9

* Race
estadd scalar native = 1.2
estadd scalar asian = 2.4
estadd scalar biracial = 3.6
estadd scalar black = 2.6
estadd scalar hispanic = 4.5
estadd scalar white = 85.6

* Education
estadd scalar lt_high_school = 2.7
estadd scalar high_school = 11.6
estadd scalar some_college = 45.7
estadd scalar college = 26.0
estadd scalar graduate = 14.0

* Other
estadd scalar marital = 22.7
estadd scalar disabled = 21.5
estadd scalar incongruence = 19.1
estadd scalar children = 0.218
estadd local children_sd = "(0.7)"
estadd scalar obs = 9047 
estadd local years = "2015"
estadd local source = "Leppel (2019)"
estadd local gender = "M2F"

/***** USTS Transmen *****/

* Index column
local c = `c' + 1
local col=`col'+1
est restore dummy
eststo col`c'
estadd local col="(`col')"
estadd local blank=""

* Employment
estadd scalar no_lfp = 19.0
estadd scalar unemployed = 12.6
estadd scalar employed = 68.5

* Age
estadd scalar _18 = 46.8
estadd scalar _25 = 43.6
estadd scalar _45 = 9.2
estadd scalar _64 = 0.4

* Race
estadd scalar native = 1.4
estadd scalar asian = 2.6
estadd scalar biracial = 5.8
estadd scalar black = 3.4
estadd scalar hispanic = 6.1
estadd scalar white = 80.7

* Education
estadd scalar lt_high_school = 3.5
estadd scalar high_school = 13.8
estadd scalar some_college = 45.6
estadd scalar college = 23.1
estadd scalar graduate = 14.1

* Other
estadd scalar marital = 17.1
estadd scalar disabled = 25.1
estadd scalar incongruence = 10.3
estadd scalar children = 0.220
estadd local children_sd = "(0.6)"
estadd scalar obs = 7871
estadd local years = "2015"
estadd local source = "Leppel (2019)"
estadd local gender = "F2M"



****************************************
  // 6) Save literature review table
****************************************


esttab col3 col4 col5 col6 col7 col8 col9 col10 col11 col1 col2 				///
	using Tables_and_Figures/lit_review.tex,									///
	stats(																		///
		gender col blank blank no_lfp unemployed employed 							/// Labor force rows
		blank _18 _25 _45 _64													/// Age rows
		blank native asian biracial black hispanic white						/// Race rows
		blank lt_high_school high_school some_college nobach college graduate	/// Education rows
		marital disabled incongruence											/// Other categorical rows
		blank age age_sd children children_sd									/// Continuous wows
		obs years source,														/// Bottom rows
		fmt(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0)	/// Rounding
		label(																	/// ROW LABELS
			" "																	/// 
			" "																	///
			"\midrule\addlinespace[0.3cm]\underline{\textit{Percentages}}" 		/// ROW LABEL 1
			"\addlinespace[0.3cm]Labor force status"							/// ROW LABEL 2
			"\addlinespace[0.1cm]\hspace{.25cm}Not in the labor force" 			/// ROW LABEL 3...
			"\addlinespace[0.1cm]\hspace{.25cm}Unemployed" 						/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Employed" 						/// 
			"\addlinespace[0.3cm]Age"											/// 
			"\addlinespace[0.1cm]\hspace{.25cm}18 to 24" 						/// 			
			"\addlinespace[0.1cm]\hspace{.25cm}25 to 44" 						///
			"\addlinespace[0.1cm]\hspace{.25cm}45 to 64" 						///
			"\addlinespace[0.1cm]\hspace{.25cm}65 and older" 					/// 
			"\addlinespace[0.3cm]Race/ethnicity"								/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Alaska Native/American Indian" 	/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Asian/Native Hawaiian/Pacific Islander" 	/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Biracial/Multiracial/Not listed" /// 
			"\addlinespace[0.1cm]\hspace{.25cm}Black" 							/// 		
			"\addlinespace[0.1cm]\hspace{.25cm}Hispanic" 						/// 
			"\addlinespace[0.1cm]\hspace{.25cm}White" 							/// 
			"\addlinespace[0.3cm]Educational attainment"						/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Less than high school" 			///
			"\addlinespace[0.1cm]\hspace{.25cm}High school graduate" 			///
			"\addlinespace[0.1cm]\hspace{.25cm}Some college" 					/// 
			"\addlinespace[0.1cm]\hspace{.25cm}No Bachelor's degree" 			/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Bachelor's degree" 				/// 
			"\addlinespace[0.1cm]\hspace{.25cm}Graduate" 						/// 
			"\addlinespace[0.3cm]Married or partnered"							/// 
			"\addlinespace[0.3cm]Disability"									/// 
			"\addlinespace[0.3cm]Perceived gender incongruence"					/// 
			"\addlinespace[0.3cm]\underline{\textit{Mean (standard deviation)}}"	/// 
			"\addlinespace[0.3cm]Age"											/// 
			"\addlinespace[0.1cm]" 												///
			"\addlinespace[0.3cm]Children"										/// 
			"\addlinespace[0.1cm]" 												///			
			"\addlinespace[0.3cm]\midrule Observations"							/// 
			"\addlinespace[0.1cm]Years"											///
			"\addlinespace[0.1cm]Source"										///
			)																	///
		)																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines nolines nonum		///
	prehead(\begin{tabular}{l*{11}{x{1.45cm}}}\toprule) 						///
	posthead( 																	///
		& \multicolumn{5}{c}{BRFSS} & \multicolumn{2}{c}{NDTS}					/// COLUMN HEADERS
		& \multicolumn{2}{c}{USTS}	& \multicolumn{2}{c}{CPS}					/// COLUMN HEARERS
		\\\cmidrule(lr){2-6}\cmidrule(lr){7-8}\cmidrule(lr){9-10}\cmidrule(lr){11-12}	/// UNDERLINE
		)																		/// 
	postfoot(\bottomrule \end{tabular}) 

