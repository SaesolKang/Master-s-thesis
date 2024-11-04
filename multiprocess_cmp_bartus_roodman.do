*-------------------------------------------------------------------------
*
* REPLICATING aML EXAMPLES FOR MULRIPROCESS STATA JOURNAL PAPER
*
*-------------------------------------------------------------------------

clear all
set memory 50m
set trace off
set more off


// Install cmp
//ssc install cmp, replace
//ssc install ghk2, replace

*-------------------------------------------------------------------------
* 5.1: 
* THE PROBLEM: EDUCATION AND THE TIMING OF SECOND BIRTHS
*-------------------------------------------------------------------------

// Obtain data
sjlog using multiprocess_cmp1, replace
use http://web.uni-corvinus.hu/bartus/stata/divorce.dta
sjlog close, replace

// Sample 
sjlog using multiprocess_cmp2, replace
keep if marnum==1 & numkids<2
replace numkids = numkids+1
sjlog close, replace
//drop sep

// Variables
sjlog using multiprocess_cmp3, replace
generate lo = ln(time-mardur)
generate hi = cond(birth==1, lo, .)
sjlog close, replace


// Education and time to birth: results from separate models
sjlog using multiprocess_cmp4, replace
replace age = age + mardur - 30
cmp (birth2 : lo hi = ib2.hereduc c.age##c.age) if numkids==2, indicators(7) 
sjlog close, replace


*-------------------------------------------------------------------------
* 5.2 AND 5.3: 
* MULTILEVEL AND SIMULTANEOUS EQ. MODELS OF RECURRENT EVENTS
*-------------------------------------------------------------------------

// Method 1: Multilevel model
sjlog using multiprocess_cmp5, replace
cmp (birth: lo hi = ib2.numkids##(ib2.hereduc c.age##c.age) || id:), indicators(7)
sjlog close, replace
 
// Method 2: Joint estimation of survival models

use "http://web.uni-corvinus.hu/bartus/stata/divorce.dta", clear
keep if marnum==1 & numkids<2
replace numkids = numkids+1
generate lo = ln(time-mardur)
generate hi = cond(birth==1, lo, .)
replace age = age + mardur - 30
drop mardur time sep
reshape wide birth age lo hi, i(id) j(numkids)

sjlog using multiprocess_cmp6, replace
cmp (birth2: lo2 hi2 = ib2.hereduc c.age2##c.age2) (birth1: lo1 hi1 = ib2.hereduc c.age1##c.age1), indicators(7 7) 
sjlog close, replace


*-------------------------------------------------------------------------
* 5.4
* SIMULTANEOUS EQ. MODEL FOR DIFFERENT EVENTS
* See the aML manual, section 4.2.1
*-------------------------------------------------------------------------

// Obtain data
use "http://web.uni-corvinus.hu/bartus/stata/divorce.dta", clear

keep if marnum==1 & numkids==1

// episode splitting at 1, 2, 5 and 10 years of durations
// bitrth events mark the beginning of new episodes

generate dur = time-mardur
generate double id2 = _n
stset dur, fail(sep==1) id(id)
stsplit bdur, at(1 2 5 10)

// Corrections
replace mardur = mardur + _t0 
replace birth = 0 if sep==.
replace sep = 0 if sep==.

// Age at the beginning of spells
replace age = age + mardur - 30

// Dependent variables
generate mlo = ln(mardur+dur)
generate mhi = cond(sep==1,mlo,.)
generate blo = ln(bdur+dur)
generate bhi = cond(birth==1, blo, .)

// Joint modeling of birth and separation processes

sjlog using multiprocess_cmp7, replace
cmp (birth: blo bhi = ib2.hereduc c.age##c.age mardur, trunc(ln(bdur) .)) ///
	 (divorce: mlo mhi = ib2.hereduc mardur, trunc(ln(mardur) .)) ///
 if numkids==1, vce(cluster id) indicators(7 7) 
sjlog close, replace


// Interpretation

sjlog using multiprocess_cmp8, replace
nlcom _b[birth:3.hereduc] - ///
	_b[divorce:3.hereduc]*tanh(_b[atanhrho_12:_cons])*exp(_b[lnsig_1:_cons])/exp(_b[lnsig_2:_cons])
sjlog close, replace



