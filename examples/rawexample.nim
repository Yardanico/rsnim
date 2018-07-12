# Example of usage of the raw API
# Has the same functionality as the DemoApp in the `src` folder of RouterScan
import strformat, strutils, strscans, os
import ../src/rsnim/librouter

template check(data: untyped): untyped = 
  ## Template to check if a call to API failed or not
  let res = data
  let toStr = astToStr(data)
  if res:
    echo "[+] " & toStr
  else:
    quit "[-] " & toStr

template strToPointer(str: untyped): pointer = 
  str[0].addr

check Initialize()

var mCount: DWord
check GetModuleCount(mCount)
  
for i in 0'u32 ..< mCount:
  var module: ModuleDesc
  check GetModuleInfoW(i, addr module)
  stdout.write("Module name: " & $cast[WideCString](module.name[0].addr))
  echo if module.enabled: "enabled)" else: "disabled)"
  echo "Module desc: ", $cast[WideCString](module.desc[0].addr)
  echo ""


check SetParamW(DWord(ProxyType), 0)
var ua = newWideCString("Mozilla/5.0 (Windows NT 5.1; rv:9.0.1) Gecko/20100101 Firefox/9.0.1")

check SetParamW(DWord(UserAgent), strToPointer(ua))
check SetParamW(DWord(UseCustomPage), false)
check SetParamW(DWord(DualAuthCheck), false)

echo "Settings updated"
var pairs = newWideCString("admin\tadmin\r\nadmin\t1234\r\nadmin\tpassword\r\n")

check SetParamW(DWord(PairsBasic), strToPointer(pairs))
check SetParamW(DWord(PairsDigest), strToPointer(pairs))
check SetParamW(DWord(PairsFrom), strToPointer(pairs))

echo "Pairs updated"

proc setTableDataW(row: DWord, name, value: WideCString) {.stdcall.} = 
  if row != 123:
    quit("Can't actually happen :)")
  # `WideCString` is converted to Nim's `string` via `$`
  echo($name & ": " & $value)

check SetParamW(DWord(SetTableDataCallback), cast[pointer](setTableDataW))

stdout.write("Enter IP address to scan (e.g. 192.168.1.1): ")

let ipAddrStr = readLine(stdin)

var
  ipAddr: DWord 
  a, b, c, d: int

proc ipAddrToUint(a, b, c, d: int): DWord = 
  result = DWord((a shl 24) or (b shl 16) or (c shl 8) or (d))


if scanf(ipAddrStr, "$i.$i.$i.$i", a, b, c, d):
  ipAddr = ipAddrToUint(a, b, c, d)
else:
  quit("Wrong IP address format!")

stdout.write("Enter port number: ")
var port = Word(parseInt(readLine(stdin)))

var routerPtr: pointer
check PrepareRouter(123, ipAddr, 80, addr routerPtr)

echo "Scanning router..."

check ScanRouter(routerPtr)
check FreeRouter(routerPtr)