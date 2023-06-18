*******************************************************************************
* Regression Analysis 1
* Base for Results displayed in Table 1
********************************************************************************

clear all
*ssc install outreg2

global path "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data" //data path
global exportpath "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data\final_results" //storage path for plots


*******************
*-1- Load and prepare data
*******************

*use "data\ETS.dta"
use "${path}\data\ETS.dta"

drop if ind == "20-99 All stationary installations" // drop aggregates
drop if ind == "21-99 All industrial installations (excl. combustion)"


egen id=group(country_code ind) //prepare panel data structure
encode country_code, gen(ccode)
encode ind, gen(icode)
drop if year=="05-07" | year=="08-12" | year=="13-20"
destring year, generate (y)

*merge prices
*merge m:1 y using "data\CFI2Z1_EUA_prices.dta"
merge m:1 y using "${path}\data\CFI2Z1_EUA_prices.dta"

tab y if _merge==1 //no data on 2005 in price data 
tab y if _merge==2 //no data on 2021 in ETS data 
drop if _merge==2
drop _merge 

xtset id y, yearly //


*****************************************
*generate additional variables 
*****************************************
gen pay_eme_sh=((surr_total-all_free)/surr_total)*100 //base for stringency: traded emissions 
replace pay_eme_sh=0 if pay_eme_sh<0 
gen ltote=log(surr_total) //log of tote surrendered emissions 

generate pay_eme_13=pay_eme_sh if y>2012
replace pay_eme_13=0 if pay_eme_13==. 

***price variables 
gen peme_sh = EUA_future_price*pay_eme_sh
gen peme_sh13 = EUA_future_price*pay_eme_13


separate y, by(ind) gen(trend_ind)
forvalues i=1(1)29{
replace trend_ind`i'=0 if trend_ind`i'==.
}


**************************************************
*selected regression for single table in latex, level and first difference 
**************************************************
gen L_ltote = L.ltote
gen L_pay_eme_sh = l.pay_eme_sh
gen L_pay_eme_13 = l.pay_eme_13
gen L_peme_sh13 = l.peme_sh13

gen D_ltote = d.ltote 
gen DL_ltote = d.L.ltote 

label var ltote "log(em)\$_t\$"
label var L_ltote "log(em)\$_{t-1}\$"
label var D_ltote "\$\Delta\$ log(em)\$_t\$"
label var DL_ltote "\$\Delta\$ log(em)\$_{t-1}\$"

label var pay_eme_sh "sh. em traded\$_t\$"
label var L_pay_eme_sh "sh. em traded\$_t-1\$"

label var peme_sh13 "ETS3: p. emsh.\$_t\$ "
label var L_peme_sh13 "ETS3: p. emsh.\$_t-1\$"


label var pay_eme_13 "ETS3: sh. em traded\$_t\$"
label var L_pay_eme_13 "ETS3: sh. em traded\$_t-1\$"

**************************************************
*Run regression, each column subsequently 
**************************************************
local regspec Table1

xtreg ltote L_ltote pay_eme_sh L_pay_eme_sh pay_eme_13  L_pay_eme_13  i.y i.ccode i.icode,re
estimates store `regspec'_c1
xtreg ltote L_ltote  pay_eme_sh L_pay_eme_sh pay_eme_13  L_pay_eme_13 peme_sh13 i.y i.ccode i.icode trend_ind*,re
estimates store `regspec'_c2
xtreg D_ltote L_ltote DL_ltote pay_eme_sh L_pay_eme_sh pay_eme_13 L_pay_eme_13 i.y i.ccode i.icode,re 
estimates store `regspec'_c3
xtreg D_ltote L_ltote DL_ltote pay_eme_sh L_pay_eme_sh peme_sh13 L_peme_sh13 i.y i.ccode trend_ind*,re
estimates store `regspec'_c4


**************************************************
*Save results 
**************************************************
estimates restore `regspec'_c1
outreg2 using "${exportpath}\\`regspec'.tex", drop(i.y i.ccode i.icode) nocons addstat(R2 overall, e(r2_o), R2 between ,e(r2_b)) addtext(Country FE, YES, Industry FE, YES, Year FE, YES)  nor2 label replace 
estimates restore `regspec'_c2
outreg2 using "${exportpath}\\`regspec'.tex", drop(i.y i.ccode i.icode trend_ind* o.trend*) nocons addstat(R2 overall, e(r2_o), R2 between ,e(r2_b)) addtext(Country FE, YES, Industry FE, YES, Year FE, YES, Year Ind Trend, YES) nor2 label append
estimates restore `regspec'_c3
outreg2 using "${exportpath}\\`regspec'.tex", drop(i.y i.ccode i.icode) nocons addstat(R2 overall, e(r2_o), R2 between ,e(r2_b)) addtext(Country FE, YES, Industry FE, YES, Year FE, YES)  nor2 label append  
estimates restore `regspec'_c4
outreg2 using "${exportpath}\\`regspec'.tex", drop(i.y i.ccode i.icode trend_ind* o.trend*) nocons addstat(R2 overall, e(r2_o), R2 between ,e(r2_b)) addtext(Country FE, YES, Industry FE, YES, Year FE, YES, Year Ind Trend, YES) nor2 label append  

