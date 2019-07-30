import strformat, strutils, os, threadpool
import ../src/rsnim

init()

if paramCount() != 1:
  quit("Usage: ./main ips.txt")

let file = paramStr(1)
if not fileExists(file):
  quit("Specified file doesn't exist!")

var ips = newSeq[string]()

for line in lines(file):
  if line == "": continue
  # Just for the example use 80 and 8080 ports
  ips.add(line & ":80")
  ips.add(line & ":8080")


# Set max verbosity for debugging
debug.set(true)
debugVerbosity.set(byte(3))

onTableChange:
  if name == "Auth":
    echo &"Got auth: IP: {ips[row]}, auth data: {value}"

onWriteLog:
  echo $verb & " - " & log

# Limit max number of threads by 16
setMaxPoolSize(16)

# We use index (i) for row number
for i, ip in ips:
  spawn scan(ip, i)

# Wait for all threads to complete
sync()