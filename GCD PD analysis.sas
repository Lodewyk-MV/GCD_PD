/* Run on server */

/* Extract the utilisation and limit data from the Adaptiv tables on the SQL server */

data Adaptiv_util_limit (keep=cif_id businessdate Sum_TodaysLimitAmount_ZAR Sum_TodaysValue_ZAR rating_month_year); 
	set CIBGRDS.'usage.vAdaptiv_Summary_ZAR'n;
		rating_month = month(businessdate);
		rating_year = year(businessdate);
		if rating_month < 10 then rating_month_year = cats(rating_year,0,rating_month);
		else rating_month_year = cats(rating_year,rating_month);
		rename cifid = cif_id; 
run;

/* Extract the rating information from the CRS tables on the SQL server */

data CRS_history_counterparty (keep='cif id'n ratingdate 'Model Used'n 'Industry ISIC'n 'Industry Description'n 'Country ISO'n 'Country name'n 'MG: Local PD'n 'MG: Local RG'n model_local_pd); 
	set CIBGRDS.'dbo.CRS_Counterparty'n;
	format model_local_pd 9.6;
	model_local_pd = 1*'MG: Local PD'n/100;
run;

data CRS_other_v3; 
	set CIBGRDS.'RCC.CRSOtherModelLookup'n;
run;

proc sort data=CRS_history_counterparty;
	by 'cif id'n;
run;

proc sort data=CRS_other_v3;
	by counterparty_id;
run;

data CRS_history_counterparty;
	merge CRS_history_counterparty (in = a) CRS_other_v3 (in=b rename=(counterparty_id = 'cif id'n));
	if a;
	by 'cif id'n;
run;

data CRS_history_transaction (keep= sap_facility_id transaction_name rating_date 'Model Name'n model_pd model_rg rg_model); 
	set CIBGRDS.'dbo.CRS_Transaction'n;
run;

/* Extract the ACBC facility numbers for Specialised Lending (Real Estate) from the CapMan table on the SQL server */

data Transaction_obligorid (keep= obligorid obligorname ACBSfacility); 
	set CIBGRDS.'RCC.CapMan'n;
	ACBSfacility = substr(accountrefcd,13,9);
run;

/*data a185874.Real_Estate_cifs;*/
/*	set ACBC_LOAN_BOOK_END_DECEMBER_2016;*/
/*run;*/
/* Needs to update this file */


/* Obtain the ACBC facility number from the ACBC loan file to merge back to RCC */

proc sort data=Transaction_obligorid;
	by ACBSfacility;
run;

proc sort data=a185874.Real_Estate_cifs;
	by Obligation_Number;
run;

data Transaction_obligorid;
	merge Transaction_obligorid (in=a) a185874.Real_Estate_cifs (in=b keep = Obligation_Number Loan_Product_Dimension_Facility_ rename=(Obligation_Number = ACBSfacility)) ;
	by ACBSfacility;
	if a=b;
run;


/* Merge data back to CRS based on the SAP Facility file */

proc sort data=Transaction_obligorid;
	by Loan_Product_Dimension_Facility_;
run;

proc sort data=CRS_history_transaction;
	by sap_facility_id;
run;

data CRS_history_transaction;
	merge CRS_history_transaction (in=a) Transaction_obligorid (in=b keep= obligorid obligorname Loan_Product_Dimension_Facility_ ACBSfacility rename=(Loan_Product_Dimension_Facility_ = sap_facility_id)) ;
	by sap_facility_id;
	if a=b;
	industry_description = "Real_Estate";
	country_name = "South Africa";
	country_iso = 'ZA';
	format model_local_pd 9.6;
	model_local_pd = 1*model_pd/100;
run;


/* Append the CRS data for the counterparties and transactions */

data CRS_history;
	set CRS_history_counterparty (rename=('cif id'n = CIF_ID ratingdate = rating_date 'Model Used'n = Model 'Industry ISIC'n = Industry_ISIC 'Industry Description'n = industry_description 'country iso'n = country_iso 'Country name'n = country_name))
		CRS_history_transaction (rename=(obligorid = CIF_ID 'Model Name'n = Model));
			rating_date2 = datepart(rating_date);
			rating_month = month(rating_date2);
			rating_year = year(rating_date2);
			if rating_month < 10 then rating_month_year = cats(rating_year,0,rating_month);
			else rating_month_year = cats(rating_year,rating_month);
run;


/* Merge the CRS data to the Adpativ data */

proc sort data=Adaptiv_util_limit;	
	by cif_id rating_month_year;
run;

proc sort data=CRS_history;	
	by CIF_ID rating_month_year;
run;

data performing;
	merge Adaptiv_util_limit (in=a) CRS_history (in=b);
	by CIF_ID rating_month_year;
	if a=b;
run;

proc sort data=performing nodupkey;
	by CIF_ID rating_month_year;
run;


/* Source the default information from the default database tables on the SQL server */

data default_history_client (keep= clientid clientname); 
	set CIBDFDBA.'dbo.SB_MOW_Clients'n;
run;

data default_history_client_cif (keep= client_id cp_id); 
	set CIBDFDBA.'dbo.SB_MOW_ids'n;
run;

data default_history_event (keep=clientid_num DefaultDate DefaultReason rating_month_year dafaultdate2); 
	set CIBDFDBA.'dbo.SB_MOW_DefaultEvent'n;
	format clientid_num 11.0;
	clientid_num = 1*clientid;
	dafaultdate2 = datepart(DefaultDate);
	rating_month = month(dafaultdate2);
	rating_year = year(dafaultdate2);
	if rating_month < 10 then rating_month_year = cats(rating_year,0,rating_month);
	else rating_month_year = cats(rating_year,rating_month);
	where DefaultDate >= "1Jan2013"d;
run;

proc sort data = default_history_client;
	by clientid;
run;

proc sort data = default_history_event;
	by clientid_num;
run;

proc sort data = default_history_client_cif;
	by client_id;
run;

data npl;
	merge default_history_client (in=a) default_history_event (in=b rename=(clientid_num=clientid)) default_history_client_cif (in=c rename=(client_id = clientid));
	by clientid;
	if b;
run;

/* Manual correction */
data npl;
	set npl;
	if clientid = 23225 then CP_ID = "506797543";
run;

proc sort data=performing;
	by cif_id;
run;

proc sort data=npl;
	by CP_ID;
run;

data final;
	merge performing (in=a) npl (in=b rename=(CP_ID = cif_id));
	by cif_id;
	if a;
run;



/* In-between steps */

proc sort data=final out=Facility_Asset_Class_test nodupkey;
	by model;
run;

data other_model;
	set final;
	where model contains "Other" and industry_description contains "BANK";
run;


proc sort data=a185874.GCD_Primary_Industry_lkup;
	by industry_description;
run;

proc sort data=final;
	by industry_description;
run;

data final;
	merge final (in=a) a185874.GCD_Primary_Industry_lkup (in=b drop=Industry_ISIC);
	by industry_description;
	if a;
run;

data final;
	set final;
	format rating_date_num 6.0;
	rating_date_num = 1*rating_month_year;
run;

proc sort data=final;
	by rating_date_num;
run;

data Adaptiv_parent_child (keep=UltimateParentCIFID childcifid cif_id);
	set CIBGRDS.'adaptiv.UltimateParentChild'n;
	format cif_id $11.; 
	cif_id = childcifid;
run;

proc sort data=Adaptiv_parent_child;
	by cif_id;
run;

proc sort data=final;
	by cif_id;
run;

data final;
	merge final (in=a) Adaptiv_parent_child (in=b);
	by cif_id;
	if a;
run;

/*data A185874.GCD_NATURE_OF_DEFAULT;*/
/*	set GCD_NATURE_OF_DEFAULT;*/
/*run;*/


proc sort data=A185874.GCD_NATURE_OF_DEFAULT;
	by defaultreason;
run;

proc sort data=final;
	by defaultreason;
run;

data final;
	merge final (in=a) A185874.GCD_NATURE_OF_DEFAULT (in=b);
	by defaultreason;
	if a;
run;


/* Populate and create according to GCD specifications */

data final2;
	set final;
	format Lender_ID 3.0 Facility_Asset_Class 3.0 Sovereign_Type 2.0 Country_Of_Residence $char2. Bank_Or_Financial_Company 3.0
		   Rating $char10. Reporting_date MMDDYY10. Reporting_date2 DDMMYY10. Reporting_default_date MMDDYY10. default_date MMDDYY10. 
		   default_date2 DDMMYY10. TTC_PD comma10.8 PIT_PD comma10.8 Borrower_ID $char20. Group_Company_ID $char20. Loan_Currency $char4. 
		   Defaulted_Previous_Period $char1. Lender_Limit comma14.3 Lender_Outstanding_Amount comma14.3;
	informat Lender_ID 3.0 Facility_Asset_Class 3.0 Sovereign_Type 2.0 Country_Of_Residence $char2. Bank_Or_Financial_Company 3.0
		   Rating $char10. Reporting_date MMDDYY10. Reporting_date2 DDMMYY10. Reporting_default_date MMDDYY10. default_date MMDDYY10. 
		   default_date2 DDMMYY10. TTC_PD comma10.8 PIT_PD comma10.8 Borrower_ID $char20. Group_Company_ID $char20. Loan_Currency $char4. 
		   Defaulted_Previous_Period $char1. Lender_Limit comma14.3 Lender_Outstanding_Amount comma14.3;

	Lender_ID = 764;
	if  find(model, "Corporate") then Facility_Asset_Class = 2; 
	else if model in ("Asset Manager v2", "Bank v4", "Broker Dealer", "Hedge Fund v2", "Long Term Insurance v1"
					  "Pension Fund v2", "Regulated Funds v1", "Short Term Insurance v1") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(short_description, "Insurance") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(industry_description, "BANK") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(industry_description, "ASSET MANAGERS") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(industry_description, "FINANCIAL") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(industry_description, "INSURANCE") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(industry_description, "FUND") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(industry_description, "INVESTMENT TRUSTS") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(industry_description, "NON LIFE ASSURANCE") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(industry_description, "SECURITIES DEALERS") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(industry_description, "SECURITY DEALING ACTIVITIES") then Facility_Asset_Class = 3;
	else if find(model, "Other") and find(industry_description, "TRUST") then Facility_Asset_Class = 3;
	else if model in ("Developer Model", "Investor Cashflow Model", "Investor Scorecard Model") then Facility_Asset_Class = 6;
	else if find(model, "Other") and find(industry_description, "PROPERTY") then Facility_Asset_Class = 6;
	else if find(model, "Other") and find(industry_description, "REAL EST") then Facility_Asset_Class = 6;
	else if find(model, "Other") and find(industry_description, "REAL ESTATE") then Facility_Asset_Class = 6;
	else if find(model, "Other") and find(short_description, "Project Finance") then Facility_Asset_Class = 7;
	else if find(model, "Sovereign") then Facility_Asset_Class = 9;
	else if model in ("Central Government", "Local Government", "Provincial Government") then Facility_Asset_Class = 9;
	else if find(model, "Other") and find(industry_description, "GOVERNMENT") then Facility_Asset_Class = 9;
	else if find(model, "Other") and find(industry_description, "FOREIGN AFFAIRS") then Facility_Asset_Class = 10;
	else if find(model, "Other") and find(industry_description, "HIGHER EDUCATION") then Facility_Asset_Class = 10;
	else if find(model, "Other") then Facility_Asset_Class = 2;

	if Facility_Asset_Class = 9 and find(model, "Sovereign") then Sovereign_Type = 6;
	else if Facility_Asset_Class = 9 and model in ("Local Government", "Provincial Government") then Sovereign_Type = 10;
	else if Facility_Asset_Class and find(model, "Other") and find(industry_description, "GOVERNMENT") then Sovereign_Type = 10;
	else if Facility_Asset_Class = 9 and model in ("Central Government") then Facility_Asset_Class = 11;

	if country_iso = "S1" then Country_Of_Residence = "-1";
	else if country_iso = "MWI" then Country_Of_Residence = "MW";
	else if country_iso = "ZMB" then Country_Of_Residence = "ZM";
	else if country_iso = "COD" then Country_Of_Residence = "CD";
	else Country_Of_Residence = country_iso;

	if Facility_Asset_Class = 3 and find(industry_description, "UNIVERSAL BANKS") then Bank_Or_Financial_Company = 1;


	else if Facility_Asset_Class = 3 and industry_description in ("BANK HOLDING COMPANIES", "BANKS", "COLLATERALISED DEBT OBLIGATIONS",
			"FACTORING/FINANCE/DISCOUNT HOUSES", "MULTILATERAL DEVELOPMENT BANKS", "COMMERCIAL/RETAIL/SAVINGS,LOAN BANKS") then Bank_Or_Financial_Company = 3;
	else if Facility_Asset_Class = 3 and find(industry_description, "BANK") then Bank_Or_Financial_Company = 3;
	else if Facility_Asset_Class = 3 and industry_description in ("INDIVIDUAL CREDIT CARD ADVANCES") then Bank_Or_Financial_Company = 6;
	else if Facility_Asset_Class = 3 and industry_description in ("MORTGAGE , HOUSING CREDIT CORPORATIONS", "PROPERTY DEVELOPMENT AND INVESTMENT",
			"REAL ESTATE ACTIVITIES", "REAL ESTATE INVESTMENT TRUSTS") then Bank_Or_Financial_Company = 7;
	else if Facility_Asset_Class = 3 and industry_description in ("GOVERNMENT", "GOVERNMENT CREDIT INSTITITUTIONS") then Bank_Or_Financial_Company = 8;
	else if Facility_Asset_Class = 3 and industry_description in ("INVESTMENT/MERCHANT BANKS", "UNIT TRUSTS", "INVESTMENT TRUSTS") then Bank_Or_Financial_Company = 10;
	else if Facility_Asset_Class = 3 and industry_description in ("HEDGE FUNDS") then Bank_Or_Financial_Company = 1;
	else if Facility_Asset_Class = 3 and industry_description in ("PENSION FUNDING", "PLACED BY FUND MANAGERS") then Bank_Or_Financial_Company = 12;
	else if Facility_Asset_Class = 3 and find(industry_description, "ASSET MANAGERS") then Bank_Or_Financial_Company = 14;
	else if Facility_Asset_Class = 3 and industry_description in ("FIN INTRMDTION ACTVTIES,EXCPT INSURANCE", "FINANCIAL INTERMEDIATION",
			"FINANCIAL INTERMEDIATION,EXCPT INSURANCE", "FINANCIAL LEASING", "NON BANK CREDIT INSTITUTIONS", "OTHER CREDIT GRANTING",
			"OTHER FINANCIAL INTERMEDIARIES", "OTHER FINANCIAL INTERMEDIATION", "OTHER FINANCIAL INTERMEDIATION N.E.C.",
			"ACTVTIES AUXILIARY TO FIN INTERMEDIATION", "EXTRACT OF CRUDE PETROLEUM" , "NATURL GAS", "BUSINESS, MANAGEMT CONSULTANCY ACTVTIES",
			"MEDICAL AID", "LONG TERM ASSET BACKED VEHICLE", "MONEY MARKET MUTUAL FUNDS", "OTHER BUSINESS ACTIVITIES"
			"PRIVATE EQUITY FUNDS") then Bank_Or_Financial_Company = 15;
	else if Facility_Asset_Class = 3 and find(industry_description, "FINANCIAL") then Bank_Or_Financial_Company = 15;
	else if Facility_Asset_Class = 3 and industry_description in ("NON LIFE ASSURANCE", "INSURANCE, PENSION FUNDING", "LIFE INSURANCE",
			"REINSURANCE") then Bank_Or_Financial_Company = 17;
	else if Facility_Asset_Class = 3 and find(industry_description, "UNIVERSAL INSURANCE") then Bank_Or_Financial_Company = 17;
	else if Facility_Asset_Class = 3 and find(industry_description, "INSURANCE") then Bank_Or_Financial_Company = 17;
	else if Facility_Asset_Class = 3 and industry_description in ("SECURITIES DEALERS", "SECURITY DEALING ACTIVITIES") then Bank_Or_Financial_Company = 19;
/*	else if Facility_Asset_Class = 3 then Bank_Or_Financial_Company = 15;*/

		 if model_local_pd <= 0.012/100 then Rating = "AAA";
	else if model_local_pd <= 0.017/100 then Rating = "AA+";
	else if model_local_pd <= 0.024/100 then Rating = "AA";
	else if model_local_pd <= 0.034/100 then Rating = "AA-";
	else if model_local_pd <= 0.067/100 then Rating = "A+";
	else if model_local_pd <= 0.095/100 then Rating = "A";
	else if model_local_pd <= 0.135/100 then Rating = "A-";
	else if model_local_pd <= 0.269/100 then Rating = "BBB+";
	else if model_local_pd <= 0.381/100 then Rating = "BBB";
	else if model_local_pd <= 0.538/100 then Rating = "BBB-";
	else if model_local_pd <= 1.076/100 then Rating = "BB+";
	else if model_local_pd <= 1.522/100 then Rating = "BB";
	else if model_local_pd <= 2.153/100 then Rating = "BB-";
	else if model_local_pd <= 4.305/100 then Rating = "B+";
	else if model_local_pd <= 6.089/100 then Rating = "B";
	else if model_local_pd <= 8.611/100 then Rating = "B-";
	else if model_local_pd <= 12.177/100 then Rating = "CCC+";
	else if model_local_pd <= 17.222/100 then Rating = "CCC";
	else if model_local_pd <= 24.355/100 then Rating = "CCC-";
	else if model_local_pd <= 34.443/100 then Rating = "CC";
	else if model_local_pd <= 99.999/100 then Rating = "C";
	else if model_local_pd = 100/100 then Rating = "D";

	if businessdate <= "31Mar13"d then Reporting_date = "31Mar13"d;
	else if businessdate <= "30Jun13"d then Reporting_date = "30Jun13"d;
	else if businessdate <= "30Sep13"d then Reporting_date = "30Sep13"d;
	else if businessdate <= "31Dec13"d then Reporting_date = "31Dec13"d;
	else if businessdate <= "31Mar14"d then Reporting_date = "31Mar14"d;
	else if businessdate <= "30Jun14"d then Reporting_date = "30Jun14"d;
	else if businessdate <= "30Sep14"d then Reporting_date = "30Sep14"d;
	else if businessdate <= "31Dec14"d then Reporting_date = "31Dec14"d;
	else if businessdate <= "31Mar15"d then Reporting_date = "31Mar15"d;
	else if businessdate <= "30Jun15"d then Reporting_date = "30Jun15"d;
	else if businessdate <= "30Sep15"d then Reporting_date = "30Sep15"d;
	else if businessdate <= "31Dec15"d then Reporting_date = "31Dec15"d;
	else if businessdate <= "31Mar16"d then Reporting_date = "31Mar16"d;
	else if businessdate <= "30Jun16"d then Reporting_date = "30Jun16"d;
	else if businessdate <= "30Sep16"d then Reporting_date = "30Sep16"d;
	else if businessdate <= "31Dec16"d then Reporting_date = "31Dec16"d;
	else if businessdate <= "31Mar17"d then Reporting_date = "31Mar17"d;
	else if businessdate <= "30Jun17"d then Reporting_date = "30Jun17"d;
	else if businessdate <= "30Sep17"d then Reporting_date = "30Sep17"d;
	else if businessdate <= "31Dec17"d then Reporting_date = "31Dec17"d;

		 if datepart(defaultdate) = . then Reporting_default_date = .;
	else if datepart(defaultdate) <= "31Mar13"d then Reporting_default_date = "31Mar13"d;
	else if datepart(defaultdate) <= "30Jun13"d then Reporting_default_date = "30Jun13"d;
	else if datepart(defaultdate) <= "30Sep13"d then Reporting_default_date = "30Sep13"d;
	else if datepart(defaultdate) <= "31Dec13"d then Reporting_default_date = "31Dec13"d;
	else if datepart(defaultdate) <= "31Mar14"d then Reporting_default_date = "31Mar14"d;
	else if datepart(defaultdate) <= "30Jun14"d then Reporting_default_date = "30Jun14"d;
	else if datepart(defaultdate) <= "30Sep14"d then Reporting_default_date = "30Sep14"d;
	else if datepart(defaultdate) <= "31Dec14"d then Reporting_default_date = "31Dec14"d;
	else if datepart(defaultdate) <= "31Mar15"d then Reporting_default_date = "31Mar15"d;
	else if datepart(defaultdate) <= "30Jun15"d then Reporting_default_date = "30Jun15"d;
	else if datepart(defaultdate) <= "30Sep15"d then Reporting_default_date = "30Sep15"d;
	else if datepart(defaultdate) <= "31Dec15"d then Reporting_default_date = "31Dec15"d;
	else if datepart(defaultdate) <= "31Mar16"d then Reporting_default_date = "31Mar16"d;
	else if datepart(defaultdate) <= "30Jun16"d then Reporting_default_date = "30Jun16"d;
	else if datepart(defaultdate) <= "30Sep16"d then Reporting_default_date = "30Sep16"d;
	else if datepart(defaultdate) <= "31Dec16"d then Reporting_default_date = "31Dec16"d;
	else if datepart(defaultdate) <= "31Mar17"d then Reporting_default_date = "31Mar17"d;
	else if datepart(defaultdate) <= "30Jun17"d then Reporting_default_date = "30Jun17"d;
	else if datepart(defaultdate) <= "30Sep17"d then Reporting_default_date = "30Sep17"d;
	else if datepart(defaultdate) <= "31Dec17"d then Reporting_default_date = "31Dec17"d;

	default_date = datepart(defaultdate);
	Borrower_ID = cif_id;

	Reporting_date2 = Reporting_date;
	default_date2 = default_date;

	if defaultdate ne . and Reporting_default_date > Reporting_date and Rating = "D" then delete; /* Default occured after the specific reporting date */

	if Reporting_default_date > Reporting_date then default_date = . ;
	if Reporting_default_date > Reporting_date then DefaultReason = .;

	if defaultdate ne . and Reporting_default_date < Reporting_date and Rating = "D" then delete; /* Default occured after the specific reporting date */

	if Reporting_default_date < Reporting_date then default_date = . ;
	if Reporting_default_date < Reporting_date then DefaultReason = .;

	if rating = "D" and default_date = . then delete;


	Loan_Currency = "ZAR";
	TTC_PD = 1*model_local_pd;
	Group_Company_ID = UltimateParentCIFID;

	Lender_Limit = Sum_TodaysLimitAmount_ZAR;
	Lender_Outstanding_Amount = Sum_TodaysValue_ZAR;
	if Sum_TodaysLimitAmount_ZAR = . then Lender_Limit = Sum_TodaysValue_ZAR + 1;
	else if Sum_TodaysValue_ZAR = . then Lender_Outstanding_Amount = Sum_TodaysLimitAmount_ZAR - 1;
	else if Sum_TodaysValue_ZAR >= Sum_TodaysLimitAmount_ZAR then Lender_Limit = Sum_TodaysValue_ZAR + 1;

	PIT_PD = .;
	Defaulted_Previous_Period = "";
	if default_date ne . then rating = "D";
	if default_date = . then Nature_Of_Default = .;
	if default_date ne . then TTC_PD = 1;

run;

data test;
	set final2;
	where cif_id = "504953218";
run;

proc sort data=final2;	
	by Borrower_ID descending BusinessDate;
run;

proc sort data=final2 nodupkey;
	by Borrower_ID Reporting_Date;
run;

/* Copy from Work on Server to Work on Local */

/* Run on local */
libname diners "C:\Users\VDVyverL\Documents\CIB Model Development\GCD\PD_ODF";

/*data diners.final;*/
/*	set final;*/
/*run;*/
/**/
/*data diners.final2;*/
/*	set final2;*/
/*run;*/
proc sort data = diners.final2;
	by Borrower_ID rating_date;
run;

data diners.Step1 (keep =  Country_Of_Residence Rating Reporting_date default_date Defaulted_Previous_Period TTC_PD PIT_PD Borrower_ID Group_Company_ID Loan_Currency Lender_Outstanding_Amount Lender_Limit Bank_Or_Financial_Company2 Facility_Asset_Class2 Lender_ID2 NATURE_OF_DEFAULT2 Primary_Industry_Code2 Sovereign_Type2 count);
	set diners.final2;
	LENGTH Bank_Or_Financial_Company2 3. Facility_Asset_Class2 3. Lender_ID2 3. NATURE_OF_DEFAULT2 3. Primary_Industry_Code2 3. Sovereign_Type2 3.;
	format Bank_Or_Financial_Company2 3.0 Facility_Asset_Class2 3.0 Lender_ID2 3.0 NATURE_OF_DEFAULT2 3.0 Primary_Industry_Code2 3.0 Sovereign_Type2 2.0;
	informat Bank_Or_Financial_Company2 3.0 Facility_Asset_Class2 3.0 Lender_ID2 3.0 NATURE_OF_DEFAULT2 3.0 Primary_Industry_Code2 3.0 Sovereign_Type2 2.0;
	Bank_Or_Financial_Company2 = Bank_Or_Financial_Company;
	Facility_Asset_Class2 = Facility_Asset_Class;
	Lender_ID2 = Lender_ID;
	NATURE_OF_DEFAULT2 = NATURE_OF_DEFAULT;
	Primary_Industry_Code2 = Primary_Industry_Code;
	Sovereign_Type2 = Sovereign_Type;
	by Borrower_ID;
	retain count;
	if first.Borrower_ID then count=0;
	count+1;
run;

data diners.Step2; 	
	set diners.Step1;
	rename Bank_Or_Financial_Company2 = Bank_Or_Financial_Company
		   Facility_Asset_Class2 = Facility_Asset_Class
		   Lender_ID2 = Lender_ID
		   Primary_Industry_Code2 = Primary_Industry_Code
		   Sovereign_Type2 = Sovereign_Type
		   NATURE_OF_DEFAULT2 = NATURE_OF_DEFAULT;
	where reporting_date <= today() and default_date <= today();
	Lender_Limit = min(Lender_Limit, 99999999999.99);
	Lender_Outstanding_Amount = min(Lender_Outstanding_Amount, 99999999999.99);
	if default_date ne . then TTC_PD = 1;
	if count = 1 and rating ="D" then delete;
run; 

data diners.Step2a; 	
	set diners.Step2;
	by Borrower_ID;
	retain count2;
	if first.Borrower_ID then count2=0;
	count2+1;
	if count2 = 1 and rating ="D" then delete;
run;


proc sort data = diners.Step2a;
	by borrower_id descending Reporting_date; 
run;

data diners.Step3 (drop=Primary_Industry_Code Country_Of_Residence Facility_Asset_Class Bank_Or_Financial_Company Sovereign_Type count count2);
	set diners.Step2a;
	length New_Primary_Industry_Code 3. New_Country_Of_Residence $2. New_Facility_Asset_Class 3. New_Bank_Or_Financial_Company 3. New_Sovereign_Type 3.;
	format New_Primary_Industry_Code 3.0 New_Country_Of_Residence $char2. New_Facility_Asset_Class 3.0 New_Bank_Or_Financial_Company 3.0 New_Sovereign_Type 2.0;
	informat New_Primary_Industry_Code 3.0 New_Country_Of_Residence $char2. New_Facility_Asset_Class 3.0 New_Bank_Or_Financial_Company 3.0 New_Sovereign_Type 2.0;
    retain New_Primary_Industry_Code New_Country_Of_Residence New_Facility_Asset_Class New_Bank_Or_Financial_Company New_Sovereign_Type; 
    by borrower_id;
    if first.borrower_id
  	then New_Primary_Industry_Code = Primary_Industry_Code;
	if first.borrower_id
  	then New_Country_Of_Residence = Country_Of_Residence;
	if first.borrower_id
  	then New_Facility_Asset_Class = Facility_Asset_Class;
	if first.borrower_id
  	then New_Bank_Or_Financial_Company = Bank_Or_Financial_Company;
	if first.borrower_id
  	then New_Sovereign_Type = Sovereign_Type;
run;

data diners.final_PD; 
	retain Lender_ID New_Facility_Asset_Class New_Sovereign_Type New_Country_Of_Residence New_Primary_Industry_Code New_Bank_Or_Financial_Company Rating Reporting_date default_date Nature_Of_Default Defaulted_Previous_Period TTC_PD PIT_PD Borrower_ID Group_Company_ID Loan_Currency Lender_Outstanding_Amount Lender_Limit;
	set diners.Step3;
	rename New_Primary_Industry_Code = Primary_Industry_Code
		   New_Country_Of_Residence = Country_Of_Residence
		   New_Facility_Asset_Class = Facility_Asset_Class
		   New_Bank_Or_Financial_Company = Bank_Or_Financial_Company
		   New_Sovereign_Type = Sovereign_Type;
run;

data test;
	set diners.step3;
	where Borrower_ID = "100061076";
run;
