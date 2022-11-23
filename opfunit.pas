unit opfunit;
{modification history
completed 4/2/2000
24/2/2000  altered field size on output
           patient diameter print only on opposing field 24/2/2000
           swapped FSX and FSY fields in output factor ST
           increase max SSD to 230 cm
           increase max diameter to 50 cm
           altered beam file to align fields needed by programs compiled under
           Delphi 5
30/5/2001  altered format of output slightly
           fixed save bug
           fixed variable SSD bug
11/6/2002  added definable expiry date
           added reference dose
           Automatic date entry added
27/6/2003  add multiple machines
           fixed save on close bug
8/8/2003   altered skin dose depth from 0.03 to 0.1
19/8/2003  fixed variable SSD print
           fixed update fields before exit
           included compensator option
9/2/2004   added initialise with dmax for dose to maximum
10/3/2004  disable TDepth for Single field dose to maximum
8/6/2005   ported to linux using Lazarus and Free Pascal Compiler
           Use CRC for integrity verification instead of checksum
           Fix exit bug
           Help disabled for the moment
21/4/2008  convert to TMR tables
20/6/2008  reduce depth range to 25 to conform with diam of 50
1/2/2011   fixed date format error, fixed various error checks
2/7/2012   added on line help and web help server
10/1/2013  fixed TMR bug on smallest field
16/10/2014 altered output to pdf
17/10/2014 disable compensators
20/10/2014 added status bar and error reporting
           added DR no
22/10/2014 set save default to My Documents/Patients
18/11/2014 fixed inconsistent save action and directories
12/7/2016  fixed defines for windows 64 bit
24/4/2019  fixed beam empty cell and data errors
10/7/2019  fix spelling Normalisation
           added standard about unit
5/2/2020   remove expiry check
7//2/2020  fix save as file name error
           update statusbar messaging system and refactor
           implemented login module
17/3/2020  add refresh linac list on beam module exit
24/3/2020  look in program data config dir first for beam file
16/4/2020  fix various mem leaks
3/8/2020   correct title of login module
18/11/2022 fix double free causing exception on new patient
           special characters in filenames
23/11/2022 convert resunit to form2pdf}

{$mode DELPHI}{$H+}

interface

uses
   Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Menus,
   ExtCtrls, Buttons, StdCtrls, LazHelpHTML, ComCtrls, lNetComponents,
   lwebserver, FileUtil, StrUtils;

const NE = 5;                      {maximum number of energies}
      SCD = 100;                   {source calibration distance}
      FaintRed:    TColor = $7979ff;
      FaintYellow: TColor = $cffcff;
      FaintGreen:  TColor = $e4ffd3;

type
   TPrescription = (Tumour, Max);  {Tumour dose or Maximum dose}

   TPresentation = (AP,Lat);       {Anterior/Posterior, Lateral}

   TField = (Opposing, Single);

   TTech = (FixedSSD,Isocentric, VarSSD);  {Fixed SSD 100cm, Isocentric, Variable SSD}

   String10 = string[10];

   String255 = string[255];

   TPatRec = record
      Fname    :string255;         {file name}
      PDate    :string10;          {date of plan}
      Pname    :string255;         {patient name}
      DRno     :string255;         {unique identification number}
      Bdate    :string10;          {patient's birth date}
      Diagnosis,                   {diagnosis of patient}
      Comment  :string255;         {comment about patient}
      Prescript: TPrescription;    {prescription, tumour or maximum dose}
      TDose,                       {total prescribed dose}
      Frac     :double;            {number of fractions}
      Fields   :TField;            {opposing or single field}
      Treatment:TTech;             {treatment technique, SSD, isocentric}
      Present  :TPresentation;     {type of presentation, AP or Lat}
      Energy   :integer;           {index of selected energy}
      EName    :string10;          {name of selected energy}
      Machine  :integer;           {index of selected machine}
      MName    :string10;          {name of selected machine}
      Comp     :boolean;           {true for compensator}
      CDepth,                      {compensator depth}
      FSX,                         {X field size}
      FSY,                         {Y field size}
      Depth,                       {treatment depth}
      Diam,                        {patient diameter}
      SSD,                         {source surface distance}
      TrayFac,                     {tray factor}
      TableFac,                    {table factor}
      CFac     :double;            {compensator factor}
      Changed  :boolean;           {true if patient data has changed}
     end;

   TPatient = class
      PatRec   :TPatRec;           {Patient information}
     public
      constructor Create;          {create and initialise TPatient}
      procedure Clear;             {clear field of TPatient}
      procedure Save;              {save patient data}
      procedure Open;              {load patient data}
     end; {of TPatient}

   TDmax = array[1..NE] of double; {array for Dmax}

   TTable = array[1..NE] of double; {array for factors}

   TTray = array[1..NE,1..5] of double; {array for factors}

   TTmrArray = array of array of double; {array for TMR values}

   Ttmr = array[1..NE] of TTmrArray; {array for TMR parameter}

   TOutfac = array[1..NE,1..7] of double; {array for output factors}

   String10Arr = array[1..NE] of String10;

   TLinacRec = record
      CheckSum :dword;             {verify integrity of data file}
      Title    :string255;         {name of installation}
      Name     :string10;          {accelerator name}
      NoE      :integer;           {number of photon energies available}
      Energy   :String10Arr;       {photon energies available}
      Table    :TTable;            {table factors for each energy}
      Tray     :TTray;             {Tray factors for each energy}
      DM       :TDmax;             {dmax of each energy}
      S        :TOutfac;           {regression coefficients for output factors}
      EDate    :TDateTime;         {program expiry date}
     end;

   TLinac = class
      LinacRec :TLinacRec;         {Linac data}
     public
      constructor Create;          {create and initialise Linac}
     end; {of Tlinac}

  { TOPFForm }

  TOPFForm = class(TForm)
     cbTTech: TComboBox;
     cbType: TComboBox;
     cbFields: TComboBox;
     cbTTechcbMachine: TComboBox;
     cbMachine: TComboBox;
     cbEnergy: TComboBox;
     cbPresentation: TComboBox;
     cbTrayFac: TComboBox;
     cbTableFac: TComboBox;
     ebPName: TEdit;
     ebDiag: TEdit;
     ebComment: TEdit;
     ebDate: TEdit;
     ebBdate: TEdit;
     ebTDose: TEdit;
     ebNFrac: TEdit;
     ebFSY: TEdit;
     ebFSX: TEdit;
     ebDiam: TEdit;
     ebTDepth: TEdit;
     ebSSD: TEdit;
     ebWedge: TEdit;
     ebDRNo: TEdit;
     gbParticulars: TGroupBox;
     gbPrescription: TGroupBox;
     gbParameters: TGroupBox;
     HTMLBrowserHelpViewer: THTMLBrowserHelpViewer;
     HTMLHelpDatabase: THTMLHelpDatabase;
     ImageList: TImageList;
     Label1: TLabel;
     Label10: TLabel;
     Label11: TLabel;
     Label12: TLabel;
     Label13: TLabel;
     Label14: TLabel;
     Label15: TLabel;
     Label16: TLabel;
     Label17: TLabel;
     Label18: TLabel;
     Label19: TLabel;
     Label2: TLabel;
     Label20: TLabel;
     Label21: TLabel;
     Label22: TLabel;
     Label23: TLabel;
     Label25: TLabel;
     Label26: TLabel;
     Label27: TLabel;
     Label28: TLabel;
     Label29: TLabel;
     Label3: TLabel;
     Label4: TLabel;
     Label5: TLabel;
     Label6: TLabel;
     Label7: TLabel;
     Label8: TLabel;
     Label9: TLabel;
     MenuItem2: TMenuItem;
     miManage: TMenuItem;
     miResetP: TMenuItem;
     miAddUser: TMenuItem;
     miSettings: TMenuItem;
     Server: TLHTTPServerComponent;
     FileHandler: TFileHandler;
     CGIHandler: TCGIHandler;
     PHPCGIHandler: TPHPFastCGIHandler;
     MainMenu1: TMainMenu;
     MenuItem1: TMenuItem;
     ExitMenu: TMenuItem;
     miAbout: TMenuItem;
     miTut: TMenuItem;
     miContents: TMenuItem;
     miHelp: TMenuItem;
     NewMenu: TMenuItem;
     MenuItem3: TMenuItem;
     OpenDialog: TOpenDialog;
     OpenMenu: TMenuItem;
     CalcMenu: TMenuItem;
     SaveDialog: TSaveDialog;
     SaveMenu: TMenuItem;
     SaveAsMenu: TMenuItem;
     MenuItem9: TMenuItem;
     StatusBar: TStatusBar;
     StatusMessages: TStringList;
     ToolBar1: TToolBar;
     ToolButton1: TToolButton;
     ToolButton2: TToolButton;
     ToolButton3: TToolButton;
     ToolButton4: TToolButton;
     ToolButton5: TToolButton;
     ToolButton6: TToolButton;
     ToolButton7: TToolButton;
     ToolButton8: TToolButton;
     ToolButton9: TToolButton;
     procedure miAddUserClick(Sender: TObject);
     procedure miManageClick(Sender: TObject);
     procedure miResetPClick(Sender: TObject);
     procedure StatusBarDrawPanel(SBar: TStatusBar;Panel: TStatusPanel; const Rect: TRect);
     procedure OPFError(sError:string);
     procedure OPFWarning(sWarn:string);
     procedure OPFMessage(sMess:string);
     procedure ClearStatus;
     procedure CalcMenuClick(Sender: TObject);
     procedure EnableFields;
     procedure DisableFields;
     procedure ExitMenuClick(Sender: TObject);
     procedure miAboutClick(Sender: TObject);
     procedure miContentsClick(Sender: TObject);
     procedure miTutClick(Sender: TObject);
     procedure NewMenuClick(Sender: TObject);
     procedure OPFFormClose(Sender: TObject; var CloseAction: TCloseAction);
     procedure OPFFormCloseQuery(Sender: TObject; var CanClose: boolean);
     procedure OpenMenuClick(Sender: TObject);
     procedure ReadLinac(FileName:string);
     procedure ListLinacs;
     procedure OPFFormCreate(Sender: TObject);
     procedure PutData(var PatRec:TPatRec);
     function GetData(var PatRec:TPatRec):boolean;
     function SaveAsMenuClick(Sender: TObject):boolean;
     procedure SaveMenuClick(Sender: TObject);
     procedure cbEnergyChange(Sender: TObject);
     procedure cbFieldsExit(Sender: TObject);
     procedure cbMachineChange(Sender: TObject);
     procedure cbPresentationExit(Sender: TObject);
     procedure cbTTechChange(Sender: TObject);
     procedure cbTableFacExit(Sender: TObject);
     procedure cbTrayFacExit(Sender: TObject);
     procedure cbTypeExit(Sender: TObject);
     procedure ebDiamExit(Sender: TObject);
     procedure ebFSXExit(Sender: TObject);
     procedure ebFSYExit(Sender: TObject);
     procedure ebNFracExit(Sender: TObject);
     procedure ebPNameChange(Sender: TObject);
     procedure ebSSDExit(Sender: TObject);
     procedure ebTDepthExit(Sender: TObject);
     procedure ebTDoseExit(Sender: TObject);
     procedure ebWedgeExit(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

function ToAlphaNum(TheString:string):string;

var
   OPFForm     :TOPFForm;
   Pat         :TPatient;
   Linac       :TLinac;
   TMR         :TTmr;
   Fault       :boolean;

implementation

uses beamunit, loginunit, CRC32,resunit2, helpintfs, aboutunit, LazFileUtils;

function ToAlphaNum(TheString:string):string;
{Eliminates everthing except alphanumeric characters from a string}
var Character: char;
begin
Result := '';
for Character in TheString do
   if Character in ['0'..'9','A'..'Z','a'..'z'] then
      Result := Result + Character;
end;


{TPatient}

constructor TPatient.Create;
{Create and initialise TPatient}
begin
inherited Create;
Clear;
end;

procedure TPatient.Clear;
{Clear the fields of TPatient}
begin
with PatRec do
   begin
   Fname := '';
   PDate := DateToStr(Now);
   Pname := '';
   DRNo := '';
   Bdate := '';
   Diagnosis := '';
   Comment := '';
   Prescript := Tumour;
   TDose := 0;
   Frac := 0;
   Fields := Opposing;
   Treatment := Isocentric;
   Present := AP;
   Energy := 1;
   EName := '';
   Machine := 1;
   MName := '';
   Comp := false;
   CDepth := 0;
   FSX := 0;
   FSY := 0;
   Depth := 0;
   Diam := 0;
   SSD := 100;
   TrayFac := 1;
   TableFac := 1;
   CFac := 1;
   Changed := False;
   end;
end;


procedure TPatient.Save;
{This procedure saves the patient data.}

var Outfile    :file of TPatRec;

begin
if Pat <> nil then
   begin
   AssignFile(Outfile,Pat.PatRec.Fname);
   Rewrite(Outfile);
   Write(Outfile,Pat.PatRec);
   CloseFile(Outfile);
   end;
end;


procedure TPatient.Open;
{This procedure loads the patient data.}

var Infile     :file of TPatRec;

begin
Assignfile(Infile,Pat.PatRec.Fname);
Reset(Infile);
Read(Infile,Pat.PatRec);
CloseFile(Infile);
end;

{TLinac}

constructor TLinac.Create;
{Create and initialise TLinac}

var I,J        :integer;

begin
inherited Create;
with LinacRec do
   begin
   Title := '';
   Name := '';
   NoE := 0;
   EDate := 0;
   for I:=1 to NE do
      begin
      Energy[I] := '';
      DM[I] := 0;
      Table[I] := 0;
      for J:=1 to 5 do Tray[I,J] := 0;
      for J:=1 to 7 do S[I,J] := 0;
      Setlength(TMR[I],0);
      end;
   end;
end;


{ TOPFForm }

procedure TOpfForm.StatusBarDrawPanel(SBar: TStatusBar;Panel: TStatusPanel;
   const Rect: TRect);
{Workaround for consistent colour panel on windows and linux}
begin
with SBar.Canvas do
   begin
   Brush.Color := StatusBar.Color;
   FillRect(Rect);
   TextRect(Rect,2 + Rect.Left, 1 + Rect.Top,Panel.Text) ;
   end;
end;


procedure TOPFForm.miManageClick(Sender: TObject);
var BeamForm   :TBeamForm;
    Current    :string;

begin
ClearStatus;
Current := cbMachine.Text;
try
   BeamForm := TBeamForm.Create(self);
   BeamForm.ShowModal;
   finally
   BeamForm.Free;
   end;
ListLinacs;
cbMachine.ItemIndex := cbMachine.Items.IndexOf(Current);
if cbMachine.ItemIndex < 0 then
   begin
   OPFError('Could not find previous machine.');
   cbMachine.ItemIndex := 0;
   end;
ReadLinac(cbMachine.Items[cbMachine.ItemIndex]);
end;


procedure TOPFForm.miResetPClick(Sender: TObject);
var LoginForm  :TLoginForm;
begin
try
   LoginForm := TLoginForm.Create(self);
   LoginForm.bbEnter.Caption := 'Reset' + LineEnding + 'Password';
   LoginForm.bbEnter.OnClick := LoginForm.ResetPass;
   LoginForm.ShowModal;
   finally
   LoginForm.Free;
   end;
end;


procedure TOPFForm.miAddUserClick(Sender: TObject);
var LoginForm  :TLoginForm;
begin
try
   LoginForm := TLoginForm.Create(self);
   LoginForm.bbEnter.Caption := 'Add User';
   LoginForm.bbEnter.OnClick := LoginForm.AddUser;
   LoginForm.ShowModal;
   finally
   LoginForm.Free;
   end;
end;


procedure TOpfForm.OPFError(sError:string);
begin
StatusBar.Panels[0].Text := sError;
StatusBar.Color := FaintRed;
StatusMessages.Add(StatusBar.Panels[0].Text);
StatusBar.Hint := StatusMessages.Text;
end;



procedure TOpfForm.OPFWarning(sWarn:string);
begin
StatusBar.Panels[0].Text := sWarn;
StatusBar.Color := FaintYellow;
StatusMessages.Add(StatusBar.Panels[0].Text);
StatusBar.Hint := StatusMessages.Text;
end;


procedure TOpfForm.OPFMessage(sMess:string);
begin
StatusBar.Panels[0].Text := sMess;
StatusBar.Color := FaintGreen;
StatusMessages.Add(StatusBar.Panels[0].Text);
StatusBar.Hint := StatusMessages.Text;
end;


procedure TOpfForm.ClearStatus;
begin
StatusBar.Panels[0].Text := '';
StatusBar.Color := clDefault;
end;


procedure TOpfForm.ReadLinac(FileName:string);
var I,J,K,
    Size,
    TMRL,
    TMRW       :integer;
    CRCValue   :dword;
    sExePath,
    sDataPath  :string;
    Infile     :TextFile;

begin
{Set directory path to program files}
{$ifdef WINDOWS}
sDataPath := GetAppConfigDir(true);
{$else}
sDataPath := GetAppConfigDir(false);
{$endif}
sDataPath := AppendPathDelim(sDataPath) + FileName + '.bdf';
sExePath := ExtractFilePath(Application.ExeName);
sExePath := AppendPathDelim(sExePath) + FileName + '.bdf';

{create and read linac data}
Fault := false;
if Linac <> nil then
   begin
   Linac.Free;
   Linac := nil;
   end;
Linac := TLinac.Create;

with Linac.LinacRec do
   begin

   {read data from disk}
      try
      if FileExists(sDataPath) then
         AssignFile(Infile,sDataPath)
        else
         AssignFile(Infile,sExePath);
      Reset(Infile);
      Readln(Infile,Checksum);
      Readln(Infile,Title);
      Readln(Infile,Name);
      Readln(Infile,NoE);
      Readln(Infile,EDate);
      for I:=1 to NoE do
         begin
         Readln(Infile,Energy[I]);
         Readln(Infile,DM[I]);
         Readln(Infile,Table[I]);
         for J:=1 to 5 do Read(Infile,Tray[I,J]);
         for J:=1 to 7 do Read(Infile,S[I,J]);
         Readln(Infile,TMRL);
         Readln(Infile,TMRW);
         SetLength(TMR[I],TMRL);
         for J:=0 to TMRL - 1 do
            begin
            SetLength(TMR[I,J],TMRW);
            for K:=0 to TMRW - 1 do
               Read(Infile,TMR[I,J,K]);
            end;
         Readln(Infile);
         end;
      CloseFile(Infile);
      except
      Fault := true;
      OPFError('File error, could not read data file');
      DisableFields;
      end;
   end;


if FileName <> Linac.LinacRec.Name then
   begin
   Fault := true;
   OPFError('Integrity of the beam data file has been'
         + ' compromised. Please select another accelerator.');
   DisableFields;
   end;

{Check if use limit of beam data has expired}
{if Now > Linac.LinacRec.EDate then
   begin
   Fault := true;
   StatusBar.SimpleText := 'The use limit of this data has expired. '
      + 'Please contact the authors to obtain an updated copy.';
   StatusBar.Color := clRed;
   StatusMessages.Add(StatusBar.SimpleText);
   StatusBar.Hint := StatusMessages.Text;
   DisableFields;
   end; }

with Linac.LinacRec do
   begin

   {check integrity}
   {create CRC value}
   CRCValue := $FFFFFFFF;
   Size := SizeOf(Title);
   CalcCRC32(@Title,Size,CRCValue);
   Size := SizeOf(Name);
   CalcCRC32(@Name,Size,CRCValue);
   Size := SizeOf(NoE);
   CalcCRC32(@NoE,Size,CRCValue);
   Size := SizeOf(Energy);
   CalcCRC32(@Energy,Size,CRCValue);
   Size := SizeOf(Table);
   CalcCRC32(@Table,Size,CRCValue);
   Size := SizeOf(Tray);
   CalcCRC32(@Tray,Size,CRCValue);
   Size := SizeOf(DM);
   CalcCRC32(@DM,Size,CRCValue);
   Size := SizeOf(S);
   CalcCRC32(@S,Size,CRCValue);
   Size := SizeOf(EDate);
   CalcCRC32(@EDate,Size,CRCValue);
   for I:=1 to NoE do
      for J:=0 to Length(TMR[I]) - 1 do
         begin
         Size := Length(TMR[I,J])*SizeOf(double);
         CalcCRC32(@TMR[I,J,0],Size,CRCValue);
         end;
   if CRCValue <> Linac.LinacRec.CheckSum then
      begin
      Fault := true;
      OPFError('Integrity of the beam data file has been'
         + ' compromised. Please select another accelerator.');
      DisableFields;
      end;


   {transfer data to OpfForm}
   if not Fault then
      begin
      OpfForm.Caption := Title;
      CBEnergy.Items.Clear;
      for I:=1 to NoE do CBEnergy.Items.Add(Energy[I]);
      CBEnergy.ItemIndex := 0;
      CBTableFac.Items.Clear;
      CBTableFac.Items.Add('1');
      CBTableFac.Items.Add(FloatToStr(Table[1]));
      CBTableFac.ItemIndex := 0;
      CBTrayFac.Items.Clear;
      I := 1;
      while (Tray[1,I] <> 0) and (I <= 5) do
	 begin
	 CBTrayFac.Items.Add(FloatToStr(Tray[1,I]));
	 Inc(I);
	 end;
      CBTrayFac.ItemIndex := 0;
      if (CBType.ItemIndex = 1) and (CBFields.ItemIndex = 1) then
	 ebTDepth.Text := FloatToStr(DM[CBEnergy.ItemIndex + 1]);
      ClearStatus;
      EnableFields;
      end;
   end;
end;


procedure TOPFForm.ListLinacs;
var SearchRec  :TSearchRec;
    sExePath,
    sDataPath,
    FileName   :string;

begin
CBMachine.Items.Clear;
{first look in data dir where config files should be stored}
{$ifdef WINDOWS}
sDataPath := GetAppConfigDir(true);
{$else}
sDataPath := GetAppConfigDir(false);
{$endif}
sDataPath := AppendPathDelim(sDataPath) + '*.bdf';
if FindFirst(sDataPath,0,SearchRec) = 0 then
   repeat
   FileName := ExtractFileName(SearchRec.Name);
   FileName := Copy(FileName,1,length(FileName) - 4);
   CBMachine.Items.Add(FileName);
   until FindNext(SearchRec)<>0
  else
   begin {else look in exe dir where beam files were stored}
   sExePath := ExtractFilePath(Application.ExeName);
   sExePath := AppendPathDelim(sExePath) + '*.bdf';
   if FindFirst('*.bdf',0,SearchRec) = 0 then
      repeat
      FileName := ExtractFileName(SearchRec.Name);
      FileName := Copy(FileName,1,length(FileName) - 4);
      CBMachine.Items.Add(FileName);
      until FindNext(SearchRec) <> 0;
   end;
FindClose(SearchRec);
end;


procedure TOPFForm.OPFFormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
if Pat <> nil then Pat.Free;
FileHandler.Free;
CGIHandler.Free;
PHPCGIHandler.Free;
OpenDialog.Destroy;
StatusMessages.Free;
Linac.Free;
end;


procedure TOpfForm.EnableFields;
begin
ebPName.Enabled := True;
ebPName.Color := clWindow;
ebDate.Enabled := True;
ebDate.Color := clWindow;
ebDate.Text := FormatDateTime('d mmmm yyyy', Now);
ebDRNo.Enabled := true;
ebDRNo.Color := clWindow;
ebDiag.Enabled := True;
ebDiag.Color := clWindow;
ebComment.Enabled := True;
ebComment.Color := clWindow;
ebBDate.Enabled := True;
ebBDate.Color := clWindow;
CBType.Enabled := True;
CBType.Color := clWindow;
ebTDose.Enabled := True;
ebTDose.Color := clWindow;
ebNFrac.Enabled := True;
ebNFrac.Color := clWindow;
CBFields.Enabled := True;
CBFields.Color := clWindow;
CBTTech.Enabled := True;
CBTTech.Color := clWindow;
CBPresentation.Enabled := True;
CBPresentation.Color := clWindow;
CBEnergy.Enabled := True;
CBEnergy.Color := clWindow;
CBMachine.Enabled := True;
CBMachine.Color := clWindow;
ebFSX.Enabled := True;
ebFSX.Color := clWindow;
ebFSY.Enabled := True;
ebFSY.Color := clWindow;
ebTDepth.Enabled := True;
ebTDepth.Color := clWindow;
ebDiam.Enabled := True;
ebDiam.Color := clWindow;
ebSSD.Enabled := True;
ebSSD.Color := clWindow;
CBTrayFac.Enabled := True;
CBTrayFac.Color := clWindow;
CBTableFac.Enabled := True;
CBTableFac.Color := clWindow;
ebWedge.Enabled := True;
ebWedge.Color := clWindow;
cbFieldsExit(Self);
cbPresentationExit(Self);
cbTTechChange(Self);
end;


procedure TOpfForm.DisableFields;
begin
ebPName.Enabled := false;
ebPName.Color := clWindow;
ebDate.Enabled := false;
ebDate.Color := clWindow;
ebDRNo.Enabled := false;
ebDRNo.Color := clWindow;
ebDiag.Enabled := false;
ebDiag.Color := clWindow;
ebComment.Enabled := false;
ebComment.Color := clWindow;
ebBDate.Enabled := false;
ebBDate.Color := clWindow;
CBType.Enabled := false;
CBType.Color := clWindow;
ebTDose.Enabled := false;
ebTDose.Color := clWindow;
ebNFrac.Enabled := false;
ebNFrac.Color := clWindow;
CBFields.Enabled := false;
CBFields.Color := clWindow;
CBTTech.Enabled := false;
CBTTech.Color := clWindow;
CBPresentation.Enabled := false;
CBPresentation.Color := clWindow;
CBEnergy.Enabled := false;
CBEnergy.Color := clWindow;
CBMachine.Enabled := True;
CBMachine.Color := clWindow;
ebFSX.Enabled := false;
ebFSX.Color := clWindow;
ebFSY.Enabled := false;
ebFSY.Color := clWindow;
ebTDepth.Enabled := false;
ebTDepth.Color := clWindow;
ebDiam.Enabled := false;
ebDiam.Color := clWindow;
ebSSD.Enabled := false;
ebSSD.Color := clWindow;
CBTrayFac.Enabled := false;
CBTrayFac.Color := clWindow;
CBTableFac.Enabled := false;
CBTableFac.Color := clWindow;
ebWedge.Enabled := false;
ebWedge.Color := clWindow;
end;


procedure TOPFForm.CalcMenuClick(Sender: TObject);
var ResForm     :TResForm2;
    sDataDir,
    sTemp       :string;
begin
if (Pat <> nil) and GetData(Pat.PatRec) then
   begin
   try
      sDataDir := GetUserDir;
      {$ifdef WINDOWS}
      sDataDir := AppendPathdelim(sDataDir) + 'My Documents';
      {$else}
      sDataDir := AppendPathdelim(sDataDir) + 'Documents';
      {$endif}
      sDataDir := AppendPathdelim(sDataDir) + 'Patients';
      if not DirectoryExists(sDataDir) then CreateDir(sDataDir);
      sDataDir := AppendPathdelim(sDataDir) + 'temp';
      if not DirectoryExists(sDataDir) then CreateDir(sDataDir);

      sTemp := Pat.PatRec.FName;
      Pat.PatRec.FName := AppendPathDelim(sDataDir) + FormatDateTime('yyyymmddHHMMss',Now) +
         ToAlphaNum(Pat.PatRec.Pname) + ToAlphaNum(Pat.PatRec.DRNo) + '.pnt';
      Pat.Save;
      Pat.PatRec.FName := sTemp;
   except
      OPFError('Could not write temp file!');
      end;
   ResForm := TResForm2.Create(Self);
   ResForm.ShowModal;
   ResForm.Free;
   end;
end;


procedure TOPFForm.ExitMenuClick(Sender: TObject);
begin
close;
end;


procedure TOPFForm.miAboutClick(Sender: TObject);
var AboutFrm   :TAboutForm;

begin
AboutFrm := TAboutForm.Create(self);
AboutFrm.ShowModal;
AboutFrm.Free;
end;


procedure TOPFForm.miContentsClick(Sender: TObject);
begin
ShowHelpOrErrorForKeyword('','HTML/OPFHelp.html');
end;


procedure TOPFForm.miTutClick(Sender: TObject);
begin
ShowHelpOrErrorForKeyword('','HTML/OPFHelp7.html');
end;


procedure TOPFForm.NewMenuClick(Sender: TObject);
var Action     :boolean;

begin
Action := true;
if Pat <> nil then
   if Pat.PatRec.Changed then
      case MessageDlg('Save patient?',mtConfirmation,[mbYes,mbNo,mbCancel],0) of
         mrYes:begin
               Action := SaveAsMenuClick(Sender);
               end;
         mrNo :;
         mrCancel :Action := False;
         end;
if Action then
   begin
   Pat.Free;
   Pat := TPatient.Create;
   EnableFields;
   PutData(Pat.PatRec);
   Pat.PatRec.Changed := False;
   ebPName.SetFocus;
   Application.ProcessMessages
   end;
end;


procedure TOPFForm.OPFFormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
CanClose := False;
if Pat <> nil then
   begin
   if Pat.PatRec.Changed then
      case MessageDlg('Save patient?',mtConfirmation,[mbYes,mbNo,mbCancel],0) of
      mrYes: begin
             if SaveAsMenuClick(Sender) then CanClose := true;
             end;
      mrNo:  CanClose := True;
     end
    else
     CanClose := True;
   end
  else
   CanClose := True;
end;


procedure TOPFForm.OpenMenuClick(Sender: TObject);
var Action     :boolean;
    sDataDir   :string;

begin
Action := true;
if Pat <> nil then
   if Pat.PatRec.Changed then
      case MessageDlg('Save patient?',mtConfirmation,[mbYes,mbNo,mbCancel],0) of
         mrYes:begin
           Action := SaveAsMenuClick(Sender);
           end;
         mrNo:;
         mrCancel:Action := False;
         end;
if Action then
   begin
   try
   sDataDir := GetUserDir;
   {$ifdef WINDOWS}
   sDataDir := AppendPathdelim(sDataDir) + 'My Documents';
   {$else}
   sDataDir := AppendPathdelim(sDataDir) + 'Documents';
   {$endif}
   sDataDir := AppendPathdelim(sDataDir) + 'Patients';
   if not DirectoryExists(sDataDir) then CreateDir(sDataDir);
   sDataDir := AppendPathdelim(sDataDir) + FormatDateTime('yyyy',Date);
   if not DirectoryExists(sDataDir) then CreateDir(sDataDir);
   sDataDir := AppendPathdelim(sDataDir) + FormatDateTime('mmMMMM',Date);
   if not DirectoryExists(sDataDir) then CreateDir(sDataDir);
   OpenDialog.InitialDir := sDataDir;
   except
      OPFError('Could not create patient directory');
      end;

   if OpenDialog.Execute then
      begin
      try
      Pat.Free;
      Pat := TPatient.Create;
      Pat.PatRec.Fname := OpenDialog.FileName;
      Pat.Open;
      EnableFields;
      ebPName.SetFocus;
      Application.ProcessMessages;
      PutData(Pat.PatRec);
      Pat.PatRec.Changed := False;
      except
         OPFError('Could not open patient!');
         end;
      end;
   end;
end;


procedure TOPFForm.OPFFormCreate(Sender: TObject);
var     sExePath:   string;

begin
Linac := nil;
Fault := false;
Pat := TPatient.Create;
StatusMessages := TStringList.Create;

{Auth user}
{User := 'Administrator';}           {comment for auth}
if not TLoginForm.Execute then    //uncomment for auth
   begin
   StatusMessages.Free;
   Halt;
   end;

if User = 'Administrator' then
   begin
   miSettings.Enabled := true;
   miSettings.Visible := true;
   end;

{Set directory path to program files}
sExePath := ExtractFilePath(Application.ExeName);
SetCurrentDir(sExePath);

{start web server for online help}
FileHandler := TFileHandler.Create;
FileHandler.MimeTypeFile := sExePath + 'html' + DirectorySeparator + 'mime.types';
FileHandler.DocumentRoot := sExePath + 'html';

CGIHandler := TCGIHandler.Create;
CGIHandler.FCGIRoot := sExePath + 'html' + DirectorySeparator + 'cgi-bin';
CGIHandler.FDocumentRoot := sExePath + 'html' + DirectorySeparator + 'cgi-bin';
CGIHandler.FEnvPath := sExePath + 'html' + DirectorySeparator + 'cgi-bin';
CGIHandler.FScriptPathPrefix := 'cgi-bin' + DirectorySeparator;

PHPCGIHandler := TPHPFastCGIHandler.Create;
PHPCGIHandler.Host := 'localhost';
PHPCGIHandler.Port := 4665;
PHPCGIHandler.AppEnv := 'PHP_FCGI_CHILDREN=5:PHP_FCGI_MAX_REQUESTS=10000';
PHPCGIHandler.AppName := 'php-cgi.exe';
PHPCGIHandler.EnvPath := sExePath + 'html' + DirectorySeparator + 'cgi-bin';

Server.RegisterHandler(FileHandler);
Server.RegisterHandler(CGIHandler);

FileHandler.DirIndexList.Add('index.html');
FileHandler.DirIndexList.Add('index.htm');
FileHandler.DirIndexList.Add('index.php');
FileHandler.DirIndexList.Add('index.cgi');
FileHandler.RegisterHandler(PHPCGIHandler);

ListLinacs;
if CBMachine.Items.Count <> 0 then
   begin
   cbMachine.ItemIndex := 0;
   ReadLinac(CBMachine.Items[0]);
   end
  else
   begin
   Fault := true;
   OPFError('No beam data files exist! Please create a file using Beam.');
   {Halt};
   end;

{check if server is running}
if not Server.Listen(3880) then
   begin
   Fault := true;
   OPFWarning('Error starting help server. Online help may not be available.');
   end;

if not Fault then
   begin
   OPFMessage('Welcome ' + User + '. Opposing Fields Program initialised correctly.');
   {PutData(Pat.PatRec);}
   end;
Pat.PatRec.Changed := false;
end;


function TOpfForm.GetData(var PatRec:TPatRec):boolean;
begin
GetData := False;

{update and check fields before transfering}
if ebTDose.Enabled then ebTDoseExit(Self);
if ebNFrac.Enabled then ebNFracExit(Self);
if ebFSY.Enabled then ebFSYExit(Self);
if ebFSX.Enabled then ebFSXExit(Self);
if ebDiam.Enabled then ebDiamExit(Self);
if ebTDepth.Enabled then ebTDepthExit(Self);
CBTrayFacExit(Self);
if CBTableFac.Enabled then CBTableFacExit(Self);
ebWedgeExit(Self);

with PatRec do
   begin
   Pname := ebPname.Text;
   PDate := ebDate.Text;
   BDate := ebBDate.Text;
   DRNo := ebDRNo.Text;
   Diagnosis := ebDiag.Text;
   Comment := ebComment.Text;
   case CBType.ItemIndex of
      0: Prescript := Tumour;
      1: Prescript := Max;
     end;
   TDose := StrToFloat(ebTDose.Text);
   Frac := StrToFloat(ebNFrac.Text);
   case CBFields.ItemIndex of
      0: Fields := Opposing;
      1: Fields := Single;
     end;
   case CBTTech.ItemIndex of
      0: Treatment := Isocentric;
      1: Treatment := FixedSSD;
      2: Treatment := VarSSD;
     end;
   case CBPresentation.ItemIndex of
      0: Present := AP;
      1: Present := Lat;
     end;
   Energy := CBEnergy.ItemIndex + 1;
   EName := CBEnergy.Items[CBEnergy.ItemIndex];
   Machine := CBMachine.ItemIndex + 1;
   MName := CBMachine.Items[CBMachine.ItemIndex];
   Comp := false;
   FSX := StrToFloat(ebFSX.Text);
   FSY := StrToFloat(ebFSY.Text);
   Diam := StrToFloat(ebDiam.Text);
   Depth := StrToFloat(ebTDepth.Text);
   SSD := StrToFloat(ebSSD.Text);
   TrayFac := StrToFloat(CBTrayFac.Text);
   TableFac := StrToFloat(CBTableFac.Text);
   CFac := StrToFloat(ebWedge.TExt);
   if (TDose >= 0) and (Frac > 0) and (FSX > 0) and (FSY > 0) and (Diam >= 0)
      and (Depth >= 0) and (SSD > 0) and (TrayFac > 0) and (TableFac > 0)
      and (CFac > 0) then
      begin
      GetData := True;
      ClearStatus;
      end
     else
      begin
      OPFError('Data out of range');
      end;
   end;
end;


procedure TOpfForm.PutData(var PatRec:TPatRec);
{This procedure places data in the edit fields.}

begin
with patRec do
   begin
   ebPname.Text := Pname;
   ebDate.Text := PDate;
   ebBDate.Text := BDate;
   ebDRNo.Text := DRNo;
   ebDiag.Text := Diagnosis;
   ebComment.Text := Comment;
   Case Prescript of
      Tumour: CBType.ItemIndex := 0;
      Max   : CBType.ItemIndex := 1;
     end;
   ebTDose.Text := FloatToStr(TDose);
   ebNFrac.Text := FloatToStr(Frac);
   case Fields of
      Opposing : CBFields.ItemIndex := 0;
      Single   : CBFields.ItemIndex := 1;
     end;
   CBFieldsExit(Self);
   case Treatment of
      Isocentric : CBTTech.ItemIndex := 0;
      FixedSSD   : CBTTech.ItemIndex := 1;
      VarSSD     : CBTTech.ItemIndex := 2;
     end;
   CBTTechChange(Self);
   case Present of
      AP  : CBPresentation.ItemIndex := 0;
      Lat : CBPresentation.ItemIndex := 1;
     end;

   ebFSX.Text := FloatToStr(FSX);
   ebFSY.Text := FloatToStr(FSY);
   ebDiam.Text := FloatToStr(Diam);
   ebTDepth.Text := FloatToStr(Depth);
   ebSSD.Text := FloatToStr(SSD);
   ebWedge.Text := FloatToStr(CFac);

   if MName <> '' then
      begin
      if CBMachine.Items.IndexOf(MName) >= 0 then
         begin
         CBMachine.ItemIndex := CBMachine.Items.IndexOf(MName);
         Machine := CBMachine.ItemIndex + 1;
         ReadLinac(CBMachine.Items[CBMachine.ItemIndex]);
         CBEnergy.ItemIndex := Energy - 1;
         CBTrayFac.Text := FloatToStr(TrayFac);
         CBTableFac.Text := FloatToStr(TableFac);
         ClearStatus;
         end
        else
         begin
         CBMachine.ItemIndex := 0;
         ReadLinac(CBMachine.Items[CBMachine.ItemIndex]);
         OPFWarning('Warning! Machine unavailable defaults selected.');
         end;
      end
     else
      begin
      CBMachine.ItemIndex := 0;
      ReadLinac(CBMachine.Items[CBMachine.ItemIndex]);
      end;
   end;
end;


function TOPFForm.SaveAsMenuClick(Sender: TObject):boolean;
var sDataDir:  string;

begin
Result := false;
if Pat <> nil then
   begin
   try
      sDataDir := GetUserDir;
      {$ifdef WINDOWS}
      sDataDir := AppendPathdelim(sDataDir) + 'My Documents';
      {$else}
      sDataDir := AppendPathdelim(sDataDir) + 'Documents';
      {$endif}
      sDataDir := AppendPathdelim(sDataDir) + 'Patients';
      if not DirectoryExists(sDataDir) then CreateDir(sDataDir);
      sDataDir := AppendPathdelim(sDataDir) + FormatDateTime('yyyy',Date);
      if not DirectoryExists(sDataDir) then CreateDir(sDataDir);
      sDataDir := AppendPathdelim(sDataDir) + FormatDateTime('mmMMMM',Date);
      if not DirectoryExists(sDataDir) then CreateDir(sDataDir);
      SaveDialog.InitialDir := sDataDir;
      if Pat.PatRec.Fname = '' then
         SaveDialog.FileName := ToAlphaNum(ebPName.Text) + ToAlphaNum(ebDRNo.Text) + '.pnt'
        else
         SaveDialog.FileName := ExtractFileName(Pat.PatRec.FName);

      if SaveDialog.Execute then
         begin
         Pat.PatRec.Fname := SaveDialog.FileName;
         SaveMenuClick(Sender);
         Result := true;
         end;
   except
      OPFError('Could not create patient directory!');
      end;
   end;
end;


procedure TOPFForm.SaveMenuClick(Sender: TObject);
begin
if (Pat.PatRec.Fname = '') then SaveAsMenuClick(Sender)
  else
   begin
   GetData(Pat.PatRec);
   Pat.PatRec.Changed := false;
   try
      Pat.Save;
   except
      OPFError('Could not save patient!');
      end;
   end;
end;


procedure TOPFForm.cbEnergyChange(Sender: TObject);
var I,J        :integer;

begin
if not Fault then
   begin
   if Pat <> nil then Pat.PatRec.Changed := True;
   I := CBEnergy.ItemIndex + 1;
   CBTableFac.Items.Clear;
   CBTableFac.Items.Add('1');
   CBTableFac.Items.Add(FloatToStr(Linac.LinacRec.Table[I]));
   CBTableFac.ItemIndex := 0;
   J := 1;
   CBTrayFac.Items.Clear;
   while (Linac.LinacRec.Tray[I,J] <> 0) and (J <= 5) do
      begin
      CBTrayFac.Items.Add(FloatToStr(Linac.LinacRec.Tray[I,J]));
      Inc(J);
      end;
   CBTrayFac.ItemIndex := 0;
   CBTypeExit(Sender);
   end;
end;


procedure TOPFForm.cbFieldsExit(Sender: TObject);
begin
if not Fault then
   begin
   Pat.PatRec.Changed := True;
   case CBFields.ItemIndex of
      0:begin
        CBPresentation.Enabled := True;
	CBPresentation.Color := clWindow;
	ebDiam.Enabled := True;
	ebDiam.Color := clWindow;
	ebTDepth.Enabled := False;
	ebTDepth.Color := clInactiveCaption;
	ebDiamExit(Sender);
	end;
      1:begin
        CBPresentation.Enabled := False;
	CBPresentation.Color := clInactiveCaption;
	CBPresentation.ItemIndex := 0;
	ebDiam.Enabled := False;
	ebDiam.Color := clInactiveCaption;
	ebTDepth.Enabled := True;
	ebTDepth.Color := clWindow;
	ebTDepthExit(Sender);
	end;
      end;
   CBTypeExit(Sender);
   end;
end;


procedure TOPFForm.cbMachineChange(Sender: TObject);
begin
Pat.PatRec.Changed := True;
ReadLinac(CBMachine.Items[CBMachine.ItemIndex]);
end;


procedure TOPFForm.cbPresentationExit(Sender: TObject);
begin
if not Fault then
   begin
   Pat.PatRec.Changed := True;
   case CBPresentation.ItemIndex of
      0:begin
        CBTableFac.Enabled := True;
        CBTableFac.Color := ClWindow;
        end;
      1:begin
        CBTableFac.Enabled := False;
        CBTableFac.Color := clInactiveCaption;
        CBTableFac.ItemIndex := 0;
        CBTableFac.Text := '1';
        end;
     end;
   end;
end;


procedure TOPFForm.cbTTechChange(Sender: TObject);
begin
if not Fault then
   begin
   Pat.PatRec.Changed := True;
   case CBTTech.ItemIndex of
      0:begin
        ebSSD.Enabled := False;
        ebSSD.Color := clInactiveCaption;
        CBFieldsExit(Sender);
        end;
      1:begin
        ebSSD.Enabled := False;
        ebSSD.Color := clInactiveCaption;
        ebSSD.Text := '100';
        end;
      2:begin
        ebSSD.Enabled := True;
        ebSSD.Color := clWindow;
        if ebSSD.Text = '' then ebSSD.Text := '100';
        end;
     end; {of case}
  end;
end;


procedure TOPFForm.cbTableFacExit(Sender: TObject);
var Check      :double;

begin
try
   Check := StrToFloat(CBTableFac.Text);
   if (Check <= 0) or (Check > 1) then
      begin
      OPFError('The table factor must be between 0 and 1');
      CBTableFac.Color := FaintRed;
      CBTableFac.SetFocus;
      Application.ProcessMessages;
      end
     else
      begin
      CBTableFac.Color := clDefault;
      ClearStatus;
      end;

except
   on EConvertError do
      begin
      OPFError('The table factor must be between 0 and 1');
      CBTableFac.Color := FaintRed;
      CBTableFac.SetFocus;
      Application.ProcessMessages;
      end;
   end; {of exception handler}
end;

procedure TOPFForm.cbTrayFacExit(Sender: TObject);
var Check      :double;

begin
try
   Check := StrToFloat(CBTrayFac.Text);
   if (Check <= 0) or (Check > 1) then
      begin
      OPFError('Normalisation must be between 0 and 1');
      CBTrayFac.Color := FaintRed;
      CBTrayFac.SetFocus;
      Application.ProcessMessages;
      end
     else
      begin
      CBTrayFac.Color := clDefault;
      ClearStatus;
      end;
except
   on EConvertError do
      begin
      OPFError('Normalisation must be between 0 and 1');
      CBTrayFac.Color := FaintRed;
      CBTrayFac.SetFocus;
      Application.ProcessMessages;
      end;
   end; {of exception handler}
end;


procedure TOPFForm.cbTypeExit(Sender: TObject);
begin
if not Fault then
   begin
   if (CBType.ItemIndex = 1) and (CBFields.ItemIndex = 1) then
      begin
      ebTDepth.Text := FloatToStr(Linac.LinacRec.DM[CBEnergy.ItemIndex + 1]);
      ebTDepth.Enabled := false;
      ebTDepth.Color := clInactiveCaption;
      end;
   if (CBType.ItemIndex = 0) and (CBFields.ItemIndex = 1) then
      begin
      ebTDepth.Enabled := true;
      ebTDepth.Color := clWindow;
      end;
   ebTDepthExit(Sender);
   end;
end;


procedure TOPFForm.ebDiamExit(Sender: TObject);
var Check      :double;

begin
Pat.PatRec.Changed := True;
try
   Check := StrToFloat(ebDiam.Text);
   if (Check >= 0) and (Check < 50) then
      begin
      ebDiam.Color := clDefault;
      ClearStatus;
      ebTDepth.Text := FloatToStrF(Check/2,ffFixed,4,1);
      case CBTTech.ItemIndex of
         0: ebSSD.Text := FloatToStrF(100 - Check/2,ffFixed,4,1);
         1: ebSSD.Text := '100';
         2: if ebSSD.Text = '' then ebSSD.Text := '100';
        end;
      end
     else
      begin
      OPFError('The patient diameter should be between 0 and 50 cm');
      ebDiam.Color := FaintRed;
      ebDiam.SetFocus;
      Application.ProcessMessages;
      end;
except
   on EConvertError do
      begin
      OPFError('The patient diameter should be between 0 and 50 cm');
      ebDiam.Color := FaintRed;
      ebDiam.SetFocus;
      Application.ProcessMessages;
      end;
   end;
end;


procedure TOPFForm.ebFSXExit(Sender: TObject);
var Check      :double;
    Energy     :integer;
    MinField,
    MaxField   :double;

begin
try
   Check :=0;
   if ebFSX.Text <> '' then
      Check := StrToFloat(ebFSX.Text);
   Energy := CBEnergy.ItemIndex + 1;
   MinField := 4*TMR[Energy,0,1];
   MaxField := 4*TMR[Energy,0,Length(TMR[Energy,0]) - 1];
   if (Check < MinField) or (Check > MaxField) then
      begin
      OPFError('The X field size must be between ' + FloatToStr(MinField)
         + ' and '+ FloatToStr(MaxField) + ' cm');
      ebFSX.Color := FaintRed;
      ebFSX.SetFocus;
      Application.ProcessMessages;
      end
     else
      begin
      ebFSX.Color := clDefault;
      ClearStatus;
      end;
except
   on EConvertError do
      begin
      OPFError('The X field size must be between ' + FloatToStr(MinField)
         + ' and '+ FloatToStr(MaxField) + ' cm');
      ebFSX.Color := FaintRed;
      ebFSX.SetFocus;
      Application.ProcessMessages;
      end;
   end; {of exception handler}
end;

procedure TOPFForm.ebFSYExit(Sender: TObject);
var Check      :double;
    Energy     :integer;
    MinField,
    MaxField   :double;

begin
try
   Check := 0;
   if ebFSY.Text <> '' then
      Check := StrToFloat(ebFSY.Text);
   Energy := CBEnergy.ItemIndex + 1;
   MinField := 4*TMR[Energy,0,1];
   MaxField := 4*TMR[Energy,0,Length(TMR[Energy,0]) - 1];
   if (Check < MinField) or (Check > MaxField) then
      begin
      OPFError('The Y field size must be between ' + FloatToStr(MinField)
         + ' and ' + FloatToStr(MaxField) + ' cm');
      ebFSY.Color := FaintRed;
      ebFSY.SetFocus;
      Application.ProcessMessages;
      end
     else
      begin
      ebFSY.Color := clDefault;
      ClearStatus;
      end;
except
   on EConvertError do
      begin
      OPFError('The Y field size must be between ' + FloatToStr(MinField)
         + ' and '+ FloatToStr(MaxField) + ' cm');
      ebFSY.Color := FaintRed;
      ebFSY.SetFocus;
      Application.ProcessMessages;
      end;
   end; {of exception handler}
end;

procedure TOPFForm.ebNFracExit(Sender: TObject);
var Check      :double;

begin
try
   Check := StrToFloat(ebNFrac.Text);
   if (Check < 1) or (Check > 50) then
      begin
      OPFError('The number of fractions must be between 1 and 50');
      ebNFrac.Color := FaintRed;
      ebNFrac.SetFocus;
      Application.ProcessMessages;
      end
     else
      begin
      ebNFrac.Color := clDefault;
      ClearStatus;
      end;
except
   on EConvertError do
      begin
      OPFError('The number of fractions must be between 1 and 50');
      ebNFrac.Color := FaintRed;
      ebNFrac.SetFocus;
      Application.ProcessMessages;
      end;
   end; {of exception handler}
end;


procedure TOPFForm.ebPNameChange(Sender: TObject);
begin
if Pat <> nil then Pat.PatRec.Changed := True;
end;


procedure TOPFForm.ebSSDExit(Sender: TObject);
var Check      :double;

begin
try
   Check := StrToFloat(ebSSD.Text);
   if (Check < 5) or (Check > 230) then
      begin
      OPFError('The source skin distance must be between 5 and 230 cm');
      ebSSD.Color := FaintRed;
      ebSSD.SetFocus;
      Application.ProcessMessages;
      end
     else
      begin
      ebSSD.Color := clDefault;
      ClearStatus;
      end;
except
   on EConvertError do
      begin
      OPFError('The source skin distance must be between 5 and 230 cm');
      ebSSD.Color := FaintRed;
      ebSSD.SetFocus;
      Application.ProcessMessages;
      end;
   end; {of exception handler}
end;


procedure TOPFForm.ebTDepthExit(Sender: TObject);
var Check      :double;

begin
try
   Check := StrToFloat(ebTDepth.Text);
   if (Check >= 0) and (Check < 30) then
      begin
      if ebTDepth.Enabled then
         ebTDepth.Color := clDefault
        else
         EbTDepth.Color := clInactiveCaption;
      ClearStatus;
      ebDiam.Text := FloatToStrF(Check*2,ffFixed,4,1);
      case CBTTech.ItemIndex of
         0: ebSSD.Text := FloatToStrF(100 - Check,ffFixed,4,1);
         1: ebSSD.Text := '100';
         2: if ebSSD.Text = '' then ebSSD.Text := '100';
        end;
      end
     else
      begin
      OPFError('The treatment depth must be between 0 and 30 cm');
      ebTDepth.Color := FaintRed;
      ebTDepth.SetFocus;
      Application.ProcessMessages;
      end;
except
   on EConvertError do
      begin
      OPFError('The treatment depth must be between 0 and 30 cm');
      ebTDepth.Color := FaintRed;
      ebTDepth.SetFocus;
      Application.ProcessMessages;
      end;
   end; {of exception handler}
end;


procedure TOPFForm.ebTDoseExit(Sender: TObject);
var Check      :double;

begin
try
   Check := StrToFloat(ebTDose.Text);
   if (Check < 0) or (Check > 100) then
      begin
      OPFError('The total dose must be between 0 and 100 Gy');
      OPFForm.ActiveControl := ebTDose;
      ebTDose.Color := FaintRed;
      ebTDose.SetFocus;
      Application.ProcessMessages;
      end
     else
      begin
      ClearStatus;
      ebTDose.Color := clDefault;
      end;
except
   on EConvertError do
      begin
      OPFError('The total dose must be between 0 and 100 Gy');
      OPFForm.ActiveControl := ebTDose;
      ebTDose.Color := FaintRed;
      ebTDose.SetFocus;
      Application.ProcessMessages;
      end;
   end; {of exception handler}
end;


procedure TOPFForm.ebWedgeExit(Sender: TObject);
var Check      :double;

begin
try
   Check := StrToFloat(ebWedge.Text);
   if (Check <= 0) or (Check > 1) then
      begin
      OPFError('The wedge factor must be between 0 and 1');
      ebWedge.Color := FaintRed;
      ebWedge.SetFocus;
      Application.ProcessMessages;
      end
     else
      begin
      ClearStatus;
      ebWedge.Color := clDefault;
      end;
except
   on EConvertError do
      begin
      OPFError('The wedge factor must be between 0 and 1');
      ebWedge.Color := FaintRed;
      ebWedge.SetFocus;
      Application.ProcessMessages;
      end;
   end; {of exception handler}
end;




initialization
  {$I opfunit.lrs}

end.

