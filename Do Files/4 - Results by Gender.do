use Data/DTA/final,clear

//Program P-Value
cap program drop pvalue
program pvalue, rclass
	version 15
	syntax  anything
	local p=`1'
	local star=" "
	if `p'<=.1{
		local star="\$^{*}\$"
		}
	if `p'<=.05{
		local star="\$^{**}\$"
		}
	if `p'<=.01{
		local star="\$^{***}\$"
		}
	return local star="`star'"
	end	
pvalue .05	
di r(star)

	
*********************
	// Build Table
*********************
local i=0
foreach gender in m2f f2m non ciswomen cismen{
	local i=`i'+1

	foreach var in laborforce employed unemployed {

		reg `var' express perc $X [pweight=_llcpwt] if(`gender'==1), vce(cluster _psu)
			//Express
				local dummy=string(round(_b[express],.001), "%9.3f")
					quietly test express
					pvalue r(p)
					local star=r(star)	
					local row1_`i'="`row1_`i''&`dummy'`star'"
				local dummy=string(round(_se[express],.001), "%9.3f")
					local row1_`i'="`row1_`i''&(`dummy')"
			//Perception
				if _b[perc] !=0 {			// ommitted for cisgender
					local dummy=string(round(_b[perc],.001), "%9.3f")
						quietly test perc
						pvalue r(p)
						local star=r(star)	
						local row2_`i'="`row2_`i''&`dummy'`star'"
					local dummy=string(round(_se[perc],.001), "%9.3f")
						local row2_`i'="`row2_`i''&(`dummy')"
				}
				else{
					local row2_`i'="`row2_`i''& &"
				}
			//Constant
				local dummy=string(round(_b[_cons],.001), "%9.3f")
					quietly test _cons
					pvalue r(p)
					local star=r(star)	
					local row3_`i'="`row3_`i''&`dummy'`star'"
				local dummy=string(round(_se[_cons],.001), "%9.3f")
					local row3_`i'="`row3_`i''&(`dummy')"
			//N
				local dummy=e(N)
				local row4_`i'="`row4_`i''&`dummy'&"
			//R^2
				local dummy=string(round(e(r2),.001), "%9.3f")
				local row5_`i'="`row5_`i''&`dummy'&"

		}
		
	}
di "`row5_2'"





texdoc i "Tables_and_Figures/est_by_gender", replace

/*tex
\begin{tabular}{l*{11}{x{1.6cm}}}
\toprule[.05cm]
 & \multicolumn{2}{c}{Labor Force}&\multicolumn{2}{c}{Employment}&\multicolumn{2}{c}{Unemployment} \\
\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} 
&Beta&(SE)&Beta&(SE)&Beta&(SE)\\
 \midrule
tex*/


* Cismen
tex \textit{Cisgender Men} &\\
tex \quad Expression `row1_5' \\
tex \quad Perception `row2_5' \\
tex \quad Constant `row3_5' \\
tex \quad N `row4_5' \\
tex \quad \$R^{2}\$ `row5_5' \\\\

* Ciswomen
tex \textit{Cisgender Women} &\\
tex \quad Expression `row1_4' \\
tex \quad Perception `row2_4' \\
tex \quad Constant `row3_4' \\
tex \quad N `row4_4' \\
tex \quad \$R^{2}\$ `row5_4' \\\\


* M2F
tex \textit{Transgender Women}&  \\
tex \quad Expression `row1_1' \\
tex \quad Perception `row2_1' \\
tex \quad Constant `row3_1' \\
tex \quad N `row4_1' \\
tex \quad \$R^{2}\$ `row5_1' \\\\

* F2M
tex \textit{Transgender Men} &\\
tex \quad Expression `row1_2' \\
tex \quad Perception `row2_2' \\
tex \quad Constant `row3_2' \\
tex \quad N `row4_2' \\
tex \quad \$R^{2}\$ `row5_2' \\\\

* Nonconforming
tex \textit{Gender Nonconforming} &\\
tex \quad Expression `row1_3' \\
tex \quad Perception `row2_3' \\
tex \quad Constant `row3_3' \\
tex \quad N `row4_3' \\
tex \quad \$R^{2}\$ `row5_3' \\

/*tex
\bottomrule[.03cm]
\end{tabular}
tex*/
texdoc close
