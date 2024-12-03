

global DATA="/Users/marcelkitenge/Documents/WHO Consultancy/WHO Meetings and documents/Essential Health Services /"

set scheme white_tableau
//set scheme s2color
				  **********************
*******************   1. PHC Headcount   ******************
				 ***********************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("PHC Headcount") firstrow clear 

gen mnth_n=_n
drop dataname

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Total_Province

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Total_Province, statistics( mean p50 p25 p75 iqr ) by(era)

label var mnth_n "Time-month"
label var Total_Province "Number of headcount"
**** Declaring time as tise series

tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Total_Province, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/PHC_Headcount.png", as(png) name("Graph") replace 

glm Total_Province era, family(poisson) link(log) eform
glm Total_Province era mnth_n, family(poisson) link(log) eform
glm Total_Province era mnth_n, family(poisson) link(log) scale(x2) eform

//glm Capricorn era mnth_n , family(poisson) link(log) eform
//glm Mopani era mnth_n, family(poisson) link(log) eform
//glm Sekhukhune era mnth_n, family(poisson) link(log) eform

****** Alternative Analysis *************
predict pred, nooffset
twoway (scatter Total_Province mnth_n) (line pred mnth_n, lcolor(red)) , title("PHC Headcount Jan,2019-,dec 2021") ///
ytitle(Number of people) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)34) xtitle(Timepoint-Month) xline(15) scheme(sj)


* (c) Adjust for seasonality

*we need to create a degrees variable for time divided by the number of time points in a year (i.e. 12 for months)
gen degrees=(mnth_n/12)*360

*we then select the number of sine/cosine pairs to include:
fourier degrees, n(2)

*these can then be included in the model
glm Total_Province era cos* sin* mnth_n, family(poisson) link(log) scale(x2) eform


*we can again check for autocorrelation
predict res2, r
twoway (scatter res2 mnth_n)(lowess res2 mnth_n),yline(0)
tsset mnth_n
ac res2
pac res2, yw


*predict and plot of seasonally adjusted model**
predict pred2, nooffset

twoway (scatter Total_Province mnth_n) (line pred2 mnth_n, lcolor(red)), title("TB Treatment Initiation:Jan,2018-July,2020") ///
ytitle(Monthly treatment Initiations) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(6)36) xtitle(Timepoint month) xtitle(year) xline(15)  
//scheme(sj) // first line december Holiday


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

twoway (scatter Total_Province mnth_n) (line pred2 mnth_n, lcolor(green)) (line pred3 mnth_n, lcolor(red) lpattern(dash)), title("Hospital admissions:March,2020-Sept,2021") ///
ytitle(Monthly hospital admissions) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(6)25) xtitle(imepoint month) xline(14) scheme(sj)



				  ************************
*******************  2. Fully Immunized ******************
				 *************************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("Immunzed Fully<1year") firstrow clear 

drop dataname

gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Immunization

label var Immunization "Number of children fully Immunized"

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

label var mnth_n "Time-month"

bysort era : count
tabstat Immunization, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Immunization, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/Immunization.png", as(png) name("Graph") replace 


glm Immunization era, family(poisson) link(log) eform
glm Immunization era mnth_n, family(poisson) link(log) eform
glm Immunization era mnth_n, family(poisson) link(log) scale(x2) eform


****** Alternative Analysis *************
predict pred, nooffset
twoway (scatter Immunization mnth_n) (line pred mnth_n, lcolor(red)) , title("Fully Immunized <1 yr Jan,2019-,Sept 2020") ///
ytitle(Children fully Immunized) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)34) xtitle(Timepoint-Month) xline(15) scheme(sj)


				  **********************
*******************   3. HIV testing  ******************
				 ***********************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("HIV Test done") firstrow clear 

drop dataname

gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Total_hivTest

label var Total_hivTest "Number of HIV testiing"
label var mnth_n "Time-month"


gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Total_hivTest, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Total_hivTest, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/HIVTesing.png", as(png) name("Graph") replace 


glm Total_hivTest era, family(poisson) link(log) eform
glm Total_hivTest era mnth_n, family(poisson) link(log) eform
glm Total_hivTest era mnth_n, family(poisson) link(log) scale(x2) eform


****** Alternative Analysis *************
predict pred, nooffset
twoway (scatter Total_hivTest mnth_n) (line pred mnth_n, lcolor(red)) , title("HIV testing overtime Jan,2019-,Sept 2020") ///
ytitle(Number of Tests) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)34) xtitle(Timepoint-Month) xline(15) scheme(sj)



				**********************
******************* 4. TROA   ***************
				***********************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("ART client remain on ART ") firstrow clear 

drop dataname

gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Total_TROA

label var Total_TROA "Number of TROA"

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Total_TROA, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Total_TROA, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/TROA.png", as(png) name("Graph") replace 


glm Total_TROA era, family(poisson) link(log) eform
glm Total_TROA era mnth_n, family(poisson) link(log) eform

glm Capricorn era mnth_n , family(poisson) link(log) eform
glm Mopani era mnth_n, family(poisson) link(log) eform
glm Sekhukhune era mnth_n, family(poisson) link(log) eform

****** Alternative Analysis *************
predict pred, nooffset
twoway (scatter Total_TROA mnth_n) (line pred mnth_n, lcolor(red)) , title("TROA overtime Jan,2019-,September 2020") ///
ytitle(Number of people) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)34) xtitle(Timepoint-Month) xline(15) scheme(sj)


glm Total_TROA era mnth_n, family(poisson) link(log) scale(x2) eform



				  **********************************
*******************   5. HIV Positive not on ART  ******************
				 **********************************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("HIV positive not on ART") firstrow clear 

drop dataname

gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Total_NotART

label var Total_NotART "Number of PLHIV"

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Total_NotART, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Total_NotART, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/NotONART.png", as(png) name("Graph") replace 



glm Total_NotART era, family(poisson) link(log) eform
glm Total_NotART era mnth_n, family(poisson) link(log) eform

glm Capricorn era mnth_n , family(poisson) link(log) eform
glm Mopani era mnth_n, family(poisson) link(log) eform
glm Sekhukhune era mnth_n, family(poisson) link(log) eform

****** Alternative Analysis *************
predict pred, nooffset
twoway (scatter Total_NotART mnth_n) (line pred mnth_n, lcolor(red)) , title("TROA overtime Jan,2019-,September 2020") ///
ytitle(Number of people) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)34) xtitle(Timepoint-Month) xline(15) scheme(sj)


glm Total_NotART era mnth_n, family(poisson) link(log) scale(x2) eform



				  **********************************
*******************   6. Started ART duringm month ******************
				 **********************************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("Started on ART during month") firstrow clear 


gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Total_startedART

label var Total_startedART "# of PLHIV who started ART"

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Total_startedART, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Total_startedART, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/StartedART.png", as(png) name("Graph") replace 


glm Total_startedART era, family(poisson) link(log) eform
glm Total_startedART era mnth_n, family(poisson) link(log) eform
glm Total_startedART era mnth_n, family(poisson) link(log) scale(x2) eform


glm Capricorn era mnth_n , family(poisson) link(log) eform
glm Mopani era mnth_n, family(poisson) link(log) eform
glm Sekhukhune era mnth_n, family(poisson) link(log) eform

****** Alternative Analysis *************

predict pred, nooffset
twoway (scatter Total_startedART mnth_n) (line pred mnth_n, lcolor(red)) , title("PLHIV Started ART Within 30 Jan,2019-,September 2020") ///
ytitle(Number of people) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)34) xtitle(Timepoint-Month) xline(15) scheme(sj)


				  **********************************
***********************  7. Delivery in clinic  ******************
				 **********************************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("Delivery in facility") firstrow clear 

drop dataname
gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Total_Delivery_Clin

label var Total_Delivery_Clin "# Of Delivery in facility"
label var mnth_n "Time-month"


gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Total_Delivery_Clin, statistics( mean p50 p25 p75 iqr ) by(era)

lm Total_Delivery_Clin era, family(poisson) link(log) eform
glm Total_Delivery_Clin era mnth_n, family(poisson) link(log) eform
glm Total_Delivery_Clin era mnth_n, family(poisson) link(log) scale(x2) eform



************* Delcaring Data Time series ************* 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Total_Delivery_Clin, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/DeliveryInClinic.png", as(png) name("Graph") replace 



glm Total_Delivery_Clin era, family(poisson) link(log) eform
glm Total_Delivery_Clin era mnth_n, family(poisson) link(log) eform
glm Total_Delivery_Clin era mnth_n, family(poisson) link(log) scale(x2) eform


//glm Capricorn era mnth_n , family(poisson) link(log) eform
//glm Mopani era mnth_n, family(poisson) link(log) eform
//glm Sekhukhune era mnth_n, family(poisson) link(log) eform

****** Alternative Analysis *************

predict pred, nooffset
twoway (scatter Total_Delivery_Clin mnth_n) (line pred mnth_n, lcolor(red)) , title("Delivery in Clinic Jan 2019-Sept 2021") ///
ytitle(Number of delivery) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)34) xtitle(Timepoint-Month) xline(15) scheme(sj)


				  **********************************
***********************  8. TB Screening  ******************
				 **********************************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("Adults TB Screening") firstrow clear 

drop dataname
gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Total_TBScreening

label var Total_TBScreening "# of individuals screened"

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Total_TBScreening, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Total_TBScreening, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/TbScreening 5yrs and older.png", as(png) name("Graph") replace 



glm Total_TBScreening era, family(poisson) link(log) eform
glm Total_TBScreening era mnth_n, family(poisson) link(log) eform
glm Total_TBScreening era mnth_n, family(poisson) link(log) scale(x2) eform


//glm Capricorn era mnth_n , family(poisson) link(log) eform
//glm Mopani era mnth_n, family(poisson) link(log) eform
//glm Sekhukhune era mnth_n, family(poisson) link(log) eform

****** Alternative Analysis *************

predict pred, nooffset
twoway (scatter Total_TBScreening mnth_n) (line pred mnth_n, lcolor(red)) , title("Delivery in Clinic Jan 2019-Sept 2021") ///
ytitle(Number of delivery) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)34) xtitle(Timepoint-Month) xline(15) scheme(sj)


				     **************************************
***********************  9. TB investigation among >5yrs  ******************
				 ******************************************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("TB investigation > 5yrs") firstrow clear 

drop dataname
gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Total_TbInvest

label var Total_TbInvest "# of TB investigation"

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Total_TbInvest, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Total_TbInvest, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/TbInvestigation.png", as(png) name("Graph") replace 



glm Total_TbInvest era, family(poisson) link(log) eform
glm Total_TbInvest era mnth_n, family(poisson) link(log) eform
glm Total_TbInvest era mnth_n, family(poisson) link(log) scale(x2) eform


//glm Capricorn era mnth_n , family(poisson) link(log) eform
//glm Mopani era mnth_n, family(poisson) link(log) eform
//glm Sekhukhune era mnth_n, family(poisson) link(log) eform

****** Alternative Analysis *************

predict pred, nooffset
twoway (scatter Total_TbInvest mnth_n) (line pred mnth_n, lcolor(red)) , title("Number of TB Investigations Jan 2019-Sept 2021") ///
ytitle(# of TB Investigations) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)34) xtitle(Timepoint-Month) xline(15) scheme(sj)



				 *******************************************************
***********************  10. Bacteriologically Confirmed among >5yrs  ******************
				 *******************************************************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("DS-TB confirmed 5 years and old") firstrow clear 

drop dataname
gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince BactConf

label var BactConf "TB Confirmed cases"

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat BactConf, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa BactConf, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/BactConfirmation.png", as(png) name("Graph") replace 


glm BactConf era, family(poisson) link(log) eform
glm BactConf era mnth_n, family(poisson) link(log) eform
glm BactConf era mnth_n, family(poisson) link(log) scale(x2) eform


//glm Capricorn era mnth_n , family(poisson) link(log) eform
//glm Mopani era mnth_n, family(poisson) link(log) eform
//glm Sekhukhune era mnth_n, family(poisson) link(log) eform

****** Alternative Analysis *************

predict pred, nooffset
twoway (scatter BactConf mnth_n) (line pred mnth_n, lcolor(red)) , title("Bacteriologically Confirmed Cases Jan 2019-Sept 2021") ///
ytitle(# BactConfi Cases) yscale(range(0 .)) ylabel(#5, labsize(small) angle(horizontal)) ///
xtick(1(2)34) xtitle(Timepoint-Month) xline(15) scheme(sj)



				 *******************************************************
***********************  11.Proportion of ART-naive clients   ******************
				 *******************************************************


import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("ART client naive start ART") firstrow clear 


drop dataname

gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Total_NotART

label var Total_NotART "Naive client on ART"

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Total_NotART, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Total_NotART, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/NotONART.png", as(png) name("Graph") replace 

glm Total_NotART era mnth_n, family(poisson) link(log) eform


				 *******************************************************
***********************  12. Screen for Symptoms fro <5 years old   ******************
				 *******************************************************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("Screen for TB symptoms<5yrs ") firstrow clear 


drop dataname

gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Total_Symptoms

label var Total_Symptoms "Total_Screened for Symptoms_5yrs"

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Total_Symptoms, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Total_Symptoms, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/SymptomsScreening_5yrs.png", as(png) name("Graph") replace 

glm Total_Symptoms era mnth_n, family(poisson) link(log) eform


				*******************************************************
***********************  13. DS-TB Treament Initiation >5yrs  ******************
				*******************************************************

import excel "$DATA\Data for Statistical Analysis- 1Feb 2022.xls", sheet("DS-TB treatment start 5 years> ") firstrow clear 

drop dataname

gen mnth_n=_n

rename lpCapricornDistrictMunicipali Capricorn
rename lpMopaniDistrictMunicipality Mopani
rename lpSekhukhuneDistrictMunicipal Sekhukhune
rename lpVhembeDistrictMunicipality Vhembe 
rename lpWaterbergDistrictMunicipali Waterberg
rename lpLimpopoProvince Tx_Initiation_5yrs

label var Tx_Initiation_5yrs "Number_TX_initiation"

gen era=1
replace era=0 if mnth_n<=15

br era mnth_n 

bysort era : count

tabstat Tx_Initiation_5yrs, statistics( mean p50 p25 p75 iqr ) by(era)


*************Delcaring Data Time series 
tsset mnth_n

* Adjust for seasonality
/* installation of the "itsa" package by using folllowing command "ssc install itsa", and click on search */

itsa Tx_Initiation_5yrs, single trperiod(16) lag(16) posttrend figure
graph export "$DATA/Tx_Initiation_5yrs.png", as(png) name("Graph") replace 

glm Tx_Initiation_5yrs era mnth_n, family(poisson) link(log) eform



