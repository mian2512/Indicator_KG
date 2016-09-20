clear all 
frmttable , clear 
set more off

*Indicator 4: Percent of teachers demonstrating, in the classroom, reading instructional best practices.

**Created by:  	Kevin Kamto
**Project:		QRP - Quality Reading Project
**Purpose:		Indicator 4: Percent of teachers demonstrating, in the classroom, reading instructional best practices.
**Modified :  		PSirma   on 9.16.2016


global path "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data"


/********************************************************************************************************************
****PART 1: Create a Pass/Fail Variables using 10 Items****
*********************************************************************************************************************/

*1.1.:Classroom File*
*********************

use "$path\KG_Classroom_2016\Classroom.dta", clear

// By looking in 2016 instrument, I see Q8 is class_id & Q9 is teacher_id
// I need Teacher_id to make the merge with teacher file
ren Q8 CLASS_ID
ren Q9 TEACHER_ID

*Check there are no duplicates on CLASS_ID	
duplicates report CLASS_ID

*Check there are no duplicates on TEACHER_ID	
duplicates report TEACHER_ID
cap drop dups
duplicates tag TEACHER_ID, gen (dups)
order TEACHER_ID
sort TEACHER_ID

br if dups>0 

duplicates drop TEACHER_ID, force 

*SCHID Var
gen SCHOOL_ID=substr(TEACHER_ID,1,7)
gen SCHOOL_ID_2=substr(CLASS_ID,1,7) 

capture assert SCHOOL_ID==SCHOOL_ID_2 

drop SCHOOL_ID_2

foreach var of varlist _all{
	if "`var'"=="TEACHER_ID"| "`var'"=="CLASS_ID" | "`var'"=="SCHOOL_ID" continue
		ren `var' `var'_C
}

*Add treatment status
preserve 
use "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\2016 KG EGRA\KG2016sample.dta", clear
rename SchoolID full_code
rename egra2016 treat 
duplicates drop full_code, force
ren full_code SCHOOL_ID
tempfile treatment_status
save "`treatment_status'"
restore

merge m:1 SCHOOL_ID using "`treatment_status'"
duplicates tag TEACHER_ID, gen (dups)
tab dups
tab dups _merge 
tab TEACHER_ID if dups>0 
drop if dups>0 // I drop these observations
drop _merge

tempfile classroom_file
save "`classroom_file'"

*1.2.Teacher File*
******************

use "$path\KG_Teacher_2016\Teacher.dta", clear

*Check there are no duplicates on TEACHER_ID
duplicates report TEACHER_ID // there is one duplacate
duplicates drop TEACHER_ID, force

*Since the variable No.s are the same in clasroom and teacher file, I rename them so in the merge they don't overwrite each other
foreach var of varlist _all{
	if "`var'"=="TEACHER_ID" continue
		ren `var' `var'_T
}

*1.3. Calculating Score for Essential Requirements**
****************************************************

merge 1:m TEACHER_ID using "`classroom_file'"
*AT merge leaves 6 of 279 files not merging... are teachers who didn't get observed or classes whose teachers weren't interviewed. fine- drop them
drop if _merge!=3

drop _merge

save "$path\merged_data", replace

*Varibales from teacher file needed for part 1: pass/fail of essential requirements (These can be found in report)
keep TEACHER_ID CLASS_ID SCHOOL_ID treat Q19_C Q21_C Q22_C Q23_C Q33A_C-Q33Q_C Q60_C Q34A_C-Q34F_C Q35A_C-Q35O_C Q66A_C-Q66N_C Q66O_C Q37_T Q21_T Q67_T // Var Q35L_C not found, is it supposed to be Q35O_C

*We first need to have all variables in a 0/1 format, b/c we need 7 out of 10 requirements fulfilled, and we'll need to add them later

numlabel _all, add //I can see in all 
*br
label drop _all

tab Q21_C
tab Q22_C

*Let see which vars of these are binary
foreach var of varlist _all{
	if "`var'"=="TEACHER_ID"| "`var'"=="CLASS_ID" | "`var'"=="_merge" continue
		di "***`var'****" // The tab would just give me the number but not whether it is _C or _T
		tab `var'
}

*drop unnecessary variables that would break the loop (i.e. unnecessary string vars)	


foreach var of varlist _all{
	if "`var'"=="TEACHER_ID"| "`var'"=="CLASS_ID"| "`var'"=="SCHOOL_ID" continue
		di "***`var'****" // The tab would just give me the number but not whether it is _C or _T
		
	if "`var'"=="Q19_C" | "`var'"=="Q23_C"|"`var'"=="Q60_C"{
		replace `var'=0 if `var'==3 // For question 23_C, option 2 (partly), becomes a zero in line before the loop. This is consistent with old file
}
	if "`var'"=="Q21_C"| "`var'"=="Q22_C" {
		tab `var'
		replace `var'=`var'!=1
		tab `var'
}	
	replace `var'=0 if `var'==2 //This command has to go after the preceding loops, b/c otherwise it would code the value of 2 as a zero in preceding questions
}


*Questions Q21_T, Q37_T, Q67_T are directly binary
*Questions Q19_C, Q21_C, Q22_C, Q23_C, Q60_C were not binary, but were turned into such
*Questions Q33_C, Q34_C, Q35_C, Q66_C are divied into multiple binary variables - we won't deal w/ them until next section

*Item 1: Teacher has textbook applicable to class*
gen ITEM_1=Q19_C
*Item 2: Written educational materials on walls of classroom, prefabricated or handmade
gen ITEM_2=Q21_C==1|Q22_C==1
*Item 3: Display of printed materials was appropriate to grade level and reading subject
gen ITEM_3=Q23_C
***ITEMS 4-7 are the complicated ones***
*Item 8: Teacher produced a lesson plan when asked
gen ITEM_8=Q21_T
*Item 9: Teacher had books in the classroom
gen ITEM_9=Q37_T
*Item 10: Teacher had books in the classroom
gen ITEM_10=Q67_T


*1.4. Creating ITEM_4 Variable: ITEM 4 is composed of Q33_C & Q60_C 
*******************************************************************

/****How Var was created in Old File****

gen score_33=0
global true1_must "q33wr_board_c q33copy_board_c q33indiv_c q33wr_ans_c var60_c"

foreach x of varlist $true1_must{
replace score_33=score_33+1 if `x'=="TRUE"
}

replace score_33=score_33+2 if q33recite_c=="TRUE"
replace score_33=score_33+2 if q33aloud_all_c=="TRUE"
replace score_33=score_33+2 if q33listen_c=="TRUE"

global true3_must "q33verb_asn_c q33aloud_ind_c q33indep_c q33skit_c q33game_c q33debate_c"

foreach x of varlist $true3_must{
replace score_33=score_33+3 if `x'=="TRUE"
}

gen q33_c_must=(score_33>=12)

*****************/

*Coding vars 33 into a binary variable

gen Q33_C_SCORE=0

*Assigining points for Q33 to each Teacher - based on previous code - search for "gen score_33" to see where this begins

* I wasn't sure we had an equivalent for this -> "q33aloud_ind_c" (old var) - I used Q33I_C (read aloud to another student)

local point_system One_Point Two_Point Three_Points

local One_Point Q33A_C Q33B_C Q33C_C Q33E_C Q60_C  //Note: We add an extra-point for Q60_C (as in old file)
local Two_Points Q33F_C Q33G_C Q33H_C
local Three_Points Q33D_C Q33I_C Q33K_C Q33N_C Q33O_C Q33P_C

foreach loc of local point_system {
	di "***********"
	di "***`loc'***"
	di "***********"
	foreach var of local `loc'{
		di "****************************************"
		di `"`: var label `var''"' 
		di "****************************************"
	} // End var loop
} // End point system loop


*Assigning points to each Teacher - based on previous code
foreach var of local One_Point {
	replace Q33_C_SCORE= Q33_C_SCORE + 1 if `var'==1
}

foreach var of local Two_Points {
	replace Q33_C_SCORE= Q33_C_SCORE + 2 if `var'==1
}

foreach var of local Three_Points {
	replace Q33_C_SCORE= Q33_C_SCORE + 3 if `var'==1
}


*Do a quick check that var got correctly coded
//br TEACHER_ID Q33A_C Q33B_C Q33C_C Q33D_C Q33F_C Q33G_C Q33H_C Q33D_C Q33I_C Q33K_C Q33N_C Q33O_C Q33P_C Q60_C Q33_C_SCORE
gen ITEM_4=(Q33_C_SCORE>=12) // Reminders: 1) ITEM 4 is composed of Q33_C & Q60_C  2) In old file we set 12 as treshold for having a 1 for this Item


*1.5. Creating ITEM_5 Variable: ITEM 4 5s is composed of Q34_C variables 
************************************************************************

/****How Var was created in Old File****

gen score_34=0
replace score_34=score_34+1 if q34ans_teach_c=="TRUE"
replace score_34=score_34+2 if q34ask_c=="TRUE"
replace score_34=score_34+2 if q34ans_c=="TRUE"
replace score_34=score_34+2 if q34disc_c=="TRUE"
replace score_34=score_34+2 if q34express_c=="TRUE"
replace score_34=score_34+2 if q34ask_teach_c=="TRUE"
gen q34_c_must=(score_34>=5)

*****************/

gen Q34_C_SCORE=0
replace Q34_C_SCORE=Q34_C_SCORE+1 if Q34E_C==1

foreach var of varlist Q34A_C-Q34F_C {
	
	if "`var'"=="Q34E_C" continue
	replace Q34_C_SCORE= Q34_C_SCORE + 2 if `var'==1
}

gen ITEM_5=(Q34_C_SCORE>=5) 

*1.6. Creating ITEM_6 Variable: ITEM 6 is composed of Q35_C variables 
*********************************************************************

/****How Var was created in Old File****

gen score_35=0
replace score_35=score_34+1 if q35explain_c=="TRUE"
replace score_35=score_34+1 if q35read_to_c=="TRUE"
replace score_35=score_34+1 if q35ans_q_c=="TRUE"
replace score_35=score_34+1 if q35classw_c=="TRUE"
replace score_35=score_34+1 if q35homew_c=="TRUE"
replace score_35=score_34+3 if q35diffw_c=="TRUE"
replace score_35=score_34+3 if q35disc_c=="TRUE"
replace score_35=score_34+3 if q35sm_group_c=="TRUE"
replace score_35=score_34+3 if q35high_q_c=="TRUE"
replace score_35=score_34+3 if q35predict_c=="TRUE"
gen q35_c_must=(score_35>=13)

*****************/

gen Q35_C_SCORE=0

local point_system One_Point Three_Points
*Note: There is no equivalent in old code for "Q35C_C" (Ask students literal recall questions about lesson, so I don't include)

local One_Point Q35A_C Q35B_C Q35D_C Q35E_C Q35F_C
local Three_Points Q35G_C Q35H_C Q35I_C Q35J_C Q35K_C

foreach loc of local point_system {
	di "***********"
	di "***`loc'***"
	di "***********"
	foreach var of local `loc'{
		di "****************************************"
		di `"`: var label `var''"' 
		di "****************************************"
	} // End var loop
} // End point system loop

*Assigning points to each Teacher - based on previous code

foreach var of local One_Point{
	replace Q35_C_SCORE= Q35_C_SCORE + 1 if `var'==1
}

foreach var of local Three_Points{
	replace Q35_C_SCORE= Q35_C_SCORE + 3 if `var'==1
}

gen ITEM_6=(Q35_C_SCORE>=13)

*1.7. Creating ITEM_6 Variable: ITEM 6 is composed of Q35_C variables 
*********************************************************************
/****How Var was created in Old File****

gen q66_c_must= (q66none_c=="FALSE")
su *_must

*****************/

*Check that when Q66O_C (no assesment) ==0, there is at least a one in one of the other options
tablist Q66A_C-Q66O_C

*Gen ITEM 7 variable
gen ITEM_7=(Q66O_C==0) // This is the last Item to be created

*1.8. Checking ITEM variables and finishing step 1
***************************************************
forval i=1/10{
	order ITEM_`i'
}

sum ITEM*

egen ITEM_SUM= rsum(ITEM_10-ITEM_1)
gen PASS_PART1= 1 if ITEM_SUM>=7
replace PASS_PART1=0 if PASS_PART1==.
tab PASS_PART1 // Here I see a little over half of the teachers pass part 1

drop *SCORE 
keep TEACHER_ID PASS_PART1 SCHOOL_ID ITEM_SUM treat ITEM*

duplicates report // No dups, as expected - we got rid of the few cases in classroom data earlier

bys treat: tab PASS_PART1

save "$path\Part_1", replace



/************************************************************************************************
*****PART 2: Use Point Categories for Extra Points****
************************************************************************************
**************************************************************************************************/

use "$path\merged_data", clear

/*************************
***Points per Question***
**************************

****Points by Question****	

*One point*
Q25_T Q29_T Q45_T Q47_T Q56_T Q70_T Q20_C Q48_C Q49_C Q52_C Q55_C Q56_C Q77_C Q78_C Q79_C Q80_C Q81_C Q82_C Q83_C

*Two points
Q20_T Q21_T Q22_T Q23_T Q24_T Q27_T Q57_T Q63_T Q68_T Q27_C Q40_C Q41_C Q42_C Q43_C Q44_C Q45_C Q46_C Q47_C Q50_C Q51_C Q53_C Q54_C Q57_C Q58_C Q60_C Q73_C Q74_C Q75_C Q76_C Q89_C Q90_C

*Three points
Q37_T Q39_T Q40_T Q46_T Q48_T Q62_T Q67_T Q23_C Q25_C Q59_C Q61_C Q62_C Q69_C Q70_C Q72_C Q85_C Q87_C

*Five points
Q64_T

****Special Points by Option****	

*Special one point*
*For any
Q26_T /*Max 6 */ Q30_T Q31_T /*Max 10*/ Q50_T /*Max 7*/ Q51_T /*Max 7*/ Q52_T /*Max 6*/ Q53_T /*Max 7*/ Q72_T /*Max 4*/

*Special two point*
Q61_T /*b or c*/ Q55_T /*for d,e,f */ Q70_T /*for b,e */ Q21_C /*for c*/ Q22_C /*for c*/ Q34_C /*for a b c d f - Max 30*/ Q36_C /* a b c d l e- Max 10 - check with Amy*/ Q87_C /* for b */ Q88_C /*2 for any*/

*Special Three points
Q54_T /*for a,b,c */ Q55_T /*for a,b,c */ Q56_T /*for b,c*/ Q59_T /*for c,d,e*/ Q70_T /*for c,d */ Q71_T /*for j,k,l,m */ Q21_C /*for d*/ Q22_C /*for d*/ Q33_C /* d j k n o p - Max 11*/ Q35_C /* g h l j k - Max 20*/ Q39_C /* for d*/ Q66_C /* h i j k l m - max 25*/

*Special Four points
Q60_T /*if b*/

****Negative Points****	
*Negative 1
Q30_T /*if less than once a month*/ Q59 /*for c,d,e*/

*Negative 2
Q61_T /*e*/ Q24_C /*for b*/ Q33_C /* f g h j - substract*/ Q87_C /* for d */			

*Negative 3
Q59_T /*for f*/	Q23_C /*for c*/ Q39_C /* a or e - Amy - not sure why A is*/	Q67_C /* for d */	Q87_C /* for e */	

*Negative 5
Q32_T Q66_T// if b (No) 
Q40_T /* If c,d,e - why is this -5? */

*Special One Point Concrete
Q54_T /*for d,e,f,g */ Q55_T /*for g, h */ Q59_T /*for b*/ Q71_T /*for a,d,e */	Q21_C /*for b*/ Q22_C /*for b*/ Q34_C /*for e - Max 11*/ Q33_C /* a b c e m - Max 30*/ Q35_C /* a b d e f - Max 20*/ Q38_C /* Max 6*/ Q66_C /* a b c d e f g  */

*/

*************Creating Variable*********

gen Score_Part2=0

local ONE_POINT Q25_T Q29_T Q45_T Q47_T Q20_C Q48_C Q49_C Q52_C Q55_C Q56_C Q77_C Q78_C Q79_C Q80_C Q81_C Q82_C Q83_C
local TWO_POINTS Q20_T Q21_T Q22_T Q23_T Q24_T Q27_T Q57_T Q63_T Q68_T Q27_C Q40_C Q41_C Q42_C Q43_C Q44_C Q45_C Q46_C Q47_C Q50_C Q51_C Q53_C Q54_C Q57_C Q58_C Q60_C Q73_C Q74_C Q75_C Q76_C Q89_C Q90_C
local THREE_POINTS Q37_T Q39_T Q46_T Q48_T Q62_T Q67_T Q25_C Q59_C Q61_C Q62_C Q69_C Q70_C Q72_C Q85_C Q87_C
local FIVE_POINTS Q64_T

*******************************
***ONE POINT***
******************************
qui foreach var of local ONE_POINT{
	noi di `"`: var label `var''"' 
	replace Score_Part2=Score_Part2 + 1 if `var'==1
}

*******************************
***TWO POINTS***
******************************
qui foreach var of local TWO_POINTS{
	noi di `"`: var label `var''"' 
	replace Score_Part2=Score_Part2 + 2 if `var'==1
}


*******************************
***THREE POINTS***
******************************
qui foreach var of local THREE_POINTS{
	noi di `"`: var label `var''"' 
	replace Score_Part2=Score_Part2 + 3 if `var'==1
}

*******************************
***FIVE POINTS***
******************************
qui foreach var of local FIVE_POINTS{
	noi di `"`: var label `var''"' 
	replace Score_Part2=Score_Part2 + 5 if `var'==1
}

*SPECIAL POINTS
***************

*One Point Per Option*
**********************
*Q26_T*
gen Score_Q26_T=0
qui foreach var of varlist Q26A_T-Q26F_T{
	noi di `"`: var label `var''"' 
	replace Score_Q26_T=Score_Q26_T+1 if `var'==1
}

sum Score_Q26_T /* Max is 6, as says in the word doc*/
*Q30_T*
gen Score_Q30_T=0
replace Score_Q30_T=1 if Q30_T!=4
replace Score_Q30_T=-1 if Q30_T==4

*Q31_T*
gen Score_Q31_T=0
qui foreach var of varlist Q31A_T-Q31J_T{
	noi di `"`: var label `var''"' 
	replace Score_Q31_T=Score_Q31_T+1 if `var'==1
}

sum Score_Q31_T /* Max is 8*/

*Q50_T*
gen Score_Q50_T=0
order Q50A_T Q50B_T Q50C_T Q50D_T Q50E_T Q50F_T
qui foreach var of varlist Q50A_T-Q50F_T{
	noi di `"`: var label `var''"' 
	replace Score_Q50_T=Score_Q50_T+1 if `var'==1
}
sum Score_Q50_T /* Max is 6 */

*Q51_T*
gen Score_Q51_T=0
order Q51A_T Q51B_T Q51C_T Q51D_T Q51E_T Q51F_T Q51G_T Q51H_T
qui foreach var of varlist Q51A_T-Q51H_T{
	noi di `"`: var label `var''"' 
	replace Score_Q51_T=Score_Q51_T+1 if `var'==1
}
sum Score_Q51_T /* Max is 8*/

*Q52_T*
gen Score_Q52_T=0
order Q52A_T Q52B_T Q52C_T Q52D_T Q52E_T Q52F_T Q52G_T Q52H_T Q52I_T
qui foreach var of varlist Q52A_T-Q52I_T{
	noi di `"`: var label `var''"' 
	replace Score_Q52_T=Score_Q52_T+1 if `var'==1
}
sum Score_Q52_T /* Max is 7*/

*Q53_T*
gen Score_Q53_T=0
order Q53A_T Q53B_T Q53C_T Q53D_T Q53E_T Q53F_T Q53G_T Q53H_T Q53I_T Q53J_T
qui foreach var of varlist Q53A_T-Q53J_T{
noi di `"`: var label `var''"' 
replace Score_Q53_T=Score_Q53_T+1 if `var'==1
}
sum Score_Q53_T /* Max is 8*/

*Q72_T*
*Note: I exclude a few options (variables Q72E_T-Q72H_T) that were not included in the word doc b
gen Score_Q72_T=0
order Q72A_T Q72B_T Q72C_T Q72D_T 
qui foreach var of varlist Q72A_T-Q72D_T{
	noi di `"`: var label `var''"' 
	replace Score_Q72_T=Score_Q72_T+1 if `var'==1
}
sum Score_Q72_T /* Max is 4, max indicated in the word doc is 4*/

*One Point for Specific Option*
*******************************

*Q54_T* In this case I add option for 3 points too
gen Score_Q54_T=0
order Q54A_T Q54B_T Q54C_T
qui foreach var of varlist Q54A_T-Q54C_T{
	noi di `"`: var label `var''"' 
	replace Score_Q54_T=Score_Q54_T+3 if `var'==1
}
order Q54D_T Q54E_T Q54F_T Q54G_T 
qui foreach var of varlist Q54D_T-Q54G_T{
	noi di `"`: var label `var''"' 
	replace Score_Q54_T=Score_Q54_T+1 if `var'==1
}
sum Score_Q54_T 

*Q59_T*
gen Score_Q59_T=0
replace Score_Q59_T=1 if Q59_T==2
replace Score_Q59_T=3 if Q59_T==3
replace Score_Q59_T=3 if Q59_T==4
replace Score_Q59_T=3 if Q59_T==5
replace Score_Q59_T=-3 if Q59_T==6

*Q71_T*
*Note: I exclude a few options (variables Q71E_T-Q71H_T) that were not included in the word doc b
gen Score_Q71_T=0
order Q71A_T Q71D_T Q71E_T
qui foreach var of varlist Q71A_T-Q71E_T{
	noi di `"`: var label `var''"' 
	replace Score_Q71_T=Score_Q71_T+1 if `var'==1
}
order Q71J_T Q71K_T Q71L_T Q71M_T
qui foreach var of varlist Q71J_T-Q71M_T{
	noi di `"`: var label `var''"' 
	replace Score_Q71_T=Score_Q71_T+3 if `var'==1
}
sum Score_Q71_T

*Q33_C*
*Note: I exclude a few options (variables Q71E_T-Q71H_T) that were not included in the word doc b
gen Score_Q33_C=0
order Q33A_C Q33B_C Q33C_C Q33E_C Q33M_C //1 point for these
qui foreach var of varlist Q33A_C-Q33M_C{ 
	noi di `"`: var label `var''"' 
	replace Score_Q33_C=Score_Q33_C + 1 if `var'==1
}
order Q33D_C Q33J_C Q33K_C Q33N_C Q33O_C Q33P_C //3 points for these
qui foreach var of varlist Q33D_C-Q33P_C{ 
	noi di `"`: var label `var''"' 
	replace Score_Q33_C=Score_Q33_C + 3 if `var'==1
}

order Q33F_C Q33G_C Q33H_C Q33J_C // -2 points for these
qui foreach var of varlist Q33F_C-Q33J_C{ 
noi di `"`: var label `var''"' 
replace Score_Q33_C=Score_Q33_C - 2 if `var'==1
}
sum Score_Q33_C // Max is 12, max indicated on sheet is 30. 

*Q35_C*
gen Score_Q35_C=0
order Q35A_C Q35B_C Q35D_C Q35E_C Q35F_C //1 point for these
qui foreach var of varlist Q35A_C-Q35F_C{ 
	noi di `"`: var label `var''"' 
	replace Score_Q35_C=Score_Q35_C + 1 if `var'==1
}
order Q35G_C Q35H_C Q35I_C Q35J_C
qui foreach var of varlist Q35G_C-Q35J_C{ //3 point for these
	noi di `"`: var label `var''"' 
	replace Score_Q35_C=Score_Q35_C + 3 if `var'==1
}
sum Score_Q35_C // I get 5, but there are 20 pts max

*Q38_C* 
gen Score_Q38_C=0
qui foreach var of varlist Q38A_C-Q38E_C{ 
	noi di `"`: var label `var''"' 
	replace Score_Q38_C=Score_Q38_C + 1 if `var'==1
}
sum Score_Q38_C // I get 3, but there are 6 pts max - though should be 5, b/c there are 5 in instrument

*Q66_C*
gen Score_Q66_C=0
qui foreach var of varlist Q66A_C-Q66G_C{ //1 point for these
	noi di `"`: var label `var''"' 
	replace Score_Q66_C=Score_Q66_C + 1 if `var'==1
}
qui foreach var of varlist Q66H_C-Q66M_C{ //3 point for these
	noi di `"`: var label `var''"' 
	replace Score_Q66_C=Score_Q66_C + 3 if `var'==1
}
sum Score_Q66_C // I get 24 max, but there are 25 pts max

*Two Points Per Option*
***********************

*Q88_C /*2 for any*/

*Q61_T*
gen Score_Q61_T=0
replace Score_Q61_T=2 if Q61_T==2|Q61_T==3
replace Score_Q61_T=-2 if Q61_T==5
sum Score_Q61_T

*Q55_T*
gen Score_Q55_T=0
qui foreach var of varlist Q55G_T Q55H_T{ //1 point for these
noi di `"`: var label `var''"' 
replace Score_Q55_T=Score_Q55_T+1 if `var'==1
}	
qui foreach var of varlist Q55D_T-Q55F_T{ //2 point for these
noi di `"`: var label `var''"' 
replace Score_Q55_T=Score_Q55_T + 2 if `var'==1
}
qui foreach var of varlist Q55A_T-Q55C_T{ //3 point for these
noi di `"`: var label `var''"' 
replace Score_Q55_T=Score_Q55_T + 3 if `var'==1
}
sum Score_Q55_T // I get 17 max, there are 17 pts max

*Q70_T*
gen Score_Q70_T=0
replace Score_Q70_T=Score_Q70_T + 1 if Q70A_T==1
replace Score_Q70_T=Score_Q70_T + 2 if Q70B_T==1
replace Score_Q70_T=Score_Q70_T + 2 if Q70E_T==1
replace Score_Q70_T=Score_Q70_T + 3 if Q70C_T==1
replace Score_Q70_T=Score_Q70_T + 3 if Q70D_T==1
sum Score_Q70_T

*Q21_C*
gen Score_Q21_C=0
tab Q21_C
replace Score_Q21_C=Score_Q21_C + 1 if Q21_C==2
replace Score_Q21_C=Score_Q21_C + 2 if Q21_C==3
replace Score_Q21_C=Score_Q21_C + 3 if Q21_C==4
sum Score_Q21_C

*Q22_C*
gen Score_Q22_C=0
tab Q22_C
replace Score_Q22_C=Score_Q22_C + 1 if Q22_C==2
replace Score_Q22_C=Score_Q22_C + 2 if Q22_C==3
replace Score_Q22_C=Score_Q22_C + 3 if Q22_C==4
sum Score_Q22_C

*Q34_C*
gen Score_Q34_C=0
replace Score_Q34_C=Score_Q34_C + 1 if Q34E_C==1
replace Score_Q34_C=Score_Q34_C + 2 if Q34A_C==1
replace Score_Q34_C=Score_Q34_C + 2 if Q34B_C==1
replace Score_Q34_C=Score_Q34_C + 2 if Q34C_C==1
replace Score_Q34_C=Score_Q34_C + 2 if Q34D_C==1
replace Score_Q34_C=Score_Q34_C + 2 if Q34F_C==1
sum Score_Q34_C /*for a b c d f - Max is 11*/

*Q36_C 
gen Score_Q36_C=0
qui foreach var of varlist Q36A_C-Q36F_C{ //1 point for these
noi di `"`: var label `var''"' 
replace Score_Q36_C=Score_Q36_C + 2 if `var'==1
}
sum Score_Q36_C // Note: Here I get 12, even though maximum set by Amy is 10

*Q87_C*
gen Score_Q87_C=0
replace Score_Q87_C=Score_Q87_C + 3 if Q87_C==1
replace Score_Q87_C=Score_Q87_C + 2 if Q87_C==2
replace Score_Q87_C=Score_Q87_C - 2 if Q87_C==4 // There are none for this option (d)
replace Score_Q87_C=Score_Q87_C - 3 if Q87_C==5 // There are none for this option (e)
sum Score_Q87_C

*Q88_C*
gen Score_Q88_C=0
replace Score_Q88_C=Score_Q88_C + 2 if Q88_C!=. // All options are 2 points
sum Score_Q88_C

*Q56_T*
gen Score_Q56_T=0
replace Score_Q56_T=Score_Q56_T + 1 if Q56_T==1
replace Score_Q56_T=Score_Q56_T + 3 if Q56_T==2
replace Score_Q56_T=Score_Q56_T + 3 if Q56_T==3
sum Score_Q56_T

***************************
***************************

*39_C**/
gen Score_Q39_C=0
replace Score_Q39_C=Score_Q39_C - 3 if Q39A_C==1 //Amy - not sure why A is
replace Score_Q39_C=Score_Q39_C + 3 if Q39D_C==1
replace Score_Q39_C=Score_Q39_C - 3 if Q39E_C==1
sum Score_Q39_C

**Special Four points**

**Q60_T**
gen Score_Q60_T=0
replace Score_Q60_T=Score_Q60_T + 3 if Q60_T==1
sum Score_Q60_T

**Negative 2**

**Q24_C**
tab Q24_C
gen Score_Q24_C=0
replace Score_Q24_C=Score_Q24_C - 2 if Q24_C==2

**Q23_C**
tab Q23_C
gen Score_Q23_C=0
replace Score_Q23_C=Score_Q23_C - 3 if Q23_C==3

**Negative 3**

**Q67_C**
gen Score_Q67_C=0
replace Score_Q67_C=-3 if Q67D_C==1

**Q32_T**
tab Q32_T
gen Score_Q32_T=0
replace Score_Q32_T=Score_Q32_T - 5 if Q32_T==2

**Negative 5**

**Q66_T**
tab Q66_T
gen Score_Q66_T=0
replace Score_Q66_T=Score_Q66_T - 5 if Q66_T==2

**Q40_T**
gen Score_Q40_T=0
tab Q40_T
replace Score_Q40_T=Score_Q40_T + 1 if Q40_T==1
replace Score_Q40_T=Score_Q40_T + 3 if Q40_T==2
replace Score_Q40_T=Score_Q40_T + 5 if Q40_T==3 
replace Score_Q40_T=Score_Q40_T + 5 if Q40_T==4 
replace Score_Q40_T=Score_Q40_T + 5 if Q40_T==5 


**************************************
***DISTRIBUTION OF SCORES IN PART 2***
**************************************

foreach var of varlist Score*{
if "`var'" == "Score_Part2" continue
replace Score_Part2=Score_Part2 + `var'
}

sum Score_Part2, detail // Mean is 133.45, about .5 difference w/ previous round


/************************************************************************************************
*****PART 3: Total # of Good Teachers****
************************************************************************************
**************************************************************************************************/


merge 1:1 TEACHER_ID using "$path\Part_1"

gen PASS_PART2=Score_Part2>=150
bys treat: tab PASS_PART2


*Have 7 of 10 essential and score of 150+
gen Best=(PASS_PART1==1 & Score_Part2>=150)
tab Best
bys treat: tab Best // PAUL "Best" is the var that we use for these tables
bys language_T: su Best  if treat==1  //Excel
bys language_T: su Best  if treat==1 & Q4_C==1 //Excel
bys language_T: su Best  if treat==1 & Q4_C==2 //Excel
bys language_T: su Best  if treat==1 & Q4_C==3 //Excel
bys language_T: su Best  if treat==1 & Q4_C==4 //Excel

su Best  if treat==1 //Excel
bys Q4_C: su Best  if treat==0
su Best  if treat==0

*compare means with ttest
bys Q4_C: ttest Best, by(treat)
ttest Best, by(treat)

*exlpore correlation between two sections. vars are ITEM_SUM and PASS_PART1, then Score_Part2 and PASS_PART2
scatter ITEM_SUM Score_Part2
corr ITEM_SUM Score_Part2

scatter ITEM_SUM Score_Part2 if treat==0
scatter ITEM_SUM Score_Part2 if treat==1
corr ITEM_SUM Score_Part2 if treat==0
corr ITEM_SUM Score_Part2 if treat==1

save "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data\KG_i4_2016.dta" , replace 
***********************************************************************************************************

global outreg "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data\Tables"

***********
*New- by PS 
***********
cou //279
keep  if treat ==1 // only keeping Treatment observations 
tab treat , m  // only treated observations left 
cou //138


*Table 11 
***********

qui estpost tabstat Best , by(Q4_C) sta(n mean)  //posting the results to e()
qui ereturn list

*Storing mean into matrix A 
cap drop mat A 
qui mat A = e(mean)' * 100 
matlist A 
mat rownames A = "Osh" "Batken" "Naryn" "Issyk-Kul" "Kyrgyz Republic"


*storing n into matrix B 
cap mat drop B
mat B = e(count)' 
matlist B
mat rownames B = "Osh" "Batken" "Naryn" "Issyk-Kul" "Kyrgyz Republic"

qui frmttable , statmat(A) sdec(1) store(table_1)
qui frmttable , statmat(B) merge(table_1) sdec(0) store(table_1)

*Table 11

frmttable using "$outreg\KG_Tables_2016" , replace replay(table_1)  ///
title("TABLE 11. Percent of Teachers Demonstrating Reading Instructional Best Practices in the Classroom, by Region, Kyrgyz Republic")  ///
ctitle("Region" , "2016" \ "" , "Mean" , "n") coljust(l{c})  basefont(fs10) statfont(fs10) multicol(1,2,2) vlines(0110) hlines(1{1}1)  colwidth(15 5 5 5 5 5 5)
	
	
*Table 12
**********

tabstat Best , by(language_T) sta(mean n)  save //saving the result in r()
return list

*Storing mean and n into matrix A 
cap drop mat A 
qui mat A = ( r(Stat1)' \  r(Stat2)') 
mat A[1,1] = A[1,1]*100
mat A[2,1] = A[2,1]*100
mat rownames A = "`r(name1)'"  "`r(name2)'"
matlist A 
qui frmttable , statmat(A) sdec(1,0) store(table_1) //storing mat A in table_1

*Exporting table 12 to word
frmttable using "$outreg\KG_Tables_2016" , addtable replay(table_1) ///
title("TABLE 12. Percent of Teachers Demonstrating Reading Instructional Best Practices in the Classroom, by Language of Instruction, Kyrgyz Republic") ///
ctitle("Language of Instruction" , "2016" \ "" , "Mean" , "n") coljust(l{c})  basefont(fs10) statfont(fs10) multicol(1,2,2)	vlines(0110) hlines(1{1}1)  colwidth(15 5 5 5 5 5 5)


