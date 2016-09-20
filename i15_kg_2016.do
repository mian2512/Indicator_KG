clear all 
set more off


**Created:		Kevin Kamto
**Indicator 15:	Percent of parents who have changed in their attitudes towards reading
**By district, gender, language

**Modified: PSirma 09.19.2016: Added code to analyze data and export the result to word


**************************************************************
*Task 1:  Pull datasets by instrument with relevant questions*
**************************************************************
	
global path "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data\KG_Parent_2016"
global outreg "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data\Tables"

use "$path\Parent.dta", clear
keep RESPONDENT_ID Q2 Q3 Q5 Q6 Q7 Q8 Q10 Q11 Q22 Q23 Q24 Q25 Q26 Q29 Q32 Q44

numlabel _all, add // To see what the numbers are. 

// Here we add points for the "positive questions", , i.e. where agreement is associated with positive attitudes towards reading. 
// More agreement -> More points

tab Q22, m // Here we provide a score based on the information that the code specifies. Amy, feel free to add something else if you have more info on why this decision was made. 
gen score=1 if Q22==1
replace score=3 if Q22==2
replace score=4 if Q22==3
replace score=5 if Q22==4
tab score Q22

tab Q23, m // Notice that the scale here is different from previous (5 options in Q23 as opposed to 4 in Q22). 
// That's the reason why the scoring is different. 
gen score2=1 if Q23==1
replace score2=2 if Q23==2
replace score2=3 if Q23==3
replace score2=4 if Q23==4
replace score2=5 if Q23==5
tab score2 Q23

tab Q29, m
gen score3=1 if Q29== 1
replace score3=2 if Q29== 2
replace score3=3 if Q29== 3
replace score3=4 if Q29== 4
replace score3=5 if Q29== 5
tab score3 Q29

tab Q32, m
gen score4=1 if Q32==1
replace score4=2 if Q32== 2
replace score4=3 if Q32== 3
replace score4=4 if Q32== 4
replace score4=5 if Q32== 5
tab score4 Q32

gen pos_score=score+score2+score3+score4 // We add all the points for positive questions

// Here we add points for the "negative" questions, i.e. where agreement is associated with negative attitudes towards reading. 
// More agreement -> Fewer points 

tab Q24, m
gen score_n=5 if Q24==1
replace score_n=4 if Q24==2
replace score_n=3 if Q24==3
replace score_n=2 if Q24==4
replace score_n=1 if Q24==5
tab score_n Q24

tab Q26, m	
gen score_n2=5 if Q26==1
replace score_n2=4 if Q26==2
replace score_n2=3 if Q26==3
replace score_n2=2 if Q26==4
replace score_n2=1 if Q26==5
tab score_n2 Q26

gen tot_score= pos_score+score_n+score_n2 // Here we add both the score of the positive and negative questions to get the total score
su tot_score, d

**************************************************
*Task 2: Merging in the treatment status variable*
**************************************************

gen SCHOOL_ID=substr(RESPONDENT_ID ,1,7) // The first step to be able to merge the treatment status var is to extract the school_id from the respondent ID. 
// This is the var we'll use to do the merge
// I call it SCHOOL_ID b/c this is the name it has in the treatment status file
preserve 
use "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\2016 KG EGRA\KG2016sample.dta", clear
*duplicates drop SchoolID, force
ren SchoolID SCHOOL_ID
tempfile treatment_status
save "`treatment_status'"
restore

merge m:1 SCHOOL_ID using "`treatment_status'"

drop if _m!=3 // Keep schools that are part of impact evaluation, which is _m==3 --> Because only schools in both files
drop _m
ren egra2016 treat
keep if treat==1 // We only want schools that have a treatment status of 1


gen sch_code=substr(RESPONDENT_ID,1,7)
gen region=substr(RESPONDENT_ID,2,1)

//Coding the gender variable & checking it is correct
tab Q2
replace Q2=0 if Q2==1
replace Q2=1 if Q2==2
label define Q2 0 "male" 1 "female", replace
tab Q2
rename Q2 female

su tot_score if female==1
su tot_score if female==0
su tot_score if Q5==1 //primary caregiver literate
su tot_score if Q5==2 //primary caregiver not literate

********************************************************
*Task 3: Calculating % of Parents who Changed Attitudes* 
********************************************************

*-> Added by Alvaro 11/3/2015

*Create unqiue list of schools in 2016 - We only wnat to analyze schools present in both years
preserve
keep sch_code
duplicates drop
distinct sch_code // 35 schools in 2016
tempfile 2016_schools
save "`2016_schools'"
restore

*Now I will calculate the base Mean and SD, and how parents rank by z-score within school

preserve

use "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2014\KG data\Indicator Do Files\i15_kg_2014.dta", clear

distinct sch_code // 157 schools - This is to be expected b/c it is 2014

merge m:1 sch_code using "`2016_schools'"
keep if _merge==3 // Only keep schools in both files
drop _merge
distinct sch_code // 35 schools in common between 2014 & 2016

sum tot_score
local mean_base_scores=r(mean)
local sd_base_scores=r(sd)
display "`mean_base_scores'" // This is a check to make sure loc is right.
display "`sd_base_scores'" // This is a check to make sure loc is right.

g z_test_score_2014=(tot_score-`mean_base_scores')/`sd_base_scores'


// We'll now need to generate a random variable, in order to break ties whenever two parents have the same z-score (and are linked to same school)

set seed 47487 // We set the seed so that each time we run the do file and generate random number, we get the same result. Otherwise it is different every time. 
gen random=uniform()
gsort sch_code -z_test_score_2014 random // This command (gsort) has the option of sorting each var in a diff. order. For instance, first var is in ascending order (default)
// second var is in descending order (indicated w/ negative sign)


bys sch_code: egen parent_ranking=rank(-z_test_score_2014), unique	// Here unique option is essential to do correct ranking. 
// It assigns a unique number to each observation, even when there are ties. This is essential to do a 1:1 merge. 
gen parent_ranking_2014=parent_ranking

drop random 
*br // This shows that it was correctly done

drop if z_test_score_2014==. // We drop cases with no standardized score, since the score is necessary to rank and match parents

tempfile base_rankings
save "`base_rankings'"

restore

//Now we can do the ranking for parents in 2016 file


g z_test_score_2016=(tot_score-`mean_base_scores')/`sd_base_scores' // We generate the standardized test scores w/ the mean and SD from 2014

// We now repeat the same process as before
set seed 47487
gen random=uniform()
gsort sch_code -z_test_score_2016 random 

bys sch_code: egen parent_ranking=rank(-z_test_score_2016), unique	// Here unique option is essential to do correct ranking
gen parent_ranking_2016=parent_ranking

br RESPONDENT_ID sch_code tot_score z_test_score_2016 parent_ranking

drop if z_test_score_2016==. // We drop cases with no standardized score, since this is necessary to rank and match parents

// Now we can match parents by school code and ranking	

merge 1:1 sch_code parent_ranking using `base_rankings'

br RESPONDENT_ID sch_code z_test_score_2014 z_test_score_2016 parent_ranking  parent_ranking_2014 parent_ranking_2016 

// We generate changed_attitude variable by looking at if the parents in 2015 have higher scores than their counterparts in 2014 w/ the same position in the ranking

gen changed_attitude=z_test_score_2016>z_test_score_2014 & z_test_score_2016!=. & z_test_score_2014!=.
replace changed_attitude=. if z_test_score_2014==.| z_test_score_2016==. 

br RESPONDENT_ID sch_code z_test_score_2014 z_test_score_2016 parent_ranking  parent_ranking_2014 parent_ranking_2016 changed_attitude

tab changed_attitude, m //Paul, this is the variable you'll use for the tables.

***********************
**Task 4: Excel Tables*
***********************

tab language changed_attitude, row

bys region: tab changed_attitude if female!=. // C4-C13 in Excel
bys region: tab changed_attitude if female==1 // D4-D13 in Excel
tab changed_attitude if female==1 //D14 in Excel
bys region: tab changed_attitude if female==0 // E4-E13 in Excel
tab changed_attitude if female==0 // E13 in Excel

*Recoding region, merging Osh Region and Osh City
*******************************************
tab region
destring region, replace 
replace region=6 if region==9
label define regionlabel 1 "Batken"  4  "Naryn" 5 "Issyk-Kul" 6 "Osh"
label values region regionlabel 
tab region

tab treat , m 
keep if treat == 1 
tab treat , m

*Table 22
********

estpost tabstat changed_attitude , by(region) sta(mean n) //posting results to e()
cap mat drop A1
mat  A1 = (e(mean)'*100 ,e(count)')  //storing the Russian results in mat A1
mat list A1
frmttable , statmat(A1) sdec(1,0)  ctitle("Region" , "2016" \ "" , "Mean" , "n") store(table_1)  ///
title("TABLE 22. Percent of Parents Whose Attitude Toward Reading Have Improved, by Region, Kyrgyz Republic")  ///
rtitle("Batken" \ "Naryn" \ "Issyk-Kul" \ "Osh" \ "Kyrgyz Republic")      ///
coljust(l{c})  basefont(fs10) statfont(fs10)  multicol(1,2,2) vlines(0110) hlines(1{1}1)  colwidth(30 5 5 5 5 5 5)