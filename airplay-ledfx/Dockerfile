ARG BUILD_FROM
FROM $BUILD_FROM

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apk add --no-cache \
    nginx \
    shairport-sync \
    avahi \
    avahi-tools \
    dbus \
    pulseaudio \
    pulseaudio-utils \
    build-base \
    libstdc++ \
    linux-headers \
    python3 \
    py3-pip \
    py3-virtualenv \
    portaudio-dev \
    pulseaudio-dev \
    alsa-lib-dev \
    python3-dev \
    libffi-dev \
    git \
    jq \
    bash

# Dependency chain: dbus → avahi → shairport; dbus → pulseaudio → ledfx

RUN mkdir -p \
    /etc/s6-overlay/s6-rc.d/dbus/dependencies.d \
    /etc/s6-overlay/s6-rc.d/avahi/dependencies.d \
    /etc/s6-overlay/s6-rc.d/pulseaudio/dependencies.d \
    /etc/s6-overlay/s6-rc.d/shairport/dependencies.d \
    /etc/s6-overlay/s6-rc.d/ledfx/dependencies.d \
    /etc/s6-overlay/s6-rc.d/nginx/dependencies.d \
    /etc/s6-overlay/s6-rc.d/user/contents.d

RUN touch \
    /etc/s6-overlay/s6-rc.d/avahi/dependencies.d/dbus \
    /etc/s6-overlay/s6-rc.d/pulseaudio/dependencies.d/dbus \
    /etc/s6-overlay/s6-rc.d/shairport/dependencies.d/avahi \
    /etc/s6-overlay/s6-rc.d/shairport/dependencies.d/pulseaudio \
    /etc/s6-overlay/s6-rc.d/ledfx/dependencies.d/pulseaudio \
    /etc/s6-overlay/s6-rc.d/nginx/dependencies.d/ledfx \
    /etc/s6-overlay/s6-rc.d/user/contents.d/dbus \
    /etc/s6-overlay/s6-rc.d/user/contents.d/avahi \
    /etc/s6-overlay/s6-rc.d/user/contents.d/pulseaudio \
    /etc/s6-overlay/s6-rc.d/user/contents.d/shairport \
    /etc/s6-overlay/s6-rc.d/user/contents.d/ledfx \
    /etc/s6-overlay/s6-rc.d/user/contents.d/nginx

# FIX: pkg_resources warning by installing it directly???
RUN python3 -m venv /opt/ledfx-venv \
    && /opt/ledfx-venv/bin/pip install --upgrade pip wheel \
    && /opt/ledfx-venv/bin/pip install --upgrade "setuptools>=65.0.0" \
    && /opt/ledfx-venv/bin/pip install ledfx \
    && /opt/ledfx-venv/bin/pip install --upgrade "setuptools>=65.0.0"

# Runtime dirs
RUN mkdir -p /run/pulse /run/dbus-private /root/.config/pulse \
    && dbus-uuidgen > /etc/machine-id

# Avahi config — allow-interfaces prevents conflict with HA's avahi
COPY avahi-daemon.conf /etc/avahi/avahi-daemon.conf

# PulseAudio config
COPY default.pa /etc/pulse/default.pa

# Service scripts
COPY services/dbus/run             /etc/s6-overlay/s6-rc.d/dbus/run
COPY services/avahi/run            /etc/s6-overlay/s6-rc.d/avahi/run
COPY services/pulseaudio/run       /etc/s6-overlay/s6-rc.d/pulseaudio/run
COPY services/pulseaudio/finish    /etc/s6-overlay/s6-rc.d/pulseaudio/finish
COPY services/shairport/run        /etc/s6-overlay/s6-rc.d/shairport/run
COPY services/ledfx/run            /etc/s6-overlay/s6-rc.d/ledfx/run
COPY services/nginx/run            /etc/s6-overlay/s6-rc.d/nginx/run

RUN chmod +x \
    /etc/s6-overlay/s6-rc.d/dbus/run \
    /etc/s6-overlay/s6-rc.d/avahi/run \
    /etc/s6-overlay/s6-rc.d/pulseaudio/run \
    /etc/s6-overlay/s6-rc.d/pulseaudio/finish \
    /etc/s6-overlay/s6-rc.d/shairport/run \
    /etc/s6-overlay/s6-rc.d/ledfx/run \
    /etc/s6-overlay/s6-rc.d/nginx/run

RUN for svc in dbus avahi pulseaudio shairport ledfx nginx; do \
      echo "longrun" > /etc/s6-overlay/s6-rc.d/$svc/type; \
    done


# Create shairport-sync user so dbus policy is satisfied
RUN adduser -S -D -H shairport-sync
COPY shairport-sync.conf /etc/shairport-sync.conf

# Remove ssh/sftp avahi service advertisements — not relevant in this container
RUN rm -f /etc/avahi/services/ssh.service \
          /etc/avahi/services/sftp-ssh.service

COPY run.sh /run.sh
RUN chmod +x /run.sh
