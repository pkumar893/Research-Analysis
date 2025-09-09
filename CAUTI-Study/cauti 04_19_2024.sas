x cd "H:\SAS";
proc import datafile="Cauti Study data 4-2024.xlsx"
out=table1 dbms=excel replace;
run;

data table1;
set table1;
if PAT_AGE <= 17 then delete;
run;

data table1;
set table1;
if Gender="Male" then Gender=0;
if Gender="Female" then Gender=1;
if DIABETES_ON_PROBLEM_LIST="Y" then DIABETES_ON_PROBLEM_LIST=1;
if DIABETES_ON_PROBLEM_LIST="N" then DIABETES_ON_PROBLEM_LIST=0;
if RENAL_INSUFFICIENY_ON_PROBLEM_LI="Y" then RENAL_INSUFFICIENY_ON_PROBLEM_LI=1;
if RENAL_INSUFFICIENY_ON_PROBLEM_LI="N" then RENAL_INSUFFICIENY_ON_PROBLEM_LI=0;
if Bowel_Incontinence="Y" then Bowel_Incontinence=1;
if Bowel_Incontinence="" then Bowel_Incontinence=0;
if Urinary_Incontinence="Y" then Urinary_Incontinence=1;
if Urinary_Incontinence="" then Urinary_Incontinence=0;
if ORDER_FOR_FOLEY="Y" then ORDER_FOR_FOLEY=1;
if ORDER_FOR_FOLEY="" then ORDER_FOR_FOLEY=0;
if CAUTI_LDA="Y" then CAUTI_LDA=1;
if CAUTI_LDA="N" then CAUTI_LDA=0;
run;

data table1;
set table1;
CAUTI_Date = input(strip(CAUTI_Infection_date), MMDDYY10.);
format CAUTI_Date DATE9.;
run;


data table2;
set table1;
admissionday= round(HOSP_DISCH_TIME-HOSP_ADMSN_TIME +1);
run;

data table3;
set table2;
CHG= CHG_NUMERATOR/CHG_DENOMINATOR*100;
run;

data table4;
set table3;
chg2=chg;
if chg2 >= 100 then chg2=100;
run;

data table4;
set table4;
foleyday = intck('day',PLACEMENT_DATE, REMOVAL_DATE) +1;
run;

proc freq data=table4;
table CAUTI_LDA;
run;

data table5;
set table4;
meatal= Meatal_Numerator/Meatal_Denominator*100;
if gender="Unknown" then delete;
if PAT_MRN_ID=. then delete;
run;

data table5;
set table5;
if meatal=>100 then meatal=100;
run;

proc means data=table5;
var meatal chg2 foleyday;
run;

*data table5;
*set table5;
*if foleyday > 60 | foleyday <3 then delete;
*cauti_lda2=cauti_lda;
*run;

proc sort;
by PAT_MRN_ID HOSP_ADMSN_TIME PLACEMENT_DATE;
run;


data table6;
set table5;
if PLACEMENT_DATE >= HOSP_ADMSN_TIME -3 and PLACEMENT_DATE < HOSP_DISCH_TIME and REMOVAL_DATE > HOSP_DISCH_TIME then REMOVAL_DATE = HOSP_DISCH_TIME;
if PLACEMENT_DATE < HOSP_ADMSN_TIME -3 then delete;
if PLACEMENT_DATE > HOSP_DISCH_TIME then delete;
if (CAUTI_LDA= 1 & (PLACEMENT_DATE > CAUTI_Date)) then delete;
run;


data table6;
set table6;
foleyday = intck('day',PLACEMENT_DATE, REMOVAL_DATE) +1;
run;

proc means data=table6;
var meatal chg2 foleyday;
run;

proc print data= table6;
var PAT_MRN_ID HOSP_ADMSN_TIME HOSP_DISCH_TIME PLACEMENT_DATE REMOVAL_DATE foleyday;
where foleyday>60;
run;

*data table7;
*set table6;
*CAUTI_LDA2=CAUTI_LDA;
*if CAUTI_LDA=1 & CAUTI_Infection_date < PLACEMENT_DATE then CAUTI_LDA2=0;
*if CAUTI_LDA=1 & CAUTI_Infection_date > removal_DATE then CAUTI_LDA2=0;
*run;

*proc freq data=table7;
*table CAUTI_LDA CAUTI_LDA2;
*run;

*data table7;
*set table6;
*new_placement= PLACEMENT_DATE;
*new_removal= REMOVAL_DATE;
*format new_placement MMDDYY10.;
*format new_removal MMDDYY10.;
*run;

*data table7;
*set table7;
*by PAT_MRN_ID
*if PLACEMENT_DATE = REMOVAL_DATE then;

data table7;
set table6;
CAUTI_LDA2= CAUTI_LDA;
if ConsecutiveFoley= "N" then CAUTI_LDA2= "0";
run;

proc logistic data=table7;
class gender(ref="0") ORDER_FOR_FOLEY(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")
Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0");
model CAUTI_LDA2(event="1") = PAT_AGE gender ORDER_FOR_FOLEY PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence 
CHG2 meatal foleyday;
run;

proc means data=table7;
var meatal chg2 foleyday;
run;




/**/
/*data table7;*/
/*set table6;*/
/*if cauti_lda2 ^= cauti_lda & date_var < placement_date then delete;*/
/*run;*/
/**/


*data table8;
*set table7;
*if cauti_lda2 ^= cauti_lda then delete;
*run;

*data table8;
*set table7;
*drop Num_Foley_Urine_Culture_Collecte Num_abnormal_Urine_Culture Num_Foley_Abnormal_Urine_Culture Num_Foley_Urine_Culture_GT_24H_a Num_Foley_Abnormal_Urine_Cultur0 POA Urine_Collected_From_foley Urine_Collected_GT_24H_From_Fole LINE_TYPE LINE_DESCRIPTION IP_LDA_ID;
*run;

data table8;
set table7;
run;

proc sort data=table8;
by PAT_MRN_ID HOSP_ADMSN_TIME PLACEMENT_DATE;
run;

data table8;
set table8;
by PAT_MRN_ID HOSP_ADMSN_TIME;
retain num_foleys;
if first.HOSP_ADMSN_TIME then num_foleys=1;
else num_foleys=num_foleys+1;
run;

*data table8;
*set table8;
*by PAT_MRN_ID HOSP_ADMSN_TIME;
*new_mrn=0;
*retain new_mrn;
*if first.PAT_MRN_ID & first.HOSP_ADMSN_TIME then new_mrn=new_mrn+1;
*else new_mrn+2;
*run;

data table8;
set table8;
by PAT_MRN_ID HOSP_ADMSN_TIME;
retain foley_gap;
r_date=lag(REMOVAL_DATE);
format r_date ddmmyy6.;
if first.HOSP_ADMSN_TIME then foley_gap=0;
else foley_gap= intck('day',r_date, PLACEMENT_DATE);
run;

data table8;
set table8;
by PAT_MRN_ID HOSP_ADMSN_TIME;
retain consec_foley;
if first.HOSP_ADMSN_TIME then consec_foley=1;
if foley_gap >1 then consec_foley=consec_foley+1;
else consec_foley=consec_foley+0;
run;

data table8;
set table8;
by PAT_MRN_ID HOSP_ADMSN_TIME;
retain consec_foley;
if CAUTI_LDA2=1 then consec_foley=0;
run;

data table9;
set table8;
run;

proc sort data=table9;
by PAT_MRN_ID HOSP_ADMSN_TIME PLACEMENT_DATE;
run;

data table9;
set table9;
by PAT_MRN_ID HOSP_ADMSN_TIME;
retain new_id;
if _N_=1 then new_id=0;
if first.HOSP_ADMSN_TIME then  new_id + 1;
run;

data table9;
set table9;
ORDER_FOR_FOLEY2= input(ORDER_FOR_FOLEY, comma9.);
run;


Proc Sql;
create table consec_foleys_new_id as
select new_id, PAT_MRN_ID, PAT_AGE, Gender, PAT_BMI, DIABETES_ON_PROBLEM_LIST, DIABETES_ON_PROBLEM_LIST_DATE, RENAL_INSUFFICIENY_ON_PROBLEM_LI, RENAL_INSUFFICIENY_ON_PROBLEM_L0, Bowel_Incontinence, Urinary_Incontinence, ORDER_FOR_FOLEY, CAUTI_Date, CathAttrib, CAUTI_Unit, Foley_Placement_unit, admissionday, foleyday, CAUTI_LDA, ConsecutiveFoley, meatal_denominator, meatal_numerator, CHG_DENOMINATOR, CHG_numerator, HOSP_ADMSN_TIME, PLACEMENT_DATE, REMOVAL_DATE, consec_foley, CAUTI_LDA2, Num_Foley_Urine_Culture_Collecte, Num_abnormal_Urine_Culture, Num_Foley_Abnormal_Urine_Culture, Num_Foley_Urine_Culture_GT_24H_a, Num_Foley_Abnormal_Urine_Cultur0, ORDER_FOR_FOLEY2, sum(meatal_denominator) as tot_meatal_denom, sum(meatal_numerator) as tot_meatal_numer, sum(CHG_denominator) as tot_CHG_denom, sum(CHG_numerator) as tot_CHG_numer, sum(Num_Foley_Urine_Culture_Collecte) as Tot_Foley_UC_Collected, sum(Num_abnormal_Urine_Culture) as Tot_abnormal_UC, sum(Num_Foley_Abnormal_Urine_Culture) as Tot_Foley_Abnormal_UC, sum(Num_Foley_Urine_Culture_GT_24H_a) as Tot_Foley_UC_GT_24H_after_insert, sum(Num_Foley_Abnormal_Urine_Cultur0) as Tot_Foley_Abnorm_UC_24H_aft_ins, sum(ORDER_FOR_FOLEY2) as ORDER_FOR_FOLEY3
from table9
group by new_id ,HOSP_ADMSN_TIME, consec_foley;
Quit;

data table10;
set consec_foleys_new_id;
if ORDER_FOR_FOLEY3 >1 then ORDER_FOR_FOLEY3=1;
run;

proc sort data=table10;
by new_id HOSP_ADMSN_TIME PLACEMENT_DATE;
run;

data table10;
set table10;
by new_id HOSP_ADMSN_TIME PLACEMENT_DATE;
retain new_placement_date;
if first.HOSP_ADMSN_TIME then new_placement_date=PLACEMENT_DATE;
if consec_foley=lag(consec_foley) then new_placement_date=new_placement_date;
else new_placement_date=PLACEMENT_DATE;
format new_placement_date date9.;
run;

proc sort data=table10;
by new_id HOSP_ADMSN_TIME PLACEMENT_DATE;
run;

data table11;
set table10;
by new_id HOSP_ADMSN_TIME PLACEMENT_DATE;
retain new_id2;
if _N_=1 then new_id2=0;
if new_placement_date=lag(new_placement_date) then  new_id2=new_id2;
else new_id2+1;
run;

proc sort data=table11;
by new_id2 descending REMOVAL_DATE;
run;


data table11;
set table11;
by new_id2;
retain new_removal_date;
if first.new_id2 then new_removal_date=REMOVAL_DATE;
else new_removal_date= new_removal_date;
format new_removal_date date9.;
run;

data table12;
set table11;
run;

data table12;
set table12;
CAUTI_LDA3=input(CAUTI_LDA2, 4.);
run;

proc sort data=table12;
by new_id2 descending CAUTI_LDA3;
run;

data table12;
set table12;
by new_id2;
retain new_CAUTI_LDA;
if first.new_id2 then new_CAUTI_LDA=CAUTI_LDA3;
else new_CAUTI_LDA+0;
run;

data table13;
set table12;
foleyday2=intck('day',new_placement_date,new_removal_date)+1;
run;

data table13;
set table13;
tot_meatal=(tot_meatal_numer/tot_meatal_denom)*100;
tot_chg=(tot_CHG_numer/tot_CHG_denom)*100;
run;

data table13;
set table13;
tot_meatal=round(tot_meatal);
tot_chg=round(tot_chg);
run;


*proc sort;
*by new_id2;
*run;

*data table14;
*set table13;
*by new_id2;
*Num_Foley_Urine_Culture_Collec_2=sum(Num_Foley_Urine_Culture_Collecte);
*run;

*proc sort;
*by PAT_MRN_ID HOSP_ADMSN_TIME descending Num_abnormal_Urine_Culture;
*run;

*data table7;
*set table7;
*by PAT_MRN_ID HOSP_ADMSN_TIME descending Num_abnormal_Urine_Culture;
*retain Num_abnormal_Urine_Culture_2;
*if first.HOSP_ADMSN_TIME then Num_abnormal_Urine_Culture_2=Num_abnormal_Urine_Culture;
*run;

*proc sort;
*by PAT_MRN_ID HOSP_ADMSN_TIME descending Num_Foley_Abnormal_Urine_Culture;
*run;

*data table7;
*set table7;
*by PAT_MRN_ID HOSP_ADMSN_TIME descending Num_Foley_Abnormal_Urine_Culture;
*retain Num_Foley_Abnormal_Urine_Cult_2;
*if first.HOSP_ADMSN_TIME then Num_Foley_Abnormal_Urine_Cult_2=Num_Foley_Abnormal_Urine_Culture;
*run;

*proc sort;
*by PAT_MRN_ID HOSP_ADMSN_TIME descending Num_Foley_Urine_Culture_GT_24H_a;
*run;

*data table7;
*set table7;
*by PAT_MRN_ID HOSP_ADMSN_TIME descending Num_Foley_Urine_Culture_GT_24H_a;
*retain Num_Foley_Urine_Culture_GT_24H_2;
*if first.HOSP_ADMSN_TIME then Num_Foley_Urine_Culture_GT_24H_2=Num_Foley_Urine_Culture_GT_24H_a;
*run;

*proc sort;
*by PAT_MRN_ID HOSP_ADMSN_TIME descending Num_Foley_Abnormal_Urine_Cultur0;
*run;

*data table7;
*set table7;
*by PAT_MRN_ID HOSP_ADMSN_TIME descending Num_Foley_Abnormal_Urine_Cultur0;
*retain Num_Foley_Abnormal_Urine_Cul24_2;
*if first.HOSP_ADMSN_TIME then Num_Foley_Abnormal_Urine_Cul24_2=sum(Num_Foley_Abnormal_Urine_Cultur0);
*run;

*data table14;
*set table13;
*meatal_change_date=input("03/31/22",MMDDYY10.);
*format meatal_change_date date9.;
*run;

data table14;
set table13;
if tot_meatal>100 then tot_meatal=100;
if tot_meatal="." then meatal_cat=.;
if 0 =< tot_meatal =< 49 then meatal_cat=1;
if 50 =< tot_meatal =< 79 then meatal_cat=2;
if 80 =< tot_meatal =< 100 then meatal_cat=3;
run;

data table14;
set table14;
if tot_chg>100 then tot_chg=100;
if tot_chg="." then chg_cat=.;
if 0 =< tot_chg =< 49 then chg_cat=1;
if 50 =< tot_chg =< 79 then chg_cat=2;
if 80 =< tot_chg =< 100 then chg_cat=3;
run;

data table15;
set table14;
by new_id2;
if first.new_id2;
run;



*Proc Sql;
*create table analysis as
select new_id2, PAT_MRN_ID, PAT_AGE, Gender, HOSP_ADMSN_TIME, new_PLACEMENT_DATE, new_REMOVAL_DATE, consec_foley, foleyday2, tot_meatal_denom, tot_meatal_numer, tot_CHG_denom, tot_CHG_numer, DIABETES_ON_PROBLEM_LIST, RENAL_INSUFFICIENY_ON_PROBLEM_LI, Bowel_Incontinence, Urinary_Incontinence, new_CAUTI_LDA, foleyday2, tot_meatal, tot_chg, meatal_cat, chg_cat
from table15 table8
group by new_id ,HOSP_ADMSN_TIME, new_placement_date;
*Quit;

proc means data=table15;
var tot_meatal tot_chg foleyday2;
run;

*data table16;
*set table15;
*if metal_deno_tot=0 then delete;
*if chg_deno_tot=0 then delete;
*if poa = "Y" then poa=1;
*if poa="" then poa=0;
*run;

proc logistic data=table15;
class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")
Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0") chg_cat (ref="1") meatal_cat (ref="1") ORDER_FOR_FOLEY3 (ref="0");
model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence 
chg_cat meatal_cat foleyday2 ORDER_FOR_FOLEY3;
run;

proc logistic data=table15;
class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")
Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0") chg_cat (ref="1") meatal_cat (ref="1");
model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence 
chg_cat meatal_cat foleyday2;
run;


proc logistic data=table15;
class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")
Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0") ORDER_FOR_FOLEY3 (ref="0");
model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence 
tot_chg tot_meatal foleyday2 ORDER_FOR_FOLEY3;
run;


proc means data=table15;
var foleyday2 tot_chg tot_meatal;
class new_CAUTI_LDA;
run;

data table16;
set table15;
if PLACEMENT_DATE =< meatal_change_date then delete;
if foleyday2<3 then delete;
if tot_meatal_denom<3 then delete;
if tot_CHG_denom<3 then delete;
run;

proc means data=table16;
var foleyday2 tot_chg tot_meatal;
class new_CAUTI_LDA;
run;

proc logistic data=table16;
class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")
Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0") ORDER_FOR_FOLEY3 (ref="0");
model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence 
tot_chg tot_meatal foleyday2 ORDER_FOR_FOLEY3;
run;

/*proc logistic data=table16;*/
/*class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")*/
/*Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0") chg_cat (ref="1") meatal_cat (ref="1");*/
/*model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence */
/*chg_cat meatal_cat foleyday2;*/
/*run;*/

proc logistic data=table16;
class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")
Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0") chg_cat (ref="1") ORDER_FOR_FOLEY3 (ref="0");
model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence 
chg_cat foleyday2 ORDER_FOR_FOLEY3;
run;


/*proc logistic data=table16;*/
/*class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")*/
/*Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0");*/
/*model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence */
/*tot_chg tot_meatal foleyday2;*/
/*run;*/

proc logistic data=table16;
class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")
Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0") ORDER_FOR_FOLEY3 (ref="0");
model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence 
tot_chg foleyday2 ORDER_FOR_FOLEY3;
run;


/*proc means data=table16;*/
/*var foleyday2 tot_chg tot_meatal;*/
/*class new_CAUTI_LDA;*/
/*run;*/


proc means data=table16;
var foleyday2 tot_chg;
class new_CAUTI_LDA;
run;

proc logistic data=table15;
class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")
Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0") ORDER_FOR_FOLEY3 (ref="0") Tot_Foley_UC_GT_24H_after_insert (ref="0");
model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence 
tot_chg tot_meatal foleyday2 ORDER_FOR_FOLEY3 Tot_Foley_UC_GT_24H_after_insert;
run;


data table17;
set table16;
if Tot_Foley_UC_GT_24H_after_insert >0 then Tot_Foley_UC_GT_24H_after_inser2=1;
else Tot_Foley_UC_GT_24H_after_inser2=0;
run;


proc logistic data=table17;
class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")
Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0") ORDER_FOR_FOLEY3 (ref="0") Tot_Foley_UC_GT_24H_after_inser2 (ref="0");
model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence 
tot_chg tot_meatal foleyday2 ORDER_FOR_FOLEY3 Tot_Foley_UC_GT_24H_after_inser2;
run;


proc logistic data=table17;
class gender(ref="0") DIABETES_ON_PROBLEM_LIST(ref="0") RENAL_INSUFFICIENY_ON_PROBLEM_LI(ref="0")
Bowel_Incontinence(ref="0") Urinary_Incontinence(ref="0") Tot_Foley_UC_GT_24H_after_inser2 (ref="0");
model new_CAUTI_LDA(event="1") = PAT_AGE gender  PAT_BMI DIABETES_ON_PROBLEM_LIST RENAL_INSUFFICIENY_ON_PROBLEM_LI Bowel_Incontinence Urinary_Incontinence 
tot_chg tot_meatal foleyday2 Tot_Foley_UC_GT_24H_after_inser2;
run;
