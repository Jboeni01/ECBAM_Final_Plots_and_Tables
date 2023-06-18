********************************************************************************
* This code generates Figure A2 (Appendix)
*
********************************************************************************

global datapath "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data\data" //data path
global exportpath "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data\descr_graphs" //storage path for plots

*******************
*-1- Load and prepare data
*******************

use "${datapath}\imports_inputs_GO_allyears.dta", clear

gen EA=0 //generate Euro Area Dummy & fill 
replace EA=1 if inlist(cou, "AUT", "BEL", "CYP", "DEU", "ESP", "EST", "FIN", "FRA", "GRC")
replace EA=1 if inlist(cou, "IRL", "ITA", "LTU", "LUX", "LVA", "MLT", "NLD", "PRT", "SVK")
replace EA=1 if inlist(cou, "SVN")

gen EU=0 //generate EU Dummy & fill 
replace EU=1 if EA==1
replace EU=1 if inlist(cou, "BGR","CZE","DNK","HRV","HUN","POL", "ROU", "SWE")
replace EU=1 if cou=="CHE" | cou=="GBR"

generate ETS = 0 //generate ETS sector dummy & fill 
replace ETS = 1 if inlist(ind,"C17","C19","C20","C23","C24","DTE","H") //ETS sectors


collapse (sum) *_*_* go CO2emission, by(year ind own EU) //collapse

gen imports=imports_D_nonEU+imports_F_nonEU+imports_D_EU+imports_F_EU //all imports

gen input=input_D_nonEU+input_F_nonEU+input_D_EU+input_F_EU //all inputs 

**********************
*-2- Compute emissions intensity by type of ownership sector and country from 
*emission level by sector country*
**********************
*assumptions: emissions are proportional to the share of input from ETS sectors 
*in total inputs*100


gen input_ETS=input_D_nonEU_ETS+input_F_nonEU_ETS+input_D_EU_ETS+input_F_EU_ETS //ETS sector inputs
gen inp_ei= input_ETS/input*100 //share of ETS sector inputs on all inputs "energy intensity"

gen goinpei=go*inp_ei //output multiplied by input energy intensity, total amount of energy intensive inputs needed for output generation 
bysort year EU ind: egen sinp_ei=sum(inp_ei) //sum of energy intensity across type of ownership, 
bysort year EU ind: egen sumgo=sum(goinpei) //sum of total amount of energy intensive inputs needed for output generation across type of ownership
gen av_ei=CO2emission*sinp_ei/sumgo //

gen ei=av_ei*inp_ei/(sinp_ei-inp_ei)
*this is ownership specific energy intensity based on the share of ETS in total 
*inputs of each class of firms (D vs F)

**********************
*-3- Rearrange Data & label 
**********************
order year EU own ind go CO2emission inp_ei sinp_ei sumgo av_ei ei
sort year ind EU own  

egen id=group( EU own ind)
xtset id year, yearly


local var imports input
local ind C19 C23 C24 DTE H
local own D F

gen ind_name="Agriculture, forestry & fishing" if ind=="A"
replace ind_name="Mining & extraction of energy producing products" if ind=="B"
replace ind_name="Food products, beverages & tobacco" if ind=="C10T12"
replace ind_name="Textiles, wearing apparel, leather & related products" if ind=="C13T15"
replace ind_name="Wood & products of wood & cork" if ind=="C16"
replace ind_name="Paper products & printing" if ind=="C17T18"
replace ind_name="Coke & refined petroleum products" if ind=="C19"
replace ind_name="Chemicals & pharmaceutical products" if ind=="C20T21"
replace ind_name="Rubber & plastic products" if ind=="C22"
replace ind_name="Other non-metallic mineral products" if ind=="C23"
replace ind_name="Basic metals" if ind=="C24"
replace ind_name="Fabricated metal products" if ind=="C25"
replace ind_name="Computer, electronic, & optical products" if ind=="C26"
replace ind_name="Electrical equipment" if ind=="C27"
replace ind_name="Machinery & equipment nec" if ind=="C28"
replace ind_name="Motor vehicles & (semi-)trailers" if ind=="C29"
replace ind_name="Other transport equipment" if ind=="C30"
replace ind_name="Other manuf., repair, installation" if ind=="C31T33"
replace ind_name="Electricity, gas, water, sewerage, waste, remediation services" if ind=="DTE"
replace ind_name="Construction" if ind=="F"
replace ind_name="Wholesale & retail trade; repair of motor vehicles" if ind=="G"
replace ind_name="Transport & storage" if ind=="H"
replace ind_name="Accomodation & food services" if ind=="I"
replace ind_name="Publishing, audiovisual & broadcasting acitvities" if ind=="J58T60"
replace ind_name="Telecommunications" if ind=="J61"
replace ind_name="IT & other information services" if ind=="J62T63"
replace ind_name="Financial & insurance activities" if ind=="K"
replace ind_name="Real estate activities" if ind=="L"
replace ind_name="Other business services" if ind=="MTN"
replace ind_name="Public admin. & defence; compulsory social security" if ind=="O"
replace ind_name="Education" if ind=="P"
replace ind_name="Human health & social work" if ind=="Q"
replace ind_name="Arts, entertainment, recreation & other service activities" if ind=="RTS"

**********************
*-4- Plot Data 
**********************

levelsof ind_name, local(ind_names)

foreach j of local ind_names {
    twoway ///
        (tsline ei if own=="D" & EU==1 & ind_name=="`j'", lcolor(red) lpattern(dash)) ///
        (tsline ei if own=="F" & EU==1 & ind_name=="`j'", lcolor(red)) ///
        (tsline ei if own=="D" & EU==0 & ind_name=="`j'", lcolor(dknavy) lpattern(dash)) ///
        (tsline ei if own=="F" & EU==0 & ind_name=="`j'", lcolor(dknavy)), ///
        title("`j'") xlabel(2005(1)2016) xtitle("") ytitle("") ///
        legend(order(1 "D-EU" 2 "F-EU" 3 "D-non EU" 4 "F-non EU") rows(1)) ///
        legend(position(bottom))
    
    graph export "${exportpath}\EI_`j'.pdf", replace
}
