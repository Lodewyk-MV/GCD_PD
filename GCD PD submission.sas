/*****************************************************************************************/
/** Original Version                                                             		 */
/*****************************************************************************************/
/*** Author(s)   : Capgemini														 */
/*** Program     : 		             		 	 						 				 */
/*** Description : User can change this script											 */
/*** Date        : 30/08/2016															 */
/*** Project     : GCD 		 										 			 		 */
/*****************************************************************************************/

/****************************************/
/* User can change these parameters 	*/
/****************************************/

/* BEGIN - DO NOT MODIFY THIS SECTION */
%global base_path Filepath filename;
/* END - DO NOT MODIFY THIS SECTION */

options NOERRORBYABEND;
/* BEGIN - USER PARAMETER SECTION */

/*Modify this path with the path where you Unzip the ODF desktop tools folder*/
%let base_path=C:\Users\VDVyverL\Documents\CIB Model Development\GCD\PD_ODF\;

/*Modify this path with the path where your input SAS dataset is located*/
%let Filepath=C:\Users\VDVyverL\Documents\CIB Model Development\GCD\PD_ODF;


/*Modify this parameter with name of your SAS input dataset*/
%let Filename=final_PD;

DM "log; clear; output ; clear; out ;clear; ODSRESULTS;CLEAR;";
%macro user_configuration;

	%let ODFMULTIYEAR_PDF=1; 				/* Set this option to 1 to generate ODF MultiYear Table in PDF */
	%let ODFMULTIYEAR_CSV=1; 				/* Set this option to 1 to generate ODF MultiYear Table in CSV */			 

	%let MIGRATION_PDF=0; 					/* Set this option to 1 to generate ODF Migration Matrix in PDF and nominal values */	
	%let MIGRATION_PERCENT_PDF=0; 			/* Set this option to 1 to generate ODF Migration Matrix in PDF and percentage values */	
	%let MIGRATION_CSV=0;					/* Set this option to 1 to generate ODF Migration Matrix in CSV */	

	%let MIGRATION_CAT_ALL=1;				/* Set this option to 1 to generate all type of Submission Matrix */	
	%let MIGRATION_CAT_QuarWtQuart=0;		/* Set this option to 1 to generate Quarterly with quaterly Step type of Submission Matrix */
	%let MIGRATION_CAT_YearWtSemiAnn=0;		/* Set this option to 1 to generate Rolling yearly with semi-annual steps type of Submission Matrix */
	%let MIGRATION_CAT_MultyYearWtYear=0;	/* Set this option to 1 to generate Multi-year with yearly steps type of Submission Matrix */
	%let MIGRATION_CAT_YearWeigthAvg=0;		/* Set this option to 1 to generate Yearly Weigthed Average type of Submission Matrix */

	
	%let EXPORT_Agg_FILES=1;				/* Set this oprtion to 1 to generate Aggregated Files to upload in GCD data portal */
	%let EXPORT_NonAgg_FILES=0;				/* Set this oprtion to 1 to generate Non Aggregated Files to upload in GCD data portal */
	/* End of choice */
	
%mend user_configuration;
/* END - USER PARAMETER SECTION */


/* BEGIN - DO NOT MODIFY THIS SECTION */
%global base_path_complete;
%let base_path_complete=&base_path.2.MACRO\*.SAS;
%put "&base_path_complete.";
%include "&base_path_complete.";

/* END - DO NOT MODIFY THIS SECTION */


%stp_delivery;
