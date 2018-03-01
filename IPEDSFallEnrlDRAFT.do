set more off
clear all
cls 

// Use this code to download, build, and save to the local computer
// data from the FALL ENROLLMENT survey at the US DOE's
// Integrated Postsecondary Education Data Stystem.
//***Add note: we will only worry about A and B for now, C will be for future 
//***development. 

// Mar/2018:     Adam Ross Nelson - Test Edit
// Feb/2018:     Naiya Patel - Original author, initial build.

/*#############################################################################

      File maintained at
	  https://github.com/adamrossnelson/StataIPEDSAll
  
##############################################################################*/

// Utilizes preckage version of sshnd (interactive file picker)/
// Stable 1.0 version of sshnd documentation available at:
// https://github.com/adamrossnelson/sshnd/tree/1.0

do https://raw.githubusercontent.com/adamrossnelson/sshnd/master/sshnd.do

capture log close                             // Close stray log files.
log using "$loggbl", append                   // Append sshnd established log file.
local sp char(13) char(10) char(13) char(10)  // Define spacer.
version 13                                    // Enforce version compatibility.
di c(pwd)                                     // Confrim working directory.

//Look is designed to download zip files and NCES provided Stata do files. 
//Stata do files need cleaning (removal of stray char(13) + char(10) + char(34)).

forvalues yindex = 2002 / 2016 {
	//Copy, unzip, and import data files. 
	copy https://nces.ed.gov/ipeds/datacenter/data/EF`yindex'A_Data_Stata.zip .
	unzipfile EF`yindex'A_Data_Stata.zip, replace
	
	//Download the NCES provided do file for A series 
	copy https://nces.ed.gov/ipeds/datacenter/data/EF`yindex'A_Stata.zip .
	unzipfile EF`yindex'A_Stata.zip, replace
	
	//Read do file into scalar for modification. 
	scalar fcontents = fileread("EF`yindex'A.do")
	
	//Remove default "insheet" command designed to import data. 
	//Remove defualt "save" command designed to save data.
	scalar fcontents = subinstr(fcontents, "insheet", "// insheet", 1)
	scalar fcontents = subinstr(fcontents, "save", "// save", .)
	
	//Remove unexpected carriage returns and line feeds. 
	scalar sstring = char(13) + char(10) + char(34)
	scalar fcontents = subinstr(fcontents, sstring, char(34), .)
	
	//Save, rename, and run the revised and working do file. 
    scalar fcontents = subinstr(fcontents, "label define label_line", "// label define label_line", .)
    scalar fcontents = subinstr(fcontents, "label values line label_line", "// label values line label_line", .)
	scalar byteswritten = filewrite("EF`yindex'a.do", fcontents, 1)

	 // File name conventions not consistent through the years.
    // 2007, 2008, 2010-2015 provide _rv_ editions of the data.
    if (`yindex' > 2006 & `yindex' < 2009) | (`yindex' > 2009 & `yindex' < 2016) {
        import delimited ef`yindex'a_rv_data_stata.csv, clear
	}
    else {
        import delimited ef`yindex'a_data_stata.csv, clear
	}
	
	di "QUIET RUN OF EF`yindex'a.do"          //Provides user with informaiton for log file
	qui do EF`yindex'a.do                     //Quietly run NCES provided do files. 
	drop x*                                   //Remove imputation variables. 
	di `sp'                                   //Spacing to assist reading output.

	if (`yindex' < 2008) {
		rename	efrace24 eftotlt              //Grand total
		rename  efrace15 eftotlm              //Grand total men
		rename	efrace16 eftotlw              //Grand toatl women
		rename	efrace19 efaiant              //American Indian or Alaska Native total
		rename	efrace05 efaianm              //American Indian or Alaska Native total men
		rename	efrace06 efaianw              //American Indian or Alaska Native total women
		rename	efrace20 efasiat              //Asian total
		rename	efrace07 efasiam              //Asian total men
		rename	efrace08 efasiaw              //Asian total women
		rename	efrace18 efbkaat              //Black or African American total
		rename	efrace03 efbkaam              //Black or African American total men
		rename	efrace04 efbkaaw              //Black or African American toatl women
		rename	efrace21 efhispt              //Hispanic total 
		rename	efrace09 efhispm              //Hispanic total men 
		rename	efrace10 efhispw              //Hispanic total women
		rename	efrace22 efwhitt              //White total
		rename	efrace11 efwhitm              //White total men
		rename	efrace12 efwhitw              //White total women
		rename	efrace23 efunknt              //Race/ethnicity unknown total
		rename	efrace13 efunknm              //Race/ethnicity unknonw total men
		rename	efrace14 efunknw              //Race/ethnicity unknown total women
		rename	efrace17 efnralt              //Nonresident alien total
		rename	efrace01 efnralm              //Nonresident alien total men
		rename	efrace02 efnralw              //Nonresident alien total women
		gen ef2mort = .                       // Two or more races total
		gen ef2morm = .                       // Two or more races men
		gen ef2morw = .                       // Two or more races women
		gen efnhpit = .                       // Native Hawaiian or Other Pacific Islander total
		gen efnhpim = .                       // Native Hawaiian or Other Pacific Islander men
		gen efnhpiw = .                       // Native Hawaiian or Other Pacific Islander women

}


// Before reshape, must save variable names 
// 
// Reshape will remove variable names, therefore, must save variable labels 
// before 


foreach varname unitid efalevel ///
	eftotlt eftotlm eftotlw efaiant efaianm efaianw efasiat efasiam ///
	efasiaw efbkaat efbkaam efbkaaw efhispt efhispm efhispw efnhpit efnhpit efnhpim efnhpiw ///
	efnhpim efnhpit ef2mort ef2morm ef2morw efwhitt efwhitm efwhitw ef2mort ef2morm ef2morw ///
	efunknt efunknm efunknw efnralt efnralm efnralw 
	{
	local l`varname' " variable label `varname' 
	
}

	

	//Reshape

	keep unitid efalevel ///
	eftotlt eftotlm eftotlw efaiant efaianm efaianw efasiat efasiam ///
	efasiaw efbkaat efbkaam efbkaaw efhispt efhispm efhispw efnhpit efnhpit efnhpim efnhpiw ///
	efnhpim efnhpit ef2mort ef2morm ef2morw efwhitt efwhitm efwhitw ef2mort ef2morm ef2morw ///
	efunknt efunknm efunknw efnralt efnralm efnralw

	keep if efalevel == 1 | efalevel == 2 | efalevel == 11 | efalevel == 12 |   ///
		    efalevel == 21 | efalevel == 22 | efalevel == 32 | efalevel == 41 | ///
		    efalevel == 42 | efalevel == 52                                     
	
	//keep if efalevel == 1, 2, 11, 12, 21, 22, 32, 41, 42, 52
	
	reshape wide ///
	eftotlt eftotlm eftotlw efaiant efaianm efaianw efasiat efasiam ///
	efasiaw efbkaat efbkaam efbkaaw efhispt efhispm efhispw efnhpit ///
	efnhpim efnhpiw efwhitt efwhitm efwhitw ef2mort ef2morm ef2morw ///
	efunknt efunknm efunknw efnralt efnralm efnralw, i(unitid) j(efalevel) 
	
	
 di "lefnralw'"
	
	foreach lev in 1 2 11 12 21 22 32 41 42 52{
		foreach varname in unitid efalevel ///
	eftotlt eftotlm eftotlw efaiant efaianm efaianw efasiat efasiam ///
	efasiaw efbkaat efbkaam efbkaaw efhispt efhispm efhispw efnhpit efnhpit efnhpim efnhpiw ///
	efnhpim efnhpit ef2mort ef2morm ef2morw efwhitt efwhitm efwhitw ef2mort ef2morm ef2morw ///
	efunknt efunknm efunknw efnralt efnralm efnralw {
		label varialbe `varname'`lev' "`lev' `l`varname''"  */
		}
	}
	

	//Add isYr index and order new variable. 
	gen int isYr = `yindex'
	order isYr, after (unitid)
	
	saveold "ef`yindex'a_data_stata.dta", version(13) replace   // Save cleaned data file.
		di `sp'	                                                // Spacer for the output.
}

use ef2016a_data_stata.dta, clear
forvalues yindex = 2015(-1)2002 {
	display "`yindex'"                                          // Output for log file.
	append using "ef`yindex'a_data_stata.dta", force
	di `sp'                                                     // Spacing for log file.
}  
cd ..
compress

label data "PanelBuildInfo: https://github.com/adamrossnelson/StataIPEDSAll/tree/master"
notes _dta: "PanelBuildInfo: https://github.com/adamrossnelson/StataIPEDSAll/tree/master"
notes _dta: "Panel built on `c(current_date)'"
saveold "$dtagbl", replace version(13)


//Beginning of B Series

cd "$wkdgbl"                                            // Change back to working directory.
forvalues yindex = 2002 / 2016 {
	//Copy, unzip, and import data files.
	copy https://nces.ed.gov/ipeds/datacenter/data/EF`yindex'B_Data_Stata.zip .
	unzipfile EF`yindex'B_Data_Stata.zip
	import delimited EF`yindex'B_Data_Stata.csv, clear
	//Add isYr index and order new variable. 
	//gen int isYr = `yindex'
	//order isYr, after (unitid)

	//Download the NCES provided do file for B series 
	copy https://nces.ed.gov/ipeds/datacenter/data/EF`yindex'B_Stata.zip .
	unzipfile EF`yindex'B_Stata.zip, replace 

	//Read do file into scalar for modification. 
	scalar fcontents = fileread("EF`yindex'B.do")
	
	//Remove default "insheet" command designed to import data. 
	//Remove default "save" command designed to save data. 
	scalar fcontents = subinstr(fcontents, "insheet", "// insheet", 1)
	scalar fcontents = subinstr(fcontents, "save", "// save", .)
	
	//Remove unexpected carriage returns and line feeds. 
	scalar sstring = char(13) + char(10) + char(34)
	scalar fcontents = subinstr(fcontents, sstring, char(34), .)
	
	//Save, rename, and run the revised and working do file. 
	scalar byteswritten = filewrite("EF`yindex'b.do", fcontents, 1)
	
	 // File name convetions not consistent through the years.
    // 2007-2015 provide _rv_ editions of the data.
    //
    if `yindex' > 2006 & `yindex' < 2016 {
        import delimited ef`yindex'b_rv_data_stata.csv, clear
	}
    else {
        import delimited ef`yindex'b_data_stata.csv, clear
	}
	
	
	di "QUIET RUN OF EF`yindex'b.do" 
	qui do EF`yindex'b
	di `sp'

	
	
	compress 
	saveold EF`yindex'B_data_stata.dta, replace version (13)
	di `sp'
	clear
}
	

use ef2016b_data_stata.dta, clear 
forvalues yindex = 2015(-1)2002 {
	display "`yindex'"                                        // Output for log file.
	append using "ef`yindex'b_data_stata.dta", force
	di `sp'	                                                  // Spacing for log file.
}
cd ..
compress

label data "PanelBuildInfo: https://github.com/adamrossnelson/StataIPEDSAll/tree/master"
notes _dta: "PanelBuildInfo: https://github.com/adamrossnelson/StataIPEDSAll/tree/master"
notes _dta: "Panel built on `c(current_date)'"
saveold "$dtagbl", replace version(13)

qui { 
noi di "#####################################################################"
noi di ""
noi di "      Saved $dtagbl"
noi di ""
noi di "######################################################################"
}
log close
