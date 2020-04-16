unit loginunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ComCtrls, StrUtils;

type

  { TLoginForm }

  TLoginForm = class(TForm)
    bbEnter: TBitBtn;
    cbName: TComboBox;
    ebPass: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    StatusBar: TStatusBar;
    procedure ebPassClick(Sender: TObject);
    procedure AddUser(Sender:TObject);
    procedure FormCreate(Sender: TObject);
    procedure ResetPass(Sender:TObject);
    procedure StatusBarDrawPanel(SBar: TStatusBar;Panel: TStatusPanel;
       const Rect: TRect);
    procedure Warning(Mess:string);
  private

  public
  class function Execute:boolean;
  end;

var
   LoginForm   :TLoginForm;
   User        :string;

implementation

uses LazFileUtils, DCPsha256;

{$R *.lfm}

function SHA256(sText:string):string;
var Hash       :TDCP_sha256;
    Digest     :array[0..31] of byte;
    I          :integer;

begin
Hash:= TDCP_sha256.Create(nil);   // create the hash
Hash.Init;                        // initialize it
Hash.UpdateStr(sText);
Hash.Final(Digest);               // produce the digest
Result:= '';
for I:= 0 to 31 do
  Result:= Result + IntToHex(Digest[I],2);
Hash.Free;
end;

{ TLoginForm }
class function TLoginForm.Execute: boolean;
begin
with TLoginForm.Create(nil) do
try
   Result := ShowModal = mrOk;
finally
   Free;
   end;
end;


procedure TLoginForm.AddUser(Sender:TObject);
var OutFile    :text;
    ConfigDir,
    UsersPath  :string;

begin
{$ifdef WINDOWS}
ConfigDir := GetAppConfigDir(true);
{$else}
ConfigDir := GetAppConfigDir(false);
{$endif}
if not DirectoryExists(ConfigDir) then CreateDir(ConfigDir);
UsersPath := AppendPathDelim(ConfigDir) + 'users.txt';
if FileExists(UsersPath) then
   begin
   AssignFile(OutFile,UsersPath);
   Append(OutFile);
   end
  else
   begin
   AssignFile(OutFile,UsersPath);
   Rewrite(OutFile);
   end;
writeln(OutFile,cbName.Text,':',SHA256(ebPass.Text));
CloseFile(OutFile);
ModalResult := mrOK;
end;

procedure TLoginForm.FormCreate(Sender: TObject);
var InFile     :Text;
    ConfigDir,
    UsersPath,
    UserName   :string;

begin
{$ifdef WINDOWS}
ConfigDir := GetAppConfigDir(true);
{$else}
ConfigDir := GetAppConfigDir(false);
{$endif}
UsersPath := AppendPathDelim(ConfigDir) + 'users.txt';
if FileExists(UsersPath) then
   begin
   AssignFile(InFile,UsersPath);
   Reset(Infile);
   while not eof(InFile) do
      begin
      readln(Infile,UserName);
      UserName := Copy2Symb(UserName,':');
      cbName.Items.Add(UserName);
      end;
   cbName.ItemIndex := 0;
   CloseFile(Infile);
   end
  else
   Warning('No authorisation file found');
end;


procedure TLoginForm.ResetPass(Sender: TObject);
var Infile,
    OutFile    :text;
    ConfigDir,
    UsersPath,
    NewPath,
    OldPath,
    UserName,
    Passwd     :string;
    Found      :boolean;

begin
Found := false;
{$ifdef WINDOWS}
ConfigDir := GetAppConfigDir(true);
{$else}
ConfigDir := GetAppConfigDir(false);
{$endif}
UsersPath := AppendPathDelim(ConfigDir) + 'users.txt';
NewPath := AppendPathDelim(ConfigDir) + 'users.new';
OldPath := AppendPathDelim(ConfigDir) + 'user.old';
if FileExists(UsersPath) then
   begin
   AssignFile(Infile,UsersPath);
   AssignFile(OutFile,NewPath);
   Reset(Infile);
   ReWrite(Outfile);
   while not eof(Infile) do
      begin
      readln(Infile,Passwd);
      UserName := Copy2SymbDel(Passwd,':');
      if UserName = cbName.Text then
         begin
         writeln(OutFile,cbName.Text,':',SHA256(ebPass.Text));
         ModalResult := mrOK;
         Found := true;
         end
        else
         writeln(Outfile,UserName,':',Passwd);
      end;
   if not Found then
      Warning('User name not found');
   CloseFile(Infile);
   CloseFile(OutFile);
   if FileExists(OldPath) then DeleteFile(OldPath);
   RenameFile(UsersPath,OldPath);
   if not RenameFile(NewPath,UsersPath) then
      Warning('Could not create new user file.')
   end
  else
   Warning('No authorisation file found');
end;


procedure TLoginForm.ebPassClick(Sender: TObject);
var Infile     :text;
    ConfigDir,
    UsersPath,
    UserName,
    Passwd     :string;
    Stop       :boolean;

begin
Stop := false;
{$ifdef WINDOWS}
ConfigDir := GetAppConfigDir(true);
{$else}
ConfigDir := GetAppConfigDir(false);
{$endif}
UsersPath := AppendPathDelim(ConfigDir) + 'users.txt';
if FileExists(UsersPath) then
   begin
   AssignFile(Infile,UsersPath);
   Reset(Infile);
   repeat
      readln(Infile,Passwd);
      UserName := Copy2SymbDel(Passwd,':');
      if UserName = cbName.Text then
         begin
         if Passwd = SHA256(ebPass.Text) then
            begin
            User := UserName;
            ModalResult := mrOK;
            end
           else
            Warning('Your password is incorrect');
         Stop := true;
         end;
      until eof(infile) or Stop;
   if not Stop then
      Warning('User name not found');
   CloseFile(Infile);
   end
  else
   Warning('No authorisation file found');
end;


procedure TLoginForm.StatusBarDrawPanel(SBar: TStatusBar;Panel: TStatusPanel;
   const Rect: TRect);
begin
with SBar.Canvas do
   begin
   Brush.Color := StatusBar.Color;
   FillRect(Rect);
   TextRect(Rect,2 + Rect.Left, 1 + Rect.Top,Panel.Text) ;
   end;
end;


procedure TLoginForm.Warning(Mess:string);
begin
StatusBar.Panels[0].Text := Mess;
StatusBar.Color := $7979ff;
end;

end.

