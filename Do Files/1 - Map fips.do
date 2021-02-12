
*******************
	// Map FIPs
*******************
import excel "$path\Data\fips_codes.xls", sheet("cqr_universe_fixedwidth_all") firstrow
rename StateFIP* fips
rename StateAbb* state
keep state fips
duplicates drop
destring fips, replace
compress
save "$path\Data\state_fips.dta", replace