program BMSMonitor;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  {$IFnDEF FPC}
  {$ELSE}
  Interfaces,
  {$ENDIF }
  Forms,
  Main in 'Main.pas' {BMSMonForm};

{$R *.res}

begin
  Application.Initialize;
  {$ifdef FPC}
  Application.Scaled := True;
  {$endif}
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TBMSMonForm, BMSMonForm);
  Application.Run;
end.
