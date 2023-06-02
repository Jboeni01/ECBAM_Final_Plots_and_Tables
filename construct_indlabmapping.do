global path "C:\Users\u0149894\Desktop\Code\ECB_ECBAM_data"


*sector names 
import excel "${path}\data\raw\ReadMe_analyticalAMNE.xlsx", cellrange(G3:H37) firstrow sheet("Country_Industry") clear
rename Code ind
rename Industry ind_lab

save "${path}\data\ind_lab.dta", replace
