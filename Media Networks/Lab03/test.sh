#!/bin/bash

# installation
sudo apt -qq update;
sudo apt -qq upgrade;
sudo apt -qq install asterisk;

cd /etc/asterisk
# sip-config
sudo mv sip.conf sip.conf.bak >/dev/null 2>&1;

read -rp "What is your provider register name: " REGISTERNAME;
read -rp "What is your provider register password: " REGISTERPASSWORD;


    echo -e "[general]
    context=public                  ; Default context for incoming calls. Defaults to 'default'
    allowoverlap=no                 ; Disable overlap dialing support. (Default is yes)
    udpbindaddr=0.0.0.0             ; IP address to bind UDP listen socket to (0.0.0.0 binds to all)
    tcpenable=no                    ; Enable server for incoming TCP connections (default is no)
    tcpbindaddr=0.0.0.0             ; IP address for TCP server to bind to (0.0.0.0 binds to all interfaces)
    transport=udp                   ; Set the default transports.  The order determines the primary default transport.
    srvlookup=yes                   ; Enable DNS SRV lookups on outbound calls
    qualify=yes                     ; monitors the phone (available, speed, etc.)"
    register=$REGISTERNAME:$REGISTERPASSWORD@sip0-d.voice.weepee.io
 >> sip.conf;

while [ "$OK" != 1 ]
do
    read -rp "What language do you want to use (nl/en): " LANGUAGE;
    
    if [ "$LANGUAGE" == "nl" ]
    then
        echo -e "language=nl" >> sip.conf;
        
        sudo wget "https://raw.githubusercontent.com/BramVH98/TM/main/Media%20Networks/Lab03/AsteriskNederlandstaligeAudiobestanden.7z"
        #sudo apt -qq install unzip;
        #sudo unzip "AsteriskNederlandstaligeAudiobestanden.7z";
		sudo apt -qq install p7zip-full;
		7z x AsteriskNederlandstaligeAudiobestanden.7z
        sudo rm -R /usr/share/asterisk/sounds/nl >/dev/null 2>&1;
        #sudo mv "AsteriskNederlandstaligeAudiobestanden" "nl";
        sudo mv "nl" "/usr/share/asterisk/sounds";
        
        OK=1;
    fi
    
    if [ "$LANGUAGE" == "en" ]
    then
        echo -e "language=en" >> sip.conf;

        
        sudo apt -qq install unzip;
        #sudo unzip "audio_en.zip";
        #sudo rm -R /usr/share/asterisk/sounds/en >/dev/null 2>&1;
        #sudo mv "audio_en" "en";
        #sudo mv "en" "/usr/share/asterisk/sounds";

        OK=1;
    fi
    
    if [ "$OK" != 1 ]
    then
        echo -e "Not a supported language";
    fi
    
done


    echo -e "[authentication]
    [basic-options](!)
    dtmfmode=rfc2833
    context=from-office
    type=friend
    [natted-phone](!,basic-options)
    directmedia=no
    host=dynamic
    [public-phone](!,basic-options)
    directmedia=yes
    [my-codecs](!)
    allow=all
    [ulaw-phone](!)
    allow=all
    [provider]
	type=friend
	context=provider
	secret=$REGISTERPASSWORD
	host=sip0-d.voice.weepee.io
	nat=force_rport,comedia
	insecure=invite
	fromdomain=sip0-d.voice.weepee.io
	defaultuser=$REGISTERNAME" >> sip.conf;

OK=0;

# dialplan and voicemail
sudo mv extensions.conf extensions.conf.bak >/dev/null 2>&1;
sudo mv voicemail.conf voicemail.conf.bak >/dev/null 2>&1;

echo "";
echo "Provide the usernames and their voicemail IDs.";

# extensions default config

    echo -e "[provider]
exten => _X!,1,NoOp(Inkomend gesprek van provider)
same => n,GoTo(mainmenu,s,1)

[mainmenu]
exten => s,1,NoOp(keuzemenu taal, autoattendent)
same => n,Set(TIMEOUTS=0) 
same => n,Answer()
same => n(loop),Background(keuzetaal)
same => n,WaitExten(5) 

exten => 1,1,GoTo(menuNL,s,1)
exten => 2,1,GoTo(menuFR,s,1)

exten => i,1,NoOp(ongeldige keuze)
same => n,GoTo(s,1)

exten => t,1,NoOp(Timeout)
#same => n,Set(TIMEOUTS=$[ \${TIMEOUTS} + 1 ]) 
same => n,Set(TIMEOUTS=$((TIMEOUTS + 1)))

same => n,GotoIf($[ \${TIMEOUTS} < 2 ]?s,loop)
same => n,Queue(queue1,,,,100)


[menuNL]
exten => s,1,NoOp(keuzemenu in Nederlands)
same => n,Answer()
same => n,Background(keuzenl)
same => n,WaitExten(10)

exten => 1,1,GoTo(phones,100,1)
exten => 2,1,GoTo(phones,101,1)

[menuFR]
exten => s,1,NoOp(keuzemenu in Frans)
same => n,Answer()
same => n,Background(keuzefr)
same => n,WaitExten(10)

exten => 1,1,GoTo(phones,102,1)
exten => 2,1,GoTo(phones,103,1)

[outgoing]
exten => _x!,1,NoOp(\${EXTEN} called)
same => n,Playback(custom/lalala)
same => n,Set(CALLERID(num)=123456)
same => n,Dial(SIP/provider/\${EXTEN})
same => n,Hangup()

[phones]" > exentions.conf;

# voicemail default config

    echo -e "[general]
    format=wav49|gsm|wav
    serveremail=asterisk
    attach=yes
    skipms=3000
    maxsilence=10
    silencethreshold=128
    maxlogins=3
    emaildateformat=%A, %B %d, %Y at %r
    pagerdateformat=%A, %B %d, %Y at %r
    sendvoicemail=yes ; Allow the user to compose and send a voicemail while inside
[zonemessages]
    eastern=America/New_York|'vm-received' Q 'digits/at' IMp
    central=America/Chicago|'vm-received' Q 'digits/at' IMp
    central24=America/Chicago|'vm-received' q 'digits/at' H N 'hours'
    military=Zulu|'vm-received' q 'digits/at' H N 'hours' 'phonetic/z_p'
    european=Europe/Copenhagen|'vm-received' a d b 'digits/at' HM
    [default]" >> voicemail.conf;

while [ "$OK" != 1 ]
do
    echo "";
    read -rp "Enter a username (Leave blank when done): " NAME;
    if [ "$NAME" != "" ]
    then
        # SIP
        read -rp "Enter a phone number for this $NAME: " TEL_NR;
        read -rp "Enter a password (Leave blank for none): " PASSWORD;
        read -rp "Enter the voicemail-ID: " VOICEMAIL;
        read -rp "Enter the voicemail-password (numbers only): " VC_PASSWORD;

        if [ "$PASSWORD" != "" ]
        then
            {
                echo -e "[$NAME]
                type=friend
                context=phones
                secret=$PASSWORD
                host=dynamic
                mailbox=$VOICEMAIL@default"
            } >> sip.conf
        else
            {
                echo -e "[$NAME]
                type=friend
                context=phones
                host=dynamic
                mailbox=$VOICEMAIL@default"
            } >> sip.conf
        fi
        
        # extensions
        {
            echo -e "exten => $TEL_NR,1,Playback(custom/lalala)
same => n,Dial(SIP/$NAME,5)
same => n,Voicemail($VOICEMAIL@default,u)
same => n,Hangup()
exten => $VOICEMAIL,1,VoiceMailMain($VOICEMAIL@default)" 
        } >> extensions.conf;
        
        # voicemail
        {
            echo -e "$VOICEMAIL => $VC_PASSWORD,$NAME"
        } >> voicemail.conf;
        
        # reset variables
        NAME="";
        VOICEMAIL="";
    else
        OK=1;
    fi
done

# Move from tmp to dest
sudo mv sip.conf /etc/asterisk;
sudo mv voicemail.conf /etc/asterisk;
sudo mv extensions.conf /etc/asterisk;

# reload config
sudo systemctl restart asterisk

echo "";
echo "Done";
exit;

