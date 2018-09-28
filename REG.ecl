

EXPORT REG := MODULE

	EXPORT linear( pDS, pIndVars='', pDepVars='' ) := MACRO
		IMPORT $.^ AS SASsy;
		IMPORT ML_Core;
		IMPORT LinearRegression;
		
		#UNIQUENAME(exlayout)
		%exlayout% := RECORD( RECORDOF(pDS) )
			UNSIGNED __id__;
		END;
		
		#UNIQUENAME(exdata)
		%exdata% := PROJECT( pDS, TRANSFORM(%exlayout%, SELF.__id__ := COUNTER; SELF := LEFT));
		
		#UNIQUENAME(indvars)
		%indvars% := pIndVars + ',__id__';
		#UNIQUENAME(depvars)
		%depvars% := pDepVars + ',__id__';
		
		#UNIQUENAME(inddata)
	 //%inddata% := SASsy.Utils.tableData( %exdata%, %indvars% );
		%inddata% := TABLE( %exdata%, { #EXPAND(REGEXREPLACE('\\,', %indvars%, ';') + ';') } );
		
		#UNIQUENAME(depdata)
		%depdata% := TABLE( %exdata%, { #EXPAND(REGEXREPLACE('\\,', %depvars%, ';') + ';') } );
		
		#UNIQUENAME(inddataNF)
		#UNIQUENAME(depdataNF)
		ML_Core.ToField( %inddata%, %inddataNF%, __id__ );
		ML_Core.ToField( %depdata%, %depdataNF%, __id__ );
		
		#UNIQUENAME(ols)
		%ols% := LinearRegression.OLS( %inddataNF%, %depdataNF% );
	 #UNIQUENAME(model)
	 %model% := %ols%.GetModel;
		SASsy.Utils.reg_report_on_parameters( %ols%, %model%, %inddataNF% );
		SASsy.Utils.reg_report_on_variance( %ols%, %inddataNF% );
		SASsy.Utils.reg_report_on_misc( %ols%, %inddataNF% );
		
	ENDMACRO;

END;