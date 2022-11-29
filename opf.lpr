program opf;
{.DEFINE DEBUG}
{$mode objfpc}{$H+}

uses
  Interfaces, // this includes the LCL widgetset
  Forms
   {$IFDEF DEBUG}
   , SysUtils              //delete SysUtils if not using heaptrc
   {$ENDIF}
  { add your units here }, opfunit,
		lnetvisual, aboutunit, loginunit, beamunit, resunit2, form2pdf;

{$R *.res}

begin
  {Set up -gh output for the Leakview package}
  {$IFDEF DEBUG}
  if FileExists('heap.trc') then
     DeleteFile('heap.trc');
  SetHeapTraceOutput('heap.trc');
  {$ENDIF}
   Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TOPFForm, OPFForm);
  Application.Run;
end.

