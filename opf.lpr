program opf;

{$mode objfpc}{$H+}

uses
  Interfaces, // this includes the LCL widgetset
  Forms
  { add your units here }, opfunit, resunit, Printer4Lazarus, pack_powerpdf,
		lnetvisual, aboutunit, loginunit, beamunit;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TOPFForm, OPFForm);
  Application.Run;
end.

