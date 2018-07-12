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
  if line == "":
    continue
  let temp = line.split(":")
  if temp.len != 2:
    # Skip invalid entries
    echo "Wrong IP format: " & line
    continue
  ips.add(line)


onTableChange:
  if name == "Auth":
    echo &"Got auth: IP: {ips[row]}, auth data: {value}"

# We use index (i) for row number
for i, ip in ips:
  spawn scan(ip, i)

# Wait for all threads to complete
sync()