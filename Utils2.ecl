EXPORT Utils2 := MODULE

	EXPORT fillin_field_name_( pResult, pDS, pFields, pIdField, pNameField ) := MACRO
		pResult := JOIN( pDS, #EXPAND(#TEXT(pFields) + '_Map'), (STRING) LEFT.pIdField = RIGHT.assigned_name, TRANSFORM( RECORDOF( pDS ),
			SELF.pNameField := IF(RIGHT.orig_name != '', RIGHT.orig_name, LEFT.pNameField);
			SELF := LEFT;
		), LEFT OUTER);
	ENDMACRO;
	
	EXPORT BOOLEAN IsNumeric(STRING n) := BEGINC++
	  if ( lenN == 0 ) return false;
		bool periodFound = false;
		for (size_t i = 0; i < lenN; i++) {
			if ((i==0 && n[i] == '-') || (!periodFound && n[i] == '.') || isdigit(n[i])) {
			  if( n[i] == '.' ) periodFound = true;
				continue;
			} else {
				return false;
			}
		}
		return true;
	ENDC++;


END;