* Clear all frames and open data
clear all
use "Data/DTA/final", clear

* Create verticle regression framecap frame drop roc
tempname figure											// temp frame name
cap frame drop `figure'
frame create `figure' x str10(gender) est upper lower

* Estimtes
local genders = "fem_cismen masc_ciswomen fem_ciswomen masc_m2f fem_m2f masc_f2m fem_f2m masc_non fem_non"
reghdfe ${outcome} `genders' [aweight=_llcpwt] , vce(cluster _psu) a($X)


**** Store Estimates for figure ****

local j=1
foreach g in `genders'{
	
	* Local estimates for figure
	lincom `g'
	local g_format = proper(subinstr("`g'", "_", " ",.))
	local id : word 2 of `g_format'
	local e : word 1 of `g_format'
	if inlist("`e'","Masc"){
		local e "Masculine"
	}
	if inlist("`e'","Fem"){
		local e "Feminine"
	}
	local gender = "`e'" + " " + "`id'" 
	local label`j' = "[`j'] `gender'"
	
	* Append values to figure frame
	frame post `figure' (`j') ("`gender'") (r(estimate)) (r(ub)) (r(lb))
	local j = `j' + 1

}

frame `figure'{

	* Variable labels
	labmask x, values(gender)

* Plot
g est2=est-.001
twoway (rbar upper lower x if x == 1, color("225 0 0 %60") lcolor("225 0 0") barw(.7) ) ///
(rbar est est2 x if x == 1 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x if x == 2 , color("225 112 0 %60") lcolor("225 112 0") barw(.7) ) ///
(rbar est est2 x if x == 2 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 3 , color("225 225 0 %60") lcolor("225 225 0") barw(.7) ) ///
(rbar est est2 x if x == 3 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 4 , color("112 225 0 %60") lcolor("112 225 0") barw(.7) ) ///
(rbar est est2 x if x == 4 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 5 , color("0 225 0 %60") lcolor("0 225 0") barw(.7) ) ///
(rbar est est2 x if x == 5 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 6 , color("0 225 112 %60") lcolor("0 225 112") barw(.7) ) ///
(rbar est est2 x if x == 6 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 7 , color("0 225 225 %60") lcolor("0 225 225") barw(.7) ) ///
(rbar est est2 x if x == 7 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 8 , color("0 112 225 %60") lcolor("0 112 225") barw(.7) ) ///
(rbar est est2 x if x == 8 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 9 , color("0 0 225 %60") lcolor("0 0 225") barw(.7) ) ///
(rbar est est2 x if x == 9 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 10 , color("112 0 225 %60") lcolor("112 0 225") barw(.7) ) ///
(rbar est est2 x if x == 10 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
,  scheme(plotplain) xtitle(Gender identity and expression) ytitle("${ytitle1}" "${ytitle2}")  ${yaxis} xlabel(1(1)9) ///
legend(size(small) position(6) ring(3) rows(2) colfirst colgap(*2) order(1 "`label1'" 3 "`label2'" 5 "`label3'" 7 "`label4'" 9 "`label5'" 11 "`label6'" 13 "`label7'" 15 "`label8'" 17 "`label9'"))  xsize(7) xline(1.5 3.5 5.5 7.5)yline(0, lcol(black) lp(solid))
graph export "Tables_and_Figures/${outcome}_regexp.pdf", replace

}