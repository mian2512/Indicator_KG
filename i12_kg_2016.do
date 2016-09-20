clear all 
set more off


**Name: 	Kevin Kamto 
**Project:	QRP - Quality Reading Project
**Purpose:	Indicator 12: Percent of teachers using results of classroom-based reading assessment.
**Modified: 	Psirma 09.19.2016



global path "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data"
global outreg "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data\Tables"

											
use "$path\KG_Teacher_2016\Teacher.dta", clear
gen sch_code=substr(TEACHER_ID,1,7)
gen region=substr(TEACHER_ID,2,1)

/*merge in LOI variable
merge m:1 sch_code using "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\KG_sch_lang.dta", force
keep if _m==3
drop _m*/ //Kevin, I'm cutting this out because we have LOI in the sample dataset below. I'm conconcerned that this merge drops observations and shows missing schools.

*merge in treatment status
preserve 
use "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\2016 KG EGRA\KG2016sample.dta", clear
rename SchoolID full_code
rename egra2016 treat
duplicates drop full_code, force
ren full_code sch_code
tempfile treatment_status
save "`treatment_status'"
restore
merge m:1 sch_code using "`treatment_status'", force
keep if _m==3
drop _m

gen use = (Q70C==1)
replace use =1 if Q70D==1
replace use =1 if Q70D==1
tab use
*31.91% of teachers, 42.75% in treat schools and 21.53% in control schools are using formative assessment.


*to get numbers for weighting
tab language region if treat==1

tab use treat, col
tab Q70C Q70D
tab Q70C use
tab Q70D use

*Recoding region, merging Osh Region and Osh City
*******************************************
tab region
destring region, replace 
replace region=6 if region==9
label define regionlabel 1 "Batken"  4  "Naryn" 5 "Issyk-Kul" 6 "Osh"
label values region regionlabel 
tab region


*Keeping only treatment obeservations for the analysis 
**********************************************
cou 
keep if treat ==1
cou 
tab treat //only have treatment observations 


**For Table 17*
*************
qui estpost tabstat use , by(region) sta(n mean)  //posting the results to e()
qui ereturn list

*Storing mean into matrix A 
cap drop mat A 
qui mat A = e(mean)' * 100 
matlist A 
mat rownames A = "Batken" "Naryn" "Issyk-Kul" " Osh" "Kyrgyz Republic"


*storing n into matrix B 
cap mat drop B
mat B = e(count)' 
matlist B
mat rownames B = "Batken" "Naryn" "Issyk-Kul" " Osh" "Kyrgyz Republic"

qui frmttable , statmat(A) sdec(1) store(table_1)
frmttable , statmat(B) merge(table_1) sdec(0) store(table_1)

*Exporting to Word
frmttable using "$outreg\KG_Tables_2016" , addtable replay(table_1)  ///
title("TABLE 17. Percent of Teachers Using Results of Classroom-Based Reading Assessment, by Region, Kyrgyz Republic")  ///
ctitle("Region" , "2016" \ "" , "Mean" , "n") coljust(l{c})  basefont(fs10) statfont(fs10) multicol(1,2,2) vlines(0110) hlines(1{1}1)  

	
**For Table 18
************
tab language
tab language , nola
*Anlysis for Kyrgyz Language
estpost tabstat use  if language == 4 ,  missing   by(region) sta(n mean)   //posting the results to e()
qui ereturn list 

*Store results in matrixes
cap mat drop A2
mat  A2 = (e(mean)'*100 ,e(count)')  //storing Krygyz results in mat A2
mat list A2
frmttable , statmat(A2) sdec(1,0)  ctitle("Region" , "Kyrgyz" \ "" , "Mean" , "n") store(table_2)

*Anlysis for Russian Language
estpost tabstat use  if language == 2 ,  missing   by(region) sta(n mean)   //posting the results to e()
cap mat drop A1
mat  A1 = (e(mean)'*100 ,e(count)')  //storing the Russian results in mat A1
mat list A1
frmttable , statmat(A1) sdec(1,0)  ctitle("Region" , "Russian" \ "" , "Mean" , "n") store(table_1)

*Merging Russian and Kyrgyz tables
frmttable , statmat(A2) sdec(1,0) ctitle("Region" , "Kyrgyz" \ "" , "Mean" , "n") store(table_2)

frmttable  ,  replay(table_2) merge(table_1) store(table2)

*Merging tables 1 and 2 and export the table to word
frmttable using "$outreg\KG_Tables_2016" , addtable replay(table2)  ///
title("TABLE 18. Percent of Teachers Using Results of Classroom-Based Reading Assessment, by Classroom Language of Instruction, Kyrgyz Republic")  ///
 ctitle("Region" , "Kyrgyz" , "",  "Russian" , ""  \ "" , "Mean" , "n" , "Mean" , "n" )  ///
 rtitle("Batken" \ "Naryn" \ "Issyk-Kul" \ "Osh" \ "Kyrgyz Republic") ///
coljust(l{c})  basefont(fs10) statfont(fs10) multicol(1,2,2;1,4,2) vlines(011110) hlines(1{1}1) 

   
