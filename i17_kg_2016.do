clear all 
set more off 

**Created:		Kevin Kamto
**Indicator 17:	Percentage of parents/other adults reading non-textbook materials with 
**students at home
**Modified: 		PSirma 09.19.2016: Added code to analyze data and export the result to word


/*Indicator calculation 
This indicator was created using survey and observational data from parent interviews, teacher interviews, and classroom observations. Schools with an adequate number of available books fulfill at least two of the following three criteria:

•	Data collectors observed that non-textbook books were available in the classroom during the classroom observation in half or more of the classes observed per school.
•	Data collectors observed that non-textbook books were available in the classroom during the teacher interview in half or more of the interviews per school.
•	Data collectors observed more than 100 children’s books available in the school library. 

Homes with an adequate number of available children’s books have 10 or more children’s books at home, as self-reported by parents. 
This median of the binary variable (homes with five or more books and homes with fewer than five books) is reported per community. 

-> By district, gender, language */


*************************************************************
*Task 1: Pull datasets by instrument with relevant questions*
*************************************************************
global path "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data\KG_Parent_2016"
global outreg "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data\Tables"

*************
*Parent data*
**************
use "$path\Parent.dta", clear

duplicates drop RESPONDENT_ID, force // Replaced parent_code (in 2014 file) w/ RESPONDENT_ID
cap drop student_id
gen student_id=substr(RESPONDENT_ID,1,11)

// Checking if there are duplicates
unique student_id
duplicates tag student_id, gen(dup_id) 
tab dup_id
br if dup_id>0 // There are no duplicates
sort RESPONDENT_ID
duplicates drop student_id, force
keep RESPONDENT_ID student_id Q44 Q3 Q4
tempfile KG_i17_parent16 // Create a tempfile here to merge later with the student data
save "`KG_i17_parent16'"


*************
*Student data*
**************

use "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\2016 KG EGRA\Working_data\KG_2016_allgrades_appended.dta", clear
**renvars student_id gender / StudentID Gender from old do file
keep StudentID q10 gender q1 q2
*tostring q23 q24, replace
rename StudentID student_id
unique student_id
duplicates tag student_id, gen(dup_id)
tab dup_id
duplicates drop student_id, force
preserve 


// Now we merge both datasets
restore 
cap drop _m
merge m:1 student_id using "`KG_i17_parent16'", 
count	
*keep if _m==3


********************************************************
*Task 2: Create variables that we will use for analysis*
********************************************************

numlabel _all, add
tab Q44

*Make binary
gen read_at_home=1 if Q44==5| Q44==4|Q44==3
replace read_at_home=0 if Q44==2| Q44==1
tab read_at_home Q44, col
tab read_at_home

*Look at conflict between kid and parent answers for those observations for which we have both
tab read_at_home q10 if _merge==3
gen discord=1 if read_at_home==0 & q10==1 & _merge==3
tab discord, m
replace discord=0 if discord==.
tab discord
label var discord "kid says parents read together; parents say never read"
tab discord
gen discord2=1 if read_at_home==1 & q10==2 & _merge==3
tab discord2
replace discord2=0 if discord2==.
label var discord2 "kid says parents never read together; parents say they do read"
tab discord
tab discord2

*Low rates of discord. opt to child answers because presumed less response bias*

replace read_at_home=1 if discord==1
replace read_at_home=0 if discord2==1
tab read_at_home //this is the number we're looking for 

*Make region*

gen region=substr(student_id,2,1) 


********************************
*Task 3: Merge Treatment Status*
********************************


drop _merge

*make School id
gen SCHOOL_ID=substr(RESPONDENT_ID ,1,7)
*merge in treatment
preserve 
use "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\2016 KG EGRA\KG2016sample.dta", clear
duplicates drop SchoolID, force

ren SchoolID SCHOOL_ID
tempfile treatment_status
save "`treatment_status'"
restore

merge m:1 SCHOOL_ID using "`treatment_status'"

drop if _m!=3 
drop _m
rename egra2016 treat 
keep if treat==1 //We only want schools that have a treatment status of 1*/


gen kid_l_diff=1 if q1!=q2
replace kid_l_diff=0 if q1==q2
gen parent_l_diff= 1 if Q4==2
replace parent_l_diff=0 if parent_l_diff==.
*calling different home and LOI if either kid or parent reports it, no otherwise
gen lang_diff=1 if parent_l_diff==1 | kid_l_diff==1
replace lang_diff=0 if lang_diff==.

*This is the language var we use*

gen lang2=mixedtreated
replace lang2=language if mixedtreatedas==""
replace lang2="K" if lang2=="K U"

*******************************
*Task 4: Tabs for Excel Tables*
*******************************

tab lang2 read_at_home, row // Excel: G5-J14
bys lang2: tab region read_at_home if gender!="", row chi // Excel: C5-P34
tab region  read_at_home if gender!="", row chi // Excel: D5-D14
bys region: tab gender read_at_home, row chi
tab gender read_at_home if gender!="", row chi m // D14 and E14 in Excel

*Analyze by home/school lang

bys region: tab lang_diff read_at_home, row chi
tab lang_diff read_at_home, row chi


*Recoding region, merging Osh Region and Osh City
********************************************
tab region
destring region, replace 
replace region=6 if region==9
label define regionlabel 1 "Batken"  4  "Naryn" 5 "Issyk-Kul" 6 "Osh"
label values region regionlabel 
tab region

*Table 26
*********
tab treat , m //only treatment observations 
tab gender
tab read_at_home

*% of parents reading with children (both boys and girls) at home
estpost tabstat read_at_home , by(region) sta(mean n ) //post results to e()

*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_0)


*% of parents reading at home with a boy child
estpost tabstat read_at_home if gender == "B" , by(region) sta(mean n )  //post results to e()
*Store results in matrixes
cap mat drop A1
mat  A1 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A1
frmttable , statmat(A1) sdec(1,0) store(table_1)

*% of parents reading at home with a girl child
estpost tabstat read_at_home if gender== "G" , by(region) sta(mean n )
*Store results in matrixes
cap mat drop A2
mat  A2 = (e(mean)'*100  , e(count)')    //storing `var' results in mat A
qui mat list A2
frmttable , statmat(A2) sdec(1,0) store(table_2)

*Merging 3 tables together 
**********************
qui frmttable , replay(table_0) merge(table_1) store(table_01)
frmttable , replay(table_01) merge(table_2) store(table3)

*Export table 26 to word 
*********************
frmttable using "$outreg\KG_Tables_2016"  , addtable replay(table3)  ///
title("TABLE 26. Percent of Parents Reading with Children at Home, by Region and Gender, Kyrgyz Republic")  ///
ctitle("Region" , "Total" , "" , "Boys" , "" , "Girls" , "" \ "" , "Mean" , "n" , "Mean" , "n"  , "Mean" , "n") ///
rtitle("Batken" \ "Naryn" \ "Issyk-Kul" \ "Osh" \ "Kyrgyz Republic")      ///
coljust(l{c})  basefont(fs10) statfont(fs10) multicol(1,2,2;1,4,2;1,6,2) vlines(01111110) hlines(1{1}1)  colwidth(30 5 5 5 5 5 5)



*Table 27
********
tab kid_l_diff

*% of students whose language of instruction = primary home language
estpost tabstat read_at_home if  kid_l_diff == 0   , by(region) sta(mean n ) //post results to e()
 
*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_0)
 
 
*% of students whose language of instruction != (IS NOT THE SAME) primary home language
estpost tabstat read_at_home if  kid_l_diff == 1   , by(region) sta(mean n ) //post results to e()

*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_1)
 
*Merging table 0 and 1
frmttable , replay(table_0) merge(table_1) store(table_2)

*Export Tablw 27 to Word
*********************
frmttable using "$outreg\KG_Tables_2016"  , addtable replay(table_2)  ///
title("TABLE 27. Percent of Parents Reading with Children at Home, by Region and Differences Between Home and School Language, Kyrgyz Republic")  ///
ctitle("Region" ,"Percent of students whose language of instruction is the same as their primary home language who are read to at home" , "" ,  ///
"Percent of students whose language of instruction differs from their primary home language who are read to at home",""\"","Mean","n","Mean","n") ///
rtitle("Batken" \ "Naryn" \ "Issyk-Kul" \ "Osh" \ "Kyrgyz Republic")      ///
coljust(l{c})  basefont(fs10) statfont(fs10) multicol(1,2,2;1,4,2) vlines(01111110) hlines(1{1}1)  colwidth(30 5 5 5 5 5 5)

