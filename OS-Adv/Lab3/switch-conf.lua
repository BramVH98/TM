file = io.open("switch-conf.txt", "w")
ip = "10.0."
octet3 = 0
octet4 = 1
io.output(file)

io.write("configure terminal")

for i=2,201 do
  io.write("\nvlan "..i)
  io.write("\nname VLAN"..i)
  io.write("\ninterface vlan "..i)
  io.write("\nip address "..ip..octet3.."."..octet4.." 255.255.255.240")

  octet4 = octet4 + 16
  if octet4 > 255 then
     octet4 = 1
     octet3 = octet3 + 1
  end
  io.write("\n!")
end

io.write("\nend")
io.close(file)
