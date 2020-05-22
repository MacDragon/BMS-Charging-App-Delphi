unit Main;

{*

Add coulomb counting?

keep track of how much charged.

BMS keep track of how much discharged, report value to charging app?

*}


{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

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
    Voltage : real;
    discharging : Boolean;
    received : Boolean;
  end;

  Temp = record
    Temperature : real;
    received : Boolean;
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
  private
    { Private declarations }
    StartTime: TDateTime;
    CanChannel1: TCanChannelEx;
    Charging : Bool;
    Values : array[0..7] of String[20];
    AccCells: array[0..143] of Cell;
    Temps : array[0..59] of Temp;
    PowerVal, PECVal, PECAvgVal : Integer;
    CurrentVal, ChargeCurrentVal,ChargeVoltageVal : Real;
    procedure CanChannel1CanRx(Sender: TObject);
    procedure Update;
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
  maxchargecurrent = 120;
  maxfanspeed = 128;

  cellcount = 144;
  tempcount = 60;


  maxtemp = 45;
  lowtemp = 20;
  mintemp = 0;

  maxvoltage = 4.2;
  minvoltage = 3.0;

  CANPowerID = 15;

  CANRequestID = 1900;

  CANCellID = 1912;
  CANTempID = 1948;

  nocells = 144;

  ErrHiRGB = $FF6EC7;
  ErrLowRGB = $FFFF00;

  NoSelection: TGridRect = (Left: 0; Top: -1; Right: 0; Bottom: -1);

procedure TBMSMonForm.CanDropped;
begin
  with CanChannel1 do
  begin
      BusActive := false;
      onBus.Caption := 'Off bus';
      goOnBus.Caption := 'Go on bus';
      CanDevices.Enabled := true;
      Close;
  end;
end;

procedure TBMSMonForm.ZeroCells;
var
  i : integer;
begin
  for i := 0 to CellCount-1 do
  begin
    AccCells[i].Voltage := 2.8 + Random*1.6;
    AccCells[i].received := true;
  end;

  for i := 0 to TempCount-1 do
  begin
    Temps[i].Temperature := -5 + Random*55;
    Temps[i].received := true;
  end;
end;

procedure TBMSMonForm.CanDevicesChange(Sender: TObject);
begin
   CanChannel1.Channel := CanDevices.ItemIndex;
end;

procedure TBMSMonForm.ChargeClick(Sender: TObject);
var
  msg: array[0..7] of byte;
const
  ID  = 1902;
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
      msg[2] := 1; // core
      if not charging then
      begin
        if BalancingMode.ItemIndex >0 then
          msg[2] := msg[2] + 2; // balancing
        msg[2] := msg[2] + 4; // charging
        charging := true;
        Charge.Caption := 'Stop';
        RandomFill.Enabled := false;
      end
      else
      begin
        charging := false;
        Charge.Caption := 'Charge';
        RandomFill.Enabled := true;
      end;

      msg[2] := msg[2] + 8; // debug, needed on to see voltages
      msg[2] := msg[2] + 16; // datalog  bits 5,6,7 not used.

      case BalancingMode.ItemIndex of
             0 : msg[3] := 0;
             1 : msg[3] := 0;
             2 : msg[3] := 1;
             3 : msg[3] := 2;
      end;

      msg[6] := ChargeCurrentSlider.Position;    // charge current
      msg[7] := FanSpeedSlider.Position;    // fan speed 128 max

      try
        Check(Write(id,msg,1,0), 'Write failed');

        // next two sections marked deprecated on original form and non editable,
        // but values still sent.

        msg[0] := numericUpDownMaxVoltage shr 8; // upper byte. 42000 default - 16 bit value
        msg[1] := byte(numericUpDownMaxVoltage);    // lower byte


        msg[2] := numericUpDownMinVoltage shr 8; // upper byte. 31000 default
        msg[3] := byte(numericUpDownMinVoltage); // lower byte

        msg[4] := numericUpDownChargerDis shr 8; // upper byte. auto disable voltage? 41900 default
        msg[5] := byte(numericUpDownChargerDis);  // lower byte

        msg[6] := numericUpDownChargerEn shr 8;   // upper byte. enable charging voltage? 41800 default.
        msg[7] := byte(numericUpDownChargerEn);

        Check(Write(id+1,msg,1,0), 'Write failed');

        msg[0] := numericUpDownDelta shr 8; // upper byte. Delta value. 100 default.
        msg[1] := byte(numericUpDownDelta); // lower byte.

        msg[2] := 0;      // padding.
        msg[3] := 0;
        msg[4] := 0;
        msg[5] := 0;
        msg[6] := 0;
        msg[7] := 0;

        Check(Write(id+2,msg,1,0), 'Write failed');
        StatusMsg.Lines.Add('CanMsgSend status charging: '+ booltostr(charging, true));
      Except
        StatusMsg.Lines.Add('Error sending can message, dropping can.');
        CanDropped;
      end;
    end;
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
end;

// ask can drivers for list of available devices
procedure TBMSMonForm.PopulateList;
var
  i : Integer;
  p : AnsiString;
begin
  SetLength(p, 64);
  CanDevices.Items.clear;
  for i := 0 to CanChannel1.ChannelCount - 1 do begin
     CanDevices.Items.Add(CanChannel1.ChannelNames[i]);
  end;
  if CanDevices.Items.Count > 0 then
    CanDevices.ItemIndex := 0;
end;

procedure TBMSMonForm.RandomFillClick(Sender: TObject);
var
  i : integer;
begin
  for i := 0 to CellCount-1 do
  begin
    AccCells[i].Voltage := 2.8 + Random*1.6;
    AccCells[i].received := true;
  end;

  for i := 0 to TempCount-1 do
  begin
    Temps[i].Temperature := -5 + Random*55;
    Temps[i].received := true;
  end;
end;

procedure TBMSMonForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if charging then
    ChargeClick(Self); // ensure try to stop charging if close form.
end;

procedure TBMSMonForm.FormCreate(Sender: TObject);
var
  i,j, col, row, id : integer;
begin
  CanChannel1 := TCanChannelEx.Create(Self);
  CanChannel1.Channel := 0;
  Charging := false;
  VoltageGrid.Selection:= NoSelection;
  TemperatureGrid.Selection:= NoSelection;
  VoltageGrid.Cells[0,0] := 'Voltage(v)';
  ChargeCurrentSlider.Max := maxchargecurrent;
  ChargeCurrentSlider.Position := maxchargecurrent;
  FanSpeedSlider.Max := maxfanspeed;
  FanSpeedSlider.Position := maxfanspeed;

  for i := 1 to VoltageGrid.ColCount-1 do
  begin
    VoltageGrid.Cells[i,0] :=  'C' + inttostr(i);
  end;

  for i := 1 to VoltageGrid.RowCount-1 do
    VoltageGrid.Cells[0,i] :=  'R' + inttostr(i);

  for i := 1 to TemperatureGrid.ColCount-1 do
  begin
    TemperatureGrid.Cells[i,0] :=  'C' + inttostr(i);
  end;

  for i := 1 to TemperatureGrid.RowCount-1 do
    TemperatureGrid.Cells[0,i] :=  'R' + inttostr(i);

  {$ifdef randomfill}
  for i := 0 to 143 do
  begin
    AccCells[i].Voltage := 2.8 + Random*1.6;
    AccCells[i].received := true;
  end;

  for i := 0 to 59 do
  begin
    Temps[i].Temperature := -5 + Random*55;
    Temps[i].received := true;
  end;
  {$endif}

{

    for i := 1912 to 1912+(12*3)-1 do //read cell voltage messages /
    begin
      col := trunc((i-1912)/3)*12;
      row := trunc((i-1912)mod 3)*4;
  //      for j := 0 to 2  do
      begin
        AccCells[col+ 0+row].Voltage := (i);
        AccCells[col+ 1+row].Voltage := (i);
        AccCells[col+ 2+row].Voltage := (i);
        AccCells[col+ 3+row].Voltage := (i);
      end;
    end;

  for i := 1948 to 1948+(12*2)-1 do //read cell voltage messages /
  begin
    col := (trunc((i-1948) / 2 )*5); //  set starting cell to work down from
    row := ((i-1948) mod 2 )*4;

    Temps[col+ 0 + row].Temperature := i;
    if row < 5 then
    begin
      Temps[col+ 1 + row].Temperature := (i);
      Temps[col+ 2 + row].Temperature := (i);
      Temps[col+ 3 + row].Temperature := (i);
    end;
  end;
         }

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
      Open;
    //  SetHardwareFilters($20, canFILTER_SET_CODE_STD);
    //  SetHardwareFilters($FE, canFILTER_SET_MASK_STD);
      OnCanRx := CanChannel1CanRx;
      BusActive := true;
      CanDevices.Enabled := false;
      Charge.Enabled := true;
      onBus.Caption := 'On bus';
      goOnBus.Caption := 'Go off bus';
      StartTime := Now;
      DateTimeToString(formattedDateTime, 'hh:mm:ss', SysUtils.Now);

    end
    else begin
      TimeReceived.Caption := '-';

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
begin
  with TStringGrid(Sender) do
  begin
    if (ACol > 0) and (ARow > 0) then
    begin
        if Cells[Acol,Arow] <> '' then
        begin
          cellvoltage := StrToFloat(Cells[ACol,ARow]);
          Canvas.Brush.Color := RGBColour(cellvoltage, minvoltage, maxvoltage, false);
        end
        else
          Canvas.Brush.Color := $FFFFFF;
        Canvas.FillRect(Rect);
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
begin
 with TStringGrid(Sender) do
  begin
    if (ACol > 0) and (ARow > 0) then
    begin

        if Cells[Acol,Arow] <> '' then
        begin
          temp := StrToFloat(Cells[ACol,ARow]);
          if ( temp > mintemp ) and ( temp < lowtemp ) then
            temp := lowtemp;
          Canvas.Brush.Color := RGBColour(temp, lowtemp, maxtemp, true);
        end
        else
          Canvas.Brush.Color := $FFFFFF;
    //      Canvas.Brush.Color := ERRLowRGB;
        Canvas.FillRect(Rect);
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
          1 :
          begin
            StatusMsg.Lines.add('test');
          end;
          10 :  // PEC
          begin
            PECVal := Get32BitBE(msg,0);
            PECAvgVal := Get32BitBE(msg,4);
          end;

          14 :
            begin
              uptime.Caption := IntToStr(Get32BitBE(msg,0));
            end;

          15 : // power
            begin
              PowerVal := Get32BitBE(msg,0);
            //  CurrentVal := (Int16)((rxData[4] << 8) | (rxData[5] << 0));
            end;

          1313 :  // current from ivt
            begin
              CurrentVal := Get32BitBE(msg,2) / 1000;
            end;

          1553 : //   read_curr_real()
          begin
            ChargeCurrent.Caption := IntToStr(Get16BitBE(msg,6) div 100);
            //Added output voltage actual to this function. Function name misleading
            ChargeVoltage.Caption := IntToStr(Get16BitBE(msg,4) div 5);
          end;


          7 :  //    private void read_time()
          begin
      //      hour = IntToStr(Get32BitBE(msg,0));    // why sending twice?
      //      minute = IntToStr(Get32BitBE(msg,4));
          end;

          8 :
          begin
      //      second = IntToStr(Get32BitBE(msg,0));
      //      labelTime.Text = "Uptime(formatted): " + hour.ToString() + ":" + minute.ToString() + ":" + second.ToString();
            Uptime.Caption := IntToStr(Get32BitBE(msg,4));
          end;

          9 : // private void read_state()
          begin
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

            if IsBitSet(i, 0) then str := str + ' core';
            if IsBitSet(i, 1) then str := str + ' balance';
            if IsBitSet(i, 2) then str := str + ' charge';
            if IsBitSet(i, 3) then str := str + ' debug';
            if IsBitSet(i, 3) then str := str + ' log';

          end;

          1909..1911 :    //   private void read_disch()
          begin
            col := (id-1909)*12*4;

            for i := 0 to 11 do
              for j := 0 to 4 do
              begin
                row := col+j*12+i;
              if IsBitSet(Get16BitBE(msg,j*2),i) then
                AccCells[row].discharging := true
              else
                AccCells[row].discharging := false;
              end;
          end;

          1912 .. (1912+(12*3)-1) :
              begin
                col := trunc((id-1912)/3)*12;
                row := trunc((id-1912)mod 3)*4;

                AccCells[col+0+row].Voltage := Get16BitBE(msg,0);
                AccCells[col+0+row].received := true;
                AccCells[col+1+row].Voltage := Get16BitBE(msg,2);
                AccCells[col+1+row].received := true;
                AccCells[col+2+row].Voltage := Get16BitBE(msg,4);
                AccCells[col+2+row].received := true;
                AccCells[col+3+row].Voltage := Get16BitBE(msg,6);
                AccCells[col+3+row].received := true;
              end;

          1948 .. ( 1948+(12*2)-1 ) :
              begin
                col := trunc((id-1948) / 2 )*5; //  set starting cell to work down from
                row := ((id-1948) mod 2 )*4;

                Temps[col+ 0 + row].Temperature :=Get16BitBE(msg,0);
                Temps[col+ 0 + row].received := true;
                if row < 5 then
                begin
                  Temps[col+ 1 + row].Temperature := (Get16BitBE(msg,2));
                  Temps[col+ 1 + row].received := true;
                  Temps[col+ 2 + row].Temperature := (Get16BitBE(msg,4));
                  Temps[col+ 2 + row].received := true;
                  Temps[col+ 3 + row].Temperature := (Get16BitBE(msg,6));
                  Temps[col+ 3 + row].received := true;
                end;
              end;

          1901 :
              begin
                PORF.Checked :=  IsBitSet(msg[0], 0);
                EXTRF.Checked := IsBitSet(msg[0], 1);
                BORF.Checked :=  IsBitSet(msg[0], 2);
                WDRF.Checked :=  IsBitSet(msg[0], 3);
                JTRF.Checked :=  IsBitSet(msg[0], 4);
              end;

        end;


      end;
    end;
  end;
end;



procedure TBMSMonForm.Update;
var
  i,j, count : integer;
  ready : Boolean;
  maxV, minV, maxT, minT, SOCval, v, t : real;
begin
  ready := true;
  for i := 0 to 11 do
    for j := 0 to 11 do
      if not AccCells[i*12+j].received then
      begin
        ready := false;
        count := count +1;
      end;



  if ready then      // received all ready, ready to update view.
  begin
    minv := AccCells[0].voltage;
    maxv := minv;

    for i := 0 to 11 do
      for j := 0 to 11 do
      begin
        v := AccCells[i*12+j].Voltage;
        VoltageGrid.Cells[i+1,j+1] := floattostrf(v,ffFixed,4,3);
        if v > maxV then
          maxV := v;
        if v < minV then
          minV := v;
        socval := socval + v;
      end;

    AvgV.Caption := floattostrf(socval / 144,ffFixed,4,3);
    DeltaV.Caption := floattostrf(maxV - minV, ffFixed,4,3);
    HighestCell.Caption := floattostrf(maxV, ffFixed,4,3);
    LowestCell.Caption := floattostrf(minV, ffFixed,4,3);
    SOC.Caption := floattostrf(socval, ffFixed,4,3);

    mint := Temps[0].Temperature;
    maxt := mint;
    socval := 0;

    for i := 0 to 11 do
      for j := 0 to 4 do
      begin
        t := Temps[i*5+j].Temperature;
        TemperatureGrid.Cells[i+1,j+1] := floattostrf(t,ffFixed,4,3);
        if t > maxT then
          maxt := t;
        if t < mint then
          mint := t;
        socval := socval + t;
      end;
    socval := socval / 60;

    HighestNTC.Caption := floattostrf((maxT), ffFixed,4,3);
    LowestNTC.Caption := floattostrf((minT), ffFixed,4,3);
    AvgTemp.Caption := floattostrf((socval), ffFixed,4,3);
    PEC.Caption := IntToStr(PECVal);
    PECAvg.Caption := IntToStr(PECAvgVal);
    Power.Caption := IntToStr(PowerVal);
    Current.Caption := floattostrf(CurrentVal / 1000, ffFixed, 4,3);

    ChargeCurrent.Caption := floattostrf(ChargeCurrentVal, ffFixed, 6,3);
    ChargeVoltage.Caption := floattostrf(ChargeVoltageVal, ffFixed, 6,3);

    for i := 0 to 143 do
      AccCells[i].received := false;
    for i := 0 to 59 do
      Temps[i].received := false;
  end;

end;

end.
