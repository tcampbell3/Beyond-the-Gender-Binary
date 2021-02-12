/*
	****STEPS OF DO FILE****

1) Create the Monthly CPS file

2) Stack the monthly CPS files

3) Keep and relabel variables

*/

************
  //Set up
************
clear
cd "${path}/Data/CPS/"

*******************************************
  // 1) Creating the Monthly CPS Files
*******************************************

forvalues year=14/17{
	local m=1
	foreach month in jan feb mar apr may jun jul aug sep oct nov dec {
		
		//Drop current label def's
		label drop _all
		
		/* The following line should contain the path to your output '.dat' file */
		
		global dat_name "`month'`year'pub.dat" 
		
		/* The following line should contain the path to your output '.dta' file */

		global dta_name "cpsb20`year'_`m'.dta"

		/* The following line should contain the path to the data dictionary `.dct' and `.do' files */
        
		cap confirm file "cpsb`month'20`year'.do" //verifies file exists
		if _rc==0{
			global dct_name "cpsb`month'20`year'.dct" 
			global do_name  "cpsb`month'20`year'.do" //Note: Must edit first 3 lines of data dictionary do's mannuelly for file paths
		}
		
		/* Create the Monthly Data */
	
		cap confirm file "`month'`year'pub.zip" //verifies file exists
		if _rc==0{
			unzipfile "`month'`year'pub.zip", replace
			do "${do_name}"
			cap erase  "`month'`year'pub.dat"
		}
		local m=`m'+1
	}
}

				
				
*****************************
  // 2) Stack Monthy Data
*****************************

forvalues year=14/17{
	forvalues month=1/12{
		if `year'==14&`month'==1{
			use "cpsb20`year'_`month'.dta", clear
		}
		else{
			append using "cpsb20`year'_`month'.dta" 
		}
		cap erase "cpsb20`year'_`month'.dta" 
	}
}

*****************************
  // 3) Keep Variables
*****************************

/* Gender */
g sex = pesex
recode sex (-1=.)
g cismen = ( sex == 1 )
g ciswomen = ( sex == 2 )
foreach v in cismen ciswomen {
	replace `v' = . if sex == .
}

/* Disability */
cap drop disabled
g disabled = ( pudis == 1 | pudis == 2 | pemlr ==6 | puwk == 4 | puabsot == 4 | pulay == 4 | pulk == 4 | pedwwnto == 4)
sum disabled

/* Employment */
g employment = pemlr
recode employment (-1=.) (1 2 = 1) (3 4 = 2) (5 6 7 = 3)
label define label_employment 1 "Employed" 2 "Unemployed" 3 "Not in the labor force", replace
label values employment label_employment
g employed = (employment == 1)
g unemployed = (employment == 2)
g no_lfp = (employment == 3)
foreach v in employed unemployed no_lfp {
	replace `v' = . if employment == .
}

/* Age */
g age = prtage
g _18 = ( age >= 18 & age <= 24 )
g _25 = ( age >= 25 & age <= 54 )
g _45 = ( age >= 45 & age <= 64 )
g _64 = ( age >= 64 )
foreach v in _18 _25 _45 _64 {
	replace `v' = . if age == .
}

/* Race */
g race = ptdtrace
recode race (-1=.)
g hispanic = ( pehspnon == 1 & race < 6 )
g white = ( race == 1 & hispanic == 0 )
g black = ( race == 2 & hispanic == 0 )
g native = ( race == 3 & hispanic == 0 )
g asian = ( race == 4 & hispanic == 0 | race == 5 & hispanic == 0 )
g biracial = ( race >=6 & race !=. )
foreach v in white black native asian biracial hispanic{
	replace `v' = . if race == .
}

/* Education */
g education = peeduca
recode education (-1=.) (31/38=1) (39=2) (40/42=3) (43=4) (44/46=5)
label define label_education 1 "lt high school" 2 "high school" 3 "some college" 4 "college" 5 "graduate", replace
label values education label_education
g lt_high_school = ( education == 1 )
g high_school = ( education == 2 )
g some_college = ( education == 3 )
g college = ( education == 4 )
g graduate = ( education == 5 )
foreach v in lt_high_school high_school some_college college graduate {
	replace `v' = . if education == .
}

/* Marital Status */
g marital = prmarsta
recode marital (-1=.) (1/3=1) (4/7=0)

/* Children */
g children = prnmchld

* Clean and save
cd ../..
rename hryear4 year
rename gestfips state
keep pwsswgt year state disabled employment employed unemployed no_lfp age _18 _25 _45 _64 race white black native asian biracial hispanic education lt_high_school high_school some_college college graduate marital children sex cismen ciswomen
compress
save "Data/DTA/CPS.dta", replace