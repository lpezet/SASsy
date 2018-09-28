EXPORT Utils := MODULE

	EXPORT reg_report_on_all( pOLS, pRegression, pFields ) := MACRO
		IMPORT SASsy;
		
		SASsy.Utils.reg_report_on_parameters( pOLS, pRegression, pFields );
		SASsy.Utils.reg_report_on_variance( pOLS, pFields );
		SASsy.Utils.reg_report_on_misc( pOLS, pFields );
	
	ENDMACRO;

	EXPORT reg_report_on_parameters( pOLS, pRegression, pFields ) := MACRO
		IMPORT SASsy;
		#UNIQUENAME(parameter_estimate_layout)
		%parameter_estimate_layout% := RECORD
			UNSIGNED id;
			UNSIGNED variable_id;
			STRING variable_name := '';
			UNSIGNED df := 1;
			REAL8 parameter_estimate := 0.0;
			REAL8 standard_error := 0.0;
			REAL8 t_value := 0.0;
			STRING p_value := '';
		END;
		//AND LEFT.number = RIGHT.number
		#UNIQUENAME(ParameterEstimates_0)
		%ParameterEstimates_0% := JOIN( pOLS.Betas(), pOLS.SE, LEFT.id = RIGHT.id, TRANSFORM( %parameter_estimate_layout%,
			SELF.id := LEFT.id;
			SELF.variable_name := IF(LEFT.id = 1, 'Intercept', '');
			SELF.variable_id := LEFT.id - 1;
			SELF.parameter_estimate := ROUND(LEFT.value,5);
			SELF.standard_error := ROUND(RIGHT.value,5);
		), LEFT OUTER );
		//AND LEFT.variable_id = RIGHT.number
		#UNIQUENAME(ParameterEstimates_1)
		%ParameterEstimates_1% := JOIN( %ParameterEstimates_0%, pOLS.TStat, LEFT.id = RIGHT.id, TRANSFORM( %parameter_estimate_layout%,
			SELF.t_value := ROUND(RIGHT.value,5);
			SELF := LEFT;
		), LEFT OUTER );
		#UNIQUENAME(ParameterEstimates_2)
		%ParameterEstimates_2% := JOIN( %ParameterEstimates_1%, pOLS.pVal, LEFT.id = RIGHT.id, TRANSFORM( %parameter_estimate_layout%,
			SELF.p_value := IF(RIGHT.value < 0.0001, '<0.0001', '' + ROUND(RIGHT.value,4));
			SELF := LEFT;
		), LEFT OUTER );
		#UNIQUENAME(ParameterEstimates)
		SASsy.Utils2.fillin_field_name_( %ParameterEstimates%, %ParameterEstimates_2%, pFields, variable_id, variable_name );
		OUTPUT(%ParameterEstimates%, NAMED(%'ParameterEstimates'%) );
	ENDMACRO;


	EXPORT reg_report_on_variance( pRegression, pFields ) := MACRO
		#UNIQUENAME(anova_layout)
		%anova_layout% := RECORD
			STRING source;
			UNSIGNED df := 1;
			STRING sum_of_squares;
			STRING mean_square;
			STRING f_value;
		END;
		#UNIQUENAME(tx_anova)
		%anova_layout% %tx_anova%( RECORDOF( pRegression.Anova ) pRecord, INTEGER pVar ) := TRANSFORM
			SELF.source := CASE( pVar, 1 => 'Model', 2 => 'Error', 3 => 'Corrected Total', '' );
			SELF.df := CASE( pVar, 1 => pRecord.model_df, 2 => pRecord.error_df, 3 => pRecord.total_df, 0 );
			SELF.sum_of_squares := CASE( pVar, 1 => '' + ROUND(pRecord.model_ss, 5), 2 => '' + ROUND(pRecord.error_ss, 5), 3 => '' + ROUND(pRecord.total_ss, 5), '' );
			SELF.mean_square := CASE( pVar, 1 => '' + ROUND(pRecord.model_ms, 5), 2 => '' + ROUND(pRecord.error_ms, 5), '' );
			SELF.f_value := CASE( pVar, 1 => '' + ROUND(pRegression.FTest[1].model_f, 5 ), '');
		END;
		#UNIQUENAME(Anovar)
		%Anovar% := NORMALIZE( pRegression.Anova, 3, %tx_anova%(LEFT, COUNTER) );
		OUTPUT( %Anovar%, NAMED(%'Anovar'%) );
	ENDMACRO;


	EXPORT reg_report_on_misc( pRegression, pFields ) := MACRO
		#UNIQUENAME(misc_layout)
		%misc_layout% := RECORD
			//UNSIGNED variable_id;
			//STRING variable_name := '';
			STRING name;
			STRING value;
		END;
		#UNIQUENAME(Misc_0)
		%Misc_0% := PROJECT( pRegression.RSquared, TRANSFORM( %misc_layout%,
			//SELF.variable_id := LEFT.number - 1;
			SELF.name := 'R-Sq';
			SELF.value := '' + ROUND(LEFT.rsquared, 5);
		));
		#UNIQUENAME(Misc_1)
		%Misc_1% := PROJECT( pRegression.AdjRSquared, TRANSFORM( %misc_layout%,
			//SELF.variable_id := LEFT.number - 1;
			SELF.name := 'Adj R-Sq';
			SELF.value := '' + ROUND(LEFT.rsquared, 5);
		));
		#UNIQUENAME(Misc_2)
		%Misc_2% := PROJECT( pRegression.AIC, TRANSFORM( %misc_layout%,
			//SELF.variable_id := LEFT.number - 1;
			SELF.name := 'AIC';
			SELF.value := '' + ROUND(LEFT.aic, 5);
		));
		#UNIQUENAME(Misc)
		%Misc% := %Misc_0% + %Misc_1% + %Misc_2%;
		//fillin_field_name_( Misc, Misc_2, pFields, variable_id, variable_name );
		OUTPUT( %Misc%, NAMED(%'Misc'%) );

	ENDMACRO;

 EXPORT tableData( pDS, pFields='') := FUNCTIONMACRO
		RETURN TABLE( pDS, { #EXPAND(REGEXREPLACE('\\,', pFields, ';') + ';') } );
 ENDMACRO;
 

 EXPORT BOOLEAN IsNumeric(STRING n) := FUNCTION
		IMPORT SASsy;
		RETURN SASsy.Utils2.IsNumeric( n );
 END;
	
	EXPORT UnivariateSingleField( pDS, pField ) := FUNCTIONMACRO
	 IMPORT SASsy;
		#UNIQUENAME(oDSVals)
		%oDSVals% :=  pDS( SASsy.Utils2.IsNumeric((STRING) pField) );
		#UNIQUENAME(d)
		%d% := RECORD
			REAL8 value;
			UNSIGNED pos := 0;
		END;
		#UNIQUENAME(oNumericValues)
		%oNumericValues% := PROJECT( %oDSVals%, TRANSFORM( %d%,
			SELF.value := (TYPEOF(%d%.value)) LEFT.pField;
		));
		#UNIQUENAME(oRankedValues)
		%oRankedValues%:= PROJECT( SORT( %oNumericValues%, value ), TRANSFORM( %d%,
			SELF.pos := COUNTER;
			SELF := LEFT;
		));
		#UNIQUENAME(oMedianPos)
		SET OF UNSIGNED %oMedianPos% := IF(MAX(%oRankedValues%,pos)%2=0,[(MAX(%oRankedValues%,pos))/2,(MAX(%oRankedValues%,pos))/2+1],[(MAX(%oRankedValues%,pos)/2)+1]);
		#UNIQUENAME(oMedianValues)
		%oMedianValues% := %oRankedValues%( pos IN %oMedianPos% );
		#UNIQUENAME(oMedian)
		%oMedian% := IF(COUNT(%oMedianValues%)=1,MIN(%oMedianValues%,value),SUM(%oMedianValues%,value)/2);
		#UNIQUENAME(oBasics)
		%oBasics% := TABLE( %oRankedValues%, {
			STRING variable := #TEXT(pField);
			UNSIGNED N 			:= COUNT(GROUP);
			TYPEOF(%d%.value) minval  	:= MIN(GROUP, value );
			TYPEOF(%d%.value) maxval  	:= MAX(GROUP, value);
			TYPEOF(%d%.value) sumval  	:= SUM(GROUP, value);
			TYPEOF(%d%.value) mean    	:= ROUND(AVE(GROUP, value),5);
			TYPEOF(%d%.value) median			:= %oMedian%;
			TYPEOF(%d%.value) var     	:= ROUND(VARIANCE(GROUP, value), 5);
			TYPEOF(%d%.value) sd      	:= ROUND(SQRT(VARIANCE(GROUP, value)), 5);
			TYPEOF(%d%.value) sd_err 		:= ROUND(SQRT(VARIANCE(GROUP, value)) / SQRT(COUNT(GROUP)), 5);
			TYPEOF(%d%.value) coef_var	:= ROUND(SQRT(VARIANCE(GROUP, value)) / AVE(GROUP, value) * 100, 5);
			TYPEOF(%d%.value) range			:= MAX(GROUP, value) - MIN(GROUP, value );
		});
		// TODO: Mode, Interquartile range
		//OUTPUT( %oBasics%, NAMED(#TEXT(pField) + '_Basics') );
		
		// Quantiles
		#UNIQUENAME(oQtile0)
		%oQtile0% := TABLE( %oRankedValues%, { %oRankedValues%; INTEGER4 ntile := 100*(pos/COUNT(%oDSVals%)); } );
		#UNIQUENAME(oQtile1)
		%oQtile1% := %oQtile0%( ntile IN [ 100,99,95,90,75,50,25,10,5,1,0 ] );
		#UNIQUENAME(oQtile2)
		%oQtile2% := TABLE( %oQtile1%, { ntile; TYPEOF(%d%.value) value := MIN(GROUP, value); }, ntile );
		#UNIQUENAME(oQtile3)
		%oQtile3% := SORT( %oQtile2%, -ntile );
		#UNIQUENAME(oQtile4)
		%oQtile4% := TABLE( %oQtile3%, { STRING quantile := ntile + '%' + CASE(ntile, 100 => ' Max', 75 => ' Q3', 50 => ' Median', 25 => ' Q1', 0 => ' Min', ''); TYPEOF(%d%.value) estimate := value; } );
		//OUTPUT( %oQtile4%, NAMED(#TEXT(pField) + '_Quantiles') );
		
		//OUTPUT( CHOOSEN(%oRankedValues%,5), NAMED(#TEXT(pField) + '_ExtremeLowest') );
		//OUTPUT( CHOOSEN(SORT(%oRankedValues%, -pos),5), NAMED(#TEXT(pField) + '_ExtremeHighest') );
		
		#UNIQUENAME(oMissingValues0)
		%oMissingValues0% := pDS( NOT SASsy.Utils2.IsNumeric((STRING) pField) );
		#UNIQUENAME(oMissingValues1)
		%oMissingValues1% := TABLE( %oMissingValues0%, { STRING value := pField; UNSIGNED count := COUNT(GROUP); REAL8 perc_all_obs := 100 * COUNT(GROUP) / COUNT( pDS ); REAL8 perc_missing := 100 * COUNT(GROUP) / COUNT( %oMissingValues0% ); }, pField );
		//OUTPUT( %oMissingValues1%, NAMED(#TEXT(pField) + '_MissingValues') );
		RETURN SEQUENTIAL(
			OUTPUT( %oBasics%, NAMED(#TEXT(pField) + '_Basics') ),
			OUTPUT( %oQtile4%, NAMED(#TEXT(pField) + '_Quantiles') ),
			OUTPUT( CHOOSEN(%oRankedValues%,5), NAMED(#TEXT(pField) + '_ExtremeLowest') ),
			OUTPUT( CHOOSEN(SORT(%oRankedValues%, -pos),5), NAMED(#TEXT(pField) + '_ExtremeHighest') ),
			OUTPUT( %oMissingValues1%, NAMED(#TEXT(pField) + '_MissingValues') )
		);
	
	ENDMACRO;
	/*
	EXPORT UnivariateSingleField2( pDS, pField ) := FUNCTIONMACRO
	 IMPORT $.^ AS SASsy;
		#UNIQUENAME(oDSVals)
		%oDSVals% :=  pDS( SASsy.Utils.IsNumeric((STRING) pField) );
		#UNIQUENAME(d)
		%d% := RECORD
			REAL8 value;
			UNSIGNED pos := 0;
		END;
		#UNIQUENAME(oNumericValues)
		%oNumericValues% := PROJECT( %oDSVals%, TRANSFORM( %d%,
			SELF.value := (TYPEOF(%d%.value)) LEFT.pField;
		));
		#UNIQUENAME(oRankedValues)
		%oRankedValues%:= PROJECT( SORT( %oNumericValues%, value ), TRANSFORM( %d%,
			SELF.pos := COUNTER;
			SELF := LEFT;
		));
		#UNIQUENAME(oMedianPos)
		SET OF UNSIGNED %oMedianPos% := IF(MAX(%oRankedValues%,pos)%2=0,[(MAX(%oRankedValues%,pos))/2,(MAX(%oRankedValues%,pos))/2+1],[(MAX(%oRankedValues%,pos)/2)+1]);
		#UNIQUENAME(oMedianValues)
		%oMedianValues% := %oRankedValues%( pos IN %oMedianPos% );
		#UNIQUENAME(oMedian)
		%oMedian% := IF(COUNT(%oMedianValues%)=1,MIN(%oMedianValues%,value),SUM(%oMedianValues%,value)/2);
		#UNIQUENAME(oBasics)
		%oBasics% := TABLE( %oRankedValues%, {
			STRING variable := #TEXT(pField);
			UNSIGNED N 			:= COUNT(GROUP);
			TYPEOF(%d%.value) minval  	:= MIN(GROUP, value );
			TYPEOF(%d%.value) maxval  	:= MAX(GROUP, value);
			TYPEOF(%d%.value) sumval  	:= SUM(GROUP, value);
			TYPEOF(%d%.value) mean    	:= AVE(GROUP, value);
			TYPEOF(%d%.value) median			:= %oMedian%;
			TYPEOF(%d%.value) var     	:= VARIANCE(GROUP, value);
			TYPEOF(%d%.value) sd      	:= SQRT(VARIANCE(GROUP, value));
			TYPEOF(%d%.value) sd_err 		:= SQRT(VARIANCE(GROUP, value)) / SQRT(COUNT(GROUP));
			TYPEOF(%d%.value) coef_var	:= SQRT(VARIANCE(GROUP, value)) / AVE(GROUP, value) * 100;
			TYPEOF(%d%.value) range			:= MAX(GROUP, value) - MIN(GROUP, value );
		});
		// TODO: Mode, Interquartile range
		//OUTPUT( %oBasics%, NAMED(#TEXT(pField) + '_Basics') );
		
		// Quantiles
		#UNIQUENAME(oQtile0)
		%oQtile0% := TABLE( %oRankedValues%, { %oRankedValues%; INTEGER4 ntile := 100*(pos/COUNT(%oDSVals%)); } );
		#UNIQUENAME(oQtile1)
		%oQtile1% := %oQtile0%( ntile IN [ 100,99,95,90,75,50,25,10,5,1,0 ] );
		#UNIQUENAME(oQtile2)
		%oQtile2% := TABLE( %oQtile1%, { ntile; TYPEOF(%d%.value) value := MIN(GROUP, value); }, ntile );
		#UNIQUENAME(oQtile3)
		%oQtile3% := SORT( %oQtile2%, -ntile );
		#UNIQUENAME(oQtile4)
		%oQtile4% := TABLE( %oQtile3%, { STRING quantile := ntile + '%' + CASE(ntile, 100 => ' Max', 75 => ' Q3', 50 => ' Median', 25 => ' Q1', 0 => ' Min', ''); TYPEOF(%d%.value) estimate := value; } );
		//OUTPUT( %oQtile4%, NAMED(#TEXT(pField) + '_Quantiles') );
		
		//OUTPUT( CHOOSEN(%oRankedValues%,5), NAMED(#TEXT(pField) + '_ExtremeLowest') );
		//OUTPUT( CHOOSEN(SORT(%oRankedValues%, -pos),5), NAMED(#TEXT(pField) + '_ExtremeHighest') );
		
		#UNIQUENAME(oMissingValues0)
		%oMissingValues0% := pDS( NOT SASsy.Utils.IsNumeric((STRING) pField) );
		#UNIQUENAME(oMissingValues1)
		%oMissingValues1% := TABLE( %oMissingValues0%, { STRING value := pField; UNSIGNED count := COUNT(GROUP); REAL8 perc_all_obs := 100 * COUNT(GROUP) / COUNT( pDS ); REAL8 perc_missing := 100 * COUNT(GROUP) / COUNT( %oMissingValues0% ); }, pField );
		//OUTPUT( %oMissingValues1%, NAMED(#TEXT(pField) + '_MissingValues') );
		RETURN MODULE
			EXPORT Basics := %oBasics%;
			EXPORT Quantiles := %oQtile4%;
			EXPORT ExtremeLow := CHOOSEN(%oRankedValues%,5);
			EXPORT ExtremeHigh := CHOOSEN(SORT(%oRankedValues%, -pos),5);
			EXPORT MissingValues := %oMissingValues1%;
		END;
	ENDMACRO;
 */

END;