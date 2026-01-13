# Multi-stage minimal Asterisk 22 image (Debian 13 / trixie)
ARG ASTERISK_VERSION=22.7.0
ARG BASE_IMAGE=debian:trixie-slim

################
# Builder stage #
################
FROM ${BASE_IMAGE} AS build
ARG ASTERISK_VERSION
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /usr/src

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential wget ca-certificates uuid-dev libxml2-dev libncurses-dev \
    libsqlite3-dev libssl-dev libedit-dev libjansson-dev libsrtp2-dev pkg-config \
    bison flex python3 xmlstarlet git subversion \
 && rm -rf /var/lib/apt/lists/*

RUN wget -q "https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}.tar.gz" \
 && tar xzf asterisk-${ASTERISK_VERSION}.tar.gz \
 && rm asterisk-${ASTERISK_VERSION}.tar.gz \
 && mv asterisk-${ASTERISK_VERSION} asterisk

WORKDIR /usr/src/asterisk


WORKDIR /usr/src/asterisk/contrib/scripts
RUN DEBIAN_FRONTEND=noninteractive  ./get_mp3_source.sh
WORKDIR /usr/src/asterisk

RUN ./contrib/scripts/get_mp3_source.sh
RUN ./configure --with-jansson-bundled
RUN DEBIAN_FRONTEND=noninteractive make menuselect.makeopts \
    && menuselect/menuselect --disable BUILD_NATIVE   \
    --enable format_mp3     \
    --enable res_config_mysql                   \
    --enable res_agi                             \
    --enable res_ari                             \
    --enable res_ari_applications                \
    --enable res_ari_asterisk                    \
    --enable res_ari_bridges                     \
    --enable res_ari_channels                    \
    --enable res_ari_device_states               \
    --enable res_ari_endpoints                   \
    --enable res_ari_events                      \
    --enable res_ari_mailboxes                   \
    --enable res_ari_model                       \
    --enable res_ari_playbacks                   \
    --enable res_ari_recordings                  \
    --enable res_ari_sounds                      \
    --enable res_clialiases                      \
    --enable res_clioriginate                    \
    --enable res_config_curl                     \
    --enable res_config_odbc                     \
    --enable res_convert                         \
    --enable res_crypto                          \
    --enable res_curl                            \
    --enable res_fax                             \
    --enable res_format_attr_celt                \
    --enable res_format_attr_g729                \
    --enable res_format_attr_h263                \
    --enable res_format_attr_h264                \
    --enable res_format_attr_ilbc                \
    --enable res_format_attr_opus                \
    --enable res_format_attr_silk                \
    --enable res_format_attr_siren14             \
    --enable res_format_attr_siren7              \
    --enable res_format_attr_vp8                 \
   #  --enable res_http_media_cache                \
   #  --enable res_http_post                       \
   #  --enable res_http_websocket                  \
    --enable res_limit                           \
    --enable res_manager_devicestate             \
    --enable res_manager_presencestate           \
    --enable res_musiconhold                     \
    --enable res_mutestream                      \
    --enable res_odbc                            \
    --enable res_odbc_transaction                \
    --enable res_parking                         \
    --enable res_pjproject                       \
    --enable res_pjsip                           \
    --enable res_realtime                        \
    --enable res_resolver_unbound                \
    --enable res_rtp_asterisk                    \
    --enable res_rtp_multicast                   \
    --enable res_security_log                    \
    --enable res_speech                          \
    --enable res_srtp                            \
    --enable res_stasis                          \
    --enable res_stir_shaken                     \
    --enable res_stun_monitor                    \
    --enable res_timing_dahdi                    \
    --enable res_timing_timerfd                  \
    --enable res_xmpp                            \
    --enable res_ael_share                       \
    --enable res_audiosocket                     \
    --enable res_chan_stats                      \
    --enable res_config_pgsql                    \
    --enable res_endpoint_stats                  \
    --enable res_hep                             \
    --enable res_hep_pjsip                       \
    --enable res_hep_rtcp                        \
    --enable res_phoneprov                       \
    --enable res_prometheus                      \
    --enable res_smdi                            \
    --enable res_snmp                            \
    --enable res_statsd                          \
    --enable res_timing_kqueue                   \
    --enable res_timing_pthread                  \
    --enable res_tonedetect                      \
    menuselect.makeopts  \
    && make -j$(nproc) 1> /dev/null     \
    && make -j$(nproc) install 1> /dev/null    \
    && make -j$(nproc) samples 1> /dev/null     \
    && make dist-clean     \
    && sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk     \
    && useradd -m asterisk -s /sbin/nologin \
    && chown -R asterisk:asterisk /var/run/asterisk \
    /etc/asterisk/ \
    /var/lib/asterisk \
    /var/log/asterisk \
    /var/spool/asterisk \
    && rm -rf /usr/src/* \
    && rm -rf /tmp/*.bz2 \
    && rm -rf /etc/asterisk/*.conf \
    && ldconfig

# Collect built shared libraries
RUN mkdir -p /usr/lib/asterisk /usr/local/lib /usr/share/asterisk; \
    find / -name 'libasterisk*.so*' -print 2>/dev/null | sort -u | while read -r f; do \
      cp -n "$f" /usr/lib/asterisk/ || true; \
      cp -n "$f" /usr/local/lib/ || true; \
    done || true; \
    find / -name 'libasteriskpj*.so*' -print 2>/dev/null | sort -u | while read -r f; do \
      cp -n "$f" /usr/lib/asterisk/ || true; \
      cp -n "$f" /usr/local/lib/ || true; \
    done || true

################
# Runtime stage #
################
FROM ${BASE_IMAGE} AS runtime
ARG ASTERISK_VERSION
ENV DEBIAN_FRONTEND=noninteractive
LABEL maintainer="faheem2084"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates libxml2 libncurses6 libsqlite3-0 libssl3 libedit2 libjansson4 \
    libsrtp2-1 tini gettext \
 && rm -rf /var/lib/apt/lists/*

# Create runtime user and directories
RUN groupadd -r asterisk \
 && useradd -r -g asterisk -d /var/lib/asterisk -s /usr/sbin/nologin asterisk \
 && mkdir -p \
    /etc/asterisk \
    /var/lib/asterisk \
    /var/spool/asterisk \
    /var/log/asterisk \
    /usr/lib/asterisk \
    /usr/local/lib \
    /usr/share/asterisk

# Copy runtime artifacts
COPY --from=build /usr/sbin/asterisk /usr/sbin/asterisk
COPY --from=build /usr/lib/asterisk /usr/lib/asterisk
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/share/asterisk /usr/share/asterisk
COPY --from=build /etc/asterisk /etc/asterisk
COPY --from=build /var/lib/asterisk /var/lib/asterisk
COPY --from=build /var/spool/asterisk /var/spool/asterisk
COPY --from=build /var/log/asterisk /var/log/asterisk

# Fix permissions
RUN chown root:asterisk /usr/sbin/asterisk \
 && chmod 750 /usr/sbin/asterisk \
 && chown -R asterisk:asterisk \
    /etc/asterisk \
    /var/lib/asterisk \
    /var/spool/asterisk \
    /var/log/asterisk \
    /usr/lib/asterisk \
    /usr/share/asterisk \
    /usr/local/lib

RUN ldconfig || true

# Copy configs & templates
RUN rm -rf /etc/asterisk/*
COPY ./configs/etc_asterisk/ /etc/asterisk
COPY ./templates /templates
RUN chown -R asterisk:asterisk /etc/asterisk /templates

# Entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER root
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["asterisk", "-f", "-U", "asterisk", "-vvvvc"]
# CMD ["/usr/sbin/asterisk", "-vvvdddf", "-T", "-W", "-U", "asterisk", "-p"]
