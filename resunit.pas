unit resunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Menus,
  ExtCtrls, Buttons, PrintersDlgs, PReport, Printers, ComCtrls;
  
type

  { TResform }

  TResform = class(TForm)
     ImageList: TImageList;
     MainMenu1: TMainMenu;
     ExitMenu: TMenuItem;
     miSavePDF: TMenuItem;
     PReport: TPReport;
     PrintDialog: TPrintDialog;
     PrintMenu: TMenuItem;
     PRLabel1: TPRLabel;
     PRLabel10: TPRLabel;
     prlFileName: TPRLabel;
     PRLabel7: TPRLabel;
     prlEnergyLabel: TPRLabel;
     prlAPLATLabel: TPRLabel;
     prlXYLabel: TPRLabel;
     prlSSDLabel: TPRLabel;
     prlDiamLabel: TPRLabel;
     PRLabel16: TPRLabel;
     PRLabel17: TPRLabel;
     prlMaxD2: TPRLabel;
     prlDose1: TPRLabel;
     PRLabel19: TPRLabel;
     PRLabel2: TPRLabel;
     prlIso: TPRLabel;
     prlUser: TPRLabel;
     PRLabel22: TPRLabel;
     prlTMRLabel: TPRLabel;
     PRLabel24: TPRLabel;
     PRLabel25: TPRLabel;
     prlOPFLabel: TPRLabel;
     prlNormLabel: TPRLabel;
     prlEQSLabel: TPRLabel;
     prlDepthLabel: TPRLabel;
     PRLabel30: TPRLabel;
     PRLabel31: TPRLabel;
     PRLabel32: TPRLabel;
     PRLabel33: TPRLabel;
     PRLabel34: TPRLabel;
     prlDose2: TPRLabel;
     prlTableLabel: TPRLabel;
     prlPASD: TPRLabel;
     prlPTD: TPRLabel;
     prlPMD: TPRLabel;
     prlWedge: TPRLabel;
     prlTMR: TPRLabel;
     prlOPF: TPRLabel;
     prlNorm: TPRLabel;
     prlTable: TPRLabel;
     prlWedgeLabel: TPRLabel;
     prlDay2: TPRLabel;
     prlField2: TPRLabel;
     prlMU2: TPRLabel;
     prlTD2: TPRLabel;
     prlRD2: TPRLabel;
     prlMaxD1: TPRLabel;
     prlField1: TPRLabel;
     prlTSD: TPRLabel;
     prlDepth: TPRLabel;
     prlEQS: TPRLabel;
     prlTType: TPRLabel;
     prlFType: TPRLabel;
     prlDPF: TPRLabel;
     PRLabel3: TPRLabel;
     PRLabel4: TPRLabel;
     PRLabel5: TPRLabel;
     PRLabel6: TPRLabel;
     prlTULabel: TPRLabel;
     PRLabel8: TPRLabel;
     PRLabel9: TPRLabel;
     prlDiam: TPRLabel;
     prlAPLAT: TPRLabel;
     prlBDate: TPRLabel;
     prlComment: TPRLabel;
     prlXY: TPRLabel;
     prlDate: TPRLabel;
     prlDay1: TPRLabel;
     prlDiagnosis: TPRLabel;
     prlDRNo: TPRLabel;
     prlEnergy: TPRLabel;
     prlPType: TPRLabel;
     prlMachine: TPRLabel;
     prlMD: TPRLabel;
     prlMU1: TPRLabel;
     prlName: TPRLabel;
     prlpHeader: TPRLayoutPanel;
     prlpPatientP: TPRLayoutPanel;
     prlpPrescription: TPRLayoutPanel;
     prlpResults: TPRLayoutPanel;
     prlpTreatment: TPRLayoutPanel;
     prlRD1: TPRLabel;
     prlSSD: TPRLabel;
     prlTD1: TPRLabel;
     prlTDose: TPRLabel;
     prlTime: TPRLabel;
     prlTitle: TPRLabel;
     PRPage: TPRPage;
     PRRect1: TPRRect;
     PRRect2: TPRRect;
     PRRect5: TPRRect;
     PRRect6: TPRRect;
     PRRect7: TPRRect;
     SaveDialog: TSaveDialog;
     ScrollBox: TScrollBox;
     ToolBar1: TToolBar;
     tbPDF: TToolButton;
     ToolButton2: TToolButton;
     tbSave: TToolButton;
     ToolButton4: TToolButton;
     tbExit: TToolButton;
     procedure ExitMenuClick(Sender: TObject);
     procedure PrintMenuClick(Sender: TObject);
     procedure ResformCreate(Sender: TObject);
     procedure tbPDFClick(Sender: TObject);
  private
    { Private declarations }
    MuTum,                         {Monitor unit for Tumour dose}
    MuMax      :integer;           {Monitor units for Maximum dose}
    EQ,                            {equivalent square of field}
    XD,                            {X field size at Depth}
    YD,                            {Y field size at Depth}
    EQD,                           {equivalent field size at ssd}
    XDm,                           {X field size at Dmax}
    YDm,                           {Y field size at Dmax}
    EQDm,                          {equivalent field at Dmax}
    XSk,                           {X field size at skin}
    YSk,                           {Y field size at skin}
    EQSk,                          {equivalent field at skin}
    XEx,                           {X field size at skin exit}
    YEx,                           {Y field size at skin exit}
    EQEx,                          {equivalent field at skin exit}
    TmrD,                          {Tissue maximum ration of EQ at Depth}
    TmrDm,                         {Tmr of opposing field at Dmax}
    TmrSk,                         {Tmr of EQSk at skin}
    TmrEx,                         {Tmr of EQEx at skin exit}
    ST,                            {collimator output factor for field EQ}
    PD,                            {percentage depth dose at Depth}
    PDDm,                          {percentage depth dose at Dmax}
    PDSk,                          {percentage depth dose at skin}
    TD,                            {tumour dose when maximum dose given}
    MD,                            {maximum dose when tumour dose given}
    RD,                            {reference dose}
    SKDose,                        {dose to the skin}
    Dose        :double;           {Dose per fraction per field}
  public
    { public declarations }
  end; 

var
  Resform: TResform;

implementation

uses opfunit, loginunit, Strutils, LazFileUtils;

{ TResform }

procedure TResform.ResformCreate(Sender: TObject);
var I,L       :integer;

function EQF(X,Y:double):double;
{Calculates the equivalent square of the field defined by X,Y.}
begin
EQF := X*Y/(2*(X+Y));
end;

function TmrF(En:integer;d,Eq:double):double;
{calculates the tissue maximum ratio using the TMR tables}
var A,B,C,
    Z1,Z2,Z3,Z4,
    X1,X2,Y1,Y2:double;        {variables for regression}
    I,J,
    TMRL,TMRW  :integer;       {length and width of TMR array}

begin
I := 1;
J := 1;
TMRL := Length(TMR[En]) - 1;
TMRW := Length(TMR[En,0]) - 1;
while (TMR[En,I,0] < d) and (I < TMRL) do Inc(I);
while (TMR[En,0,J] < Eq) and (J < TMRW) do Inc(J);
if (J >= TMRW) and (Eq > 10) then
   ShowMessage('Warning! Max field size exceeded. Results may be unreliable.');
if (J < 0) then
   ShowMessage('Warning! Min field size exceeded. Results may be unreliable.');
if (I > 1) and (J > 1) then Z1 := TMR[En,I-1,J-1] else Z1 := TMR[En,I,J];
if (I > 1) then Z2 := TMR[En,I-1,J] else Z2 := TMR[En,I,J];
if (J > 1) then Z3 := TMR[En,I,J-1] else Z3 := TMR[En,I,J];
Z4 := TMR[En,I,J];
if (I > 1) then Y1 := TMR[En,I-1,0] else Y1 := TMR[En,I,0];
Y2 := TMR[En,I,0];
if (J > 1) then X1 := TMR[En,0,J-1] else X1 := TMR[En,0,J-1];
X2 := TMR[En,0,J];
if (Y1 - Y2) <> 0 then
   C := (Z1 + Z2 - Z3 - Z4)/(2*(Y1 - Y2))
  else
   C := 0;
if (X1 - X2) <> 0 then
   B := (Z1 - Z2 + Z3 - Z4)/(2*(X1 - X2))
  else
   B := 0;
A := (Z1 + Z2 + Z3 + Z4)/4 - B*(X1 + X2)/2 - C*(Y1+Y2)/2;
TmrF := A + B*Eq + C*d;
end;

function Attn(d,Eq:double):double;
{Calculates the attenuation of tissue thickness d for field size Eq}
begin
with Linac.LinacRec do
Attn := 0;
end;

function OutPutFac(En:Integer;EQ:double):double;
{Calculates the Output or Relative Dose Factor using a logarithmic fit}
begin
with Linac.LinacRec do
   OutPutFac := S[En,1] + S[En,2]*ln(S[En,3]*EQ + S[En,4]);
end;

begin
with Pat.PatRec do with Linac.LinacRec do
   begin
   I := Pat.PatRec.Energy;
   case Treatment of
      FixedSSD: with Linac.LinacRec do
         begin
         SSD := 100;
         case Fields of
            Opposing:
               begin
               Depth := Diam/2.0;
               end;
            Single:
               begin
               Diam := Depth*2;
               end;
           end;
         end;
      Isocentric: with Linac.LinacRec do
         begin
         SSD := SCD - Diam/2.0;
         case Fields of
            Opposing:
               begin
               Depth := Diam/2.0;
               end;
            Single:
               begin
               Diam := Depth*2;
               end;
           end;
         end;
      VarSSD:
         begin
         case Fields of
            Opposing:
               begin
               Depth := Diam/2.0;
               end;
            Single:
               begin
               Diam := Depth*2;
               end;
           end;
         end;
      end; {of case Treatment}

   {calculate equivalent field of collimator setting}
   EQ := EQF(FSX,FSY);

   {calculate equivalent square at treatment depth}
   XD := FSX*((SSD + Depth)/100);
   YD := FSY*((SSD + Depth)/100);
   EQD := EQF(XD,YD);

   {calculate equivalent field at Dmax}
   XDm := FSX*((SSD + DM[I])/100);
   YDm := FSY*((SSD + DM[I])/100);
   EQDm := EQF(XDm,YDm);

   {calculate equivalent field at skin entrance}
   XSk := FSX*(SSD/100);
   YSk := FSY*(SSD/100);
   EQSk := EQF(XSk,YSk);

   {calculate equivalent field at skin exit}
   XEx := FSX*((SSD + Diam)/100);
   YEx := FSY*((SSD + Diam)/100);
   EQEx := EQF(XEx,YEx);

   {calculate Tmr values}
   TmrD := TmrF(I,Depth,EQD);
   TmrDm := TmrF(I,Diam-DM[I],EQDm);
   TmrSk := TmrF(I,0.1,EQSk);
   TmrEx := TmrF(I,Diam,EQEx);

   {Calculate output factor}
   ST := OutPutFac(I,EQ);

   {Calculate monitor units}
   if Fields = Single then
      begin
      {calculate percentage depth doses}
      PD := 100*TmrD*sqr((SSD + DM[I])/(SSD + Depth));
      PDDm := 100;
      PDSk := 100*TmrSk*sqr((SSD + DM[I])/(SSD + 0.1));

      {divide dose by 1 to get fraction per beam}
      Dose := TDose/Frac;
      MuMax := Round(Dose*100/(ST*TrayFac*CFac*1*Sqr((100 + DM[I])/(SSD + DM[I]))))
      end
     else
      begin
      {calculate percentage depth doses}
      PD := 200*TmrD*sqr((SSD + DM[I])/(SSD + Depth));
      PDDm := 100 + 100*TmrDm*Sqr((SSD + DM[I])/(SSD + Diam -DM[I]));
      PDSk := 100*TmrSk*sqr((SSD + DM[I])/(SSD + 0.1)) +
              100*TmrEx*sqr((SSD + DM[I])/(SSD + Diam));

      {divide dose by 2 to get fraction per beam}
      Dose := TDose/(2*Frac);
      MuMax := Round(Dose*200/(ST*TrayFac*CFac*(1*Sqr((100 + DM[I])/(SSD + DM[I])) +
         TmrDm*Sqr((100 + Dm[I])/(SSD + Diam - DM[I])))));
      end;
   MuTum := Round(Dose*100/(TmrD*ST*TrayFac*CFac*Sqr((100 + DM[I])/(SSD + Depth))));

   {Calculate alternative dose values}
   MD := TDose*PDDm/(PD*Frac);
   TD := TDose*PD/(PDDm*Frac);
   RD := TDose*100/(PD*Frac);
   SKDose := PDSk*MD*Frac/PDDm;
   end;

{display results}
   prlTitle.Caption := Linac.LinacRec.Title;
   with Pat.PatRec do
      begin
      {print patient details}
      prlName.Caption := Pname;
      prlDRNo.Caption := DRNo;
      prlBDate.Caption := BDate;
      prlDiagnosis.Caption :=  Diagnosis;
      prlComment.Caption := Comment;

      {print prescription}
      prlTDose.Caption := FloatToStr(TDose) + 'Gy in ' + FloatToStr(Frac) + ' fractions';
      prlDPF.Caption := FloatToStrF(TDose/Frac,ffFixed,4,2) + ' Gy';
      case Prescript of
         Tumour: prlPType.Caption := 'Dose to tumour';
         Max:    prlPType.Caption := 'Dose to maximum';
         end;
      case Fields of
         Opposing : prlFType.Caption := 'Opposing fields';
         Single   : prlFType.Caption := 'Single field';
         end;
      case Treatment of
         FixedSSD:   prlTType.Caption := 'Fixed SSD';
         Isocentric: prlTType.Caption := 'Isocentric';
         VarSSD:     prlTType.Caption := 'Variable SSD';
         end;

      {print machine parameters}
      L := 0;
      prlMachine.Caption := Linac.LinacRec.Name;
      prlMachine.Top := L*15 + 20;
      prlTULabel.Top := L*15 + 20;
      Inc(L);

      prlEnergy.Caption := Linac.LinacRec.Energy[Energy];
      prlEnergy.Top := L*15 + 20;
      prlEnergyLabel.Top := L*15 + 20;
      Inc(L);

      case Present of
         AP:  prlAPLAT.Caption := 'Anterior/Posterior';
         Lat: prlAPLAT.Caption := 'Lateral';
        end;
      prlAPLAT.Top := L*15 + 20;
      prlAPLATLabel.Top := L*15 + 20;
      Inc(L);

      prlXY.Caption := 'Length(Y): ' + FloatToStrF(FSY,ffFixed,4,1) + ' cm, Breadth(X): ' +
         FloatToStrF(FSX,ffFixed,4,1) + ' cm';
      prlXY.Top := L*15 + 20;
      prlXYLabel.Top := L*15 + 20;
      Inc(L);

      prlEQS.Caption :=  FloatToStrF(EQ*4,ffFixed,4,1) + ' cm';
      prlEQS.Top := L*15 + 20;
      prlEQSLabel.Top := L*15 + 20;
      Inc(L);

      if Fields = Opposing then
         begin
         prlDiamLabel.Caption := 'Patient diameter:';
         prlDiam.Caption := FloatToStrF(Diam,ffFixed,4,1) + ' cm';
         prlDiam.Top := L*15 + 20;
         prlDiamLabel.Top := L*15 + 20;
         Inc(L);
         end
        else
         begin
         prlDiam.Caption := '';
         prlDiamLabel.Caption := '';
        end;

      prlDepth.Caption := FloatToStrF(Depth,ffFixed,4,1) + ' cm';
      prlDepth.Top := L*15 + 20;
      prlDepthLabel.Top := L*15 + 20;
      Inc(L);

      prlSSD.Caption := FloatToStrF(SSD,ffFixed,5,1) + ' cm';
      prlSSD.Top := L*15 + 20;
      prlSSDLabel.Top := L*15 + 20;
      Inc(L);

      prlTMR.Caption := FloatToStrF(TmrD,ffFixed,7,3);
      prlTMR.Top := L*15 + 20;
      prlTMRLabel.Top := L*15 + 20;
      Inc(L);

      prlOPF.Caption := FloatToStrF(ST,ffFixed,7,3);
      prlOPF.Top := L*15 + 20;
      prlOPFLabel.Top := L*15 + 20;
      Inc(L);

      prlNorm.Caption :=  FloatToStrF(TrayFac,ffFixed,7,3);
      prlNorm.Top := L*15 + 20;
      prlNormLabel.Top := L*15 + 20;
      Inc(L);

      prlTable.Caption := FloatToStrF(TableFac,ffFixed,7,3);
      prlTable.Top := L*15 + 20;
      prlTableLabel.Top := L*15 + 20;
      Inc(L);

      prlWedge.Caption := FloatToStrF(CFac,ffFixed,7,3);
      prlWedge.Top := L*15 + 20;
      prlWedgeLabel.Top := L*15 + 20;
      Inc(L);

      {print dose results}
      prlPASD.Caption := FloatToStrF(PDSk,ffFixed,7,1) + ' %';
      prlPTD.Caption := FloatToStrF(PD,ffFixed,7,1) + ' %';
      prlPMD.Caption := FloatToStrF(PDDm,ffFixed,7,1) + ' %';

      case Prescript of
         Tumour: begin
            prlDose1.Caption := 'Tumour Dose';
            prlDose2.Caption := 'Max Dose';
            prlDay1.Caption := '1-' + FloatToStr(Frac);
            prlField1.Caption := '1';
            prlMU1.Caption := IntToStr(Round(MuTum/TableFac));
            prlTD1.Caption := FloatToStrF(Dose,ffFixed,7,2) + ' Gy';
            prlMaxD1.Caption := FloatToStrF(MD,ffFixed,7,2) + ' Gy';
            prlRD1.Caption := FloatToStrF(RD,ffFixed,7,2) + ' Gy';
            if Fields <> Single then
               begin
               prlDay2.Caption := '1-' + FloatToStr(Frac);
               prlField2.Caption := '2';
               prlMU2.Caption := IntToStr(MuTum);
               prlTD2.Caption := FloatToStrF(Dose,ffFixed,7,2) + ' Gy';
               prlMaxD2.Caption := '';
               prlRD2.Caption := FloatToStrF(RD,ffFixed,7,2) + ' Gy';
               end
              else
               begin
               prlDay2.Caption := '';
               prlField2.Caption := '';
               prlMU2.Caption := '';
               prlTD2.Caption := '';
               prlMaxD2.Caption := '';
               prlRD2.Caption := '';
               end;
            prlIso.Caption := 'Total dose at maximum buildup:';
            prlMD.Caption := FloatToStrF(MD*Frac,ffFixed,7,2) + ' Gy';
            end;
         Max: begin
            prlDose1.Caption := 'Max Dose';
            prlDose2.Caption := 'Tumour Dose';
            prlDay1.Caption := '1-' + FloatToStr(Frac);
            prlField1.Caption := '1';
            prlMU1.Caption := IntToStr(Round(MuMax/TableFac));
            prlTD1.Caption := FloatToStrF(Dose,ffFixed,7,2) + ' Gy';
            prlMaxD1.Caption := FloatToStrF(TD,ffFixed,7,2) + ' Gy';
            prlRD1.Caption := FloatToStrF(RD,ffFixed,7,2) + ' Gy';
            if Fields <> Single then
               begin
               prlDay2.Caption := '1-' + FloatToStr(Frac);
               prlField2.Caption := '2';
               prlMU2.Caption := IntToStr(MuMax);
               prlTD2.Caption := FloatToStrF(Dose,ffFixed,7,2) + ' Gy';
               prlMaxD2.Caption := '';
               prlRD2.Caption := FloatToStrF(RD,ffFixed,7,2) + ' Gy';
               end
              else
               begin
               prlDay2.Caption := '';
               prlField2.Caption := '';
               prlMU2.Caption := '';
               prlTD2.Caption := '';
               prlMaxD2.Caption := '';
               prlRD2.Caption := '';
               end;
            prlIso.Caption := 'Total dose at the isocentre:';
            prlMD.Caption := FloatToStrF(TD*Frac,ffFixed,7,2) + ' Gy';
            end;
         end; {of case Prescript}
      prlTSD.Caption := FloatToStrF(SKDose,ffFixed,7,2) + ' Gy';
      prlUser.Caption := 'Calculated by: ' + User;
      prlDate.Caption := 'Date: ' + FormatDateTime('dd mmmm yyyy',Now);
      prlTime.Caption := 'Time: ' + FormatDateTime('HH:MM',Now);
      end;
end;

procedure TResform.tbPDFClick(Sender: TObject);
var sDataDir   :string;

begin
sDataDir := GetUserDir;
{$ifdef WIN32}
sDataDir := AppendPathdelim(sDataDir) + 'My Documents';
{$else}
sDataDir := AppendPathDelim(sDataDir) + 'Documents';
{$endif}
sDataDir := AppendPathdelim(sDataDir) + 'Patients';
if not DirectoryExists(sDataDir) then CreateDir(sDataDir);
sDataDir := AppendPathdelim(sDataDir) + FormatDateTime('yyyy',Date);
if not DirectoryExists(sDataDir) then CreateDir(sDataDir);
sDataDir := AppendPathdelim(sDataDir) + FormatDateTime('mmMMMM',Date);
if not DirectoryExists(sDataDir) then CreateDir(sDataDir);
SaveDialog.InitialDir := sDataDir;
SaveDialog.FileName := DelSpace(Pat.PatRec.Pname) + DelSpace(Pat.PatRec.DRNo) + '.pdf';

if SaveDialog.Execute then with PReport do
   begin
   Filename := SaveDialog.FileName;
   prlFileName.Caption := FileName;
   BeginDoc;
   Print(PRPage);
   EndDoc;
   end;
end;

procedure TResform.ExitMenuClick(Sender: TObject);
begin
close;
end;


procedure TResform.PrintMenuClick(Sender: TObject);
var sDataDir   :string;
    X1,X2,X3,
    Y1,Y2,Y3,
    XDI,
    YDI,
    I,J        :integer;
    XS,                        {x scale}
    YS         :double;        {y scale}
    iRect      :TRect;

begin
sDataDir := GetUserDir;
{$ifdef WIN32}
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

with PReport do
   begin
   Filename := AppendPathDelim(sDataDir) + FormatDateTime('yyyymmddHHMMss',Now) +
      DelSpace(Pat.PatRec.Pname) + DelSpace(Pat.PatRec.DRNo) + '.pdf';
   prlFileName.Caption := FileName;
   BeginDoc;
   Print(PRPage);
   EndDoc;
   end;

if PrintDialog.Execute then with Printer do
   begin
   BeginDoc;
   Canvas.Font.Name := 'Arial';
   XDI := Printer.XDPI;
   YDI := Printer.YDPI;
   XS := XDI/72.0;
   YS := YDI/72.0;

   for I:=0 to PRPage.ControlCount - 1 do
      begin
      if (PRPage.Controls[I] is TPRLayoutPanel) then
         with (PRPage.Controls[I] as TPRLayoutPanel) do
            begin
            X1 := Round(Left*XS);
            X2 := X1;
            Y1 := Round(Top*YS);
            Y2 := Y1;
            Printer.Canvas.Font.Size := 12;
            if Caption <> '' then
               Printer.Canvas.TextOut(X1,Y1,Caption);
            for J:=0 to ControlCount - 1 do
               begin
               if Controls[J] is TPRLabel then
                  with Controls[J] as TPRLabel do
                     begin
                     X2 := X1 + Round(Left*XS);
                     Y2 := Y1 + Round(Top*YS);
                     Printer.Canvas.Font.Size := Round(FontSize);
                     if Caption <> '' then
                        begin
                        if Alignment = taCenter then
                           X2 := X2 + Round((Width*XS -
                           Printer.Canvas.TextWidth(Caption))/2);
                        Printer.Canvas.TextOut(X2,Y2,Caption);
                        end;
                     end;
               if Controls[J] is TPRRect then
                  with Controls[J] as TPRRect do
                     begin
                     X2 := X1 + Round(Left*XS);
                     Y2 := Y1 + Round(Top*YS);
                     X3 := X1 + Round((Left + Width)*XS);
                     Y3 := Y1 + Round((Top + Height)*YS);
                     Printer.Canvas.Rectangle(X2,Y2,X3,Y3);
                     end;
               if Controls[J] is TPRImage then
                  with Controls[J] as TPRImage do
                     begin
                     X2 := X1 + Round(Left*XS);
                     Y2 := Y1 + Round(Top*YS);
                     X3 := X1 + Round((Left + Width)*XS);
                     Y3 := Y1 + Round((Top + Height)*YS);
                     iRect := Rect(X2,Y2,X3,Y3);
                     Printer.Canvas.StretchDraw(iRect,Picture.Bitmap);
                     end;
               end;
            end;
      end;

   EndDoc;
   end;
end;



initialization
  {$I resunit.lrs}

end.

