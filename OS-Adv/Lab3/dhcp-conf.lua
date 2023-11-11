file = io.open("dhcp-conf.txt", "w")
io.output(file)
ip_base = "10.0."
range_start = 3
range_end = 14

octet3 = 0
octet4 = 0

for i = 2, 201 do
    if octet4 > 255 then
        octet4 = 0
        octet3 = octet3 + 1
    end

    io.write("echo subnet " .. ip_base .. octet3 .. "." .. octet4 .. " netmask 255.255.255.240 '{' >> /etc/dhcpd.conf")
    io.write("\necho \"    range dynamic-bootp " .. ip_base .. octet3 .. "." .. (range_start + octet4) .. " " .. ip_base .. octet3 .. "." .. (range_end + octet4) .. ";\" >> /etc/dhcpd.conf\n")
    io.write("echo \"    option routers " .. ip_base .. octet3 .. "." .. (range_start - 1 + octet4) .. ";\" >> /etc/dhcpd.conf\n")
    io.write("echo } >> /etc/dhcpd.conf\n")

    octet4 = octet4 + 16
end

io.close(file)

