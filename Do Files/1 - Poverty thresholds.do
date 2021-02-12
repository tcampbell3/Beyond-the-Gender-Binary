
**********************************************
*********Creating poverty thresholds**********
**********************************************

forvalues i=14/17{
	clear
	cap confirm file "$path\Data\Poverty_Thresholds\thresh`i'_stata.xls"
	if _rc==0{
		import excel "$path\Data\Poverty_Thresholds\thresh`i'_stata.xls", sheet("Sheet1") firstrow
	}
	else {
		import excel "$path\Data\Poverty_Thresholds\thresh`i'_stata.xlsx", sheet("Sheet1") firstrow
	}
	cap drop if(child0==.)
	reshape long child, i(Sizeoffamilyunit)
	rename child poverty_thresh
	rename _j children
	rename Sizeoffamilyunit adult_plus_child
	gen year=20`i'
	save "$path\Data\Poverty_Thresholds\poverty_20`i'.dta", replace
}

//Append all other years
forvalues i=14/16{
	append using "$path\Data\Poverty_Thresholds\poverty_20`i'.dta"
}
gen numadult = adult_plus_child-child
drop if poverty==.
compress
save "$path\Data\Poverty_Thresholds\poverty_combined.dta", replace
clear