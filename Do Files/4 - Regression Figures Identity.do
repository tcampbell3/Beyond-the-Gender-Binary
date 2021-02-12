* Clear all frames and open data
clear all
use "Data/DTA/final", clear

* Create verticle regression framecap frame drop roc
tempname figure											// temp frame name
cap frame drop `figure'
frame create `figure' x str10(gender) est upper lower

* Estimtes
local genders = "ciswomen m2f f2m non"
reghdfe ${outcome} `genders' [aweight=_llcpwt] , vce(cluster _psu) a($X)


**** Store Estimates for figure ****

local j=1
foreach g in `genders'{
	
	* Local estimates for figure
	lincom `g'
	local gender = proper("`g'") 
	
	* Append values to figure frame
	frame post `figure' (`j') ("`gender'") (r(estimate)) (r(ub)) (r(lb))
	local j = `j' + 1

}

* Labels
frame `figure'{

	* Variable labels
	replace gender = "Male-to-female" if gender == "M2F"
	replace gender = "Female-to-male" if gender == "F2M"
	replace gender = "Nonconforming" if gender == "Non"
	labmask x, values(gender)

	* Legend Labels
	forvalues i = 1/4{
		levelsof gender if x == `i', clean
		local disc = r(levels)
		local label`i' = "[`i'] `disc'"
	}
	



* Plot
g est2=est-.001
twoway (rbar upper lower x if x == 1, color("225 0 0 %60") lcolor("225 0 0") barw(.6))			///
(rbar est est2 x if x == 1 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.585)) 	///
(rbar upper lower x if x == 2 , color("225 225 0 %60") lcolor("225 225 0") barw(.6))			///
(rbar est est2 x if x == 2 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.585))	///
(rbar upper lower x  if x == 3 , color("0 225 0 %60") lcolor("0 225 0") barw(.6))				///
(rbar est est2 x if x == 3 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.585))	///
(rbar upper lower x  if x == 4 , color("0 150 225 %60") lcolor("0 150 225") barw(.6))			///
(rbar est est2 x if x == 4 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.585))	///
(rbar upper lower x  if x == 5 , color("200 0 225 %60") lcolor("200 0 225") barw(.6))			///
(rbar est est2 x if x == 5 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.585)) 	///
, scheme(plotplain) xtitle(Gender identity and sex) ytitle("${ytitle1}" "${ytitle2}")  ${yaxis} xlabel(1(1)4, val) ///
yline(0, lcol(black) lp(solid)) legend(size(small) position(6) ring(3) col(5) colfirst order(1 "`label1'" 3 "`label2'" 5 "`label3'" 7 "`label4'" 9 "`label5'"))

graph export "Tables_and_Figures/${outcome}_regiden.pdf", replace

}

