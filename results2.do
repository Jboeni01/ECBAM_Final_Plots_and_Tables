*******************************************************************************
* Diff-in-diff-in-diff Regression Analysis
* Base for Results displayed in Table 2 and Table A5
********************************************************************************

clear all
set more off
*ssc install outreg2
*ssc install estout 

*cd "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data"
global datapath "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data\data"
global exportpath "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data\final_results" //storage path for plots

use "${datapath}\EA_CO2_toAMNE_allyears.dta", clear

************
* -1- Prepare Data
************

egen id=group(cou ind)

encode cou, gen(ccode)
encode ind, gen(icode)


xtset id y, yearly //set panel strucuture 

gen EU = 0 //generate EU dummy & fill
replace EU = 1 if inlist(cou, "AUT","BEL","CYP","DEU","ESP","EST","EA","DNK","CZE") ///
 | inlist(cou, "EU_actual","FIN","FRA","GRC","IRL","ITA","LTU","LUX","LVA") ///
 | inlist(cou, "MLT","NLD","PRT","SVK","SVN","POL","ROU","BGR","SWE") | inlist(cou, "HUN","HRV", "GBR")

generate ETS = 0 //generate ETS industry dummy & fill
replace ETS = 1 if inlist(ind,"C17","C19","C20","C23","C24","DTE","H")


gen ETP=0 //dummy for ETS enactment 
replace ETP=1 if year>=2005

gen ETSETP=ETS*ETP //dummy for ETS industries in ETS period 

gen ETSETPEU=ETS*ETP*EU 
/* the treatment dummy interacts three dimensions which characterize the 
European trading system: it only concerns EU countries, specific sectors and 
started after 2005*/

separate year, by(ind) gen(trend_ind) /*generate industry trends */
forvalues i=1(1)34{
replace trend_ind`i'=0 if trend_ind`i'==.
}

separate year, by(cou) gen(trend_cou) /*generate country trend */
forvalues i=1(1)44{
replace trend_cou`i'=0 if trend_cou`i'==.
}


*generate and label variables 
gen ltote = log(CO2emission) 

gen L_ltote = L.ltote //lag
gen D_ltote = d.ltote //fist difference
gen DL_ltote = d.L.ltote //first difference of lag 


label var ltote "log(em)\$ _t\$"
label var L_ltote "log(em)\$ _{t-1}\$"
label var D_ltote "\$\Delta\$ log(em)\$ _t\$"
label var DL_ltote "\$\Delta\$ log(em)\$ _{t-1}\$"



******************************************
* FINAL TABLE 
******************************************
*drop if ind=="H"


label var ETP "D1: year $\geq 2005$"
label var ETSETP "D2: year $\geq 2005$, ind $\in$ ETS"
label var ETSETPEU "D3: year $\geq 2005$, ind $\in$ ETS, cou. $\in$ EU"

eststo clear

eststo: qui xtreg ltote L_ltote ETP ETSETP ETSETPEU i.year,fe //equation 1
estadd local idfe Yes 
estadd local yfe Yes

eststo: qui xtreg ltote L_ltote ETP ETSETP ETSETPEU 1.ETP#c.L_ltote 1.ETSETP#c.L_ltote 1.ETSETPEU#c.L_ltote i.year,fe //equation 3

estadd local idfe Yes
estadd local yfe Yes

eststo: qui xtreg D_ltote L_ltote DL_ltote ETP ETSETP ETSETPEU i.year,fe //equation 2
estadd local idfe Yes
estadd local yfe Yes


eststo: qui xtreg D_ltote L_ltote DL_ltote ETP ETSETP ETSETPEU 1.ETP#c.DL_ltote 1.ETSETP#c.DL_ltote 1.ETSETPEU#c.DL_ltote i.year,fe //equation 4
estadd local idfe Yes
estadd local yfe Yes



local varlabels 1.ETP#c.L_ltote "D1 X log(em)$ _{t-1}$" ///
 1.ETSETP#c.L_ltote "D2 X log(em)$ _{t-1}$" ///
 1.ETSETPEU#c.L_ltote "D3 X log(em)$ _{t-1}$" ///
 1.EU#c.L_ltote "EU=1 X log(em)$ _{t-1}$" ///
 1.EU#c.DL_ltote "EU=1 X \$\Delta\$ log(em)$ _{t-1}$" ///
 1.ETP#c.DL_ltote "D1 X \$\Delta\$ log(em)$ _{t-1}$" ///
 1.ETSETP#c.DL_ltote "D2 X \$\Delta\$ log(em)$ _{t-1}$" ///
 1.ETSETPEU#c.DL_ltote "D3 X \$\Delta\$ log(em)$ _{t-1}$" ///

esttab using "${exportpath}\\table_2.tex", se order(L_ltote DL_ltote)label ///
drop(_cons *.year) star stats(idfe yfe r2 N N_g, ///
labels("Country-Sector FE" "Year FE" "Adjusted R-squared" "Observations" "Number of id")) ///
scalars("N_g Number of id") nobaselevels interaction("|") coeflabels(`varlabels') ///
 mgroups("log(em)\$_{t}\$" "\$\Delta\$ log(em)\$_{t}\$", pattern(1 0 1 0 0)) nomtitle ///
 substitute((_ \_) ) replace

esttab, se order(L_ltote DL_ltote)label drop(_cons *.year) star ///
 stats(idfe yfe r2 N N_g, labels("Country-Sector FE" "Year FE" "Adjusted R-squared" "Observations" "Number of id")) /// add stats and label accordingly 
 scalars("N_g Number of id") nobaselevels interaction("|")   /// add further scalars, drop base level of factor vars specify interaction operator
 coeflabels(`varlabels')  /// specify coefficient labels perviously defined 
 mgroups("log(em)\$_{t}\$" "\$\Delta\$_{t-1}\$ log(em)\$_{t}\$", /// group title 
 pattern(1 0 1 0 0)) nomtitle  substitute((_ \_) ) // pattern in which group titles should be displayed 

***********************************
*Appendix: rerun regression separately for each ETS sector 
*
*Basis for results of Table A5
***********************************

label var ETP "D1: year $\geq 2005$"
label var ETSETP "D2: year $\geq 2005$, ind $\in$ ETS"
label var ETSETPEU "D3: year $\geq 2005$, ind $\in$ ETS, cou. $\in$ EU"

local ETS  C19 C23 C24 DTE H
cap drop ETSETPEU_* 

local i 5
foreach sec in `ETS'{



gen ETSETPEU_`sec' = 0
replace ETSETPEU_`sec' = 1 if ETSETPEU==1 & ind == "`sec'"

label var ETSETPEU_`sec' "D4: year $\geq 2005$, ind = `sec', cou. $\in$ EU"
 
eststo clear

eststo: qui xtreg ltote L_ltote ETP ETSETP ETSETPEU ETSETPEU_`sec' i.year,fe //equation 1
estadd local idfe Yes 
estadd local yfe Yes

eststo: qui xtreg ltote L_ltote ETP ETSETP ETSETPEU ETSETPEU_`sec' 1.ETP#c.L_ltote 1.ETSETP#c.L_ltote 1.ETSETPEU#c.L_ltote 1.ETSETPEU_`sec'#c.L_ltote i.year,fe //equation 3

estadd local idfe Yes
estadd local yfe Yes

eststo: qui xtreg D_ltote L_ltote DL_ltote ETP ETSETP ETSETPEU ETSETPEU_`sec' i.year,fe //equation 2
estadd local idfe Yes
estadd local yfe Yes


eststo: qui xtreg D_ltote L_ltote DL_ltote ETP ETSETP ETSETPEU 1.ETP#c.DL_ltote 1.ETSETP#c.DL_ltote 1.ETSETPEU#c.DL_ltote 1.ETSETPEU_`sec'#c.DL_ltote i.year,fe //equation 4
estadd local idfe Yes
estadd local yfe Yes


*eststo: qui xtreg D_ltote  ETP ETSETP ETSETPEU L_ltote  1.EU#c.L_ltote DL_ltote 1.EU#c.DL_ltote 1.ETSETPEU#c.DL_ltote  i.y trend_cou* trend_ind*,fe //equation 8
*estadd local idfe Yes


local varlabels 1.ETP#c.L_ltote "D1 X log(em)$ _{t-1}$" /// 
 1.ETSETP#c.L_ltote "D2 X log(em)$ _{t-1}$" ///
 1.ETSETPEU#c.L_ltote "D3 X log(em)$ _{t-1}$" ///
 1.ETSETPEU#c.DL_ltote "D3 X \$\Delta\$ log(em)$ _{t-1}$" ///
 1.EU#c.L_ltote "EU=1 X log(em)$ _{t-1}$"  ///
 1.EU#c.DL_ltote "EU=1 X \$\Delta\$ log(em)$ _{t-1}$" /// 
 1.ETP#c.DL_ltote "D1 X \$\Delta\$ log(em)$ _{t-1}$" ///
 1.ETSETP#c.DL_ltote "D2 X \$\Delta\$ log(em)$ _{t-1}$" ///
 1.ETSETPEU_`sec'#c.L_ltote "D4 X log(em)$ _{t-1}$" ///
 1.ETSETPEU_`sec'#c.DL_ltote "D4 X \$\Delta\$ log(em)$ _{t-1}$"

display("******************************") 
display("results for sector `sec', ")
display("******************************")
 
esttab using "${exportpath}\\table_A`i'_`sec'.tex", se order(L_ltote DL_ltote) ///
label drop(_cons *.year) star stats(idfe yfe r2 N N_g, ///
labels("Country-Sector FE" "Year FE" "Adjusted R-squared" "Observations" "Number of id")) ///
 scalars("N_g Number of id") nobaselevels interaction("|") coeflabels(`varlabels') ///
 mgroups("log(em)\$_{t}\$" "\$\Delta\$ log(em)\$_{t}\$", pattern(1 0 1 0 0)) ///
 nomtitle  substitute((_ \_) ) replace

esttab, se order(L_ltote DL_ltote)label drop(_cons *.year) star ///
stats(idfe yfe r2 N N_g, ///
labels("Country-Sector FE" "Year FE" "Adjusted R-squared" "Observations" "Number of id")) ///
 scalars("N_g Number of id") nobaselevels interaction("|") coeflabels(`varlabels') ///
 mgroups("log(em)\$_{t}\$" "\$\Delta\$_{t-1}\$ log(em)\$_{t}\$", pattern(1 0 1 0 0)) ///
 nomtitle  substitute((_ \_) )

local ++i
}


