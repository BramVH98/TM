file = io.open("suse-vlan.txt","w")
io.output(file)
ip_base = "10.0."
octet3 = 0
octet4 = 2

for i = 2,201 do
    if octet4 > 255 then
        octet4 = 0
        octet3 = octet3 + 1
    end
    
    io.write("echo IPADDR=\\'"..ip_base..octet3.."."..octet4.."\\' >> ifcfg-vlan"..i)
    io.write("\necho BOOTPROTO=\\'static\\' >> ifcfg-vlan"..i)
    io.write("\necho STARTMODE=\\'hotplug\\' >> ifcfg-vlan"..i)
    io.write("\necho NETMASK=\\'255.255.255.240\\' >> ifcfg-vlan"..i)
    io.write("\necho ZONE=public >> ifcfg-vlan"..i)
    io.write("\necho VLAN=\\'yes\\' >> ifcfg-vlan"..i)
    io.write("\necho ETHERDEVICE=\\'eth1\\' >> ifcfg-vlan"..i.."\n")
    
    octet4 = octet4 + 16
end

io.close(file)
