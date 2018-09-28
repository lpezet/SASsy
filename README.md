*SASsy*
=======

SASsy is an ECL Bundle to help SAS users transition to ECL. It provides a simplified version of SAS functions (e.g. PROC) and tries to match SAS format for outputs.


Installation
============

To install, use the `ecl-bundle` command line interface.

```
ecl-bundle install https://github.com/lpezet/SASsy.git
```

Usage
=====

Once installed, you merely IMPORT the library or one of its submodules, then call any methods as appropriate.

For example:
```
IMPORT SASsy.PROC;

ds := DATASET([ {693.0, 16.0, 67.0, 76.0},
				{570.0, 15.0, 92.0, 79.0},
				{546.0, 17.0, 97.0, 68.0},
				{571.0, 20.0, 90.0, 87.0},
				{478.0, 18.0, 89.0, 87.0},
				{737.0, 21.0, 29.0, 96.0},
				{536.0, 21.0, 71.0, 100.0},
				{523.0, 19.0, 69.0, 71.0},
				{655.0, 20.0, 65.0, 100.0},
				{523.0, 19.0, 74.0, 87.0},
				{521.0, 19.0, 74.0, 94.0},
				{709.0, 17.0, 18.0, 96.0},
				{505.0, 19.0, 75.0, 94.0},
				{762.0, 20.0, 18.0, 100.0},
				{722.0, 20.0, 11.0, 95.0},
				{603.0, 19.0, 71.0, 88.0},
				{657.0, 19.0, 67.0, 100.0},
				{705.0, 17.0, 46.0, 96.0},
				{754.0, 20.0, 25.0, 100.0},
				{490.0, 23.0, 71.0, 65.0},
				{698.0, 19.0, 44.0, 100.0}
			],{REAL8 perf, REAL8 class_size, REAL8 perc_free_meals, REAL8 full_creds});

PROC.CONTENTS( ds );
```

PROC function
=============

1. *SELECT( pOutDS, pInDS, pFields='' )*

Example:
```
PROC.SELECT( mealsFull, ds, 'perc_free_meals,full_creds');
OUTPUT( mealsFull, NAMED('MealsAndFull'));
```

2. *PRINT( pInDS, pObs=100 )*

Example:
```
PROC.PRINT( ds, 10 );
```


3. *CONTENTS( pInDS )*

Example:
```
PROC.CONTENTS( ds );
```

4. *MEANS( pOutDS, pInDS, pFields = '' )*

Example:
```
PROC.MEANS( means, ds, 'year');
OUTPUT( means, NAMED('Means'));
```


5. *FREQ( pOutDS, pInDS, pFields = '' )*

Example:
```
PROC.FREQ( freq, ds, 'class_size');
OUTPUT( freq, NAMED('Freq') );
```

6. *UNIVARIATE( pInDS, pFields = '' )*

Example:
```
PROC.UNIVARIATE( ds, 'perc_free_meals');

```

Misc
====

1. *SASsy.Utils.reg_report_on_all( pOLS, pRegressionModel, pFields )*

This provide similar outputs from SAS `REG` function. You will need to use HPCC Systems Machine Learning ECL Bundle (`ML_Core`).

Example:
```
IMPORT SASsy;
IMPORT ML_Core;
IMPORT LinearRegression;

pIndVars := 'class_size,perc_free_meals,full_creds';
pDepVars := 'perf';

exlayout := RECORD( RECORDOF(ds) )
	UNSIGNED __id__;
END;
exdata := PROJECT( ds, TRANSFORM(exlayout, SELF.__id__ := COUNTER; SELF := LEFT));

indvars := pIndVars + ',__id__';
depvars := pDepVars + ',__id__';

inddata := TABLE( exdata, { #EXPAND(REGEXREPLACE('\\,', indvars, ';') + ';') } );
depdata := TABLE( exdata, { #EXPAND(REGEXREPLACE('\\,', depvars, ';') + ';') } );

ML_Core.ToField( inddata, inddataNF, __id__ );
ML_Core.ToField( depdata, depdataNF, __id__ );

ols := LinearRegression.OLS( inddataNF, depdataNF );
model := ols.GetModel;
SASsy.Utils.reg_report_on_all( ols, model, inddataNF );
```