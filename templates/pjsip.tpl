[transport-tcp-nat]
type=transport
protocol=tcp
bind=0.0.0.0
local_net=${SUBNET_MASK_RANGE}
external_media_address=${PUBLIC_IP}
external_signaling_address=${PUBLIC_IP}

[pjsiptpl](!)
type=endpoint
context=softphone-ctx
disallow=all
allow=${ALLOWED_CODECS}
transport=transport-tcp-nat
rtp_symmetric=yes
force_rport=yes
rewrite_contact=yes
direct_media=${DIRECT_MEDIA}
media_address=${PUBLIC_IP}

[123](pjsiptpl)
auth=123
aors=123

[123]
type=auth
auth_type=userpass
password=${SOFTPHONE_PASS}
username=123

[123]
type=aor
max_contacts=1

[456](pjsiptpl)
auth=456
aors=456

[456]
type=auth
auth_type=userpass
password=${SOFTPHONE_PASS}
username=456

[456]
type=aor
max_contacts=1

[${TRUNK_NAME}]
type=aor
contact=sip:${SBC_IP}:${SBC_PORT}

[${TRUNK_NAME}]
type=auth
auth_type=userpass
username=${TRUNK_USERNAME}
password=${TRUNK_PASSWORD}

[${TRUNK_NAME}]
type=endpoint
context=${INBOUND_CONTEXT}
disallow=all
allow=${ALLOWED_CODECS}
transport=transport-tcp-nat
aors=${TRUNK_NAME}
outbound_auth=${TRUNK_NAME}
direct_media=${DIRECT_MEDIA}
from_domain=${SBC_IP}

[${TRUNK_NAME}]
type=identify
endpoint=${TRUNK_NAME}
match=${IDENTIFY_IP}