*******************************************************************************
* Set of Descriptives 1 - Emission Intensities 
* Base for Figure 1 & Figure A1
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

gen emisugo = CO2emission/go //construct CO2 intensity measure (kg CO2)/USD

generate ETS = 0 //generate ETS dummy & fill 
replace ETS = 1 if inlist(ind,"C17","C19","C20","C23","C24","DTE","H")


gen ind_lab_comb = ind + " - " + ind_lab //variable for title name of plots 

bysort year cou: egen go_indsh = sum(go) //total output by country & year across industries 
drop if cou=="ROW" //drop rest of the world, aggregation in this case meaningless
gsort year ind -go
by year ind: gen cousec_rank = _n //country ranking for each industry by gross output 
replace go_indsh = go/go_indsh //share of each industry on total output by country


levelsof ind_lab_comb, local(inds)

foreach l of local inds {
	preserve
	di "`l'"
	keep if ind_lab_comb=="`l'" & year==2016 //plots for 2016
	
	gsort -emisugo //sort

	*gen cou_id = _n //ranking by emission intensity 
	
	*drop industry-country-observation if share on total output by country is 
	*below 1 percent when the industry-country-observation is not in the top 5 
	*in terms of gross output for that industry  
	drop if (go_indsh<0.01 | go_indsh==.) & cousec_rank>5 
	
	*drop cou_id 
	gsort -emisugo
	gen cou_id = _n
	
	qui sum emisugo
	local ymax=r(max) //store maximum of emission intensity for ylabel 
	
	qui sum cou_id 
	
	di r(max)
	local xlabmax = r(max)
	
	labmask cou_id, values(cou) //x-axis labelling
	
	*plot emission intensity, barplot, red for EU, blue owtherwise 
	twoway bar emisugo cou_id, barw(.6) ysc(r(0 `ymax')) xlabel(1(1)`r(max)', valuelabel) bcolor(dknavy) || ///
	bar emisugo cou_id if cou=="EU", barw(.6) bcolor(red) leg(off) xtitle("") ytitle("Emissions per unit of production (kg/USD)") title("`l'")
	
	local ind=ind[1]

	graph export "${exportpath}\descr_emisugo_2016_`ind'.pdf", replace
	
	restore 
  }

