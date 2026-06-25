* Encoding: GBK.
*===============================================================.
* Table S2: Baseline and week 4 on Neuroimaging Outcome Measures.
* Long-format dataset.
*
* Original group coding:
*   1 = Scalp-Based Measurement group.
*   2 = Functional Connectivity-Guided group.
*
* To match the table order, create group_tbl:
*   1 = Functional Connectivity-Guided group.
*   2 = Scalp-Based Measurement group.
*
* Outputs needed:
*   1. Raw mean (SD) at baseline and week 4.
*   2. Group-by-time interaction F and P.
*   3. Week 4 least squares mean difference (95% CI) and P.
*===============================================================.

SET PRINTBACK=ON MPRINT=ON.

GET FILE='/Users/yuejuan/Documents/Neuromodulation/RCTManu/clinical/ANA_Latest44_longformat.sav'.
DATASET NAME longfm WINDOW=FRONT.

*-------------------------.
* 0. Labels and variable settings.
*-------------------------.
VALUE LABELS group
  1 'Scalp-Based Measurement group'
  2 'Functional Connectivity-Guided group'.

VALUE LABELS Time
  1 'Baseline'
  2 'week 4'.

VALUE LABELS gender
  0 'female'
  1 'male'.

COMPUTE group_tbl = 3 - group.
VARIABLE LABELS group_tbl 'Table order for Table S2'.
VALUE LABELS group_tbl
  1 'Functional Connectivity-Guided group'
  2 'Scalp-Based Measurement group'.

VARIABLE LEVEL group_tbl gender Time (NOMINAL).
VARIABLE LEVEL age duration FC ALFF_sti ALFF_LGPi (SCALE).
EXECUTE.

*-------------------------.
* 1. Basic checks.
*-------------------------.
FREQUENCIES VARIABLES=group group_tbl Time gender.
DESCRIPTIVES VARIABLES=age duration FC ALFF_sti ALFF_LGPi.

*===============================================================.
* 2. Raw mean (SD).
* group_tbl = 1: Functional Connectivity-Guided group.
* group_tbl = 2: Scalp-Based Measurement group.
* Time = 1: Baseline.
* Time = 2: week 4.
*===============================================================.
MEANS TABLES=FC ALFF_sti ALFF_LGPi BY group_tbl BY Time
 /CELLS MEAN STDDEV COUNT.

*===============================================================.
* 3. Linear mixed model macro.
*
* Important:
* - group_tbl, gender, Time are categorical variables in BY.
* - age and duration are continuous covariates in WITH.
*
* For Table S2:
* A. Group-by-time interaction:
*    Use row group_tbl*Time in Type III Tests of Fixed Effects.
*
* B. Least Squares Mean Difference (95% CI):
*    Use Pairwise Comparisons at Time = week 4, I=1, J=2.
*    Because group_tbl=1 is FC-guided and group_tbl=2 is Scalp-based,
*    Mean Difference (I-J) = FC-guided minus Scalp-based.
*===============================================================.
DEFINE !LMM (Y=!TOKENS(1))

MIXED !Y BY group_tbl gender Time
  WITH age duration
  /CRITERIA = CIN(95) MXITER(100) MXSTEP(20) SCORING(1)
              SINGULAR(0.000000000001)
              HCONVERGE(0, ABSOLUTE)
              LCONVERGE(0, ABSOLUTE)
              PCONVERGE(0.000001, ABSOLUTE)
  /FIXED = age duration gender group_tbl Time group_tbl*Time | SSTYPE(3)
  /METHOD = REML
  /RANDOM = INTERCEPT | SUBJECT(id) COVTYPE(VC)
  /REPEATED = Time | SUBJECT(id) COVTYPE(UN)
  /PRINT = SOLUTION TESTCOV
  /EMMEANS = TABLES(group_tbl*Time) COMPARE(group_tbl) ADJ(LSD)
  /EMMEANS = TABLES(group_tbl*Time) COMPARE(Time) ADJ(LSD)
.

!ENDDEFINE.

*-------------------------.
* 4. Run the three outcomes in Table S2.
*-------------------------.
!LMM Y=FC.
!LMM Y=ALFF_sti.
!LMM Y=ALFF_LGPi.

*-------------------------.
* 5. Optional: add ReHo outcomes if needed.
*-------------------------.
* !LMM Y=ReHo_LGPi.
* !LMM Y=ReHo_Sti.

*===============================================================.
* 6. How to fill Table S2.
*
* Raw mean (SD):
*   Take from the MEANS output.
*
* Group-by-time interaction:
*   Take F and Sig. from row group_tbl*Time in
*   Type III Tests of Fixed Effects.
*   Use the actual numerator and denominator df from output.
*
* Least Squares Mean Difference (95% CI):
*   Take from Pairwise Comparisons at Time=week 4, I group_tbl=1,
*   J group_tbl=2.
*
* P value:
*   Use the Sig. from that same week 4 pairwise comparison.
*===============================================================.
