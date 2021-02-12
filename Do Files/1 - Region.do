
****************
	// Region
***************

import excel "$path\Data\state-geocodes-v2016.xlsx", sheet("CODES14") cellrange(A6:D70) firstrow clear
rename StateFIPS state
destring state, replace
drop if state==0
destring Region, replace
set obs 54
replace Region=5 if Region==.
replace state=66 in 52 //Guam fips
replace state=72 in 53 //Puerto Rico fips
replace state=78 in 54 //Virgin Islands fips
rename Region region
destring Division, gen(division)
compress
save "$path\Data\region.dta", replace
