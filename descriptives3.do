*******************************************************************************
* Set of Descriptives 3 - Emission Intensities of countries relative to EU 2016
* Base for Table A2
********************************************************************************

global datapath "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data"
global exportpath "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data\descr_graphs"

use "${datapath}\data\imports_inputs_GO_allyears.dta", clear //load data, contains CO2 emissions and output

*-1- Data preparation:
collapse (sum) CO2emission go, by(year cou ind) //aggregate across type of ownership 

merge m:1 ind using "${path}\data\ind_lab.dta" //add industry labels
drop _m

gen EA=0 //generate Euro Area dummy & fill
replace EA=1 if inlist(cou, "AUT", "BEL", "CYP", "DEU", "ESP", "EST", "FIN", "FRA", "GRC")
replace EA=1 if inlist(cou, "IRL", "ITA", "LTU", "LUX", "LVA", "MLT", "NLD", "PRT", "SVK")
replace EA=1 if inlist(cou, "SVN")

gen EU=0 //generate EU dummy & fill
replace EU=1 if EA==1
replace EU=1 if inlist(cou, "BGR","CZE","DNK","HRV","HUN","POL", "ROU", "SWE")
*replace EU=1 if cou=="CHE" | cou=="GBR"

replace cou="EU" if EU==1 //replace country name for aggregation

collapse (sum) CO2emission go , by(year cou ind ind_lab) //aggregate for EU by year and industry

keep if year==2016

*-2- Variable construction:
gen emisugo = CO2emission/go //construct CO2 intensity measure (kg CO2)/USD
gen emisugo_help = . //help variable, used to fill EU values of CO2 emission intensity
replace emisugo_help = emisugo if cou=="EU"

bysort year ind: egen emisugo_EU = max(emisugo_help) //fill variable :(max) is used  bc any other entry other than EU is missing 

gen emisugo_relEU = emisugo/emisugo_EU //generate CO2 intensity relative to EU

*-3- Clean and arrange Data 
sort ind cou
keep year cou ind ind_lab emisugo_relEU

reshape wide emisugo_relEU, i(year ind ind_lab) j(cou) string

rename emisugo_relEU* *

drop EU 
drop if ind == "T"

*-4- Display results, which are basis for Table A2 
br //Results used for Table A2 
