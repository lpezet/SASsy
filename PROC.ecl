EXPORT PROC := MODULE

	EXPORT SELECT( pOutDS, pInDS, pFields='' ) := MACRO
		LOADXML('<xml/>');
		//pOutDS := TABLE( pInDS; { #EXPAND(pFields); UNSIGNED frequency := COUNT(GROUP); DECIMAL4_2 percent := 0.0; UNSIGNED cumul_frequency := 0; DECIMAL4_2 cumul_percent := 0.0 }, #EXPAND(pFields) ) 
		#DECLARE(tablefieldslist) #SET(tablefieldslist,'')
		#DECLARE(tablefieldsgroup) #SET(tablefieldsgroup,'')
		#EXPORTXML(fields,RECORDOF(pInDS))
		#FOR(fields)
			#FOR(Field)
				#IF(REGEXFIND('\\s*,\\s*'+%'{@label}'%+',',','+pFields+',',NOCASE))
					#APPEND(tablefieldslist, %'{@label}'%)
					#APPEND(tablefieldslist, ';')
					#IF(%'tablefieldsgroup'%!='')
						#APPEND(tablefieldsgroup, ',')
					#END
					#APPEND(tablefieldsgroup, %'{@label}'%)
				#END
			#END
		#END
		pOutDS := TABLE( pInDS, { #EXPAND(%'tablefieldslist'%) } );
	ENDMACRO;
// 
	EXPORT PRINT( pInDS, pObs=100 ) := MACRO
		OUTPUT( CHOOSEN( pInDS, IF( pObs > 0, pObs, CHOOSEN:ALL)), NAMED('Print_' + pObs));
	ENDMACRO;

	EXPORT CONTENTS( pInDS ) := MACRO
	 
		#EXPORTXML( fields, RECORDOF( pInDS ) );
		#DECLARE( vars );
		#SET( vars, 0 );
		#FOR(fields)
		  #FOR(Field)
					#SET( vars, %vars% + 1);
				#END
		#END
		
		summary := TABLE( pInDS, { 
			UNSIGNED observations := COUNT(GROUP); 
			UNSIGNED variables := %vars%;
		} );
		OUTPUT( summary, NAMED('Contents_Summary') );
		//OUTPUT('Total vars:' + %'vars'%);
		
		var_layout := RECORD
			UNSIGNED pos{xpath('@position')};
			STRING variable{xpath('@name')};
			STRING type{xpath('@type')};
			STRING label{xpath('@label')};
		END;
		vars_layout := RECORD
			DATASET(var_layout) var{xpath('/Field')};
	 END;
		
		#DECLARE( fields2 );
		#EXPORT( fields2, RECORDOF( pInDS ) );
		rec := FROMXML(vars_layout, %'fields2'%);
		//OUTPUT(rec);
		OUTPUT(rec.var, NAMED('Contents_Variables'));
	ENDMACRO;
	
	EXPORT MEANS( pOutDS, pInDS, pFields = '' ) := MACRO
	IMPORT SASsy;
		LOADXML('<xml/>');
		//pOutDS := TABLE( pInDS; { #EXPAND(pFields); UNSIGNED frequency := COUNT(GROUP); DECIMAL4_2 percent := 0.0; UNSIGNED cumul_frequency := 0; DECIMAL4_2 cumul_percent := 0.0 }, #EXPAND(pFields) ) 
		#DECLARE(tablefieldslist) #SET(tablefieldslist,'')
		#DECLARE(tablefieldsgroup) #SET(tablefieldsgroup,'')
		#EXPORTXML(fields,RECORDOF(pInDS))
		pOutDS := MERGE(
		#FOR(fields)
			#FOR(Field)
				#IF(REGEXFIND('\\s*,\\s*'+%'{@label}'%+',',','+pFields+',',NOCASE))
					TABLE( pInDS( SASsy.Utils.IsNumeric((STRING) %{@label}%) ), { STRING100 variable := %'{@label}'%; UNSIGNED N := COUNT(GROUP); REAL8 mean := ROUND(AVE(GROUP, (REAL8) %{@label}%),5); REAL8 std_dev := ROUND(SQRT(VARIANCE(GROUP, (REAL8) %{@label}%)),5); REAL8 minimum := ROUND(MIN(GROUP, (REAL8) %{@label}%),5); REAL8 maximum := ROUND(MAX(GROUP, (REAL8) %{@label}%), 5); } ),
				#END
			#END
		#END
				SORTED(variable)
		);
	ENDMACRO;
	
	EXPORT FREQ( pOutDS, pInDS, pFields = '' ) := MACRO
		LOADXML('<xml/>');
		//pOutDS := TABLE( pInDS; { #EXPAND(pFields); UNSIGNED frequency := COUNT(GROUP); DECIMAL4_2 percent := 0.0; UNSIGNED cumul_frequency := 0; DECIMAL4_2 cumul_percent := 0.0 }, #EXPAND(pFields) ) 
		#DECLARE(tablefieldslist) #SET(tablefieldslist,'')
		#DECLARE(tablefieldsgroup) #SET(tablefieldsgroup,'')
		#EXPORTXML(fields,RECORDOF(pInDS))
		#FOR(fields)
			#FOR(Field)
				#IF(REGEXFIND('\\s*,\\s*'+%'{@label}'%+',',','+pFields+',',NOCASE))
					#APPEND(tablefieldslist, %'{@label}'%)
					#APPEND(tablefieldslist, ';')
					#IF(%'tablefieldsgroup'%!='')
						#APPEND(tablefieldsgroup, ',')
					#END
					#APPEND(tablefieldsgroup, %'{@label}'%)
				#END
			#END
		#END
		//OUTPUT( %'tablefieldslist'% );
		//OUTPUT( %'tablefieldsgroup'% );
		#UNIQUENAME(Summary)
		%Summary% := TABLE( pInDS, { #EXPAND(%'tablefieldslist'%) UNSIGNED frequency := COUNT(GROUP); DECIMAL5_2 percent := 100 * COUNT(GROUP) / COUNT(pInDS); UNSIGNED cumul_frequency := 0; DECIMAL5_2 cumul_percent := 0.0; }, #EXPAND(%'tablefieldsgroup'%) );
		pOutDS := ITERATE( %Summary%, TRANSFORM( RECORDOF( %Summary% ),
			SELF.cumul_frequency := LEFT.cumul_frequency + RIGHT.frequency;
			SELF.cumul_percent := LEFT.cumul_percent + RIGHT.percent;
			SELF := RIGHT;
		));
	ENDMACRO;
	
	EXPORT UNIVARIATE( pInDS, pFields = '' ) := MACRO
		IMPORT SASsy;
		LOADXML('<xml/>');
		#EXPORTXML(fields,RECORDOF(pInDS))
		//pOutDS := MERGE(
		#FOR(fields)
			#FOR(Field)
				#IF(REGEXFIND('\\s*,\\s*'+%'{@label}'%+',',','+pFields+',',NOCASE))
					SASsy.Utils.UnivariateSingleField( pInDS, %{@label}% );
					//TABLE( pInDS( $.Utils.isNumeric(%{@label}%) ), { STRING100 variable := %'{@label}'%; UNSIGNED N := COUNT(GROUP); REAL8 mean := AVE(GROUP, (REAL8) %{@label}%); REAL8 std_dev := SQRT(VARIANCE(GROUP, (REAL8) %{@label}%)); REAL8 minimum := MIN(GROUP, (REAL8) %{@label}%); REAL8 maximum := MAX(GROUP, (REAL8) %{@label}%); } ),
				#END
			#END
		#END
		//		SORTED(variable)
		//);
	ENDMACRO;
	/*
	EXPORT UNIVARIATE2( pInDS, pFields = '' ) := MACRO
		IMPORT $.^ AS SASsy;
		
		#DECLARE(TotalFields)
		#SET(TotalFields, 0)
		LOADXML('<xml/>');
		#EXPORTXML(fields,RECORDOF(pInDS))
		//pOutDS := MERGE(
		
		#UNIQUENAME(UniqName)
		#DECLARE(UniRes)
		#SET(UniRes, %'UniqName'%)
		
		#FOR(fields)
			#FOR(Field)
				#IF(REGEXFIND('\\s*,\\s*'+%'{@label}'%+',',','+pFields+',',NOCASE))
					//#APPEND(outStr, 'uni_' + wi + ' := SASsy.Utils.UnivariateSingleField2( pInDS, %{@label}% );
					#SET (TotalFields, %TotalFields% + 1)
					//OUTPUT( %'UniRes'% + %'TotalFields'% );
					#EXPAND(%'UniRes'% + %'TotalFields'% ) := SASsy.Utils.UnivariateSingleField2( pInDS, %{@label}% );
					//TABLE( pInDS( $.Utils.isNumeric(%{@label}%) ), { STRING100 variable := %'{@label}'%; UNSIGNED N := COUNT(GROUP); REAL8 mean := AVE(GROUP, (REAL8) %{@label}%); REAL8 std_dev := SQRT(VARIANCE(GROUP, (REAL8) %{@label}%)); REAL8 minimum := MIN(GROUP, (REAL8) %{@label}%); REAL8 maximum := MAX(GROUP, (REAL8) %{@label}%); } ),
				#END
			#END
		#END

		#UNIQUENAME(BasicsName)
		
		#UNIQUENAME(oQuartiles)
		#DECLARE(BasicsStr)
		#SET(BasicsStr, %'BasicsName'%)
		#APPEND(BasicsStr, ' := ');
		//#DECLARE(Quantiles)
		//#SET(Quantiles, %oQuartiles% + ' := ');
		
		#DECLARE (Ndx)
		#SET(Ndx, 0)
		#LOOP
			#IF(%Ndx% >= %TotalFields%)
				#BREAK
			#ELSE
				#SET (Ndx, %Ndx% + 1)
			#END
			
			#APPEND(BasicsStr, %'UniRes'% + %'Ndx'% + '.Basics');
			#IF(%Ndx% < %TotalFields%)
			  #APPEND(BasicsStr, ' + ');
			#END
   //Same for quantiles and so on
	 
		#END
		#APPEND(BasicsStr, ';');
		
		OUTPUT( %'BasicsStr'% );
		%BasicsStr%;
		//%Quartiles%;
		OUTPUT( %BasicsName%, NAMED('Basics'));
		
		
		//		SORTED(variable)
		//);
	ENDMACRO;
	*/


END;