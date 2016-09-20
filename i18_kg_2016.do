clear all 
set more off 

**Created:		Kevin Kamto
*Indicator 18: 	Percentage of primary grade students participating in at-home reading program
*by district, gender, language, grade
**Modified: 		PSirma 09.19.2016: Added code to analyze data and export the result to word


*************************************************************
*Task 1: Pull datasets by instrument with relevant questions*
*************************************************************

*Key variable to measure this indicator is Q10: Books (not textbooks) read at home

use "H:\ECA Region Projects\QRP Central Asia-D3452\Technical\Data\2016 KG EGRA\Working_data\KG_2016_allgrades_appended.dta", clear
tostring q23 q24, replace

// Create student_id variable
replace country="1" if country=="K"

rename treat treatment

//Keep key variables
keep StudentID q2 q1 gender q10 region treatment mixedtreatedas language grade

// Q10 - Do you ever read books that are not textbooks at home? 	
tab q10 
drop if q10==3 | q10==.  // To be consistent with previous files
tab q10 
tab region q10, row
bys region: tab gender q10, row chi
tab gender q10, row chi

// Q2 - Language spoken at home 
bys region: tab q2 q10, row 
tab q2 q10, row 

// Q1- Language spoken at school
drop if q1==3 // For this indicator, we are only looking at Russian and Kyrgyz, so we are deleting other languages 
drop if q2==3  
drop if q2==4

keep if treatment==1 // We are only considering treatment schools

tab mixedtreatedas // This is the language variable we use
gen lang2=mixedtreated
replace lang2=language if mixedtreatedas==""
//replace lang2="K" if lang2=="Kyrgyz"...from old files, languages are already coded in "R" and "K"
//replace lang2="R" if lang2=="Russian"...from old files, languages are already coded in "R" and "K"
tab lang2, m

*******************************
*Task 2: Tabs for Excel Tables*
*******************************

*Distribution by language*
tab lang2 q10, row // Excel N16-Q33
bys lang2: tab region q10 if gender!="", row chi 

*Gender and Region*
bys region: tab gender q10, row chi 
tab gender q10, row chi 

*Language at Home and Region*
bys region: tab q2 q10, row chi 
tab q2 q10, row chi 

*Language of instruction and region*
bys region: tab q1 q10, row chi 
tab q1 q10, row chi 

*Grade and Region*
bys region: tab grade q10, row chi
tab grade q10, row chi 

*Recoding region, merging Osh Region and Osh City
*******************************************
replace region=6 if region==9
label define regionlabel 1 "Batken"  4  "Naryn" 5 "Issyk-Kul" 6 "Osh"
label values region regionlabel 

*recoding for tables
*****************
replace q10=0 if q10==2
tab q10, nolabel


*Keep treat only 
**************
keep if treat ==1 
tab treat , m  //1,309 Treatment observations 


*Table 28
********
tab q10
tab gender 

*% of primary students reading at home, TOTAL (boys + girls)
estpost tabstat q10 , by(region)  sta(mean n)  //posting results to e()

*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_0)

*% of primary students reading at home, BOYS
estpost tabstat q10  if gender == "B" , by(region)  sta(mean n)  //posting results to e()

*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100  , e(count)')    //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_1)

*% of primary students reading at home, Girls
estpost tabstat q10  if gender == "G" , by(region)  sta(mean n)  //posting results to e()

*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_2)

*Merging tables 0-2
frmttable ,  replay(table_0)  merge(table_1) store(table_01)
frmttable ,  replay(table_01)  merge(table_2) store(table_3)

*Exporting to Word 
****************

frmttable using "$outreg\KG_Tables_2016"  , addtable replay(table_3)  ///
title("TABLE 28. Percent of Primary Students Reading at Home, by Region and Gender, Kyrgyz Republic")  ///
ctitle("Region" , "Total" , "" , "Boys" , "" , "Girls" , "" \ "" , "Mean" , "n" , "Mean" , "n"  , "Mean" , "n") ///
rtitle("Batken" \ "Naryn" \ "Issyk-Kul" \ "Osh" \ "Kyrgyz Republic")      ///
coljust(l{c})  basefont(fs10) statfont(fs10)  multicol(1,2,2;1,4,2;1,6,2) vlines(01111110) hlines(1{1}1)  colwidth(30 5 5 5 5 5 5)


*Table 29
********
tab q2 
tab q2, nola

*Language spoken at home = Russian 
estpost tabstat q10 if q2==1 , by(region) sta(mean n) //post results to e()

*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_0)

*Language spoken at home = Kyrgyz 
estpost tabstat q10 if q2==2 , by(region) sta(mean n) //post results to e()

*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_1)

*Language spoken at home = Other 
estpost tabstat q10 if q2==5 , by(region) sta(mean n) //post results to e()

*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_2)

*Merging Tables 0-2 
frmttable , replay(table_0) merge(table_1) store(table_01)
frmttable , replay(table_01) merge(table_2) store(table_3)

*Export Table 29 to word 
*********************
frmttable using "$outreg\KG_Tables_2016"  , addtable replay(table_3)  ///
title("TABLE 29. Percent of Primary Students Reading at Home, by Region and Home Language, Kyrgyz Republic")  ///
ctitle("Region" , "Russian Spoken at Home" , "" , "Kyrgyz Spoken at Home" , "" , "Other Language Spoken at Home" , "" \ "" , "Mean" , "n" , "Mean" , "n"  , "Mean" , "n") ///
rtitle("Batken" \ "Naryn" \ "Issyk-Kul" \ "Osh" \ "Kyrgyz Republic")      ///
coljust(l{c})  basefont(fs10) statfont(fs10)  multicol(1,2,2;1,4,2;1,6,2) vlines(01111110) hlines(1{1}1)  colwidth(30 5 5 5 5 5 5)


*Table 30
********
tab q1
tab q1 , nola

*Language spoken is Russian 
estpost tabstat q10 if q1 ==1  , by(region) sta(mean n)

*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_0)


*Language spoken is Krygzy 
estpost tabstat q10 if q1 ==2  , by(region) sta(mean n)

*Store results in matrixes
cap mat drop A0
mat  A0 = (e(mean)'*100 , e(count)')  //storing `var' results in mat A
qui mat list A0
frmttable , statmat(A0) sdec(1,0) store(table_1)

*Merging Table 0-1
frmttable , replay(table_0) merge(table_1) store(table_2)
 
*Export Table 30 to Word 
*********************
frmttable using "$outreg\KG_Tables_2016"  , addtable replay(table_2)  ///
title("TABLE 30. Percent of Primary Students Reading at Home, by Region and Language of Instruction, Kyrgyz Republic")  ///
ctitle("Region" , "Russian" , "" , "Kyrgyz" , "" \ "" , "Mean" , "n" , "Mean" , "n" ) ///
rtitle("Batken" \ "Naryn" \ "Issyk-Kul" \ "Osh" \ "Kyrgyz Republic")      ///
coljust(l{c})  basefont(fs10) statfont(fs10)  multicol(1,2,2;1,4,2) vlines(011110) hlines(1{1}1)  colwidth(30 5 5 5 5 5 5)

