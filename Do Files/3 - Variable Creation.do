use "data\dta\brfss_pooled.dta", clear

* Gender identity
rename trnsgndr trans
gen cismen=(sex==1&trans>3)
replace cismen=. if sex==.
gen ciswomen=(sex==2&trans>3)
replace ciswomen=. if sex==.
gen m2f=(trans==1)
gen f2m=(trans==2)
gen non=(trans==3)
gen cis=(cismen==1|ciswomen==1)
gen masculine=(sex==1)
replace masculine=. if sex==.

* Gender expression
merge 1:1 id using "data\dta\expression.dta", nogen keep(3)

* Gender perception
gen perc=(sex==1)
replace perc=. if sex==. | sex>2

* Gender Categories
g masc_cismen = (cismen==1&express>${thresh})
g fem_cismen = (cismen==1&express<=${thresh})
g masc_ciswomen = (ciswomen==1&express>${thresh})
g fem_ciswomen = (ciswomen==1&express<=${thresh})
g masc_m2f = (m2f == 1 & sex == 1 & express >${thresh})
g inc_m2f = (m2f == 1 & sex == 1 & express <=${thresh}) | (m2f == 1 & sex == 2 & express >${thresh})
g fem_m2f = (m2f == 1 & sex == 2 & express <=${thresh})
g masc_f2m = (f2m == 1 & sex == 1 & express >${thresh})
g inc_f2m = (f2m == 1 & sex == 1 & express <=${thresh}) | (f2m == 1 & sex == 2 & express >${thresh})
g fem_f2m = (f2m == 1 & sex == 2 & express <=${thresh})
g masc_non = (non == 1 & sex == 1 & express >${thresh})
g inc_non = (non == 1 & sex == 1 & express <=${thresh}) | (non == 1 & sex == 2 & express >${thresh})
g fem_non = (non == 1 & sex == 2 & express <=${thresh})	

* Cellphone survey
gen cellphone=(qstver>=20)
replace cellphone=99 if qstver==.						//missing=99

* Marital status indicator
rename marital _marital
gen marital=_marital
replace marital=0 if inlist(_marital,1,6)				//couple=0
replace marital=1 if inlist(_marital,5) 				//single==1 (never married)
replace marital=2 if inlist(_marital,2,3,4,9) 			//other=2
replace marital=99 if _marital==. 						//missing=99
		
* Education indicator
rename _educag education
replace education=9 if education==.
	
* Race indicator
rename _racegr3 race
replace race=3 if race==4 								// 3 denotes "other" or "mix"
replace race=9 if race==.
	
* Sexuality indicator
gen sexuality = sxorient
replace sexuality=4 if inlist(sxorient,7,9)
replace sexuality=99 if sxorient==.
	
* Employment indicators
gen employed = inlist(employ1,1,2)
replace employed=. if inlist(employ1, 9, .)
gen laborforce = inlist(employ1, 1, 2, 3, 4)
replace laborforce = . if inlist(employ1, 9, .)
gen unemployed = inlist(employ1, 3, 4)
replace unemployed = . if inlist(employ1, 9, .) | inlist(laborforce, 0)

* Family income: average values, top bracket lower bound
replace income=5000 if(income==1)
replace income=12500 if(income==2)
replace income=17500 if(income==3)
replace income=22500 if(income==4)
replace income=30000 if(income==5)
replace income=42500 if(income==6)
replace income=62500 if(income==7)
replace income=124588 if(income==8&year==2014) // cps 2014 median over 75000 age 18-64
replace income=125508 if(income==8&year==2015) // cps 2015 median over 75000 age 18-64
replace income=128104 if(income==8&year==2016) // cps 2016 median over 75000 age 18-64
replace income=128104 if(income==8&year==2017) // topcoding doesn't matter since not in poverty	
replace income=. if(income==9)

		
* Poverty indicator

	* number of adult (top coded at 9) 
	replace hhadult=. if(hhadult>76)
	replace numadult=hhadult if(cellphone==1)	// num_adult only for home, hhadult for cellphone
	replace numadult=1 if numadult<1&numadult!=.
	replace numadult=9 if numadult>9&numadult!=.
	
	* children (top coded at 8)
	replace children=. if(children==99)
	replace children=0 if(children==88) 
	replace children=8 if(children>8&children!=.)
	
	* Merge poverty thresholds
	merge m:1 year children numadult using "data\poverty_thresholds\poverty_combined.dta", nogen keep(1 3)
	replace poverty_thresh =. if _age65yr>1 //_age65yr=2 if 65 or older, =3 if age missing
	gen poverty = (income<=poverty_thresh)
	replace poverty=. if(income==.|poverty_thresh==.)
	replace numadult = 99 if numadult==.
	
* Metro
gen metro=(mscode<5)
replace metro=99 if mscode==.

* Age (10 year)
gen age = floor((_ageg5yr-1) / 2) 

* Region
rename _state state
merge m:1 state using "data\region.dta", nogen keep(1 3)

* Time (year-month)
egen time = group(year fmonth)

* Save
keep 	id cellphone age marital education race sexuality employed unemployed 	///
		laborforce poverty express sex _psu _ststr _llcpwt perc numadult time	///
		m2f f2m cismen ciswomen non year fmonth state trans metro division masc_* fem_* inc_*
compress
save "data\dta\final.dta", replace

