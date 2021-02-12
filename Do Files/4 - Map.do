cd "${path}"
use "Data\DTA\final.dta", clear

* Count years of trans data for each state
gen Trans=(trans<4)
replace Trans=. if trans==.
collapse Trans [aw=_llcpwt], by(state year)
g dummy = 1
bys state: egen number_of_years = sum(dummy)
rename state fips
merge m:1 fips using "$path\Data\state_fips.dta", nogen
drop if state==""
replace number_of_years = 0 if number_of_years == .
keep number_of_years state
duplicates drop

* Create map
maptile number_of_years, geo(state) cutvalues(0 1 2 3) ///
twopt(legend(lab(2 "Never asked") lab(3 "1 year") lab(4 "2 years") lab(5 "3 years") lab(6 "4 years")))

* Save Map
graph export Tables_and_Figures/map.pdf, replace 

