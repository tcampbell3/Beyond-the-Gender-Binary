* Clear all frames and open data
clear all
use "Data/DTA/final", clear

* Create verticle regression framecap frame drop roc
tempname figure											// temp frame name
cap frame drop `figure'
frame create `figure' x str10(gender) est upper lower

* Estimtes
local genders = "fem_cismen masc_ciswom fem_ciswom masc_masc_m2f masc_fem_m2f fem_masc_m2f fem_fem_m2f masc_masc_f2m masc_fem_f2m fem_masc_f2m fem_fem_f2m masc_masc_non masc_fem_non fem_masc_non fem_fem_non"	
reghdfe ${outcome} `genders' [aweight=_llcpwt] , vce(cluster _psu) a($X)


**** Store Estimates for figure ****

local j=1
foreach g in `genders'{
	
	* Local estimates for figure
	lincom `g'
	local gender = proper(subinstr("`g'", "_", " ",.))
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
(rbar upper lower x  if x == 6 , color("0 225 75 %60") lcolor("0 225 75") barw(.7) ) ///
(rbar est est2 x if x == 6 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 7 , color("0 225 150 %60") lcolor("0 225 150") barw(.7) ) ///
(rbar est est2 x if x == 7 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 8 , color("0 225 225 %60") lcolor("0 225 225") barw(.7) ) ///
(rbar est est2 x if x == 8 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 9 , color("0 150 225 %60") lcolor("0 150 225") barw(.7) ) ///
(rbar est est2 x if x == 9 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 10 , color("0 75 225 %60") lcolor("0 75 225") barw(.7) ) ///
(rbar est est2 x if x == 10 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 11 , color("0 0 225 %60") lcolor("0 0 225") barw(.7) ) ///
(rbar est est2 x if x == 11 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 12 , color("75 0 225 %60") lcolor("75 0 225") barw(.7) ) ///
(rbar est est2 x if x == 12 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 13 , color("150 0 225 %60") lcolor("150 0 225") barw(.7) ) ///
(rbar est est2 x if x == 13 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 14 , color("225 0 225 %60") lcolor("225 0 225") barw(.7) ) ///
(rbar est est2 x if x == 14 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 15 , color("225 0 150 %60") lcolor("225 0 150") barw(.7) ) ///
(rbar est est2 x if x == 15 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
(rbar upper lower x  if x == 16 , color("225 0 75 %60") lcolor("225 0 75") barw(.7) ) ///
(rbar est est2 x if x == 16 , color("200 200 200 200") lcolor("200 200 200 200")  barw(.685) ) ///
,  scheme(plotplain) xtitle("Gender identity, expression and perception") ytitle("${ytitle1}" "${ytitle2}")  ${yaxis} xlabel(1(1)15) ///
legend(size(small) position(6) ring(3) col(4) colfirst order(1 "`label1'" 3 "`label2'" 5 "`label3'" 7 "`label4'" 9 "`label5'" 11 "`label6'" 13 "`label7'" 15 "`label8'" 17 "`label9'" 19 "`label10'" 21 "`label11'" 23 "`label12'" 25 "`label13'" 27 "`label14'" 29 "`label15'"))  xsize(7) xline(1.5 3.5 7.5 11.5) yline(0, lcol(black) lp(solid))

graph export "Tables_and_Figures/${outcome}_reg.pdf", replace

}