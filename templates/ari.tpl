[general]
enabled=${ARI_ENABLED}
websocket_write_timeout=100
pretty=yes
;channelvars = var1,var2,var3

[${ARI_USER}]
type=user
read_only=no
password=${ARI_PASSWORD}
password_format=plain