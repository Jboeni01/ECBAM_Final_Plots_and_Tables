*******************************************************************************
* Regression Analysis 3
* Base for Results displayed in Table 3 and Table 4, Table A10 and Table A11
********************************************************************************
clear all 
set more off


global datapath "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data\data"
global exportpath "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data\final_results"

*******************
*-1- Load and prepare data
*******************

use "${datapath}\imports_inputs_GO_allyears.dta", clear



egen id=group(ind own cou)
xtset id year, yearly

*variable transformation
rename imports_* imp_* 
rename input_* inp_*
rename EUA_future_price emip
rename CO2emission emi

*generate input and import (log) (as sh of gross output), 
*input and import from ETS ind (as share of gross ouput) 
local int imp inp 
foreach v of local int{
gen `v'= `v'_D_nonEU+`v'_F_nonEU+`v'_D_EU+`v'_F_EU
gen `v'_ETS= `v'_D_nonEU_ETS+`v'_D_EU_ETS+`v'_F_nonEU_ETS+`v'_F_EU_ETS
gen `v'ETSsugo=`v'_ETS/go
gen  ln`v'=log(`v')
gen  `v'sugo=`v'/go*100
}
*generate emission intensity and log, also multiplied with ETS prices and log of emission prices
local emis go emi emip
foreach e of local emis{
gen  ln`e'=log(`e')
gen  `e'sugo=`e'/go*100
}

****
replace emisugo = emi_intensity_own*100
****
drop gosugo
gen lagpch= L.d.lnemip
gen lag2pch=L2.d.lnemip

*Generate country group indicators
gen EA=0 //generate Euro Area Dummy and fill 
replace EA=1 if inlist(cou, "AUT", "BEL", "CYP", "DEU", "ESP", "EST", "FIN", "FRA", "GRC")
replace EA=1 if inlist(cou, "IRL", "ITA", "LTU", "LUX", "LVA", "MLT", "NLD", "PRT", "SVK")
replace EA=1 if inlist(cou, "SVN")

gen EU=0 //generate EU dummy and fill 
replace EU=1 if EA==1
replace EU=1 if inlist(cou, "BGR","CZE","DNK","HRV","HUN","POL", "ROU", "SWE")
replace EU=1 if cou=="CHE" | cou=="GBR"

generate ETS = 0 //generate ETS dummy and fill 
replace ETS = 1 if inlist(ind,"C17","C19","C20","C23","C24","DTE","H")

*generate ECBAM = 0
*replace ECBAM = 1 if inlist(ind,"C23","C24","H")


gen ETSEU=ETS*EU /* the treatment dummy is 1 for EU countries, specific sectors*/
*gen ECBAMEU=ECBAM*EU 

separate year, by(ind) gen(trend_ind) /*generate industry  trend */
forvalues i=1(1)34{
replace trend_ind`i'=0 if trend_ind`i'==.
}

separate year, by(cou) gen(trend_cou) /*generate country trend */
forvalues i=1(1)44{
replace trend_cou`i'=0 if trend_cou`i'==.
}


local var imp inp
local own D F
local cou EU nonEU
local sec ETS //ECBAM

*generate different ETS input and import shares by origin and type of ownership,
*and also multiplied by the log of emission prices 
foreach v of local var{
foreach o of local own{
foreach c of local cou{
foreach s of local sec{
gen sh_`v'_`o'_`c'_`s'=`v'_`o'_`c'_`s'/go*100
gen psh_`v'_`o'_`c'_`s'=sh_`v'_`o'_`c'_`s'*lnemip
*gen ln_`v'_`o'_`c'_`s'=ln(`v'_`o'_`c'_`s')

label var sh_`v'_`o'_`c'_`s' "`v' intensity of `s' products located in `c' by `o' companies"
label var psh_`v'_`o'_`c'_`s' "p. emissions X `v' intensity of `s' produced in `c' by `o' companies"
}
}
}
}


encode ind, gen(sec)
encode own, gen(pro)

********************************************************************************
*Regression on productions, regression results 3
*
*Base for regression table 3, 4, A10, and A11
********************************************************************************

label var impsugo "high emission import intensity"
label var inpsugo "high emission input intensity"

local em inp  //run regression for either inputs or imports imp
local own F D
local depvar lngo d.lngo //run regression for two different dependent variables 

local inp_ETS_L table3 //labelling of final table
local inp_nonETS_L table4
local inp_ETS_D tableA10
local inp_nonETS_D tableA11


foreach dep of local depvar{
if "`dep'"== "lngo"{
local dlab L //corresponding level to dependent variable 
}
else{
local dlab D
}

forvalues j =0(1)1{
foreach e of local em{

eststo clear

local regspec `e'
display "`e'" 
display `j' 

*run regression for Table 3, Table 4, Table A10 and Table A11 in a loop
*for table 3 and 4: dependent variable `dep' is the log of gross output (lngo)
*for table A10 and A11: dep var is the first difference of the log of gross output (d.lngo)

*pro is type of ownership, interaction of different variables as explained in 
*the text 
 
eststo `regspec'`dlab'_`j': xtreg `dep'  EU#pro#c.emisugo EU#pro#c.`e'sugo ///
EU#pro#c.sh_`e'_D_EU_ETS EU#pro#c.sh_`e'_D_nonEU_ETS EU#pro#c.sh_`e'_F_EU_ETS ///
EU#pro#c.sh_`e'_F_nonEU_ETS EU#pro#c.L.psh_`e'_D_EU_ETS EU#pro#c.L.psh_`e'_D_nonEU_ETS ///
 EU#pro#c.L.psh_`e'_F_EU_ETS EU#pro#c.L.psh_`e'_F_nonEU_ETS lagpch lag2pch ///
 i.y trend_cou* trend_ind* if ETS==`j',fe //


*reshape the results to to display results as explained in the text 

qui esttab, se nostar 
matrix C=r(coefs) //capture coefficients

eststo clear
local rnames : rownames C
display("`rnames'")
local models : coleq C
local models : list uniq models
display("`models'")
local i 0

*local e imp
local v1 emisugo
local v2 impsugo
local v3 sh_`e'_D_EU_ETS
local v4 sh_`e'_D_nonEU_ETS
local v5 sh_`e'_F_EU_ETS
local v6 sh_`e'_F_nonEU_ETS
local v7 psh_`e'_D_EU_ETS
local v8 psh_`e'_D_nonEU_ETS
local v9 psh_`e'_F_EU_ETS
local v10 psh_`e'_F_nonEU_ETS
*local v11 lagpch
*local v12 lag2pch

*Rename locals 
local m1 non-EU-D
local m2 non-EU-F
local m3 EU-D
local m4 EU-F

forvalues v=1/10{
    local ++i
    *local j 0
    capture matrix drop b
    capture matrix drop se
		forvalues d = 1/4{
		if `v'<=10{
		matrix tmp = C[4*(`v'-1)+`d',1]
		}
		else{
		matrix tmp = C[4*10+`v'-10,1]
		*matrix list tmp 
		}
		matrix colnames tmp = `m`d''
		matrix b = nullmat(b), tmp
		if `v'<=10{
		matrix tmp = C[4*(`v'-1)+`d',2]
		}
		else{
		matrix tmp = C[4*10+`v'-10,2]
		}
		matrix colnames tmp = `m`d''
		matrix se = nullmat(se), tmp
		}
		

    ereturn post b
    quietly estadd matrix se
    eststo `v`v''
}

if `j'==0{
	local ETS_lab "nonETS"
}
else{
	local ETS_lab "ETS"
}


local labels "emisugo" "`e'sugo" "\shortstack{sh_`e'_D\\_EU_\\ETS}" "\shortstack{sh_`e'_D_ \\ nonEU_\\ETS}" "\shortstack{sh_`e'_F_ \\ EU_\\ETS}" "\shortstack{sh_`e'_F_ \\ nonEU_\\ETS}" "\shortstack{psh_`e'_D_ \\ EU_\\ETS}" "\shortstack{psh_`e'_D_ \\ nonEU_\\ETS}" "\shortstack{psh_`e'_F_ \\ EU_\\ETS}" "\shortstack{psh_`e'_F_ \\ nonEU_\\ETS}" "dlogplag" "dlogplag2"

display("Results from paper, ``em'_`ETS_lab'_`dlab''")
esttab using "${exportpath}\\``em'_`ETS_lab'_`dlab''.tex", se mtitles(`labels') star(* 0.10 ** 0.05 *** 0.01) noobs replace
esttab, se mtitles(`labels') noobs replace star(* 0.10 ** 0.05 *** 0.01)

}
}
}

********************************************************************************
*Phase 3 dummies regression - Extension of Regression results 3
*
*Base for results Table A12 and Table A13
********************************************************************************

***********1- add time dummy

gen phase3 = 0
replace phase3 = 1 if y >=2013


local em inp //run regression for either inputs or imports
local own F D
local depvar d.lngo lngo //run regression for two different dependent variables 

local inp_ETS_L_phase3 tableA12 //labelling of final table
local inp_ETS_D_phase3 tableA13 


foreach dep of local depvar{
if "`dep'"== "lngo"{
local dlab L //corresponding level to dependent variable 
}
else{
local dlab D
}


foreach e of local em{

eststo clear

local regspec `e'
display "`e'" 
display `j' 

*eststo `regspec'D_`j': xtreg d.lngo  EU#pro#c.emisugo EU#pro#c.`e'sugo EU#pro#c.sh_`e'_D_EU_ETS EU#pro#c.sh_`e'_D_nonEU_ETS EU#pro#c.sh_`e'_F_EU_ETS EU#pro#c.sh_`e'_F_nonEU_ETS EU#pro#c.L.psh_`e'_D_EU_ETS EU#pro#c.L.psh_`e'_D_nonEU_ETS EU#pro#c.L.psh_`e'_F_EU_ETS EU#pro#c.L.psh_`e'_F_nonEU_ETS lagpch lag2pch i.y trend_cou* trend_ind* if ETS==`j',fe

eststo `regspec'`dlab'_`j': xtreg `dep'  ///
EU#pro#c.emisugo phase3#EU#pro#c.emisugo EU#pro#c.emisugo EU#pro#c.`e'sugo ///
EU#pro#c.sh_`e'_D_EU_ETS EU#pro#c.sh_`e'_D_nonEU_ETS EU#pro#c.sh_`e'_F_EU_ETS ///
 EU#pro#c.sh_`e'_F_nonEU_ETS EU#pro#c.L.psh_`e'_D_EU_ETS ///
 EU#pro#c.L.psh_`e'_D_nonEU_ETS EU#pro#c.L.psh_`e'_F_EU_ETS ///
 EU#pro#c.L.psh_`e'_F_nonEU_ETS lagpch lag2pch i.y trend_cou* trend_ind* if ETS==1,fe //for ETS sectors only


qui esttab, se nostar //keep(1.EU#2.pro#c.emisugo)
*mat list r(coefs)
matrix C=r(coefs)
matrix list C

eststo clear
local rnames : rownames C
display("`rnames'")
local models : coleq C
local models : list uniq models
display("`models'")
local i 0

*local e imp
local v1 emisugo
local v2 phase3_emisugo_0
local v3 phase3_emisugo
local v4 impsugo
local v5 sh_`e'_D_EU_ETS
local v6 sh_`e'_D_nonEU_ETS
local v7 sh_`e'_F_EU_ETS
local v8 sh_`e'_F_nonEU_ETS
local v9 psh_`e'_D_EU_ETS
local v10 psh_`e'_D_nonEU_ETS
local v11 psh_`e'_F_EU_ETS
local v12 psh_`e'_F_nonEU_ETS
*local v13 lagpch
*local v14 lag2pch


local m1 non-EU-D
local m2 non-EU-F
local m3 EU-D
local m4 EU-F

foreach v of numlist 1 3 4 5 6 7 8 9 10 11 12 {
    local ++i
    *local j 0
    capture matrix drop b
    capture matrix drop se
		forvalues d = 1/4{
		if `v'<=12{
		matrix tmp = C[4*(`v'-1)+`d',1]
		}
		else{
		matrix tmp = C[4*12+`v'-12,1]
		*matrix list tmp 
		}
		matrix colnames tmp = `m`d''
		matrix b = nullmat(b), tmp
		if `v'<=12{
		matrix tmp = C[4*(`v'-1)+`d',2]
		}
		else{
		matrix tmp = C[4*12+`v'-12,2]
		}
		matrix colnames tmp = `m`d''
		matrix se = nullmat(se), tmp
		}

    ereturn post b
    quietly estadd matrix se
    eststo `v`v''
}





local ETS_lab "ETS"


local labels "emisugo" "\shortstack{phase3# \\emisugo}" "`e'sugo" "\shortstack{sh_`e'_D\\_EU_\\ETS}" "\shortstack{sh_`e'_D_ \\ nonEU_\\ETS}" "\shortstack{sh_`e'_F_ \\ EU_\\ETS}" "\shortstack{sh_`e'_F_ \\ nonEU_\\ETS}" "\shortstack{psh_`e'_D_ \\ EU_\\ETS}" "\shortstack{psh_`e'_D_ \\ nonEU_\\ETS}" "\shortstack{psh_`e'_F_ \\ EU_\\ETS}" "\shortstack{psh_`e'_F_ \\ nonEU_\\ETS}" "dlogplag" "dlogplag2"

display("Results from paper, ``em'_`ETS_lab'_`dlab'_phase3'")

esttab using "${exportpath}\\``em'_`ETS_lab'_`dlab'_phase3'.tex", se mtitles(`labels') star(* 0.10 ** 0.05 *** 0.01) noobs replace
esttab, se mtitles(`labels') noobs replace star(* 0.10 ** 0.05 *** 0.01)

}
}


