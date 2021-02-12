
* Open data
use DTA/full_no_impute, clear

* Store regressions
eststo clear
reghdfe profit year [aw=k_r], vce(cluster country) a(country)
eststo
 
reghdfe profit year exp [aw=k_r], vce(cluster country) a(country)
eststo

reghdfe profit year exp op [aw=k_r], vce(cluster country) a(country)
eststo

reghdfe profit year exp op w  [aw=k_r], vce(cluster country) a(country)
eststo

reghdfe profit year exp op w rpcc  [aw=k_r], vce(cluster country) a(country)
eststo

reghdfe profit year exp op w rpcc exploit [aw=k_r], vce(cluster country) a(country)
eststo

reghdfe profit year op w rpcc exploit [aw=k_r], vce(cluster country) a(country)
eststo

* Save table
esttab using "Output/Regressions.tex", nomtitles nonotes booktabs nogap  		///
	b(%010.4fc) se(%010.4fc) r2 label replace star(* 0.1 ** 0.05 *** 0.01)



