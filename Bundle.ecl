IMPORT Std;

EXPORT Bundle := MODULE(Std.BundleBase)
  EXPORT Name := 'SASsy';
  EXPORT Description := 'Bundle providing SAS-like procedures.';
  EXPORT Authors := ['LP'];
  EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
  EXPORT Copyright := 'Copyright (C) 2018 Luke Pezet';
  EXPORT DependsOn := [];
  EXPORT Version := '1.0.0';
	EXPORT Properties := DICTIONARY( [{ 'Category' => 'Test' } ], Std.BundleBase.PropertyRecord);
  EXPORT PlatformVersion := '6.2.0';
END;
