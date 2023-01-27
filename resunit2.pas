unit resunit2;

{$mode ObjFPC}{$H+}

interface

uses
   Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Menus,
   ComCtrls, ExtCtrls, StdCtrls;

type

   { TResForm2 }

   TResForm2 = class(TForm)
      gbPatientP: TGroupBox;
      gbPrescription: TGroupBox;
      gbTreatment: TGroupBox;
      gbResults: TGroupBox;
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
      lDose1: TLabel;
      lDose2: TLabel;
      Label20: TLabel;
      lUser: TLabel;
      Label23: TLabel;
      lDate: TLabel;
      lTime: TLabel;
      lFileName: TLabel;
      Label27: TLabel;
      lMD: TLabel;
      lTSD: TLabel;
      lIso: TLabel;
      Label22: TLabel;
      lPASD: TLabel;
      lPTD: TLabel;
      lPMD: TLabel;
      lDay1: TLabel;
      lField1: TLabel;
      lMU1: TLabel;
      lTD1: TLabel;
      lMaxD1: TLabel;
      lRD1: TLabel;
      lDay2: TLabel;
      lField2: TLabel;
      lMU2: TLabel;
      lTD2: TLabel;
      lMaxD2: TLabel;
      lRD2: TLabel;
      lMachine: TLabel;
      lEnergy: TLabel;
      lAPLAT: TLabel;
      lXY: TLabel;
      lEQS: TLabel;
      lDiam: TLabel;
      lDepth: TLabel;
      lSSD: TLabel;
      lTMR: TLabel;
      lOPF: TLabel;
      lNorm: TLabel;
      lTable: TLabel;
      lWedge: TLabel;
      lTULabel: TLabel;
      lEnergyLabel: TLabel;
      lAPLATLabel: TLabel;
      lXYLabel: TLabel;
      lEQSLabel: TLabel;
      lDiamLabel: TLabel;
      lDepthLabel: TLabel;
      lSSDLabel: TLabel;
      lTMRLabel: TLabel;
      lOPFLabel: TLabel;
      lNormLabel: TLabel;
      lTableLabel: TLabel;
      lWedgeLabel: TLabel;
      lTDose: TLabel;
      lDPF: TLabel;
      lPType: TLabel;
      lFType: TLabel;
      lTType: TLabel;
      Label7: TLabel;
      Label8: TLabel;
      Label9: TLabel;
      lDiagnosis: TLabel;
      lComment: TLabel;
      Label2: TLabel;
      Label3: TLabel;
      Label4: TLabel;
      Label5: TLabel;
      Label6: TLabel;
      lName: TLabel;
      lDRNo: TLabel;
      lBDate: TLabel;
      lTitle: TLabel;
      MainMenu: TMainMenu;
      miExit: TMenuItem;
      miSavePDF: TMenuItem;
      pPage: TPanel;
      pHeader: TPanel;
      pFooter: TPanel;
      SaveDialog: TSaveDialog;
      ScrollBox: TScrollBox;
      Shape1: TShape;
      Shape2: TShape;
      ToolBar: TToolBar;
      tbSavePDF: TToolButton;
      ToolButton1: TToolButton;
      tbExit: TToolButton;
      procedure FormCreate(Sender: TObject);
      procedure miExitClick(Sender: TObject);
      procedure miSavePDFClick(Sender: TObject);
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

   end;

var
   ResForm2: TResForm2;

implementation

uses opfunit, loginunit, form2pdf, LazFileUtils;

{ TResForm2 }

procedure TResForm2.FormCreate(Sender: TObject);
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
   lTitle.Caption := Linac.LinacRec.Title;
   with Pat.PatRec do
      begin
      {print patient details}
      lName.Caption := Pname;
      lDRNo.Caption := DRNo;
      lBDate.Caption := BDate;
      lDiagnosis.Caption :=  Diagnosis;
      lComment.Caption := Comment;

      {print prescription}
      lTDose.Caption := FloatToStr(TDose) + ' Gy in ' + FloatToStr(Frac) + ' fractions';
      lDPF.Caption := FloatToStrF(TDose/Frac,ffFixed,4,2) + ' Gy';
      case Prescript of
         Tumour: lPType.Caption := 'Dose to tumour';
         Max:    lPType.Caption := 'Dose to maximum';
         end;
      case Fields of
         Opposing : lFType.Caption := 'Opposing fields';
         Single   : lFType.Caption := 'Single field';
         end;
      case Treatment of
         FixedSSD:   lTType.Caption := 'Fixed SSD';
         Isocentric: lTType.Caption := 'Isocentric';
         VarSSD:     lTType.Caption := 'Variable SSD';
         end;

      {print machine parameters}
      L := 0;
      lMachine.Caption := Linac.LinacRec.Name;
      lMachine.Top := L*15;
      lTULabel.Top := L*15;
      Inc(L);

      lEnergy.Caption := Linac.LinacRec.Energy[Energy];
      lEnergy.Top := L*15;
      lEnergyLabel.Top := L*15;
      Inc(L);

      case Present of
         AP:  lAPLAT.Caption := 'Anterior/Posterior';
         Lat: lAPLAT.Caption := 'Lateral';
        end;
      lAPLAT.Top := L*15;
      lAPLATLabel.Top := L*15;
      Inc(L);

      lXY.Caption := 'Length(Y): ' + FloatToStrF(FSY,ffFixed,4,1) + ' cm, Breadth(X): ' +
         FloatToStrF(FSX,ffFixed,4,1) + ' cm';
      lXY.Top := L*15;
      lXYLabel.Top := L*15;
      Inc(L);

      lEQS.Caption :=  FloatToStrF(EQ*4,ffFixed,4,1) + ' cm';
      lEQS.Top := L*15;
      lEQSLabel.Top := L*15;
      Inc(L);

      if Fields = Opposing then
         begin
         lDiamLabel.Caption := 'Patient diameter:';
         lDiam.Caption := FloatToStrF(Diam,ffFixed,4,1) + ' cm';
         lDiam.Top := L*15;
         lDiamLabel.Top := L*15;
         Inc(L);
         end
        else
         begin
         lDiam.Caption := '';
         lDiamLabel.Caption := '';
        end;

      lDepth.Caption := FloatToStrF(Depth,ffFixed,4,1) + ' cm';
      lDepth.Top := L*15;
      lDepthLabel.Top := L*15;
      Inc(L);

      lSSD.Caption := FloatToStrF(SSD,ffFixed,5,1) + ' cm';
      lSSD.Top := L*15;
      lSSDLabel.Top := L*15;
      Inc(L);

      lTMR.Caption := FloatToStrF(TmrD,ffFixed,7,3);
      lTMR.Top := L*15;
      lTMRLabel.Top := L*15;
      Inc(L);

      lOPF.Caption := FloatToStrF(ST,ffFixed,7,3);
      lOPF.Top := L*15;
      lOPFLabel.Top := L*15;
      Inc(L);

      lNorm.Caption :=  FloatToStrF(TrayFac,ffFixed,7,3);
      lNorm.Top := L*15;
      lNormLabel.Top := L*15;
      Inc(L);

      lTable.Caption := FloatToStrF(TableFac,ffFixed,7,3);
      lTable.Top := L*15;
      lTableLabel.Top := L*15;
      Inc(L);

      lWedge.Caption := FloatToStrF(CFac,ffFixed,7,3);
      lWedge.Top := L*15;
      lWedgeLabel.Top := L*15;
      Inc(L);

      {print dose results}
      lPASD.Caption := FloatToStrF(PDSk,ffFixed,7,1) + ' %';
      lPTD.Caption := FloatToStrF(PD,ffFixed,7,1) + ' %';
      lPMD.Caption := FloatToStrF(PDDm,ffFixed,7,1) + ' %';

      case Prescript of
         Tumour: begin
            lDose1.Caption := 'Tumour Dose';
            lDose2.Caption := 'Max Dose';
            lDay1.Caption := '1-' + FloatToStr(Frac);
            lField1.Caption := '1';
            lMU1.Caption := IntToStr(Round(MuTum/TableFac));
            lTD1.Caption := FloatToStrF(Dose,ffFixed,7,2) + ' Gy';
            lMaxD1.Caption := FloatToStrF(MD,ffFixed,7,2) + ' Gy';
            lRD1.Caption := FloatToStrF(RD,ffFixed,7,2) + ' Gy';
            if Fields <> Single then
               begin
               lDay2.Caption := '1-' + FloatToStr(Frac);
               lField2.Caption := '2';
               lMU2.Caption := IntToStr(MuTum);
               lTD2.Caption := FloatToStrF(Dose,ffFixed,7,2) + ' Gy';
               lMaxD2.Caption := '';
               lRD2.Caption := FloatToStrF(RD,ffFixed,7,2) + ' Gy';
               end
              else
               begin
               lDay2.Caption := '';
               lField2.Caption := '';
               lMU2.Caption := '';
               lTD2.Caption := '';
               lMaxD2.Caption := '';
               lRD2.Caption := '';
               end;
            lIso.Caption := 'Total dose at maximum buildup:';
            lMD.Caption := FloatToStrF(MD*Frac,ffFixed,7,2) + ' Gy';
            end;
         Max: begin
            lDose1.Caption := 'Max Dose';
            lDose2.Caption := 'Tumour Dose';
            lDay1.Caption := '1-' + FloatToStr(Frac);
            lField1.Caption := '1';
            lMU1.Caption := IntToStr(Round(MuMax/TableFac));
            lTD1.Caption := FloatToStrF(Dose,ffFixed,7,2) + ' Gy';
            lMaxD1.Caption := FloatToStrF(TD,ffFixed,7,2) + ' Gy';
            lRD1.Caption := FloatToStrF(RD,ffFixed,7,2) + ' Gy';
            if Fields <> Single then
               begin
               lDay2.Caption := '1-' + FloatToStr(Frac);
               lField2.Caption := '2';
               lMU2.Caption := IntToStr(MuMax);
               lTD2.Caption := FloatToStrF(Dose,ffFixed,7,2) + ' Gy';
               lMaxD2.Caption := '';
               lRD2.Caption := FloatToStrF(RD,ffFixed,7,2) + ' Gy';
               end
              else
               begin
               lDay2.Caption := '';
               lField2.Caption := '';
               lMU2.Caption := '';
               lTD2.Caption := '';
               lMaxD2.Caption := '';
               lRD2.Caption := '';
               end;
            lIso.Caption := 'Total dose at the isocentre:';
            lMD.Caption := FloatToStrF(TD*Frac,ffFixed,7,2) + ' Gy';
            end;
         end; {of case Prescript}
      lTSD.Caption := FloatToStrF(SKDose,ffFixed,7,2) + ' Gy';
      lUser.Caption := 'Calculated by: ' + User;
      lDate.Caption := 'Date: ' + FormatDateTime('dd mmmm yyyy',Now);
      lTime.Caption := 'Time: ' + FormatDateTime('HH:MM',Now);
      end;
end;


procedure TResForm2.miExitClick(Sender: TObject);
begin
close;
end;


procedure TResForm2.miSavePDFClick(Sender: TObject);
var sDataDir,
    Dummy      :string;
    I,
    Error      :integer;

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
SaveDialog.FileName := ToAlphaNum(Pat.PatRec.Pname) + ToAlphaNum(Pat.PatRec.DRNo) + '.pdf';

if SaveDialog.Execute then
   begin
   FormToPDF;
   FDoc.SetMargins(0,0,36,36,36,36);
   Dummy := SaveDialog.FileName;
   I := lFileName.Canvas.TextWidth(Dummy);
   if I >= lFileName.Width then
      Dummy := leftStr(Dummy, round(Length(Dummy)*lFileName.Width/(2*I) - 1)) + '...'
         + RightStr(Dummy, round(Length(Dummy)*lFileName.Width/(2*I) - 1));
   lFileName.Caption := Dummy;
   Error := FormToPDF(Self.pPage,SaveDialog.FileName);
   if Error > 0 then
      OPFForm.OPFMessage(IntToStr(Error) + ' objects printed to PDF.')
     else
      OPFForm.OPFWarning('Could not create PDF. Error no: ' + IntToStr(Error));
   end;
end;



initialization
   {$I resunit2.lrs}

end.

