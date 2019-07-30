type
  Setting* = enum 
    EnableDebug, DebugVerbosity, WriteLogCallback, SetTableDataCallback, 
    UserAgent, UseCustomPage, CustomPage, DualAuthCheck, PairsBasic, PairsDigest,
    ProxyType, ProxyIP, ProxyPort, UseCredentials, CredentialsUsername, 
    CredentialsPassword, PairsFrom, FilterRules, ProxyUseAuth, ProxyUser, 
    ProxyPass

  Cells* = enum
    Status, Auth, Type, RadioOff, Hidden, CheckX = "[X]", Minus = "-", BSSID, 
    NoWireless = "<no wireless>", SSID, Sec, Key, WPS, LANIP, LANMask, 
    Bridge = "<bridge>", WANIP, WANMask, WANGate, DNS
  
  Word* = uint16
  
  DWord* = uint32

  ModuleDesc* = object
    enabled*: bool
    empty: array[3, byte] # For alignment :)
    name*: array[16, Utf16Char]
    desc*: array[32, Utf16Char]
  
  ModuleDescPtr* = ptr ModuleDesc

const
  librouterdll = 
    when defined(Windows): "librouter.dll" 
    elif defined(Linux): "liblibrouter.so"
    else: "No librouter for your platform :(" 

{.pragma: librouter, discardable, stdcall, importc, dynlib: librouterdll.}


proc Initialize*: bool {.librouter.}
proc GetModuleCount*(count: var DWord): bool {.librouter.}
proc GetModuleInfoW*(index: DWord, info: ptr ModuleDesc): bool {.librouter.}
proc SwitchModule*(index: DWord, enabled: bool): bool {.librouter.}
proc GetParamW*(st: DWord, value: var DWord, size: DWord, outLength: var DWord): bool {.librouter.}
proc GetParamW*(st: DWord, value: pointer, size: DWord, outLength: var DWord): bool {.librouter.}
proc GetParamW*(st: DWord, value: var bool, size: DWord, outLength: var DWord): bool {.librouter.}
proc GetParamA*(st: DWord, value: pointer, size: DWord, outLength: var DWord): bool {.librouter.}
proc SetParamW*(st: DWord, value: uint): bool {.librouter.}
proc SetParamW*(st: DWord, value: pointer): bool {.librouter.}
proc SetParamA*(st: DWord, value: pointer): bool {.librouter.}
proc PrepareRouter*(row, ip: DWord, port: Word, hRouter: pointer): bool {.librouter.}
proc ScanRouter*(hRouter: pointer): bool {.librouter.}
proc StopRouter*(hRouter: pointer): bool {.librouter.}
proc IsRouterStopping*(hRouter: pointer): bool {.librouter.}
proc FreeRouter*(hRouter: pointer): bool {.librouter.}

proc SetParamW*(st: DWord, value: bool): bool {.stdcall, discardable.} = 
  result = SetParamW(st, uint(value))