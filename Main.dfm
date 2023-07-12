object BMSMonForm: TBMSMonForm
  Left = 0
  Top = 0
  Caption = 'BMSMonForm'
  ClientHeight = 768
  ClientWidth = 1139
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clDefault
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object OnBus: TLabel
    Left = 16
    Top = 34
    Width = 36
    Height = 13
    Caption = 'Off Bus'
  end
  object TimeReceived: TLabel
    Left = 99
    Top = 35
    Width = 66
    Height = 13
    Caption = 'TimeReceived'
  end
  object OpModeLabel: TLabel
    Left = 864
    Top = 34
    Width = 40
    Height = 13
    Caption = 'Opmode'
  end
  object OpMode: TLabel
    Left = 912
    Top = 34
    Width = 40
    Height = 13
    Caption = 'OpMode'
  end
  object SafeStateReasonLabel: TLabel
    Left = 864
    Top = 544
    Width = 109
    Height = 13
    Caption = 'SafeStateReasonLabel'
  end
  object SafeStateReason: TLabel
    Left = 979
    Top = 544
    Width = 84
    Height = 13
    Caption = 'SafeStateReason'
  end
  object FanSpeedLabel: TLabel
    Left = 384
    Top = 602
    Width = 51
    Height = 13
    Caption = 'Fan Speed'
  end
  object ChargingCurrentLabel: TLabel
    Left = 106
    Top = 602
    Width = 55
    Height = 13
    Caption = 'Charge Cur'
  end
  object StatusLabel: TLabel
    Left = 384
    Top = 8
    Width = 102
    Height = 40
    Caption = 'Status:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clDefault
    Font.Height = -33
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Status: TLabel
    Left = 504
    Top = 10
    Width = 96
    Height = 40
    Caption = 'Offline'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clDefault
    Font.Height = -33
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object VoltageGrid: TStringGrid
    Left = 8
    Top = 62
    Width = 850
    Height = 235
    ColCount = 19
    DefaultColWidth = 43
    Enabled = False
    RowCount = 9
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clDefault
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssNone
    TabOrder = 0
    OnDrawCell = VoltageGridDrawCell
  end
  object TemperatureGrid: TStringGrid
    Left = 8
    Top = 303
    Width = 849
    Height = 233
    ColCount = 10
    DefaultColWidth = 86
    Enabled = False
    RowCount = 9
    ScrollBars = ssNone
    TabOrder = 1
    OnDrawCell = TemperatureGridDrawCell
  end
  object CanDevices: TComboBox
    Left = 99
    Top = 8
    Width = 145
    Height = 21
    Style = csDropDownList
    TabOrder = 2
    OnChange = CanDevicesChange
  end
  object goOnBus: TButton
    Left = 8
    Top = 6
    Width = 75
    Height = 25
    Caption = 'Go on bus'
    TabOrder = 3
    OnClick = goOnBusClick
  end
  object BalancingMode: TRadioGroup
    Left = 99
    Top = 631
    Width = 481
    Height = 130
    Caption = 'Balancing'
    ItemIndex = 0
    Items.Strings = (
      'No Balancing'
      'Discharge all cells whose voltage is above '#39'min_voltage + delta'#39
      
        'Discharge Only the highest cell. If max_voltage - min_voltage < ' +
        'Delta, no discharge is done.'
      
        'Discharge all cells whose voltage is above '#39'average cell voltage' +
        ' + delta'#39
      'Discharge all cells to 3.8V for storage ( Atmel currently )')
    TabOrder = 4
    OnClick = BalancingModeClick
  end
  object Charge: TButton
    Left = 8
    Top = 599
    Width = 75
    Height = 25
    Caption = 'Charge'
    Enabled = False
    TabOrder = 5
    OnClick = ChargeClick
  end
  object LoggingEnabled: TCheckBox
    Left = 264
    Top = 10
    Width = 97
    Height = 17
    Hint = 'Not yet implemented.'
    Caption = 'LoggingEnabled'
    Enabled = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 6
  end
  object VoltageGroup: TGroupBox
    Left = 864
    Top = 56
    Width = 161
    Height = 129
    Caption = 'Voltages'
    TabOrder = 7
    object HighestCellLabel: TLabel
      Left = 18
      Top = 24
      Width = 56
      Height = 13
      Caption = 'Highest Cell'
    end
    object LowestCellLabel: TLabel
      Left = 18
      Top = 43
      Width = 54
      Height = 13
      Caption = 'Lowest Cell'
    end
    object DeltaVLabel: TLabel
      Left = 18
      Top = 62
      Width = 64
      Height = 13
      Caption = 'Delta Voltage'
    end
    object AvgVLabel: TLabel
      Left = 18
      Top = 81
      Width = 58
      Height = 13
      Caption = 'Avg Voltage'
    end
    object SOCLabel: TLabel
      Left = 18
      Top = 100
      Width = 21
      Height = 13
      Caption = 'SOC'
    end
    object HighestCell: TLabel
      Left = 106
      Top = 24
      Width = 4
      Height = 13
      Caption = '-'
    end
    object LowestCell: TLabel
      Left = 106
      Top = 43
      Width = 4
      Height = 13
      Caption = '-'
    end
    object DeltaV: TLabel
      Left = 106
      Top = 62
      Width = 4
      Height = 13
      Caption = '-'
    end
    object AvgV: TLabel
      Left = 106
      Top = 81
      Width = 4
      Height = 13
      Caption = '-'
    end
    object SOC: TLabel
      Left = 106
      Top = 100
      Width = 4
      Height = 13
      Caption = '-'
    end
  end
  object TemperatureGroup: TGroupBox
    Left = 864
    Top = 191
    Width = 161
    Height = 89
    Caption = 'Temperatures'
    TabOrder = 8
    object HighestNTCLabel: TLabel
      Left = 18
      Top = 24
      Width = 59
      Height = 13
      Caption = 'Highest NTC'
    end
    object LowestNTCLabel: TLabel
      Left = 18
      Top = 43
      Width = 57
      Height = 13
      Caption = 'Lowest NTC'
    end
    object AvgTempLabel: TLabel
      Left = 18
      Top = 62
      Width = 48
      Height = 13
      Caption = 'Avg Temp'
    end
    object HighestNTC: TLabel
      Left = 106
      Top = 24
      Width = 4
      Height = 13
      Caption = '-'
    end
    object LowestNTC: TLabel
      Left = 106
      Top = 43
      Width = 4
      Height = 13
      Caption = '-'
    end
    object AvgTemp: TLabel
      Left = 106
      Top = 62
      Width = 4
      Height = 13
      Caption = '-'
    end
  end
  object ChargingGroup: TGroupBox
    Left = 864
    Top = 286
    Width = 161
    Height = 227
    Caption = 'Charging'
    TabOrder = 9
    object PowerLabel: TLabel
      Left = 18
      Top = 24
      Width = 30
      Height = 13
      Caption = 'Power'
    end
    object CurrentLabel: TLabel
      Left = 18
      Top = 43
      Width = 37
      Height = 13
      Caption = 'Current'
    end
    object ChargeCurrentLabel: TLabel
      Left = 18
      Top = 62
      Width = 75
      Height = 13
      Caption = 'Charge Current'
    end
    object Power: TLabel
      Left = 106
      Top = 24
      Width = 4
      Height = 13
      Caption = '-'
    end
    object Current: TLabel
      Left = 106
      Top = 43
      Width = 4
      Height = 13
      Caption = '-'
    end
    object ChargeCurrent: TLabel
      Left = 106
      Top = 62
      Width = 4
      Height = 13
      Caption = '-'
    end
    object ChargeVoltageLabel: TLabel
      Left = 18
      Top = 81
      Width = 74
      Height = 13
      Caption = 'Charge Voltage'
    end
    object ChargeVoltage: TLabel
      Left = 106
      Top = 81
      Width = 4
      Height = 13
      Caption = '-'
    end
    object PECLabel: TLabel
      Left = 18
      Top = 100
      Width = 19
      Height = 13
      Caption = 'PEC'
    end
    object PECAvgLabel: TLabel
      Left = 18
      Top = 119
      Width = 41
      Height = 13
      Caption = 'PEC Avg'
    end
    object PEC: TLabel
      Left = 106
      Top = 100
      Width = 4
      Height = 13
      Caption = '-'
    end
    object PECAvg: TLabel
      Left = 106
      Top = 119
      Width = 4
      Height = 13
      Caption = '-'
    end
    object OperatingModeLabel: TLabel
      Left = 18
      Top = 138
      Width = 77
      Height = 13
      Caption = 'Operating Mode'
    end
    object OperatingMode: TLabel
      Left = 106
      Top = 138
      Width = 4
      Height = 13
      Caption = '-'
    end
    object UptimeLabel: TLabel
      Left = 18
      Top = 157
      Width = 33
      Height = 13
      Caption = 'Uptime'
    end
    object Uptime: TLabel
      Left = 106
      Top = 157
      Width = 4
      Height = 13
      Caption = '-'
    end
    object AIRLabel: TLabel
      Left = 18
      Top = 176
      Width = 47
      Height = 13
      Caption = 'AIR State'
    end
    object AIRState: TLabel
      Left = 106
      Top = 176
      Width = 4
      Height = 13
      Caption = '-'
    end
    object PREStateLabel: TLabel
      Left = 18
      Top = 195
      Width = 48
      Height = 13
      Caption = 'PRE State'
    end
    object PREState: TLabel
      Left = 106
      Top = 195
      Width = 4
      Height = 13
      Caption = '-'
    end
  end
  object StatusMsg: TMemo
    Left = 687
    Top = 598
    Width = 442
    Height = 133
    ReadOnly = True
    TabOrder = 10
  end
  object ResetReasonGroup: TGroupBox
    Left = 1031
    Top = 289
    Width = 98
    Height = 224
    Caption = 'Reset Reason'
    TabOrder = 11
    object PORF: TCheckBox
      Left = 16
      Top = 24
      Width = 97
      Height = 17
      Caption = 'PORF'
      Enabled = False
      TabOrder = 0
    end
    object EXTRF: TCheckBox
      Left = 16
      Top = 47
      Width = 97
      Height = 17
      Caption = 'EXTRF'
      Enabled = False
      TabOrder = 1
    end
    object BORF: TCheckBox
      Left = 16
      Top = 70
      Width = 97
      Height = 17
      Caption = 'BORF'
      Enabled = False
      TabOrder = 2
    end
    object WDRF: TCheckBox
      Left = 16
      Top = 93
      Width = 97
      Height = 17
      Caption = 'WDRF'
      Enabled = False
      TabOrder = 3
    end
    object JTRF: TCheckBox
      Left = 16
      Top = 116
      Width = 97
      Height = 17
      Caption = 'JTRF'
      Enabled = False
      TabOrder = 4
    end
  end
  object SafeState: TCheckBox
    Left = 864
    Top = 519
    Width = 97
    Height = 17
    Caption = 'SafeState'
    Enabled = False
    TabOrder = 12
  end
  object FanSpeedSlider: TScrollBar
    Left = 528
    Top = 598
    Width = 153
    Height = 21
    Max = 128
    PageSize = 0
    TabOrder = 13
    OnChange = FanSpeedSliderChange
  end
  object FanSpeedEdit: TEdit
    Left = 441
    Top = 599
    Width = 81
    Height = 21
    NumbersOnly = True
    TabOrder = 14
    Text = '0'
    OnChange = FanSpeedEditChange
  end
  object ChargeCurrentSlider: TScrollBar
    Left = 211
    Top = 599
    Width = 146
    Height = 21
    Max = 60
    PageSize = 0
    TabOrder = 15
    OnChange = ChargeCurrentSliderChange
  end
  object ChargeCurrentEdit: TEdit
    Left = 167
    Top = 599
    Width = 38
    Height = 21
    NumbersOnly = True
    TabOrder = 16
    Text = '0'
    OnChange = ChargeCurrentEditChange
  end
  object RandomFill: TButton
    Left = 8
    Top = 706
    Width = 75
    Height = 25
    Caption = 'RandomFill'
    TabOrder = 17
    OnClick = RandomFillClick
  end
  object StopButton: TButton
    Left = 8
    Top = 630
    Width = 75
    Height = 25
    Caption = 'Stop'
    Enabled = False
    TabOrder = 18
    OnClick = StopButtonClick
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 256
    Top = 32
  end
end
