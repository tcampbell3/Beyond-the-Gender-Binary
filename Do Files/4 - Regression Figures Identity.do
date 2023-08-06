* Open data
clear all
use "Data/DTA/final", clear
global ylab=""
global ylab2=""

* Program to save space
cap program drop _figs
program _figs
	syntax [, j(int 50) g(varlist)]
	lincom `g'
	replace est=r(estimate) in `j'
	replace ub=r(ub) in `j'
	replace lb=r(lb) in `j'
	replace i = `j' in `j'
	if "`g'"=="ciswomen"{
		global ylab=`"${ylab} `j' "Ciswomen""'
	}
	if "`g'"=="m2f"{
		global ylab=`"${ylab} `j' "Transwomen""'
	}
	if "`g'"=="f2m"{
		global ylab=`"${ylab} `j' "Transmen""'
	}
	if "`g'"=="non"{
		global ylab=`"${ylab} `j' "Nonconforming""'
	}
	local b=round(r(estimate),.001)
	local se=round(r(se),.001)
	global ylab2=`"${ylab2} `j' "`b' (`se')""'
	end

* Store Estimates for figure
local ylab=""
g est=.
g ub=.
g lb=.
g i=.
local j=1
foreach y in laborforce employed unemployed{

	* Estimtes
	reghdfe `y' ciswomen m2f f2m non [aweight=_llcpwt] , vce(cluster _psu) a($X)

	* Outcome
	if "`y'" == "employed"{
		global ylab=`"${ylab} `j' "{bf:Outcome}: {it:Employment}""'
	}
	if "`y'" == "laborforce"{
		global ylab=`"${ylab} `j' "{bf:Outcome}: {it:Labor force}""'
	}
	if "`y'" == "unemployed"{
		global ylab=`"${ylab} `j' "{bf:Outcome}: {it:Unemployment}""'
	}
	local j=`j'+1

	* Loop genders
	foreach g in ciswomen m2f f2m non{
		_figs , j(`j') g(`g')
		local j=`j'+1
	}
	local j=`j'+1
	di "`j'"
	
}

* Plot
sum i, meanonly
local max=r(max)
local min=r(min)-1

keep if !inlist(i,.)
twoway 	(rcap ub lb i, lc("247 168 184") lp(solid) lw(thick) msize(medlarge)) 	///
		(scatter est i, ms(D) msiz(medlarge) mc("85 205 252") mlc(black%50))	///
		(scatter est i, ms(D) msiz(tiny) mc(black%0) mlc(black%0) xaxis(2))		///
		, xlab(`max' " " `min' " " ${ylab}, angle(vertical) labsize(medium)) 	///
		xlab(`max' " " `min' " " ${ylab2}, angle(vertical) labsize(medium) axis(2))	///
		legend(off) yline(0) ysc(alt) ylab(,angle(vertical) labsize(medium)) 	///
		xtitle("") xtitle("",axis(2)) xsize(6) xsc(titlegap(-6)) xsc(titlegap(-6) axis(2))

graph export "Tables_and_Figures/Basline-identity.pdf", replace
