cd "$path"
use Data/DTA/final,clear

********************************************
	// Generate Dummy Dependent Variables
********************************************

* gen dummy years
forvalue i=2014/2017{
	gen d_`i'=(year==`i')
}

* gen dummy metro
foreach value in 0 1 99{
	gen d_metro_`value'=(metro==`value')
	replace d_metro_`value'=. if (metro==.)
}

* gen dummy age
foreach value in 0 1 2 3 4{
	gen d_age_`value'=(age==`value')
	replace d_age_`value'=. if (age==.)
}

* gen dummy marital
foreach value in 0 1 2 99{
	gen d_marital_`value'=(marital==`value')
	replace d_marital_`value'=. if (marital==.)
}

* gen dummy education
foreach value in 1 2 3 4 9{
	gen d_edu_`value'=(education==`value')
	replace d_edu_`value'=. if (education==.)
}

* gen dummy sexuality
foreach value in 1 2 3 4 99{
	gen d_sex_`value'=(sexuality==`value')
	replace d_sex_`value'=. if (sexuality==.)
}						

* gen dummy race
foreach value in 1 2 3 5 9{
	gen d_r_`value'=(race==`value')
	replace d_r_`value'=. if (race==.)
}	
	
*********************
	// Build Table
*********************

local genders = "masc_cismen fem_cismen masc_ciswom fem_ciswom masc_m2f fem_m2f inc_m2f masc_f2m fem_f2m inc_f2m  masc_non fem_non inc_non"	

*Get Mean
foreach dep in laborforce employ unemployed poverty d_2014 d_2015 d_2016 d_2017  ///
 d_metro_0 d_metro_1 d_metro_99 d_age_0 d_age_1 d_age_2 d_age_3 d_age_4 ///
 d_marital_0 d_marital_1 d_marital_2 d_marital_99 cellphone d_edu_1 d_edu_2 d_edu_3 d_edu_4 d_edu_9 ///
 d_sex_1 d_sex_2 d_sex_3 d_sex_4 d_sex_99 d_r_1 d_r_2 d_r_3 d_r_5 d_r_9 {
	
	//Gender Specific by Sex
	quietly reg `dep' `genders' [pweight=_llcpwt], nocons vce(cluster _psu)
	foreach var in `genders'{
		local star=""
		if "`var'"!="masc_cismen"{
			quietly test `var'=masc_cismen
			local p=r(p)
			if `p'<.05{
				local star="\$^{*}\$"
				}
			if `p'<.01{
				local star="\$^{\dagger}\$"
				}
			if `p'<.001{
				local star="\$^{\ddag}\$"
				}
			}
		local dummy=string(round(_b[`var']*100,.1), "%9.1f")
		local row_`dep'="`row_`dep''&`dummy'`star'"
		}
	
	}
	

di "`row_laborforce'"
di "`row_unemployed'"
drop d_*

* N	
foreach g in `genders' {
	quietly sum year if(`g'==1)
	local dummy=r(N)
	local row_N="`row_N'&`dummy'"
}
di  "`row_N'"

* Gender
local i= 1						// Column number indexes genders
foreach g in `genders'{
	
	* Format gender
	local g_format = proper(subinstr("`g'", "_", " ",.))
	local cis : word 2 of `g_format'	
	local cis = substr("`cis'",1,3)
	
 	* Seperate for Cis and Trans since perception is not defined for cis sample
	if inlist("`cis'","Cis"){
	
		* Identitiy
		local id : word 2 of `g_format'
		local identity = "`identity'&`id'"
		
		* Expression
		local e : word 1 of `g_format'
		local expression = "`expression'&`e'"		
		
		* Perception
		local perception = "`perception'& N/A"	
	
	}
	else{
	
		* Identitiy
		local id : word 3 of `g_format'
		local identity = "`identity'&`id'"
		
		* Expression
		local e : word 1 of `g_format'
		local expression = "`expression'&`e'"		
		
		* Perception
		local p : word 2 of `g_format'
		local perception = "`perception'&`p'"	
	
	}
	
	* up index
	local firstrow="`firstrow' & (`i')"
	local i = `i' + 1
}


*** Table ****

* set up
texdoc i "Tables_and_Figures/sumstat", replace
tex \begin{tabular}{l*{16}{x{1.25cm}}}
tex \toprule[.05cm]
tex & \multicolumn{2}{c}{Cismen} & \multicolumn{2}{c}{Ciswomen}  & \multicolumn{3}{c}{Transwomen} & \multicolumn{3}{c}{Transmen} & \multicolumn{3}{c}{Nonconforming} \\\cmidrule(lr){2-3}\cmidrule(lr){4-5}\cmidrule(lr){6-8}\cmidrule(lr){9-11}\cmidrule(lr){12-14}
tex & Masc & Fem & Masc & Fem & Masc & Fem &  Inc & Masc & Fem &  Inc & Masc & Fem &  Inc \\
tex `firstrow' \\
tex \midrule

* Labor market outcomes of interest
tex Labor Force `row_laborforce'\\
tex Employment `row_employ'\\
tex Unemployment `row_unemployed'\\
tex Poverty `row_poverty'\\\\

* race
tex \textit{Race}&  \\
tex \hspace{.25cm}White `row_d_r_1' \\
tex \hspace{.25cm}Black `row_d_r_2' \\
tex \hspace{.25cm}Hispanic `row_d_r_5' \\
tex \hspace{.25cm}Other `row_d_r_3' \\
tex \hspace{.25cm}Missing `row_d_r_9'  \\\\

* sexuality
tex \textit{Sexuality} &\\
tex \hspace{.25cm}Straight `row_d_sex_1' \\
tex \hspace{.25cm}Gay/Les `row_d_sex_2' \\
tex \hspace{.25cm}Bisexual `row_d_sex_3' \\
tex \hspace{.25cm}Other `row_d_sex_4' \\
tex \hspace{.25cm}Missing `row_d_sex_99' \\\\

* education
tex \textit{Education} &\\
tex \hspace{.25cm}$<$ High school `row_d_edu_1' \\
tex \hspace{.25cm}High school `row_d_edu_2' \\
tex \hspace{.25cm}Some college `row_d_edu_3' \\
tex \hspace{.25cm}College `row_d_edu_4' \\
tex \hspace{.25cm}Missing `row_d_edu_9' \\\\

* marital
tex \textit{Marital Status} &\\
tex \hspace{.25cm}Couple `row_d_marital_0' \\
tex \hspace{.25cm}Single `row_d_marital_1' \\
tex \hspace{.25cm}Other `row_d_marital_2' \\
tex \hspace{.25cm}Missing `row_d_marital_99' \\\\

* metro
tex \textit{Metropolitan Status} &\\
tex \hspace{.25cm}Metro `row_d_metro_1' \\
tex \hspace{.25cm}Rural `row_d_metro_0' \\
tex \hspace{.25cm}Missing `row_d_metro_99' \\\\

* year
tex \textit{Survey Year} &\\
tex \hspace{.25cm}2014 `row_d_2014' \\
tex \hspace{.25cm}2015 `row_d_2015' \\
tex \hspace{.25cm}2016 `row_d_2016' \\
tex \hspace{.25cm}2017 `row_d_2017' \\\\

* age
tex \textit{Age}&\\
tex \hspace{.25cm}18 to 29 `row_d_age_0' \\
tex \hspace{.25cm}30 to 39 `row_d_age_1' \\
tex \hspace{.25cm}40 to 49 `row_d_age_2' \\
tex \hspace{.25cm}50 to 59 `row_d_age_3' \\
tex \hspace{.25cm}60 to 64 `row_d_age_4' \\\\

tex Cellphone  `row_cellphone' \\

tex Observations  `row_N' \\


/*tex
\bottomrule[.03cm]
\end{tabular}
tex*/
texdoc close
