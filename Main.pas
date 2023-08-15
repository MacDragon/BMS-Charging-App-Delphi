unit Main;
{*
Add coulomb counting?
keep track of how much charged.
BMS keep track of how much discharged, report value to charging app?
*}

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$define liveupdate}
interface
uses
//  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
//  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.StdCtrls, canchanex,
//  Vcl.ExtCtrls;
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, Grids, StdCtrls, canchanex,
  ExtCtrls;
type
  Cell = record
    Voltage : Real;
    discharging : Boolean;
    received : Boolean;
    max, min : Boolean;
  end;
  Temp = record
    Temperature : Real;
    received : Boolean;
    max, min : Boolean;
  end;
  TBMSMonForm = class(TForm)
    VoltageGrid: TStringGrid;
    TemperatureGrid: TStringGrid;
    CanDevices: TComboBox;
    goOnBus: TButton;
    OnBus: TLabel;
    TimeReceived: TLabel;
    BalancingMode: TRadioGroup;
    Charge: TButton;
    LoggingEnabled: TCheckBox;
    Timer1: TTimer;
    VoltageGroup: TGroupBox;
    HighestCellLabel: TLabel;
    LowestCellLabel: TLabel;
    DeltaVLabel: TLabel;
    AvgVLabel: TLabel;
    SOCLabel: TLabel;
    HighestCell: TLabel;
    LowestCell: TLabel;
    DeltaV: TLabel;
    AvgV: TLabel;
    SOC: TLabel;
    TemperatureGroup: TGroupBox;
    HighestNTCLabel: TLabel;
    LowestNTCLabel: TLabel;
    AvgTempLabel: TLabel;
    HighestNTC: TLabel;
    LowestNTC: TLabel;
    AvgTemp: TLabel;
    ChargingGroup: TGroupBox;
    PowerLabel: TLabel;
    CurrentLabel: TLabel;
    ChargeCurrentLabel: TLabel;
    Power: TLabel;
    Current: TLabel;
    ChargeCurrent: TLabel;
    ChargeVoltageLabel: TLabel;
    ChargeVoltage: TLabel;
    PECLabel: TLabel;
    PECAvgLabel: TLabel;
    PEC: TLabel;
    PECAvg: TLabel;
    OperatingModeLabel: TLabel;
    OperatingMode: TLabel;
    UptimeLabel: TLabel;
    Uptime: TLabel;
    AIRLabel: TLabel;
    AIRState: TLabel;
    StatusMsg: TMemo;
    PREStateLabel: TLabel;
    PREState: TLabel;
    ResetReasonGroup: TGroupBox;
    PORF: TCheckBox;
    EXTRF: TCheckBox;
    BORF: TCheckBox;
    WDRF: TCheckBox;
    JTRF: TCheckBox;
    OpModeLabel: TLabel;
    OpMode: TLabel;
    SafeState: TCheckBox;
    SafeStateReasonLabel: TLabel;
    SafeStateReason: TLabel;
    FanSpeedSlider: TScrollBar;
    FanSpeedEdit: TEdit;
    ChargeCurrentSlider: TScrollBar;
    ChargeCurrentEdit: TEdit;
    FanSpeedLabel: TLabel;
    ChargingCurrentLabel: TLabel;
    RandomFill: TButton;
    StopButton: TButton;
    StatusLabel: TLabel;
    Status: TLabel;
    RequestV: TButton;
    Label1: TLabel;
    Label2: TLabel;
    u1: TLabel;
    U2: TLabel;
    procedure VoltageGridDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure FormCreate(Sender: TObject);
    procedure CanDevicesChange(Sender: TObject);
    procedure goOnBusClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TemperatureGridDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure Timer1Timer(Sender: TObject);
    procedure ChargeClick(Sender: TObject);
    procedure FanSpeedSliderChange(Sender: TObject);
    procedure FanSpeedEditChange(Sender: TObject);
    procedure ChargeCurrentEditChange(Sender: TObject);
    procedure ChargeCurrentSliderChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure RandomFillClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure DebugOnClick(Sender: TObject);
    procedure BalancingModeClick(Sender: TObject);
  private
    { Private declarations }
    StartTime: TDateTime;
    LastSeen:  TDateTime;
    CanChannel1: TCanChannelEx;
    RequestCharging, timeout : Bool;
    Values : array[0..7] of String[20];
    AccCells, AccCellsDisplay: array[0..143] of Cell;
    Temps, TempsDisplay : array[0..71] of Temp; //023
    PowerVal, PECVal, PECAvgVal : Integer;
    maxV, minV, maxT, minT : Real;
    CurrentVal, ChargeCurrentVal,ChargeVoltageVal, U1Val, U2Val : Real;
    procedure CanChannel1CanRx(Sender: TObject);
    procedure Update;
    procedure SendCommand;
    procedure CanDropped;
    procedure ZeroCells;
   // Discharging array

  public
    { Public declarations }
    procedure PopulateList;
  end;
var
  BMSMonForm: TBMSMonForm;
implementation
uses DateUtils, canlib;
{$ifdef FPC}
{$R *.lfm}
{$else}
{$R *.dfm}
{$endif}
const
  maxchargecurrent = 60;
  maxfanspeed = 255;
  cellcount = 144;
  //tempcount = 60;
  tempcount = 72; //023
  maxtemp = 45;
  lowtemp = 20;
  mintemp = 0;
  maxvoltage = 4.2;
  minvoltage = 3.0;
  CANPowerID = 15;
  CANBMSStatusIDNew = 151;
  CANCommandIDNew = 150;
  CANBMSStatusID = 7;
  CANIVTID = $521;
  CANIID =  $611;
  CANIID2 = $648;
  CANRequestID = 1900;
  CANBMSErrorStateID = 1901;
  CANCommandID = 1902;
  CANDischargeID = 1909;
  CANCellID = 1912;
  CANTempID = 1960;
  ErrHiRGB = $FF6EC7;
  ErrLowRGB = $FFFF00;
  NoSelection: TGridRect = (Left: 0; Top: -1; Right: 0; Bottom: -1);
  function IsBitSet(const AValueToCheck, ABitIndex: Integer): Boolean;
begin
  Result := AValueToCheck and (1 shl ABitIndex) <> 0;
end;

function Get32BitBE(var msg: array of byte; start : byte ) : Long;
begin
   result := msg[start] shl 24 + msg[start+1] shl 16 + msg[start+2] shl 8 + msg[start+3];
end;
function Get16BitBE(var msg: array of byte; start : byte ) : Long;
begin
   result := msg[start] shl 8 + msg[start+1];
end;

function Get32BitLE(var msg: array of byte; start : byte ) : Long;
begin
   result := msg[start+3] shl 24 + msg[start+2] shl 16 + msg[start+1] shl 8 + msg[start];
end;
function Get16BitLE(var msg: array of byte; start : byte ) : Long;
begin
   result := msg[start+1] shl 8 + msg[start];
end;

procedure TBMSMonForm.CanDropped;
begin
  with CanChannel1 do
  begin
    try
      BusActive := false;
      onBus.Caption := 'Off bus';
      goOnBus.Caption := 'Go on bus';
      CanDevices.Enabled := true;
      Close;
    except
      onBus.Caption := 'Off bus';
      CanDevices.Enabled := false;
      Close;
    end;
  end;
end;
procedure TBMSMonForm.ZeroCells;
var
  i : integer;
begin
  for i := 0 to CellCount-1 do
  begin
    AccCells[i].Voltage := 0;
    AccCells[i].received := false;
    AccCellsDisplay[i].Voltage := 0;
    AccCellsDisplay[i].received := false;
  end;
  for i := 0 to TempCount-1 do
  begin
    TempsDisplay[i].Temperature := 0;
    TempsDisplay[i].received := false;
  end;
end;
procedure TBMSMonForm.CanDevicesChange(Sender: TObject);
begin
   CanChannel1.Channel := CanDevices.ItemIndex;
end;

(*
procedure TBMSMonForm.SendCommand;
var
  msg: array[0..7] of byte;
const
  numericUpDownMaxVoltage = 42000;
  numericUpDownMinVoltage = 31000;
  numericUpDownChargerDis = 41900;
  numericUpDownChargerEn = 41800;
  numericUpDownDelta = 100;
begin
  with CanChannel1 do // send our 'fake' adc data from form input.
  begin
    if Active then
    begin
      msg[0] := 0; // unused
      msg[1] := 0; // unused
      msg[4] := 0; // unused
      msg[5] := 0; // unused
      msg[2] := 1; // core
      msg[2] := msg[2] + 8; // debug always wanted, needed on to see voltages
      if RequestCharging then
      begin
        if BalancingMode.ItemIndex >0 then
          msg[2] := msg[2] + 2; // balancing
        msg[2] := msg[2] + 4; // charging
        msg[6] := ChargeCurrentSlider.Position;    // charge current
        {$ifdef liveupdate}
        Charge.Caption := 'Stop';
        {$else}
        Charge.Caption := 'Update';
        StopButton.Enabled := true;
        {$endif}

        RandomFill.Enabled := false;
      end
      else
      begin
        Charge.Caption := 'Charge';
        msg[2] := msg[2] + 16; // datalog always on to keep sd card log. with app bits 5,6,7 not used.
      end;
      case BalancingMode.ItemIndex of
             0 : msg[3] := 0;
             1 : msg[3] := 0;
             2 : msg[3] := 1;
             3 : msg[3] := 2;
             4 : msg[3] := 3;
      end;

      msg[7] := FanSpeedSlider.Position;  // fan speed 128 max  anything else off?
      try
        Check(Write(CANCommandID,msg,8,0), 'Write failed');
        // next two sections marked deprecated on original form and non editable,
        // but values still sent.
        msg[0] := numericUpDownMaxVoltage shr 8; // upper byte. 42000 default - 16 bit value
        msg[1] := byte(numericUpDownMaxVoltage);    // lower byte

        msg[2] := numericUpDownMinVoltage shr 8; // upper byte. 31000 default
        msg[3] := byte(numericUpDownMinVoltage); // lower bfyte
        msg[4] := numericUpDownChargerDis shr 8; // upper byte. auto disable voltage? 41900 default
        msg[5] := byte(numericUpDownChargerDis);  // lower byte
        msg[6] := numericUpDownChargerEn shr 8;   // upper byte. enable charging voltage? 41800 default.
        msg[7] := byte(numericUpDownChargerEn);
        Check(Write(CANCommandID+1,msg,8,0), 'Write failed');
        msg[0] := numericUpDownDelta shr 8; // upper byte. Delta value. 100 default.
        msg[1] := byte(numericUpDownDelta); // lower byte.
        msg[2] := 0;      // padding.
        msg[3] := 0;
        msg[4] := 0;
        msg[5] := 0;
        msg[6] := 0;
        msg[7] := 0;
        Check(Write(CANCommandID+2,msg,8,0), 'Write failed');
        StatusMsg.Lines.Add('CanMsgSend status charging: '+ booltostr(RequestCharging, true));
      Except
        StatusMsg.Lines.Add('Error sending can message, dropping can.');
        CanDropped;
      end;
    end;
  end;
end;
*)

procedure TBMSMonForm.SendCommand;
var
  msg: array[0..7] of byte;
begin
  with CanChannel1 do // send our 'fake' adc data from form input.
  begin
    if Active then
    begin
      try
        msg[0] := 1; // upper byte. Delta value. 100 default.
        msg[1] := 0;
        msg[2] := 0;      // padding.
        msg[3] := 0;
        msg[4] := 0;
        msg[5] := 0;
        msg[6] := 0;
        msg[7] := 0;
        Check(Write(CANCommandIDNew,msg,8,0), 'Write failed');
        StatusMsg.Lines.Add('CanMsgSend voltage status request');
      Except
        StatusMsg.Lines.Add('Error sending can message, dropping can.');
        CanDropped;
      end;
    end;
  end;
end;

procedure TBMSMonForm.ChargeClick(Sender: TObject);
begin
  if CanChannel1.Active then
  begin
    {$ifdef liveupdate}
    if RequestCharging then
      RequestCharging := false
    else
    begin
      if not timeout then
        RequestCharging := true;
    end;
    {$else}
    RequestCharging := true;
    {$endif}
    SendCommand;
  end;
end;
procedure TBMSMonForm.ChargeCurrentEditChange(Sender: TObject);
var
  val : integer;
begin
  if ChargeCurrentEdit.Text = '' then
  begin
     ChargeCurrentSlider.Position := 0;
     exit;
  end;
  if not TryStrToInt( ChargeCurrentEdit.Text, val) then ChargeCurrentEdit.Text := '0'
  else if StrToInt(ChargeCurrentEdit.Text) < 0 then ChargeCurrentEdit.Text := '0'
  else if StrToInt(ChargeCurrentEdit.Text) > maxchargecurrent then
    ChargeCurrentEdit.Text := IntToStr(maxchargecurrent);
  ChargeCurrentSlider.Position := StrToInt(ChargeCurrentEdit.Text);
end;
procedure TBMSMonForm.ChargeCurrentSliderChange(Sender: TObject);
begin
    ChargeCurrentEdit.Text := IntToStr(ChargeCurrentSlider.Position);
    {$ifdef liveupdate}
    SendCommand;
    {$endif}
end;
procedure TBMSMonForm.DebugOnClick(Sender: TObject);
begin
  SendCommand;
end;
procedure TBMSMonForm.FanSpeedEditChange(Sender: TObject);
var
  val : integer;
begin
  if FanSpeedEdit.Text = '' then
    begin
     FanSpeedSlider.Position := 0;
     exit;
  end;
  if not TryStrToInt( FanSpeedEdit.Text, val) then FanSpeedEdit.Text := '0'
  else if StrToInt(FanSpeedEdit.Text) < 0 then FanSpeedEdit.Text := '0'
  else if StrToInt(FanSpeedEdit.Text) > maxfanspeed then FanSpeedEdit.Text := IntToStr(maxfanspeed);
  FanSpeedSlider.Position := StrToInt(FanSpeedEdit.Text);
end;
procedure TBMSMonForm.FanSpeedSliderChange(Sender: TObject);
begin
  FanSpeedEdit.Text := IntToStr(FanSpeedSlider.Position);
  {$ifdef liveupdate}
  SendCommand;
  {$endif}
end;
// ask can drivers for list of available devices
procedure TBMSMonForm.PopulateList;
var
  i : Integer;
  p : AnsiString;
begin
  SetLength(p, 64);
  CanDevices.Items.clear;
  for i := 0 to CanChannel1.ChannelCount - 1 do
  begin
    if ansipos('Virtual', CanChannel1.ChannelNames[i]) = 0 then  // don't populate virtual channels.
      CanDevices.Items.Add(CanChannel1.ChannelNames[i]);
  end;
  if CanDevices.Items.Count > 0 then
    CanDevices.ItemIndex := 0;
end;
procedure TBMSMonForm.RandomFillClick(Sender: TObject);
var
  i, j, col, row, id : integer;
  temp : Word;
begin
  for i := 0 to CellCount-1 do
  begin
    AccCells[i].Voltage := 0;
    AccCells[i].received := true;
  end;
  for i := 0 to TempCount-1 do
  begin
    Temps[i].Temperature := 0;
    Temps[i].received := true;
  end;
  for id := CANDischargeID+1 to CANDischargeID+1 do //CANDischargeID+2 do
  begin
    row := (id-CANDischargeID)*4;
    // [0000 0001][0000 0001][0000 0001][0000 0001][0000 0001][0000 0001][0000 0001][0000 0001]
    //    DCCx[0] = (UInt16)(((UInt16)rxData[0] << 8) | ((UInt16)rxData[1]));
    // = a whole row over 16 bits.
    // CANDischargeII Msg[0][1] = row 0   [0000 1111][1111 1111]
    // CANDischargeII Msg[2][3] = row 1   and so on
    // CANDischargeII Msg[4][5] = row 2
    // CANDischargeII Msg[6][7] = row 3
    temp := 1+2+4+8+16+32+64+256+512+1024;
    for col := 0 to 18 do // columns
      for j := 0 to 7 do // rows
      begin
        if IsBitSet(temp,col) then
 //       if IsBitSet(Get16BitBE(msg,j*2),col) then
          AccCells[col+(row+j)*12].discharging := true
        else
          AccCells[col+(row+j)*12].discharging := false;
      end;
  end;
  for row := 0 to 7 do
  begin
    col := 0;
    while col < 18 do
    begin
    //StatusMsg.Lines.Add('Id '+inttostr(id)+' row: '+inttostr(row)+' col: '+inttostr(col));
      AccCells[col+row*18].Voltage := 2.8 + Random*1.6;
      AccCells[col+row*18].received := true;
      AccCells[col+1+row*18].Voltage := 2.8 + Random*1.6;
      AccCells[col+1+row*18].received := true;
      AccCells[col+2+row*18].Voltage := 2.8 + Random*1.6;
      AccCells[col+2+row*18].received := true;
      inc(col, 3);
    end;
  end;
  for row := 0 to 7 do
  begin
    col := 0;
    while col < 9 do
    begin

      Temps[col + row*9].Temperature := 0 + Random*55;//col + row*8;
      Temps[col + row*9].received := true;
      Temps[col+1 + row*9].Temperature := 0 + Random*55;//col + row*8;
      Temps[col+1 + row*9].received := true;
      Temps[col+2 + row*9].Temperature := 0 + Random*55;//col + row*8;
      Temps[col+2 + row*9].received := true;


    {
    //StatusMsg.Lines.Add('Id '+inttostr(id)+' row: '+inttostr(row)+' col: '+inttostr(col));
      Temps[col + row*9].Temperature := col + row*9;
      Temps[col + row*9].received := true;
      Temps[col+1 + row*9].Temperature := col + row*9;
      Temps[col+1 + row*9].received := true;
      Temps[col+2 + row*9].Temperature := col + row*9;
      Temps[col+2 + row*9].received := true;
      }
      inc(col, 3);
    end;
    //Modified for testing
    //Temps[col + row*8].Temperature := -5 + Random*55;
  end;
end;
procedure TBMSMonForm.StopButtonClick(Sender: TObject);
begin
  if CanChannel1.Active then
  begin
    if RequestCharging = true then
    begin
          RequestCharging := false;
          Charge.Caption := 'Charge';
          RandomFill.Enabled := true;
          Charge.Enabled := true;
          StopButton.Enabled := false;
    end
    else
    begin
          RequestCharging := false;
          Charge.Caption := 'Charge';
          RandomFill.Enabled := true;
          Charge.Enabled := true;
          StopButton.Enabled := false;
    end;
    SendCommand;
  end;
end;
procedure TBMSMonForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if RequestCharging = true then
    ChargeClick(Self); // ensure try to stop charging if close form.
end;
procedure TBMSMonForm.FormCreate(Sender: TObject);
var
  i,j, col, row, id : integer;
begin
  try
    CanChannel1 := TCanChannelEx.Create(Self);
  except
     ShowMessage('Error initialisiting, are KVASER drivers installed?');
     Application.Terminate();
  end;
  CanChannel1.Channel := 0;
  RequestCharging := false;
  VoltageGrid.Selection:= NoSelection;
  TemperatureGrid.Selection:= NoSelection;
  VoltageGrid.Cells[0,0] := 'Volts(v)';
  ChargeCurrentSlider.Max := maxchargecurrent;
  ChargeCurrentSlider.Position := maxchargecurrent;
  FanSpeedSlider.Max := maxfanspeed;
  FanSpeedSlider.Position := maxfanspeed;
  {$ifdef liveupdate}
  StopButton.Hide;
  {$endif}
  for i := 1 to VoltageGrid.ColCount-1 do
  begin
    VoltageGrid.Cells[i,0] :=  'C' + inttostr(i);
  end;
  for i := 1 to VoltageGrid.RowCount-1 do
    VoltageGrid.Cells[0,i] :=  'S' + inttostr(i);
  for i := 1 to TemperatureGrid.ColCount-1 do
  begin
    TemperatureGrid.Cells[i,0] :=  'C' + inttostr(i);
  end;
  for i := 1 to TemperatureGrid.RowCount-1 do
    TemperatureGrid.Cells[0,i] :=  'S' + inttostr(i);
  {$ifdef randomfill}
  RandomFillClick(Self);
  {$endif}

  TemperatureGrid.ColWidths[0] := 86;
{
    for i := CANCellID to CANCellID+(12*3)-1 do //read cell voltage messages /
    begin
      col := trunc((i-CANCellID)/3)*12;
      row := trunc((i-CANCellID)mod 3)*4;
  //      for j := 0 to 2  do
      begin
        AccCells[col+ 0+row].Voltage := (i);
        AccCells[col+ 1+row].Voltage := (i);
        AccCells[col+ 2+row].Voltage := (i);
        AccCells[col+ 3+row].Voltage := (i);
      end;
    end;
  for i := CANTempID to CANTempID+(12*2)-1 do //read cell voltage messages /
  begin
    col := (trunc((i-CANTempID) / 2 )*12); //  set starting cell to work down from
    row := ((i-CANTempID) mod 2 )*4;
    Temps[col+ 0 + row].Temperature := i;
    if row < 5 then
    begin
      Temps[col+ 1 + row].Temperature := (i);
      Temps[col+ 2 + row].Temperature := (i);
      Temps[col+ 3 + row].Temperature := (i);
    end;
  end;
         }
       Timer1.Enabled := true;
end;
procedure TBMSMonForm.FormShow(Sender: TObject);
begin
  PopulateList;
end;
procedure TBMSMonForm.goOnBusClick(Sender: TObject);
var
  formattedDateTime : String;
begin
  with CanChannel1 do begin
    if not Active then begin
      Bitrate := canBITRATE_1M;
      Channel := CanDevices.ItemIndex;
      Options := [ccNotExclusive];  // allows eg canking to also run.
      Open;
    //  SetHardwareFilters($20, canFILTER_SET_CODE_STD);
    //  SetHardwareFilters($FE, canFILTER_SET_MASK_STD);
      OnCanRx := CanChannel1CanRx;
      BusActive := true;
      CanDevices.Enabled := false;
      Charge.Enabled := true;
      StopButton.Enabled := true;
      onBus.Caption := 'On bus';
      goOnBus.Caption := 'Go off bus';
      StartTime := SysUtils.Now;
      LastSeen := SysUtils.Now;
      DateTimeToString(formattedDateTime, 'hh:mm:ss', SysUtils.Now);
      timeout := true;
      SendCommand;
    end
    else begin
      TimeReceived.Caption := '-';
      Status.Caption := 'Offline';
      BusActive := false;
      onBus.Caption := 'Off bus';
      goOnBus.Caption := 'Go on bus';
      CanDevices.Enabled := true;
      Charge.Enabled := false;
      Close;
    end;
  end;
end;
function RGBColour(Val, Low, High : real; inv : boolean ) : Long;
var
  valratio, r, g, b : byte;
  valr : real;
  HighRGB, LowRGB : Long;
begin
  if inv then
  begin
    HighRGB := ErrHiRGB;
    LowRGB := ErrLowRGB;
  end
  else
  begin
    HighRGB := ErrLowRGB;
    LowRGB := ErrHiRGB;
  end;
  if Val < Low then
    Exit(LowRGB)
  else if Val > High then
   Exit(HighRGB);
  valr := 1/(high-low)*(val-low)*2;
  valratio := (round(frac(valr)*$FF));
  B := 0;
  case Trunc(valr) of
    0: begin
        R := $FF;
        G := valratio;
      end;
    1: begin
        R := $FF - valratio;
        G := $FF;
      end;
  end;
  if Inv then
  begin
    B := R;
    R := G;
    G := B;
    B := 0;
  end;
  RGBColour := rgb(R,G,B);
end;
procedure TBMSMonForm.VoltageGridDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  RectForText: TRect;
  cellvoltage : real;
  Cell : Integer;
begin
  with TStringGrid(Sender) do
  begin
    if (ACol > 0) and (ARow > 0) then
    begin
        cell := (ARow-1)*18+(ACol-1);
        if Cells[Acol,Arow] <> '' then
        begin
          cellvoltage := AccCellsDisplay[cell].Voltage;
          Canvas.Brush.Color := RGBColour(cellvoltage, minvoltage, maxvoltage, false);
        end
        else
          Canvas.Brush.Color := $FFFFFF;
        Canvas.FillRect(Rect);
        if AccCellsDisplay[cell].discharging then
          Canvas.TextOut(Rect.right-30,Rect.Top+8,'▼');
        if AccCellsDisplay[cell].max then
          Canvas.Font.Style := [fsBold];
        if AccCellsDisplay[cell].min then
          Canvas.Font.Style := [fsBold, fsItalic];
        Canvas.TextOut(Rect.Left+2,Rect.Top+8,Cells[ACol, ARow]);
    end
    else
    begin
        Canvas.Brush.Color := clGray;// $BBGGRR
        Canvas.Font.Color := clBlack;
        Canvas.FillRect(Rect);
        RectForText := Rect;
    // Make the rectangle where the text will be displayed a bit smaller than the cell
    // so the text is not "glued" to the grid lines
        InflateRect(RectForText, -2, -8);
        DrawText (Canvas.Handle,
            PChar(Cells[ACol, ARow]),
            Length(Cells[ACol, ARow]),
            RectForText, DT_WORDBREAK or DT_EXPANDTABS or DT_CENTER);
    end
  end
end;

procedure TBMSMonForm.TemperatureGridDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  RectForText: TRect;
  temp : real;
  Cell : Integer;
begin
 with TStringGrid(Sender) do
  begin
    if (ACol > 0) and (ARow > 0) then
    begin
        //cell := (ARow-1)*12+(ACol-1);
        cell := (ARow-1)*9+(ACol-1); //023
        if Cells[Acol,Arow] <> '' then
        begin
          temp := TempsDisplay[cell].Temperature;
          if ( temp > mintemp ) and ( temp < lowtemp ) then
            temp := lowtemp;
          //Canvas.Brush.Color := RGBColour(temp, lowtemp, maxtemp, true);
        end
        else
          Canvas.Brush.Color := $FFFFFF;
    //    Canvas.Brush.Color := ERRLowRGB;
        Canvas.FillRect(Rect);
        {if TempsDisplay[cell].max then
          Canvas.Font.Style := [fsBold];
        if TempsDisplay[cell].min then
          Canvas.Font.Style := [fsBold, fsItalic];}
        Canvas.TextOut(Rect.Left+2,Rect.Top+8,Cells[ACol, ARow]);
    end
    else
    begin
        Canvas.Brush.Color := clGray;// $BBGGRR
        Canvas.Font.Color := clBlack;
        Canvas.FillRect(Rect);
        RectForText := Rect;
    // Make the rectangle where the text will be displayed a bit smaller than the cell
    // so the text is not "glued" to the grid lines
        InflateRect(RectForText, -2, -8);
        DrawText (Canvas.Handle,
            PChar(Cells[ACol, ARow]),
            Length(Cells[ACol, ARow]),
            RectForText, DT_WORDBREAK or DT_EXPANDTABS or DT_CENTER);
    end
  end
end;

procedure TBMSMonForm.Timer1Timer(Sender: TObject);
begin
  Update;// call update request
end;
// Check if the bit at ABitIndex position is 1 (true) or 0 (false)
procedure TBMSMonForm.BalancingModeClick(Sender: TObject);
begin
    {$ifdef liveupdate}
    SendCommand;
    {$endif}
end;
procedure TBMSMonForm.CanChannel1CanRx(Sender: TObject);
var
  dlc, flag, time: cardinal;
  msg, msgout: array[0..7] of byte;
  i,j, col, row : integer;
  id: longint;
  formattedDateTime, str : string;
begin
//  Output.Items.BeginUpdate;
  with CanChannel1 do begin
    while Read(id, msg, dlc, flag, time) >= 0 do begin
      DateTimeToString(formattedDateTime, 'hh:mm:ss', SysUtils.Now);
      if flag = $20 then
      begin
// error frame.
      end
      else
      begin
        for i := 0 to 7 do
        msgout[i] := 0;
        case id of
        {
          1 :
          begin
            StatusMsg.Lines.add('test');
          end;
          //             canStatus = Canlib.canReadSpecific(canHandle, id, rxData, out dlc, out flags, out time);
         //   pec = (uint)(((uint)rxData[0] << 24) | ((uint)rxData[1] << 16) | ((uint)rxData[2] << 8) | ((uint)rxData[3] << 0));
         //   pec_avg = (uint)(((uint)rxData[4] << 24) | ((uint)rxData[5] << 16) | ((uint)rxData[6] << 8) | ((uint)rxData[7] << 0));
          CANBMSStatusID+3 :  // PEC
          begin
            PECVal := Get32BitBE(msg,0);
            PECAvgVal := Get32BitBE(msg,4);
          end;
          CANBMSStatusID+7 :
          begin
            uptime.Caption := IntToStr(Get32BitBE(msg,0));
          end;
          CANBMSStatusID+8 : // power
          begin
            PowerVal := Get32BitBE(msg,0);
          //  CurrentVal := (Int16)((rxData[4] << 8) | (rxData[5] << 0));
          end;
          CANIID : //   read_curr_real()
          begin
            ChargeCurrent.Caption := IntToStr(Get16BitBE(msg,6) div 100);
            //Added output voltage actual to this function. Function name misleading
            ChargeVoltage.Caption := IntToStr(Get16BitBE(msg,4) div 5);
          end;
          CANIID2 : //   read_curr_real()
          begin
            ChargeCurrent.Caption := IntToStr(Get16BitBE(msg,6) div 100);
            //Added output voltage actual to this function. Function name misleading
            ChargeVoltage.Caption := IntToStr(Get16BitBE(msg,4) div 5);
          end;        }

          CANIVTID :  // current from ivt
          begin
            CurrentVal := Get32BitBE(msg,2);// / 1000;
          end;

          CANIVTID + 1 : // u1
          begin
            U1Val :=  Get32BitBE(msg,2);
          end;

          CANIVTID + 2 : // u2
          begin
            U2Val :=  Get32BitBE(msg,2);
          end;

          CANBMSStatusIDNew :  //    private void read_time()
          begin
              lastseen := SysUtils.Now;
      //      hour = IntToStr(Get32BitBE(msg,0));    // why sending twice?
      //      minute = IntToStr(Get32BitBE(msg,4));
          end;
               {
          CANBMSStatusID :  //    private void read_time()
          begin
      //      hour = IntToStr(Get32BitBE(msg,0));    // why sending twice?
      //      minute = IntToStr(Get32BitBE(msg,4));
          end;
          CANBMSStatusID+1 :
          begin
      //      second = IntToStr(Get32BitBE(msg,0));
      //      labelTime.Text = "Uptime(formatted): " + hour.ToString() + ":" + minute.ToString() + ":" + second.ToString();
            Uptime.Caption := IntToStr(Get32BitBE(msg,4));  // is updating.
          end;
          CANBMSStatusID+2 : // private void read_state()
          begin
            lastseen := SysUtils.Now;
            SafeState.Checked := Boolean(msg[0]);
            if SafeState.Checked = true then
            begin
              case msg[1] of
                0 : str := 'undefined';
                1 : str := 'overvoltage';
                2 : str := 'undervoltage';
                3 : str := 'overtemperature';
                4 : str := 'undertemperature';
                5 : str := 'overcurrent';
                6 : str := 'overpower';
                7 : str := 'external';
                8 : str := 'pec_error';
                9 : str := 'Accumulator Undervoltage';
                10 : str := 'IVT MOD timeout';
              end;
              SafeStateReason.Caption := str;
            end;
            AIRState.Caption := IntToStr(msg[2]);
            PREState.Caption := IntToStr(msg[3]);
            i := msg[4];
            str := '';
            if IsBitSet(i, 3) = false then str := str + ' Nodebug';
          //  if IsBitSet(i, 3) then str := str + ' log';
            if msg[0] = 0 then
            begin
            //  if IsBitSet(i, 0) then str := str + ' core';
              str := 'Online';
              if IsBitSet(i, 2) then str := str + ' - Charging';
              if IsBitSet(i, 1) then str := str + ' with balancing';
              Status.Caption := str;
              opmode.Caption := IntToStr(msg[4]);
            end
            else
            begin
              Status.Caption := 'Not Charging: Safe State.';
            end;
          end;
          CANDischargeID .. CANDischargeID+2 :    //   private void read_disch()
          begin
              row := (id-CANDischargeID)*4;
              // [0000 0001][0000 0001][0000 0001][0000 0001][0000 0001][0000 0001][0000 0001][0000 0001]
              //    DCCx[0] = (UInt16)(((UInt16)rxData[0] << 8) | ((UInt16)rxData[1]));
              // = a whole row over 16 bits.
              // CANDischargeII Msg[0][1] = row 0   [0000 1111][1111 1111]
              // CANDischargeII Msg[2][3] = row 1   and so on
              // CANDischargeII Msg[4][5] = row 2
              // CANDischargeII Msg[6][7] = row 3
              for col := 0 to 11 do
                for j := 0 to 3 do
                begin
                  if IsBitSet(Get16BitBE(msg,j*2),i) then
                    AccCells[col+(row+j)*12].discharging := true;
                end;
          end;    }
          CANCellID:// .. (CANCellID+(12*3)-1) :
          begin
            col := msg[7];
            row := msg[6];
            AccCells[col+row*18].Voltage := Get16BitLE(msg,0)/10000;;
            AccCells[col+row*18].received := true;
            AccCells[col+1+row*18].Voltage := Get16BitLE(msg,2)/10000;
            AccCells[col+1+row*18].received := true;
            AccCells[col+2+row*18].Voltage := Get16BitLE(msg,4)/10000;
            AccCells[col+2+row*18].received := true;
          end;
          CANTempID:// .. ( CANTempID+(16*2)-1 ) : //023
          begin
            col := msg[7];
            row := msg[6];

            if col = 1 then
              col := 3;
            if col = 2 then
              col := 6;

            Temps[col + row*9].Temperature := (Get16BitLE(msg,0));
            Temps[col + row*9].received := true;
            Temps[col + 1 + row*9].Temperature := (Get16BitLE(msg,2));
            Temps[col + 1 + row*9].received := true;
            Temps[col + 2 + row*9].Temperature := (Get16BitLE(msg,4));
            Temps[col + 2 + row*9].received := true;
          end;
                 {
          CANBMSErrorStateID :
              begin
                PORF.Checked :=  IsBitSet(msg[0], 0);
                EXTRF.Checked := IsBitSet(msg[0], 1);
                BORF.Checked :=  IsBitSet(msg[0], 2);
                WDRF.Checked :=  IsBitSet(msg[0], 3);
                JTRF.Checked :=  IsBitSet(msg[0], 4);
              end;
              }
        end;

      end;
    end;
  end;
end;

procedure TBMSMonForm.Update;
var
  i, row,col, cell, count : integer;
  ready : Boolean;
  SOCval, v, t : real;
begin
  ready := true;
  if CanChannel1.Active then
    if secondsBetween(Now,lastseen) > 0 then
    begin
      Status.Caption := 'Timeout for ' + inttostr(secondsBetween(LastSeen,Now))+' seconds';
      timeout := true;
    end
    else
    begin
      Status.Caption := 'Online';
      timeout := false;
    end;


  for row := 0 to 7 do     // this is failing too frequently. examine.
    for col := 0 to 18 do
      if not AccCells[row*18+col].received then
      begin
        ready := false;
        count := count +1;
      end;

 // if ready then      // received all ready, ready to update grid.
  begin
//    statusmsg.Lines.Add('readycount:' + inttostr(count));
    AccCellsDisplay := AccCells;
    TempsDisplay := Temps;
    for i := 0 to CellCount-1 do
    begin
      AccCells[i].received := false;
      AccCells[i].discharging := false;
    end;
    for i := 0 to TempCount-1 do
      Temps[i].received := false;
    //for i := 0 to TempCount-1 do

    minv := 200;
    maxv := 0;
    for row := 0 to 7 do
      for col := 0 to 17 do
      begin
        cell := row*18+col;
        v := AccCellsDisplay[cell].Voltage;
        VoltageGrid.Cells[col+1,row+1] := floattostrf(v,ffFixed,4,4);
        if v >= maxV then
        begin
          maxV := v;
        end;
        if (v <= minV) and (v > 0) then
        begin
          minV := v;          
        end;
        socval := socval + v;
      end;

    for i := 0 to CellCount-1 do
    begin
      if AccCellsDisplay[i].Voltage >= maxV then
        AccCellsDisplay[i].max := true
      else
        AccCellsDisplay[i].max := false;
      if AccCellsDisplay[i].Voltage <= minV then
        AccCellsDisplay[i].min := true
      else
        AccCellsDisplay[i].min := false;
    end;
//    statusmsg.Lines.Add('received count :'+inttostr(count));
    AvgV.Caption := floattostrf(socval / CellCount,ffFixed,4,4);
    DeltaV.Caption := floattostrf(maxV - minV, ffFixed,4,4);
    HighestCell.Caption := floattostrf(maxV, ffFixed,4,4);
    LowestCell.Caption := floattostrf(minV, ffFixed,4,4);
    SOC.Caption := floattostrf(socval, ffFixed,4,4);
    mint := 200;
    maxt := -200;
    socval := 0;
    for row := 0 to 7 do
      for col := 0 to 8 do
      begin
        cell := row*9+col;
        t := TempsDisplay[cell].Temperature;
        TemperatureGrid.Cells[col+1,row+1] := floattostrf(t,ffFixed,4,2);
        if t >= maxT then
        begin
          maxt := t;
        end;
        if t <= mint then
        begin
          mint := t;
        end;
        socval := socval + t;
      end;
    for i := 0 to tempcount-1 do
    begin
      if TempsDisplay[i].Temperature >= maxT then
        TempsDisplay[i].max := true
      else
        TempsDisplay[i].max := false;
      if TempsDisplay[i].Temperature <= minT then
        TempsDisplay[i].min := true
      else
        TempsDisplay[i].min := false;
    end;

    socval := socval / 72;
    HighestNTC.Caption := floattostrf((maxT), ffFixed,4,2);
    LowestNTC.Caption := floattostrf((minT), ffFixed,4,2);
    AvgTemp.Caption := floattostrf((socval), ffFixed,4,2);
    if PECVal > 0 then
    begin
      PEC.Caption := IntToStr(PECVal);
      PECAvg.Caption := IntToStr(PECAvgVal);
    end;
    Power.Caption := IntToStr(PowerVal);
    Current.Caption := floattostrf(CurrentVal / 1000, ffFixed, 4,3);
    U1.Caption := floattostrf(U1Val / 1000, ffFixed, 4,3);
    U2.Caption := floattostrf(U2Val / 1000, ffFixed, 4,3);
  //  ChargeCurrent.Caption := floattostrf(ChargeCurrentVal, ffFixed, 6,3);
  //  ChargeVoltage.Caption := floattostrf(ChargeVoltageVal, ffFixed, 6,3);
  end;
end;
end.
