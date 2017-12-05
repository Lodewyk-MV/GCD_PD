/*LDAP authentication for GRDS SQL Database*/
%let usern = SCMBNT1\VDVyverL;

proc pwencode in='password to be changed';
run;
/*Run above code, look at your log file and take the password generated from above code and put it in the %let passw =*/
%let passw = {SAS002}3F1C821E475D635D259B3E9343499B9E;
		     


/*Run the following code, this will give you access to the GRDS SQL server and the GRDS data. You must have access to the GRDS SQL Server and the schemas on GRDS. Michael or Maria can assist with access.*/

Libname CIBDFDBA      SQLSVR datasrc="CreditDefaultdatabase"      schema= "CreditDefaultdatabase" user="&usern" password="&passw"   dbindex=yes;
Libname CIBCRS        SQLSVR datasrc="CRS"                       schema= "CRS"                            user="&usern" password="&passw"   dbindex=yes;
Libname SICBC         SQLSVR datasrc="CRSICBC"                   schema= "CRSICBC"                  user="&usern" password="&passw"   dbindex=yes;
Libname CRSLib        SQLSVR datasrc="CRSLib"                    schema= "CRSLib"                   user="&usern" password="&passw"   dbindex=yes;
Libname CIBFitch      SQLSVR datasrc="Fitch"                           schema= "Fitch"                    user="&usern" password="&passw"   dbindex=yes;
Libname CIBGCD        SQLSVR datasrc="GCD"                       schema= "DBO"                            user="&usern" password="&passw"   dbindex=yes;
Libname CIBGRDS       SQLSVR datasrc="GlobalRiskDS"              schema= "GlobalRiskDS"             user="&usern" password="&passw"   dbindex=yes;
Libname GRDSICB       SQLSVR datasrc="GlobalRiskDSICBC"          schema= "GlobalRiskDSICBC"         user="&usern" password="&passw"   dbindex=yes;
Libname GRDSLIB       SQLSVR datasrc="GlobalRiskDSLib"           schema= "GlobalRiskDSLib"          user="&usern" password="&passw"   dbindex=yes;
Libname CIBLBA        SQLSVR datasrc="LBA"                       schema= "LBA"                            user="&usern" password="&passw"   dbindex=yes;
/*Libname LGDOVER SQLSVR datasrc="LGD_Overrides"             schema= "LGD_Overrides"       user="&usern" password="&passw"   dbindex=yes;*/
Libname LGDOVERP      SQLSVR datasrc="LGD_Overrides_PROD"   schema= "LGD_Overrides_PROD" user="&usern" password="&passw"   dbindex=yes;
Libname CIBMDS        SQLSVR datasrc="MDS"                       schema= "MDS"                            user="&usern" password="&passw"   dbindex=yes;
Libname CIBMODEV      SQLSVR datasrc="ModelDev"                  schema= "ModelDev"                      user="&usern" password="&passw"   dbindex=yes;
/*Libname CIBMMON SQLSVR datasrc="ModelMonitoring"           schema= "ModelMonitoring"          user="&usern" password="&passw"   dbindex=yes;*/
Libname CIBMOODY      SQLSVR datasrc="Moodys"                    schema= "Moodys"                   user="&usern" password="&passw"   dbindex=yes;
Libname CIBPROAR      SQLSVR datasrc="PropertyArchive"           schema= "PropertyArchive"          user="&usern" password="&passw"   dbindex=yes;
Libname SNPCAPIQ      SQLSVR datasrc="SnPCapitalIQ"              schema= "SnPCapitalIQ"             user="&usern" password="&passw"   dbindex=yes;
Libname SPREDPAC      SQLSVR datasrc="Spreadpac"                 schema= "Spreadpac"                user="&usern" password="&passw"   dbindex=yes;
Libname CIBSTAGE      SQLSVR datasrc="Stage"                           schema= "Stage"                    user="&usern" password="&passw"   dbindex=yes;
Libname SANDP         SQLSVR datasrc="StandardNPoors"       schema= "StandardNPoors"           user="&usern" password="&passw"   dbindex=yes;
Libname XPRFECON      SQLSVR datasrc="XpressFeedControl"         schema= "XpressFeedControl"   user="&usern" password="&passw"   dbindex=yes;

