clear all
set more off


**Name: 	Kevin Kamto 
**Project:	QRP - Quality Reading Project

**Indicator 13: Percentage of schools and communities with adequate number of grade-level appropriate supplementary reading materials
**mod to change LOI file to include treat variable
** By: Region, School, Communities, Language
**Modified: PSirma 09.19.2016


/*Indicator calculation 
This indicator was created using survey and observational data from parent interviews, teacher interviews, and classroom observations. 
Schools with an adequate number of available books fulfill at least two of the following three criteria:
*/


global path "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data"
global outreg "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\other M&E data\M&Edata\2016\KG data\Tables"

*************************************************************
*Task 1: pull datasets by instrument with relevant questions
*************************************************************	

use "$path\KG_Parent_2016\Parent.dta", clear
gen sch_code=substr(RESPONDENT_ID,1,7) //looks like some school id issue-- will look at when we merge in treatment variable

*Make index for home*
*********************

bys sch_code: egen median_home_books=median(Q12) // Median gets school-level value from indiv level responses


gen home_books= (median_home_books>=10) // The indicator states that homes with an adequate number of available children’s books have 10 or more children’s books at home
label var home_books "if 10 or more children's books at home"
tab home_books, m
duplicates drop sch_code, force //making dataset of just schools

keep sch_code home_books // Keep relevant variables - median_home_books was an intermediary variable to create home_books, so we don't need to keep it

tempfile KG_i13_parent
save `KG_i13_parent', replace // Here I create a tempfile so that I can later merge with the teacher data

*Teacher*
*********

use "$path\KG_Teacher_2016\Teacher.dta", clear
count
keep TEACHER_ID Q40 // We keep the relevant vars - teachers and the number of books in the classroom (var Q40)
gen sch_code=substr(TEACHER_ID,1,7)
*make 1 of 3 part index for school
gen class_enough= (Q40!=1) // Option 1 stands for fewer than 10 books - so we keep all options except for that one
label var class_enough "if more than 10 books were seen in classroom during teacher interview"  // Enough is more than 10 non-textbook books per class KEVIN we need to make missing Q40 into 0, not 1
replace class_enough=0 if Q40==.


bys sch_code: egen median_class_enough=median(class_enough) // Median gets school-level value from multiple classroom level responses

bys sch_code: replace median_class_enough=. if _n!=1 // We replace to missing if variable is not one of the 4 higher options of Q40 (different intervals of more than 10 books)
drop if median_class_enough==.
drop TEACHER_ID Q40 class_enough

duplicates drop sch_code, force //making dataset of just schools

keep sch_code median_class_enough // Keep relevant variables

tempfile KG_i13_teach
save `KG_i13_teach', replace							 


*Class*
*******
use "$path\KG_Classroom_2016\Classroom.dta", clear
rename Q8 CLASS_ID
keep CLASS_ID Q25
gen sch_code=substr(CLASS_ID,1,7)

*make 2 of 3 part index for school
gen class_books= (Q25==1) // Q25 stands for the number of non-textbooks available in the classroom
bys sch_code: egen median_class_books=median(class_books)
replace median_class_books=1 if median_class_books>=.5 // Correcting to be binary form
label var median_class_books "binary for books seen in class"
bys sch_code: replace median_class_books=. if _n!=1
drop if median_class_books==.

keep sch_code median_class_books // Keep relevant variables
tempfile KG_i13_class
save `KG_i13_class', replace

*Lib*
*****
use "$path\KG_Librarian_2016\Librarian.dta", clear
keep LIBRARIAN_ID Q3 
gen sch_code=substr(LIBRARIAN_ID,1,7)

*make 3 of 3 part index for school
gen sch_books= (Q3 ==4) // Option 4 of this var means that there are over 100 books
label var sch_books "if more than 100 books in school library"
bys sch_code: egen median_sch_books=median(sch_books) //
bys sch_code: replace median_sch_books=. if _n!=1
drop if median_sch_books==.

keep median_sch_books sch_code // Keep relevant variables
tempfile KG_i13_librarian
save `KG_i13_librarian', replace
*60 schools

*Start here with making school merge, then 2 of 3 for that final school variable. Then merge in home.
**********************************************************************************

*Merge all datasets

merge 1:1 sch_code using `KG_i13_parent'
drop _m
sort sch_code
*save "$path\KG_i13.dta", replace

*save "$Output\KG_i13.dta", replace
merge 1:1 sch_code using `KG_i13_teach'
drop _m
sort sch_code
merge 1:1 sch_code using `KG_i13_class'
drop if _m!=3
drop _m
sort sch_code
*save "$Output\i13.dta", replace

gen region=substr(sch_code,2,1) // 


// Create Enough school books variable

gen enough_sch_books=median_sch_books+median_class_enough+median_class_books // Amy - Can we add some info from the docs on why we have to add these 3 vars
replace enough_sch_books= (enough_sch_books>=2) // Enough school books is 2 of 3 median_sch_books median_class_enough median_class_books

gen enough_both= enough_sch_books+home_books // Enough both if we have a value of 1 for each variable, which means sum must add up to 2

replace enough_both= (enough_both==2)
ren sch_code SchoolID // We will need to match this file with the file containing the treatment status. On that file, that var is called full_code

// Here we merge school treatment variable

merge 1:m SchoolID using "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\2016 KG EGRA\KG2016sample", keepus (language egra2016)
drop if _m!=3 // Keep schools that are part of impact evaluation, which is _m==3 --> Because only schools in both files
drop _merge
ren egra2016 treat
ren SchoolID sch_code		
	

***Paul enough_both is the variable we need for tables here. remember report only treat
cou //71
keep if treat ==1 
tab treat , m  // only treated observations remained 
cou //35

des region 
tab region 
cap drop region 
gen region = substr(sch_code , 2, 1)
destring region , replace
tab region 
recode region (9=6) 
label define regionlabel 1 "Batken"  4  "Naryn" 5 "Issyk-Kul" 6 "Osh"  , replace 
lab val region regionlabel
tab region 

*Table 19
*********	
foreach var of varlist 	enough_sch_books home_books enough_both{ 

 	estpost tabstat `var' , by(region) stat(mean n)
		
	*Store results in matrixes
	cap mat drop A
	mat  A = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
	qui mat list A
	
	qui frmttable , statmat(A) sdec(1,0)  store(table_0)
	 
	
	if "`var'" ==  "enough_sch_books" {    //store Table 0 in Table 1
		di "*** `var' ******"
		frmttable , replay(table_0) sdec(1,0)  store(table_1)

		
	}
	else {   //merge Table 1 with Table 0 
		di "*** `var' *** "
		frmttable , merge(table_0) replay(table_1) sdec(1,0)  store(table_1)
	
	}

}
*Exporting Table 19 to Word 
frmttable using "$outreg\KG_Tables_2016"  , addtable replay(table_1) sdec(1,0)  store(table_1)  ///
title("TABLE 19. Percent of Schools and Communities with an Adequate Number of Grade-Level-Appropriate Supplementary Reading Materials, by Region, Kyrgyz Republic")  ///
ctitle("Region" , "Books at school" , "" , "Books at home" , "" , "Books at school and home", "" \ "" , "Mean" , "n" , "Mean" , "n" , "Mean" , "n" )  ///
rtitle("Batken" \ "Naryn" \ "Issyk-Kul" \ "Osh" \ "Kyrgyz Republic") ///
coljust(l{c})  basefont(fs10) statfont(fs10) multicol(1,2,2;1,4,2;1,6,2) vlines(01111110) hlines(1{1}1)  colwidth(15 5 5 5 5 5 5)


*Table 20 
*********
des language
tab language 	
cap drop x 
encode language , gen(x)
tab language x , nol

lab define lang 1 "Kyrgyz only" 2 "Kyrgyz and Russian" 3 "Kyrgyz, Russian, and Uzbek" 4 "Russian only" , replace
lab val x lang
tab language x 
drop language
rename x language

estpost tabstat enough_both , by(language )  sta(mean n ) nototal

*Store results in matrixes
cap mat drop A
mat  A = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A

*Exporting Table to Word 
*********************
frmttable using "$outreg\KG_Tables_2016" , addtable statmat(A) sdec(1,0)  store(table_1) ///
title("TABLE 20. Percent of Schools and Communities with an Adequate Number of Grade-Level-Appropriate Supplementary Reading Materials, by School Language(s) of Instruction, Kyrgyz Republic")  ///
ctitle("Region" , "2016" , "" \ "" , "Mean" , "n" )  ///
coljust(l{c})  basefont(fs10) statfont(fs10) multicol(1,2,2) vlines(0110) hlines(1{1}1)  colwidth(30 5 5 5 5 5 5)


