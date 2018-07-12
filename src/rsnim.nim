import strutils, strscans
import rsnim/librouter

type
  Word = uint16

  DWord = uint32

  Module* = ref object        ## LibRouter module
    enabled*: bool            ## module status (enabled/disabled)
    name*, desc*: string      ## module name and description

  SettingContainer*[T] = object
    ## A container object for LibRouter settings
    setting: Setting

  Proxy* = enum               ## Available proxy types
    None, HttpAndS, HttpConnect, Socks4, Socks4a, Socks5



converter toDword(s: Setting): DWord =
  ## Implicitly converts values of Setting enum to DWord
  DWord(s)


template checkRaise(call: untyped): untyped =
  ## Checks if `call` returns "false" and raises exception if it does
  if not call:
    raise newException(ValueError, astToStr(call) & " didn't succeed!")


template strToPointer(str: untyped): untyped = str[0]. addr


template newSetting(settingData, typ: untyped): untyped =
  SettingContainer[typ](setting: settingData)


proc get*[T](s: SettingContainer[T]): T =
  ## Gets a value from `s`

  var outLen: DWord
  when T is string:
    # We need to preallocate memory for the GetParamA call
    # We use 1 MB of memory here, it should enough for most purposes
    setLen(result, 1024 * 1024 * 1)
    checkRaise GetParamA(s.setting, result[0]. addr, len(result), outLen)
    # Resize our string to the outLen (so unneeded memory will be freed)
    setLen(result, int(outLen))

  # If a value is SomeOrdinal it can be converted to DWord and can be easily
  # passed regardless if it's integer or boolean
  elif T is SomeOrdinal:
    checkRaise GetParamW(s.setting, addr result, DWord(sizeof(result)),
        outLen)


proc set*[T](s: var SettingContainer[T], data: T) =
  ## Sets a setting to some value 

  # Works for enums and any int/uint types
  when compiles(DWord(data)):
    checkRaise SetParamW(s.setting, DWord(data))
  # For cstrings and strings
  elif data is cstring | string:
    var param = data
    checkRaise SetParamA(s.setting, strToPointer(param))
  # If we can actually pass the value with the same type
  elif compiles(SetParamW(s.setting, data)):
    checkRaise SetParamW(s.setting, data)


var debug* = newSetting(EnableDebug, bool)

var debugVerbosity* = newSetting(DebugVerbosity, byte)

var userAgent* = newSetting(UserAgent, string)

var useCustomPage* = newSetting(UseCustomPage, bool)

var dualAuthCheck* = newSetting(DualAUthCheck, bool)


# We don't export these because we provide `setProxy` and `setCredentials`
# procedures which are easier to use
var proxyType = newSetting(ProxyType, Proxy)
var proxyIp = newSetting(ProxyIP, string)
var proxyPort = newSetting(ProxyPort, int)
var useCredentials = newSetting(UseCredentials, bool)
var credsUsername = newSetting(CredentialsUsername, string)
var credsPassword = newSetting(CredentialsPassword, string)
var proxyAuth = newSetting(ProxyUseAuth, bool)
var proxyUser = newSetting(ProxyUser, string)
var proxyPass = newSetting(ProxyPass, string)

proc setProxy*(kind: Proxy, address: string, username = "", pass = "") =
  ## Enables the proxy with the type `kind` and address ("ip:port") `address`
  ##
  ## If `username` or/and `pass` are provided, proxy will use authentication
  ##
  ## ValueError is raised if `address` is not valid
  proxyType.set(kind)
  let temp = address.split(":")
  if temp.len != 2:
    raise newException(ValueError, "Invalid proxy address!")

  proxyIp.set(temp[0])
  proxyPort.set(parseInt(temp[1]))
  if username != "" or pass != "":
    proxyAuth.set(true)
    proxyUser.set(username)
    proxyPass.set(pass)


proc setCredentials*(user, pass: string) =
  useCredentials.set(true)
  credsUsername.set(user)
  credsPassword.set(pass)


proc registerCallback(
  fun: proc (rawRow: DWord, rawName, rawValue: WideCString) {.nimcall.}) =
  # We need to declare proc as {.nimcall.} here and in the onTableChange 
  # so it doesn't become a closure
  checkRaise SetParamW(SetTableDataCallback, cast[pointer](fun))

template onTableChange*(body: untyped) =
  ## Can be used to set a callback for any change in scan table
  ## You can access these parameters in the body:
  ## - `row` (int) - current row
  ## - `name` (string) - name of changed column
  ## - `value` (string) - value of changed column
  ##
  ## You can declare only *one* callback currently!
  bind registerCallback

  proc onChange(rawRow: DWord, rawName, rawValue: WideCString) {.nimcall.} =
    let row {.inject.} = int(rawRow)
    let name {.inject.} = $rawName
    let value {.inject.} = $rawValue
    body

  registerCallback(onChange)


var modules*: seq[Module]     ## A sequence of all modules available


proc switchModule(m: Module, state: bool) =
  checkRaise SwitchModule(DWord(modules.find(m)), state)
  m.enabled = state           # Change module state on Nim side too


template enableModule*(m: Module): untyped =
  ## Enables module `m`
  switchModule(m, true)

template disableModule*(m: Module): untyped =
  ## Disables module `m`
  switchModule(m, false)


proc init* =
  ## Initializes LibRouter library and retrieves all available modules
  ##
  ## Should be called **ONCE** in the entire application
  checkRaise Initialize()

  var moduleCount: DWord
  checkRaise GetModuleCount(moduleCount)

  for i in 0'u32 ..< moduleCount:
    var raw: ModuleDesc
    checkRaise GetModuleInfoW(i, addr raw)
    modules.add(
      Module(
        enabled: raw.enabled,
        name: $ cast[WideCString](addr(raw.name[0])),
        desc: $ cast[WideCString](addr(raw.name[0]))
      )
    )

proc scan*(address: string, row: int) =
  ## Scans the IP:port combination `address` with the row `row`
  ##
  ## Blocks until completion; can be used in multiple threads
  let temp = address.split(":")

  if temp.len() != 2:
    raise newException(ValueError, "Invalid address format!")

  let ipStr = temp[0]
  let port = parseInt(temp[1])

  var ipAddr: DWord
  # IP address octets
  var a, b, c, d: int

  proc ipAddrToUint(a, b, c, d: int): DWord =
    result = DWord((a shl 24) or (b shl 16) or (c shl 8) or (d))

  if scanf(ipStr, "$i.$i.$i.$i", a, b, c, d):
    ipAddr = ipAddrToUint(a, b, c, d)
  else:
    raise newException(ValueError, "Invalid IP address!")

  var routerPtr: pointer
  checkRaise PrepareRouter(DWord(row), ipAddr, Word(port), addr routerPtr)
  checkRaise ScanRouter(routerPtr)
  checkRaise FreeRouter(routerPtr)
