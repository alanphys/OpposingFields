unit aboutunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ComCtrls, StdCtrls;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    mAbout: TMemo;
    mLicence: TMemo;
    mCredits: TMemo;
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  AboutForm: TAboutForm;

implementation

{ TAboutForm }

procedure TAboutForm.FormCreate(Sender: TObject);
begin
try
   mAbout.Lines.LoadFromFile('readme.txt');
   except
   on E:Exception do
      mAbout.Lines.Text := 'Sorry readme not available';
   end;

try
   mLicence.Lines.LoadFromFile('licence.txt');
   except
   on E:Exception do
      mLicence.Lines.Text := 'Sorry licence not available';
   end;

try
   mCredits.Lines.LoadFromFile('credits.txt');
   except
   on E:Exception do
      mCredits.Lines.Text := 'Sorry credits not available';
   end;
end;

initialization
  {$I aboutunit.lrs}

end.

