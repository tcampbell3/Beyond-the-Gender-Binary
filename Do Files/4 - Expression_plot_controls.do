
use "Data\DTA\Final.dta", clear

if "${gender}"!="Total"{
	keep if $gender == 1
}
binsreg ${outcome} express ${X}, dots(0,0) vce(cluster _psu ) polyreg(3) scheme(plotplain) ytitle("${ytitle}") xtitle("Gender-typical expression") dotsplotopt(mcol(${color}%30) msize(large)) polyregplotopt(lcol(${color}*.9) lw(thick))

graph export "Tables_and_Figures/${outcome}_${gender}_c.pdf", replace


