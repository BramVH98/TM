#<?xml version="1.0" encoding="utf-8"?>
#<pfSense>
#    <vlans>
#spaces = 5
#        <vlan>
#spaces = 9         
#            <if>vmx1</if>
#spaces = 13             
#            <tag>1</tag>
#        </vlan>
#        <vlan>
#            <if>vmx1</if>
#            <tag>2</tag>
#        </vlan>
#        <!-- Add more <vlan> entries for each VLAN -->
#    </vlans>
#</pfSense>

with open("pfsenseVLANS.xml", "w") as conf_file:

    fivespaces = ' ' * 5
    thirteenspaces = ' ' * 13
    ninespaces = ' ' * 9

    conf_file.write(f'<?xml version="1.0" encoding="utf-8"?>\n<pfSense>\n')
    conf_file.write(f'{fivespaces}<vlans>\n')

    for i in range(0, 200):
        conf_file.write(f'{ninespaces}<vlan>\n')
        conf_file.write(f'{thirteenspaces}<if>vmx1</if>\n')
        conf_file.write(f'{thirteenspaces}<tag>{i+2}</tag>\n')
        conf_file.write(f'{ninespaces}</vlan>\n')
    conf_file.write(f'{fivespaces}</vlans>\n')
    conf_file.write(f'</pfSense>')
