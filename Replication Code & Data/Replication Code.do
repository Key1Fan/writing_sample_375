
/**************************************************************************************************************
Class: 				ECO375
Project: 			Canada 2023 Foreign Buyer Ban
Author:				Keyi Fan
Date Created: 		Sep 15 2023
Last Updated:		2023

Description: 		Evaluation of the 2023 Foreign Buyer Ban Policy's effect on Canadian housing price, especially for high competition densed population centers vs. low competitions' "towns" or small-sized cities
					
Input: 				/Users/keyifan/Library/Mobile Documents/com~apple~CloudDocs/UofT/23-24/2023_Ban
					
Output:				N/A
**************************************************************************************************************/

//Setting it up
log using "/Users/keyifan/Library/Mobile Documents/com~apple~CloudDocs/UofT/23-24/2023_Ban/project_log"

*Clear stata memory
clear all 

*Increase the Print Area, better have it. 
set more off
set linesize 240

*Current Directory 
cd "/Users/keyifan/Library/Mobile Documents/com~apple~CloudDocs/UofT/23-24/2023_Ban/output"

ssc install estout

//Note Data Cleaning and peparing codes are not included in this file, I used python and manual sorting in spreadsheets. Please find my cleaned structure in the data file provided
/***Provinces' Avaliability Notes: 
ON=Ontario
QC=Quebec
NS=Nova_Scotia
NB=New_Brunswick
MB=Manitoba* lack of MLS data - drop. but have the CBD data - winningpeg is participating
BC=British_Columbia
PE=Prince_Edward_Island
SK=Saskatchewan
AB=Alberta
NL=Newfoundland_and_Labrador
NT=Northwest Territories* lack of MLS data
YT=Yukon * Lack of data
NU=Nunavut * lack of data
***/

*Generate a "numberic id for" each location
encode location_name, generate(location_id)
*Decalre the panel data structure
sort location_id ym
xtset location_id ym
*generate time treatment dummies
gen ban = (ym > ym(2022,12) & ym =< ym(2023,3))
gen amendment = (ym > ym(2023,3))

*Summary Statistics
ssc install estout


* Generate summary statistics and store them
* for variables hpi_stats benchmark_stats ym_stats location_id_stats ir_stats ban_stats amendment_stats town_stats province_n_stats n_dpop_stats n_gdp_cap_stats n_cpi_stats n_e_income_stats n_e_hp_stats
qui sum hpi benchmark ym location_id ir ban amendment town province_n n_dpop n_gdp_cap n_cpi n_e_income n_e_hp, detail
eststo stats: sum hpi benchmark ym location_id ir ban amendment town province_n n_dpop n_gdp_cap n_cpi n_e_income n_e_hp, detail

* Generate the summary statistics table

esttab stats using "summary_stats.tex", ///
    cells("mean sd min max") varwidth(30) label replace
	
	
	
*define time varied controls here
local controls ir n_e_hp  n_e_income n_dpop n_cpi n_gdp_cap np_res_norm

eststo reg_hpi: xtreg hpi town##ban town##amendment `controls' if province == 0
quietly estadd local fixed_effect "No", replace
quietly estadd local controlled "Yes", replace


eststo reg_benchmark: xtreg benchmark  town##ban town##amendment `controls'  if province == 0
quietly estadd local fixed_effect "No", replace
quietly estadd local controlled "Yes", replace


eststo reg_hpi_fe: xtreg hpi  town##ban town##amendment `controls' if province == 0, fe 
quietly estadd local fixed_effect "Yes", replace
quietly estadd local controlled "Yes", replace


eststo reg_benchmark_fe: xtreg benchmark  town##ban town##amendment `controls' if province == 0, fe 
quietly estadd local fixed_effect "Yes", replace
quietly estadd local controlled "Yes", replace


*Print out the main table 
#delimit ; 
esttab reg_hpi reg_hpi_fe reg_benchmark reg_benchmark_fe using "maintable.tex",
	label se star(* 0.10 ** 0.05 *** 0.01) 
	drop(0.town 0.ban 0.town#0.ban 1.town#0.ban 0.town#1.ban 0.amendment 0.town#0.amendment 1.town#0.amendment 0.town#1.amendment)
	rename(1.town#1.ban "Town under Ban Periods" 1.town#1.amendment "Town under Amendment Periods" )
	s(fixed_effect controlled, 
	label("Fixed Effect" "Controlled"))
	varwidth(30);

#delimit cr

			  
*test for pre-trends

/* Generate pre-trends agents if have not generate in dataframe
gen time_trend = month(ym)
gen pre_treatment = ( m(2022m5)<ym & ym < m(2023m1))
*/

local controls ir n_e_hp  n_e_income n_dpop n_cpi n_gdp_cap np_res_norm
xtset location_id ym
eststo pre_trends: xtreg hpi town##pre_treatment time_trend `controls'
quietly estadd local fixed_effect "No", replace
quietly estadd local controlled "Yes", replace

eststo pre_trends_fe: xtreg hpi town##pre_treatment time_trend `controls', fe
quietly estadd local fixed_effect "Yes", replace
quietly estadd local controlled "Yes", replace

*generate the tables
#delimit ; 
esttab pre_trends pre_trends_fe using "pre-trends.tex",
	label se star(* 0.10 ** 0.05 *** 0.01) 
	drop(0.town 0.town#0.pre_treatment 1.town#0.pre_treatment 0.town#1.pre_treatment 0.pre_treatment)
	rename(1.town#1.pre_treatment "Town under Pre-treatment Periods" )
	s(fixed_effect controlled, 
	label("Fixed Effect" "Controlled"));
#delimit cr

