* Open data
clear all
use "Data/DTA/final", clear
global ylab1=""
global ylab2=""
global ylab3=""

* Program to save space
cap program drop _figs
program _figs
	syntax [, j(real 50) g(varlist)]
	lincom `g'
	replace est=r(estimate) in `j'
	replace ub=r(ub) in `j'
	replace lb=r(lb) in `j'
	replace i = `j' in `j'
	if substr("`g'",1,3)=="fem"{
		global ylab1=`"${ylab1} `j' "Feminine""'
	}
	if substr("`g'",1,4)=="masc"{
		global ylab1=`"${ylab1} `j' "Masculine""'
	}
	if substr("`g'",1,3)=="inc"{
		global ylab1=`"${ylab1} `j' "Incongruent""'
	}
	local b=round(r(estimate),.001)
	local se=round(r(se),.001)
	global ylab3=`"${ylab3} `j' "`b' (`se')""'
	end

* Store Estimates for figure
g est=.
g ub=.
g lb=.
g i=.
local j=1

* Estimtes
reghdfe ${outcome} fem_cismen masc_ciswomen fem_ciswomen masc_m2f fem_m2f inc_m2f masc_f2m fem_f2m inc_f2m masc_non fem_non inc_non [aweight=_llcpwt] , vce(cluster _psu) a($X)

* Loop genders
foreach g in fem_cismen masc_ciswomen fem_ciswomen masc_m2f fem_m2f inc_m2f masc_f2m fem_f2m inc_f2m masc_non fem_non inc_non{
	if "`g'"=="fem_cismen"{
		global ylab2=`"${ylab2} `j' "{bf:Cismen}""'
		local j=`j'+1
	}
	if "`g'"=="masc_ciswomen"{
		global ylab2=`"${ylab2} `j' "{bf:Ciswomen}""'
		local j=`j'+1
	}
	if "`g'"=="masc_m2f"{
		global ylab2=`"${ylab2} `j' "{bf:Transwomen}""'
		local j=`j'+1
	}
	if "`g'"=="masc_f2m"{
		global ylab2=`"${ylab2} `j' "{bf:Transmen}""'
		local j=`j'+1
	}
	if "`g'"=="masc_non"{
		global ylab2=`"${ylab2} `j' "{bf:Nonconforming}""'
		local j=`j'+1
	}
	_figs , j(`j') g(`g')
	local j=`j'+1
	if inlist("`g'","fem_cismen","fem_ciswomen","inc_m2f","inc_f2m","inc_non"){
		local j=`j'+1
	}
}

* Plot
sum i, meanonly
local max=r(max)+.5
local min=r(min)-1.5
keep if !inlist(i,.)
twoway 	(rcap ub lb i, lc("247 168 184") lp(solid) lw(thick) msize(medlarge)) 	///
		(scatter est i, ms(D) msiz(medlarge) mc("85 205 252") mlc(black%50))	///
		(scatter est i, ms(D) msiz(tiny) mc(black%0) mlc(black%0) xaxis(2))		///
		, xlab(`max' " " `min' " " ${ylab1}, angle(vertical) labsize(large) labcolor(black)) 	///
		xlab(`max' " " `min' " " ${ylab2}, angle(vertical) labsize(large) add custom labcolor("85 205 252"*1.5)) ///
		xlab(`max' " " `min' " " ${ylab3}, angle(vertical) labsize(large) axis(2))	///
		legend(off) yline(0) ysc(alt) ylab(-.4(.2).4,angle(vertical) labsize(large)) 	///
		xtitle("") xtitle("",axis(2)) xsize(7) xsc(titlegap(-5)) xsc(titlegap(-5) axis(2))

graph export "Tables_and_Figures/Basline-${outcome}.pdf", replace

