unit beamunit;
{7/6/2005 ported to Linux using lazarus and Free Pascal Compiler
used CRC check instead of checksum for file verification
1/8/2005 added text export and import
4/4/2008 use text beam definition file instead of binary to solve field
alignment problem. Removed text import and export.beamunit
2/4/2008 version 3 use TMR tables instead of Prof Strydom's equation
1/2/2011 fixed dynamic array reference problem for CRC
1/2/2011 fixed date format problem
24/5/2019 fixed empty cell and data bugs
28/2/2020 remove definitions and use from opfunit
24/3/2020 store all beam config files automatically in program config dir}

{$mode DELPHI}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, Grids, Buttons, Printer, PrintersDlgs, StrUtils, opfunit;

const NE = 5;                      {number of energies}
      NFS = 15;                    {number of field sizes}

type
   { TBeamForm }

   TBeamForm = class(TForm)
      bbPrint: TBitBtn;
     bbFinish: TBitBtn;
     bbNext: TBitBtn;
     bbBack: TBitBtn;
     bbOpen: TBitBtn;
     bbImportTMR: TBitBtn;
     ebTitle: TEdit;
     ebMName: TEdit;
     ebNoE: TEdit;
     ebEDate: TEdit;
     Label1: TLabel;
     Label10: TLabel;
     Label11: TLabel;
     Label12: TLabel;
     Label13: TLabel;
     Label14: TLabel;
     Label16: TLabel;
     Label2: TLabel;
     Label3: TLabel;
     Label4: TLabel;
     Label5: TLabel;
     Label6: TLabel;
     Label7: TLabel;
     Label8: TLabel;
     Label9: TLabel;
     OpenDialog: TOpenDialog;
     PageControl: TPageControl;
     PrintDialog: TPrintDialog;
     sgTable: TStringGrid;
     sgTray: TStringGrid;
     sgOPF: TStringGrid;
     tsOutFact: TTabSheet;
     tsEnergies: TTabSheet;
     sgEnergy: TStringGrid;
     sgDmax: TStringGrid;
     tsFactors: TTabSheet;
     procedure BeamFormCreate(Sender: TObject);
     procedure PageControlChange(Sender: TObject);
     procedure bbBackClick(Sender: TObject);
     procedure bbExportClick(Sender: TObject);
     procedure bbImportClick(Sender: TObject);
     procedure bbImportTMRClick(Sender: TObject);
     procedure bbNextClick(Sender: TObject);
     procedure bbPrintClick(Sender: TObject);
     procedure tsEnergiesExit(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
   BeamForm:   TBeamForm;
   Linac:      TLinac;
   TMRTabs:    boolean;
   TMRData:    array[1..NE] of TStringGrid;
   TMR:        TTmr;

implementation

uses CRC32, LazFileUtils;

{ TBeamForm }

procedure TBeamForm.BeamFormCreate(Sender: TObject);
var I          :integer;

begin
ebTitle.Text := 'Your site name here';
ebMName.Text := 'Generic';
ebNoE.Text := '0';
ebEDate.Text := DateToStr(Now);
bbBack.Enabled := False;
bbBack.Visible := False;
bbImportTMR.Enabled := False;
bbImportTMR.Visible := False;
PageControl.ActivePageIndex := 0;
TMRTabs := False;
for I:=1 to NE do TMRData[I] := nil;
end;


procedure TBeamForm.PageControlChange(Sender: TObject);
begin
if PageControl.ActivePageIndex = 0 then
   begin
   bbBack.Enabled := False;
   bbBack.Visible := False;
   end;
if (not bbBack.Enabled) and (PageControl.ActivePageIndex > 0) then
   begin
   bbBack.Enabled := True;
   bbBack.Visible := True;
   end;
if (not bbNext.Enabled) and (PageControl.ActivePageIndex < PageControl.PageCount - 1) then
   begin
   bbNext.Enabled := True;
   bbNext.Visible := True;
   end;
if PageControl.ActivePageIndex = PageControl.PageCount - 1 then
   begin
   bbNext.Enabled := False;
   bbNext.Visible := False;
   bbImportTMR.Enabled:= True;
   bbImportTMR.Visible:= True;
   end;
if PageControl.ActivePageIndex > 2 then
   begin
   bbImportTMR.Enabled:= True;
   bbImportTMR.Visible:= True;
   end
  else
   begin
   bbImportTMR.Enabled:= False;
   bbImportTMR.Visible:= False;
   end;
end;

procedure TBeamForm.bbBackClick(Sender: TObject);
begin
if PageControl.ActivePageIndex > 0 then
 PageControl.ActivePageIndex := PageControl.ActivePageIndex - 1;
 PageControlChange(Sender);
end;

procedure TBeamForm.bbExportClick(Sender: TObject);
var Outfile,Lst:   Textfile;           {text file for output}
    I,J,K:     integer;            {loop variables}
    CRCValue   :dword;             {holder for checksum}
    Size       :integer;           {size of field}
    sDataPath  :string;            {program data dir}
    CellVal    :double;            {value of the cell}

begin
if Linac = nil then Linac := TLinac.Create;

{Transfer data to linac}
with Linac.LinacRec do
   begin
   Title := ebTitle.Text;
   Name := ebMName.Text;
   NoE := StrToInt(ebNoE.Text);
   EDate := StrToDate(EBEDate.Text);
   for I:=1 to NoE do
      begin
      Energy[I] := SGEnergy.Cells[1,I];
      if SGDmax.Cells[1,I] <> '' then
         DM[I] := StrToFloat(SGDmax.Cells[1,I]);
      if SGTable.Cells[1,I]<> '' then
         Table[I] := StrToFloat(SGTable.Cells[1,I]);
      for J:=1 to 5 do
         if SGTray.Cells[J-1,I] <> '' then
            Tray[I,J] := StrToFloat(SGTray.Cells[J-1,I]);
      for J:=1 to 7 do
         if sgOPF.Cells[J,I] <> '' then
            S[I,J] := StrToFloat(sgOPF.Cells[J,I]);
      if TMRData[I] <> nil then with TMRData[I] do
         begin
         SetLength(TMR[I],RowCount,ColCount);
         for J:=0 to RowCount - 1 do
            begin
            for K:=0 to ColCount - 1 do
               begin
               try
                  CellVal := StrToFloat(Cells[K,J])
                  except
                  CellVal := 0;
                  end;
               TMR[I,J,K] := CellVal;
               end;
            end;
         end;
      end;

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
   Linac.LinacRec.Checksum := CRCValue;

   {get path to program config data}
   {$ifdef WINDOWS}
   sDataPath := GetAppConfigDir(true);
   {$else}
   sDataPath := GetAppConfigDir(false);
   {$endif}

   {write data to text file}
   sDataPath := AppendPathDelim(sDataPath) + Linac.LinacRec.Name + '.bdf';
   AssignFile(OutFile,sDataPath);
   Rewrite(Outfile);
   Writeln(Outfile,Checksum);
   Writeln(Outfile,Title);
   Writeln(Outfile,Name);
   Writeln(Outfile,Noe);
   Writeln(Outfile,EDate);
   for I:=1 to NoE do
      begin
      Writeln(Outfile,Energy[I]);
      Writeln(Outfile,DM[I]:4:3);
      Writeln(Outfile,Table[I]:4:3);
      for J:=1 to 5 do Write(Outfile,Tray[I,J]:4:3,' ');
      writeln(Outfile);
      for J:=1 to 6 do Write(Outfile,S[I,J]:9:8,' ');
      writeln(Outfile,S[I,7]:9:8);
      writeln(Outfile,Length(TMR[I]));
      if length(TMR[I]) > 0 then writeln(Outfile,Length(TMR[I,0]))
         else writeln(Outfile,0);
      for J:=0 to Length(TMR[I]) - 1 do
         begin
         for K:=0 to Length(TMR[I,J]) - 1 do
             Write(Outfile,TMR[I,J,K]:5:3,'  ');
         Writeln(Outfile);
         end;
      end;
   Closefile(Outfile);
   Linac.Free;
   Close;
   end;
end;



procedure TBeamForm.bbImportClick(Sender: TObject);
var TMRL,                          {Number of TMR rows}
    TMRW,                          {Number of TMR columns}
    I,J,K      :integer;           {counters for loop}
    Infile     :Textfile;          {input file for data}
    Size       :integer;           {size of field}
    CRCValue   :dword;             {holder for checksum}
    sExePath   :string;
    tsEnergy   :TTabSheet;          {Tabsheet for energies}
    sgTMR      :TStringGrid;        {string grid to display TMRs}

begin
{Set directory path to program files}
sExePath := ExtractFilePath(Application.ExeName);
SetCurrentDir(sExePath);
OpenDialog.FilterIndex := 1;

if OpenDialog.Execute then
   begin
   if Linac = nil then Linac := TLinac.Create;
   TMRTabs := True;
   
   with Linac.LinacRec do
      begin

      {read data from disk}
      try
         AssignFile(Infile,OpenDialog.FileName);
         Reset(Infile);
         Readln(Infile,Checksum);
         Readln(Infile,Title);
         Readln(Infile,Name);
         Readln(Infile,Noe);
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
            SetLength(TMR[I],TMRL,TMRW);
            for J:=0 to TMRL - 1 do
               begin
               for K:=0 to TMRW - 1 do
                  Read(Infile,TMR[I,J,K]);
               end;
            Readln(Infile);
            end;
         CloseFile(Infile);
      except
         ShowMessage('File error, could not read data file');
         end;


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
         ShowMessage('Integrity of beam data file has been compromised');

      {clear previous energy tabsheets}
      I := 1;
      while PageControl.PageCount > 3 do
         begin
         PageControl.ActivePageIndex := 3;
         tsEnergy := PageControl.ActivePage;
         tsEnergy.PageControl := nil;
         tsEnergy.Free;
         if tmrData[I] <> nil then tmrData[I].Free;
         tmrData[I] := nil;
         inc(I);
         end;
         
      {transfer data to form}
      ebTitle.Text := Title;
      ebMName.Text := Name;
      ebNoE.Text := IntToStr(NoE);
      EBEDate.Text := DateToStr(EDate);
      for I:=1 to NoE do
         begin
         SGEnergy.Cells[1,I] := Energy[I];
         SGDmax.Cells[1,I] := FloatToStrF(DM[I],ffFixed,4,1);
         SGTable.Cells[1,I] := FloatToStrF(Table[I],ffFixed,7,3);
         for J:=1 to 5 do SGTray.Cells[J-1,I] := FloatToStrF(Tray[I,J],ffFixed,7,3);
         for J:=1 to 7 do sgOPF.Cells[J,I] := FloatToStrF(S[I,J],ffFixed,15,8);

         {create tabsheet}
         tsEnergy := TTabSheet.create(self);
         tsEnergy.PageControl := PageControl;
         tsEnergy.Name := 'ts' + DelSpace(Energy[I]);
         tsEnergy.Caption := Energy[I];
         PageControl.ActivePage := tsEnergy;
         
         {create string grid}
         sgTMR := TStringGrid.Create(Self);
         with sgTMR do
            begin
            Name := 'sg' + tsEnergy.Name;
            Visible := True;
            SetBounds(0,0,580,200);
            ColCount := TMRW;
            RowCount := TMRL;
            Parent := PageControl.ActivePage;
            end;
         TMRData[I] := sgTMR;
         
         {copy data to string grid}
         for J:=0 to sgTMR.RowCount - 1 do
            for K:=0 to sgTMR.ColCount - 1 do
               sgTMR.Cells[K,J] := FloatToStrF(TMR[I,J,K],ffFixed,4,3);
         end;
      end;
   Linac.Free;
   Linac := nil;
   end;
end;


procedure TBeamForm.bbImportTMRClick(Sender: TObject);
var sgTMR:     TStringGrid;
    Lines:     TStringList;
    I,J:       integer;
    CelText,
    LineText,
    sExePath:  string;

begin
{Set directory path to program files}
sExePath := ExtractFilePath(Application.ExeName);
SetCurrentDir(sExePath);
with OpenDialog do
   begin
   DefaultExt  := '.bdf';
   Filter := 'Comma delimited | *.csv |Beam Data Files | *.bdf|Text Files|*.txt|All files|*.*';
   OpenDialog.FilterIndex := 1;
   end;

if OpenDialog.Execute then
   begin
   {Read in file}
   Lines := TStringList.Create;
   Lines.LoadFromFile(OpenDialog.FileName);

   {create stringGrid}
   if TMRData[PageControl.ActivePageIndex - 2] <> nil then
      begin
      TMRData[PageControl.ActivePageIndex - 2].Free;
      TMRData[PageControl.ActivePageIndex - 2] := nil;
      end;
   sgTMR := TStringGrid.Create(Self);
   with sgTMR do
      begin
      Name := 'sg' + PageControl.ActivePage.Name;
      Visible := True;
      SetBounds(0,0,580,200);
      ColCount := StrToInt(Copy2Symb(Lines[0],','));
      RowCount := StrToInt(Copy2Symb(Lines[1],','));
      Parent := PageControl.ActivePage;
      end;
   TMRData[PageControl.ActivePageIndex - 2] := sgTMR;

   {copy file to stringgrid}
   for I:= 0 to sgTMR.RowCount - 1 do
      begin
      J := 0;
      LineText := Lines[I+2];
         repeat
         CelText := Copy2SymbDel(LineText,',');
         sgTMR.Cells[J,I] := CelText;
         Inc(J);
         until LineText = ''
      end;
   end;
end;


procedure TBeamForm.bbNextClick(Sender: TObject);
begin
if PageControl.ActivePageIndex < PageControl.PageCount - 1 then
   PageControl.ActivePageIndex := PageControl.ActivePageIndex + 1;
PageControlChange(Sender);
end;



procedure TBeamForm.bbPrintClick(Sender: TObject);
{This procedure prints the beam file data}

var I,J        :integer;           {counters for loops}
    Lst        :Textfile;

begin
Linac := Tlinac.Create;

{Transfer data to linac}
with Linac.LinacRec do
   begin
   Title := ebTitle.Text;
   Name := ebMName.Text;
   NoE := StrToInt(ebNoE.Text);
   EDate := StrToDate(EBEDate.Text);
   for I:=1 to NoE do
      begin
      Energy[I] := SGEnergy.Cells[1,I];
      DM[I] := StrToFloat(SGDmax.Cells[1,I]);
      Table[I] := StrToFloat(SGTable.Cells[1,I]);
      for J:=1 to 5 do Tray[I,J] := StrToFloat(SGTray.Cells[J-1,I]);
      for J:=1 to 7 do S[I,J] := StrToFloat(sgOPF.Cells[J,I]);
      end;
   end;

{send data to printer}
if PrintDialog.Execute then with Linac.LinacRec do
   begin
   try
//      AssignPrn(Lst,'| kprinter');
//      Rewrite(Lst);
//      Writeln(Lst);
//      Writeln(Lst);}
{      Printer.Canvas.Font.Name := 'Courier New';
      Printer.Canvas.Font.Size := 10; }
//      Write(Lst,'          ');
{      Printer.Canvas.Font.Name := 'Times New Roman';
      Printer.Canvas.Font.Style := [fsUnderline];
      Printer.Canvas.Font.Size := 28;       }
//      Writeln(Lst,Title,' - ',Name);
{      Printer.Canvas.Font.Name := 'Courier New';
      Printer.Canvas.Font.Style := [];
      Printer.Canvas.Font.Size := 10;        }
//      Writeln(Lst);
//      Writeln(Lst);
//      Writeln(Lst,'          Program expiry date: ',DateToStr(EDate));
//      Writeln(Lst,'          Number of photon energies: ',NoE);
//      Writeln(Lst);
//      Write(Lst,'          Beam number: ');
//      for I:=1 to NoE do Write(Lst,I:12);
//      Writeln(Lst);
//      Write(Lst,'          Energy:      ');
//      for I:=1 to NoE do Write(Lst,Energy[I]:12);
//      Writeln(Lst);
//      Write(Lst,'          Dmax:        ');
//      for I:=1 to NoE do Write(Lst,DM[I]:12:1);
//      Writeln(Lst);
//      Write(Lst,'          Table Factors');
//      for I:=1 to NoE do Write(Lst,Table[I]:12:4);
//      Writeln(Lst);
//      Writeln(Lst,'          Tray Factors ');
//      for J:=1 to 5 do
//         begin
//         Write(Lst,'          Tray: ',J:2);
//         for I:=1 to NoE do Write(Lst,Tray[I,J]:12:4);
//         Writeln(Lst);
//         end;
//      Writeln(Lst);
//      Writeln(Lst);
//      Writeln(Lst,'          Regression parameters for Output factors');
//      Write(Lst,'          Beam number: ');
//      for I:=1 to NoE do Write(Lst,I:12);
//      Writeln(Lst);
//      for J:=1 to 7 do
//         begin
//         Write(Lst,'          Parameter: ',J:2);
//         for I:=1 to NoE do Write(Lst,S[I,J]:12:8);
//         Writeln(Lst);
//         end;
//      Writeln(Lst);
   finally
//      CloseFile(Lst);
      end;
   end;
Linac.Free;
end;


procedure TBeamForm.tsEnergiesExit(Sender: TObject);
var I,
    NumTabs:   integer;            {number of tabs to create}
    tsEnergy:  TTabSheet;

begin
if not TMRTabs then
   begin
   NumTabs := StrToInt(ebNoE.Text);
   for I:=1 to NumTabs do
      begin
      tsEnergy := TTabSheet.create(self);
      tsEnergy.PageControl := PageControl;
      tsEnergy.Name := 'ts' + DelSpace(sgEnergy.Cells[1,I]);
      tsEnergy.Caption := sgEnergy.Cells[1,I];
      end;
   TMRTabs := True;
   end;
end;


initialization
  {$I beamunit.lrs}

end.

