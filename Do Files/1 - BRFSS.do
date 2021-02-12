
***************************************
*********	  Pool BRFSS   	***********
***************************************

* Note: Sample ommits missing/refused/unknown sex or transgender, Guam, and Puerto Rico

* Open BRFSS annual data
cd "Data\SAS"
forvalues year=2014/2018{
	unzipfile "LLCP`year'", replace
}


* IOWA 2015 uses optional SOGI question in version 1
unzipfile "LLCP15V1_XPT", replace
import sasxport5 "LLCP15V1.xpt", clear
gen year=2015
drop if sex>2|trnsgndr>4|trnsgndr==.|sex==. 				// Drop missing sex/transgender or not working age
keep if _state==19
rename _lcpwtv1 _llcpwt
compress
save "..\DTA\BRFSS_IA_2015.dta", replace	

cd ../..

* Import data and define sample
forvalues year =2014/2018{	// 2018 is only used for validation

	import sasxport5 "Data\SAS\LLCP`year'.xpt", clear
	gen year=`year'
	drop if sex>2|trnsgndr>4|trnsgndr==.|sex==.				// Drop missing sex/transgender or not working age
	drop if inlist(_state, 66, 72)							// Drop Guam and Puerto Rico
	compress
	save "Data\DTA\BRFSS_`year'.dta", replace
	
}

* append datasets (not 2018 since only used as test data)
use "Data\DTA\BRFSS_2014"
forvalues year =2015/2017{	// 2018 is only used for validation
	append using "Data\DTA\BRFSS_`year'", force
}

* Append Iowa 2015
drop if year==2015 & _state==19
append using Data\DTA\BRFSS_IA_2015.dta, force


* ID
gen id=_n

* save stacked dataset
compress
save "Data\DTA\BRFSS_Pooled.dta", replace
clear

//Delete Unused Data
forvalues year=2014/2018{
	if `year'!=2018{
		erase "$path\Data\DTA\BRFSS_`year'.dta"
	}
	erase "$path\Data\SAS\LLCP`year'.XPT"
}
