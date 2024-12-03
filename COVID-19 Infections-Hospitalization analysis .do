
*** Set a working diretory*****
global DATA="/Users/marcelkitenge/Documents/WHO Consultancy/Limpopo Documents/Hospital Admissions Report /Data"

**** Importort sitrep *****

import excel "$DATA\New_Sitrep-23Feb2021.xlsx", sheet("Dist_sub") firstrow clear // 38 variables 

************* Data processing ***********
br 
sort report_date // sort  in descending order 

generate  admit_time= dofc(AdmissionDate)
generate DoB=dofc(dob) 
generate birthDate=dofc(BirthDate)
generate DoPospeciCol=dofc(first_pos_spec_col_date)

format admit_time DoB birthDate DoPospeciCol %td

//list admit_time report_date, ab(12)

count if Age==. // 2060 missing information on age 

count if Age==. & (birthDate!=. | DoB!=.)
br Age birthDate DoB if Age==. & (birthDate!=. | DoB!=.) // 310 observations have no age while having date of birthDate

*** Generate age variabel based on DOB and Date of positive specimen collection*******

gen age=(DoPospeciCol-birthDate)/365.25 
replace Age=age if Age==.

count if Age==.
count if Age==. & (birthDate!=. | DoB!=.) // 55

***** Case_ID has characters , which will prevent merging 

drop if strmatch(case_id ,"*N*")
drop if case_id=="A160720"
drop if case_id=="vhe"
destring case_id, replace
br case_id
duplicates report case_id // check for duplicates 

rename AdmissionDate AdmissionDate1
rename DiagnosisDate DiagnosisDate1
rename DiagnosisDate DxDate
count

**** save Sitrep

save "$DATA\sitrep.dta", replace 


				*******************************
**************** Opening Hospitalization data *********************
				*******************************

import excel "$DATA\upadated-Datcov-24Feb2021.xlsx",  firstrow clear // 45 variables 

sort DiagnosisDate
 
rename NICDCaseID case_id
duplicates report case_id // 12186 uniques

duplicates tag case_id , gen(dup)
tab dup

duplicates report PatientId //  15016 uniques 

* what is the difference between case_id and PatientId ? 

**** Checking for multiple covid-19 episode ******

gsort PatientId DiagnosisDate
bysort PatientId: gen order=_n
tab order // There alot of duplicates, many patients. who have different diagnosis dates
br PatientId DiagnosisDate Name Surname Sex order

**** Dropping the duplicates 

duplicates report case_id
duplicates drop case_id,force
duplicates report case_id
count if case_id==. // 12990 patients have no case_id

count if Age==. // No missing data on age 
count if AdmissionDate==.

rename Age Ageadmission
rename AdmissionDate DoA

count 

drop Agegroup DiagnosisProvince Province SubDistrict ExportDate

**** Save hospital admission data 

save "$DATA\Admissions.dta", replace 


******* Merging databases *****


use "$DATA\sitrep.dta", clear 

duplicates report case_id
merge 1:1 case_id using "$DATA\Admissions.dta" // 509 patients did merge from using 

count if _merge==2 & Age>=50 & Age!=. // 0 are aged 60+ yrs 

br Ageadmission Age age birthDate BirthDate DxDate DoA if Age==.

drop age

********* Trying to  expond age variable *******

gen age=(DoA-birthDate)/365.25
replace Age=age if Age==.
count if Age==.
count if Age==. & _merge==3

***** Applying inclusion criteria 

keep if Age>=50 & Age!=.

sort Age
count if Age==.

br  Age age birthDate BirthDate DxDate DoA 
br Age DoA DxDate
count

save "$DATA\Merged-admi+sitrep.dta", replace


			************************************
************ Generating era, admission and time **********
			************************************
			
use "$DATA\Merged-admi+sitrep.dta", clear 

*** Generating era
gen era=.
replace era=0 if DoPospeciCol<date("17may2021","DMY") & DoPospeciCol!=.
replace era=1 if DoPospeciCol>=date("17may2021","DMY") & DoPospeciCol!=.
tab _merge era , m
sort DoPospeciCol
br era DoPospeciCol

******* Generating admission *********

gen admission=. if _merge
replace admission=1 if DoA!=.
replace admission=0 if DoA==.

******* Flowchart **********

bysort era : count 
bysort era : tab admission

tabstat Age, statistics( mean sd ) by(era)
encode gender, gen(gender_)
label list gender_
replace gender_=. if gender_==4
bysort era: tab gender_
tab gender_

bysort era: tab admission
bysort era: tab EverVentilate

generate sex_=.
replace sex_=1 if gender_==3
replace sex_=0 if gender_==1


****** DATA Processing for Interrupted Time Series Analaysis ********

gen rxweek=week(DoPospeciCol)
gen rxyr=year(DoPospeciCol)
gen rxmn=month(DoPospeciCol)
gen mnth_n = month(DoPospeciCol) if rxyr==2020
replace mnth_n = month(DoPospeciCol) + 12 if rxyr==2021
replace mnth_n= month(DoPospeciCol) + 12 if rxyr==2022

gen rxweek1=week(DoA)
gen rxyr1=year(DoA)
gen rxmn1=month(DoA)
gen mnth_n1 = month(DoA) if rxyr==2020
replace mnth_n1 = month(DoA) + 12 if rxyr==2021
replace mnth_n1 = month(DoA) + 12 if rxyr==2022
glm admission era, family(poisson) link(log) eform
glm admission mnth_n, family(poisson) link(log) eform
glm admission Age, family(poisson) link(log) eform
//glm admission sex_, family(poisson) link(log) eform

glm admission era mnth_n Age sex_, family(poisson) link(log) eform

glm EverVentilate era mnth_n Age sex_, family(poisson) link(log) eform




sort DoPospeciCol
tab rxyr mnth_n 

br era rxyr mnth_n DoPospeciCol Age admission

save "$DATA\FinalAdmission.dta", replace


					*****************************
********************* 1. Confirmed COVDI-19 cases **************
					*****************************

use "$DATA\FinalAdmission.dta", clear 

gen confirmed=1 if DoPospeciCol!=.
tab confirmed
collapse (count) confirmed , by(rxyr rxmn)

******* Processing variables for ITS

gen era=0 
replace era=1 if rxyr==2021 & rxmn>=5

******* Generte time varaibesl using sequence 
gen mnth_n=_n

***** Declaring time as tise series

tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa confirmed, single trperiod(15) lag(15) posttrend figure

glm confirmed era mnth_n , family(poisson) link(log) eform


**** Assessing for overdispersion *******

glm confirmed  era mnth_n, family(poisson) link(log) scale(x2) eform

* (c) Adjust for seasonality
/* installation of the "circular" package. or type the following command "ssc install circular" find packages select Help > SJ and User-written Programs, 
and click on search */

*we need to create a degrees variable for time divided by the number of time points in a year (i.e. 12 for months)
gen degrees=(mnth_n/12)*360

*we then select the number of sine/cosine pairs to include:
fourier degrees, n(2)

*these can then be included in the model
glm confirmed era cos* sin* mnth_n, family(poisson) link(log) scale(x2) eform


*we can again check for autocorrelation
predict res2, r
twoway (scatter res2 mnth_n)(lowess res2 mnth_n),yline(0)
tsset mnth_n
ac res2
pac res2, yw


*predict and plot of seasonally adjusted model**
predict pred2, nooffset
twoway (scatter confirmed mnth_n) (line pred2 mnth_n, lcolor(red)), title("TB Treatment Initiation:Jan,2018-July,2020") ///
ytitle(Monthly treatment Initiations) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(6)36) xtitle(Timepoint month) xtitle(year) xline(15)  scheme(sj) // first line december Holiday


/*it is sometimes difficult to clearly see the change graphically in the seasonally adjusted model
therefore it can be useful to plot a straight line as if all months were the average to produce a
'deseasonalised' trend. */

egen avg_cos_1 = mean(cos_1)
egen avg_sin_1 = mean(sin_1)
egen avg_cos_2 = mean(cos_2)
egen avg_sin_2 = mean(sin_2)

drop cos* sin*

rename avg_cos_1 cos_1
rename avg_sin_1 sin_1
rename avg_cos_2 cos_2
rename avg_sin_2 sin_2


*this can then be added to the plot as a dashed line 
predict pred3, nooffset

twoway (scatter confirmed mnth_n) (line pred2 mnth_n, lcolor(green)) (line pred3 mnth_n, lcolor(red) lpattern(dash)), title("Confirmed COVID-19 Cases:March,2020-Sept,2021") ///
ytitle(Monthly Confirmed COVID-19 cases) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(6)23) xtitle(Timepoint month) xline(15) scheme(sj)


*********************************************************
** additional Verifcations
**********************************************************
***add a change in slope

*generate interaction term between intervention and time centered at the time of intervention
gen inter_eratime = era*(mnth_n-36)


*restore fourier variables that were previously changed
drop cos* sin* degrees
gen degrees=(mnth_n/12)*360
fourier degrees, n(2)

*add the interaction term to the model

glm confirmed era cos* sin* mnth_n, family(poisson) link(log) eform // this is the final model to include in the analysi

*********** The following codes perfrom sensitivity analysis **********

glm confirmed era inter_eratime cos* sin* mnth_n, family(poisson) link(log) scale(x2) eform

glm confirmed era cos* sin* mnth_n, family(poisson) link(log) scale(x2) eform


							 **************************
**************************** Hospital Admissions ***********************
							***************************

use "$DATA\FinalAdmission.dta", clear 

keep if admission==1
collapse (count) admission , by(rxyr1 rxmn1)

drop if rxyr1==.
gen era=0 
replace era=1 if rxyr1==2021 & rxmn1>=5

gen mnth_n=_n


tsset mnth_n
itsa admission, single trperiod(14) lag(14) posttrend figure


predict pred, nooffset
twoway (scatter admission mnth_n) (line pred mnth_n, lcolor(red)) , title("Confirmed COVID-19 Cases overtime Jan,2018-July,2020") ///
ytitle(Number of cases) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)36) xtitle(Timepoint-Month) xline(15) scheme(sj)


glm admission era mnth_n , family(poisson) link(log) eform


glm admission  era mnth_n, family(poisson) link(log) scale(x2) eform

* (c) Adjust for seasonality

*we need to create a degrees variable for time divided by the number of time points in a year (i.e. 12 for months)
gen degrees=(mnth_n/12)*360

*we then select the number of sine/cosine pairs to include:
fourier degrees, n(2)

*these can then be included in the model
glm admission era cos* sin* mnth_n, family(poisson) link(log) scale(x2) eform


*we can again check for autocorrelation
predict res2, r
twoway (scatter res2 mnth_n)(lowess res2 mnth_n),yline(0)
tsset mnth_n
ac res2
pac res2, yw


*predict and plot of seasonally adjusted model**
predict pred2, nooffset
twoway (scatter admission mnth_n) (line pred2 mnth_n, lcolor(red)), title("TB Treatment Initiation:Jan,2018-July,2020") ///
ytitle(Monthly treatment Initiations) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(6)36) xtitle(Timepoint month) xtitle(year) xline(15)  scheme(sj) // first line december Holiday


/*it is sometimes difficult to clearly see the change graphically in the seasonally adjusted model
therefore it can be useful to plot a straight line as if all months were the average to produce a
'deseasonalised' trend. */

egen avg_cos_1 = mean(cos_1)
egen avg_sin_1 = mean(sin_1)
egen avg_cos_2 = mean(cos_2)
egen avg_sin_2 = mean(sin_2)

drop cos* sin*

rename avg_cos_1 cos_1
rename avg_sin_1 sin_1
rename avg_cos_2 cos_2
rename avg_sin_2 sin_2


*this can then be added to the plot as a dashed line 
predict pred3, nooffset

twoway (scatter admission mnth_n) (line pred2 mnth_n, lcolor(green)) (line pred3 mnth_n, lcolor(red) lpattern(dash)), title("Hospital admissions:March,2020-Sept,2021") ///
ytitle(Monthly hospital admissions) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(6)25) xtitle(imepoint month) xline(14) scheme(sj)


*********************************************************
** additional material
**********************************************************
***add a change in slope

*generate interaction term between intervention and time centered at the time of intervention
gen inter_eratime = era*(mnth_n-36)


*restore fourier variables that were previously changed
drop cos* sin* degrees
gen degrees=(mnth_n/12)*360
fourier degrees, n(2)

*********** The following codes perfrom sensitivity analysis **********

*add the interaction term to the model

glm admission era cos* sin* mnth_n, family(poisson) link(log) eform


glm admission era inter_eratime cos* sin* mnth_n, family(poisson) link(log) scale(x2) eform
glm admission era cos* sin* mnth_n, family(poisson) link(log) scale(x2) eform



**************** Ever needed a ventilated************


use "$DATA\FinalAdmission.dta", clear 

keep if EverVentilated==1
collapse (count) EverVentilated , by(rxyr1 rxmn1)

gen era=0 
replace era=1 if rxyr==2021 & rxmn>=5

gen mnth_n=_n


tsset mnth_n
itsa EverVentilated , single trperiod(15) lag(15) posttrend figure

glm EverVentilated era mnth_n , family(poisson) link(log) eform


/*
predict pred, nooffset

twoway (scatter confirmed mnth_n) (line pred mnth_n, lcolor(red)) , title("Confirmed COVID-19 Cases overtime Jan,2018-July,2020") ///
ytitle(Number of cases) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)36) xtitle(Timepoint-Month) xline(15) scheme(sj)
*/

glm EverVentilated  era mnth_n, family(poisson) link(log) scale(x2) eform

* (c) Adjust for seasonality

*we need to create a degrees variable for time divided by the number of time points in a year (i.e. 12 for months)
gen degrees=(mnth_n/12)*360

*we then select the number of sine/cosine pairs to include:
fourier degrees, n(2)

*these can then be included in the model
glm EverVentilated era cos* sin* mnth_n, family(poisson) link(log) scale(x2) eform


*we can again check for autocorrelation
predict res2, r
twoway (scatter res2 mnth_n)(lowess res2 mnth_n),yline(0)
tsset mnth_n
ac res2
pac res2, yw

*predict and plot of seasonally adjusted model**
predict pred2, nooffset
twoway (scatter EverVentilated mnth_n) (line pred2 mnth_n, lcolor(red)), title("TB Treatment Initiation:Jan,2018-July,2020") ///
ytitle(Monthly treatment Initiations) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(6)36) xtitle(Timepoint month) xtitle(year) xline(15)  scheme(sj) // first line december Holiday


/*it is sometimes difficult to clearly see the change graphically in the seasonally adjusted model
therefore it can be useful to plot a straight line as if all months were the average to produce a
'deseasonalised' trend. */

egen avg_cos_1 = mean(cos_1)
egen avg_sin_1 = mean(sin_1)
egen avg_cos_2 = mean(cos_2)
egen avg_sin_2 = mean(sin_2)

drop cos* sin*

rename avg_cos_1 cos_1
rename avg_sin_1 sin_1
rename avg_cos_2 cos_2
rename avg_sin_2 sin_2


*this can then be added to the plot as a dashed line 
predict pred3, nooffset

twoway (scatter EverVentilated mnth_n) (line pred2 mnth_n, lcolor(green)) (line pred3 mnth_n, lcolor(red) lpattern(dash)), title("Confirmed COVID-19 Cases:March,2020-Sept,2021") ///
ytitle(Monthly Confirmed COVID-19 cases) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(6)23) xtitle(Timepoint month) xline(15) scheme(sj)


*********************************************************
** additional Analyses 
**********************************************************
***add a change in slope

*generate interaction term between intervention and time centered at the time of intervention
gen inter_eratime = era*(mnth_n-36)


*restore fourier variables that were previously changed
drop cos* sin* degrees
gen degrees=(mnth_n/12)*360
fourier degrees, n(2)


*********** The following codes perfrom sensitivity analysis **********

*add the interaction term to the model

glm EverVentilated era cos* sin* mnth_n, family(poisson) link(log) eform

glm EverVentilated era inter_eratime cos* sin* mnth_n, family(poisson) link(log) scale(x2) eform
glm EverVentilated era cos* sin* mnth_n, family(poisson) link(log) scale(x2) eform // accountiing for ever dispersion 
