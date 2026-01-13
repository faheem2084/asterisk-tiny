#!/usr/bin/env bash
set -euo pipefail

# Render templates using envsubst. Explicitly list the variables you want to substitute
# to avoid accidental replacement of shell-like strings in template content.
# Add or remove variables from the lists below as your templates require.

mkdir -p /etc/asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk /usr/lib/asterisk /usr/share/asterisk /usr/local/lib /etc/asterisk/manager.d

# pjsip.tpl variables

envsubst '${PUBLIC_IP} ${PRIVATE_IP} ${SUBNET_MASK_RANGE} ${SBC_IP} ${SBC_PORT} ${ALLOWED_CODECS} \
  ${DIRECT_MEDIA} ${SOFTPHONE_PASS} ${TRUNK_NAME} ${TRUNK_USERNAME} \
  ${TRUNK_PASSWORD} ${INBOUND_CONTEXT} ${IDENTIFY_IP}'\
  < /templates/pjsip.tpl > /etc/asterisk/pjsip.conf

envsubst '${INBOUND_CONTEXT} ${OUTBOUND_CONTEXT} ${FASTAGI_HOST} \
${FASTAGI_PORT} ${SOFTPHONE_CLI} ${TRUNK_NAME}' \
 < /templates/extensions.tpl > /etc/asterisk/extensions.conf

envsubst '${AMI_USER} ${AMI_USER_PASSWORD}' < /templates/ami.tpl > /etc/asterisk/manager.d/dialers.conf
envsubst '${AMI_BINDADDR}' < /templates/manager.tpl > /etc/asterisk/manager.conf
envsubst '${RTP_START_PORT_RANGE} ${RTP_END_PORT_RANGE}' < /templates/rtp.tpl > /etc/asterisk/rtp.conf

envsubst '${ARI_ENABLED} ${ARI_USER} ${ARI_PASSWORD}' \
< /templates/ari.tpl > /etc/asterisk/ari.conf

envsubst '${HTTP_ENABLED} ${HTTP_BINDADDR} ${HTTP_PORT}' \
< /templates/http.tpl > /etc/asterisk/http.conf

envsubst '${PROMETHEUS_ENABLED} '\
< /templates/prometheus.tpl > /etc/asterisk/prometheus.conf

# # Ensure directories exist

# Make sure permissions are set for asterisk-owned paths (if running as root in container)
# If your container runs as non-root, adjust/remove the chown.

chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk /usr/lib/asterisk /usr/share/asterisk /usr/local/lib || true


echo "Starting asterisk (foreground)..."

# If the Dockerfile/CMD provides the asterisk startup, exec the passed command.
# Typical asterisk foreground invocation:
# exec /usr/sbin/asterisk -f -U asterisk -vvv

# If the container was started with a CMD, this will run it. Otherwise you can add the asterisk command above.
exec "$@"