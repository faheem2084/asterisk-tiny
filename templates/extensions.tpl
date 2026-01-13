[general]
static=yes
writeprotect=no
clearglobalvars=no

[globals]
CONSOLE=Console/dsp				; Console interface for demo
;CONSOLE=DAHDI/1
;CONSOLE=Phone/phone0
IAXINFO=guest					; IAXtel username/password
;IAXINFO=myuser:mypass
TRUNK=DAHDI/G2					; Trunk interface

[${OUTBOUND_CONTEXT}]
exten => _+X.,1,NoOp(Welcome to My Asterisk)
same => n, Agi(agi://${FASTAGI_HOST}:${FASTAGI_PORT}/outbound)

[${INBOUND_CONTEXT}]
exten => _+X.,1,NoOp(Inound call - ${EXTEN})
same => n,Progress()
same => n,Wait(1)
same => n,Playback(silence/1,noanswer)
same => n, Agi(agi://${FASTAGI_HOST}:${FASTAGI_PORT}/inbound)


[softphone-ctx]
exten => _+X.,1,NoOp(softphone dialed number - ${EXTEN})
same => n,Set(CALLERID(num)=${SOFTPHONE_CLI})
same => n, Dial(PJSIP/${EXTEN}@${TRUNK_NAME},45)
exten => h, 1, Verbose(Got hangup)
