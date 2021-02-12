cd "${path}"
use "Data\DTA\final.dta", clear

local genders = "fem_cismen masc_ciswomen fem_ciswomen masc_masc_m2f masc_fem_m2f fem_masc_m2f fem_fem_m2f masc_masc_f2m masc_fem_f2m fem_masc_f2m fem_fem_f2m masc_masc_non masc_fem_non fem_masc_non fem_fem_non"	

* Labels
label var masc_cismen "Masculine Cismen"
label var fem_cismen "Feminine Cismen"
label var masc_ciswomen "Masculine Ciswomen"
label var fem_ciswomen "Feminine Ciswomen"
label var masc_masc_m2f "Masc-Masc M2F"
label var fem_masc_m2f "Femme-Masc M2F"
label var masc_fem_m2f "Masc-Femme M2F"
label var fem_fem_m2f "Femme-Femme M2F"
label var masc_masc_f2m "Masc-Masc F2M"
label var fem_masc_f2m "Femme-Masc F2M"
label var masc_fem_f2m "Masc-Femme F2M" 
label var fem_fem_f2m "Femme-Femme F2M"
label var masc_masc_non "Masc-Masc Non"
label var fem_masc_non "Femme-Masc Non"
label var masc_fem_non  "Masc-Femme Non"
label var fem_fem_non 	"Femme-Femme Non"


********************************************************************************
************************							****************************
************************		Robustness			****************************
************************							****************************
********************************************************************************
foreach var in homemaker laborforce unemployed poverty{
eststo clear
	reg `var' `genders' ${g1} [aweight=_llcpwt], vce(cluster _psu) 
		eststo
	reghdfe `var' `genders' [aweight=_llcpwt], vce(cluster _psu) a($g2)
		eststo	
	reghdfe `var' `genders' [aweight=_llcpwt], vce(cluster _psu) a($g3)
		eststo	
	reghdfe `var' `genders' [aweight=_llcpwt], vce(cluster _psu) a($g4)
		eststo	
	reghdfe `var' `genders' [aweight=_llcpwt], vce(cluster _psu) a($g5)
		eststo	
	esttab using Tables_and_Figures/`var'_subset.tex , nogaps keep(`genders' _cons) replace star(* 0.10 ** 0.05 *** 0.01) label stats(N r2,  fmt(0 2) label("N" "\$R^2\$")) mtitles("G1" "G2" "G3" "G4" "G5") se(3) nonumbers nonotes b(2)		
	
}

