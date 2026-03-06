# Dependency chain: dbus → avahi → shairport; dbus → pulseaudio → ledfx
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm
FROM $BUILD_FROM

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    # Build tools
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    git \
    xxd \
    libcap2-bin \
    net-tools \
    # shairport-sync dependencies
    avahi-daemon \
    libavahi-client-dev \
    avahi-utils \
    dbus \
    libssl-dev \
    libsoxr-dev \
    libconfig-dev \
    libpopt-dev \
    libasound2-dev \
    libplist-dev \
    libplist-utils \
    libsodium-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libgcrypt20-dev \
    uuid-dev \
    libmosquitto-dev \
    # PulseAudio
    pulseaudio \
    libpulse-dev \
    pulseaudio-utils \
    # nginx
    nginx \
    # Python / LedFx
    python3 \
    python3-pip \
    python3-venv \
    portaudio19-dev \
    python3-dev \
    libffi-dev \
    jq

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Build libplist from source to get plistutil binary
#UN git clone https://github.com/libimobiledevice/libplist.git /tmp/libplist \
#   && cd /tmp/libplist \
#   && autoreconf -fi \
#   && ./configure --without-cython \
#   && make \
#   && make install \
#   && ldconfig \
#   && rm -rf /tmp/libplist

# Build NQPTP with real-time scheduling made non-fatal
RUN git clone https://github.com/mikebrady/nqptp.git /tmp/nqptp \
    && cd /tmp/nqptp \
    && autoreconf -fi \
    && ./configure \
    && make \
    && make install \
    && ldconfig \
    && rm -rf /tmp/nqptp

#    && sed -i 's/die("pthread_setschedparam failed/warn("pthread_setschedparam failed/' nqptp.c \
#    && setcap 'cap_net_bind_service=+ep' /usr/local/bin/nqptp \

# RUN adduser -S -D -H nqptp \
#     && apk add --no-cache libcap \
#     && setcap 'cap_net_bind_service=+ep' /usr/local/bin/nqptp

# Build ALAC library
#WORKDIR /tmp
RUN git clone --depth 1 https://github.com/mikebrady/alac.git /tmp/alac && \
    cd /tmp/alac && \
    autoreconf -fi && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    (ldconfig 2>/dev/null || true) && \
    cd .. && \
    rm -rf alac


# Build shairport-sync with AirPlay 2
RUN git clone https://github.com/mikebrady/shairport-sync.git /tmp/shairport-sync \
    && cd /tmp/shairport-sync \
    && autoreconf -fi \
    && PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconf" \
    && ./configure \
        --sysconfdir=/etc \
        --with-avahi \
        --with-soxr \
        --with-pulseaudio \
        --with-metadata \
        --with-mqtt-client \
        --with-apple-alac \
        --with-airplay-2 \
        --with-ssl=openssl \
    && make \
    && make install \
    && ldconfig \
    && rm -rf /tmp/shairport-sync

# TODO: Clean up build dependencies to reduce image size

RUN mkdir -p \
    /etc/s6-overlay/s6-rc.d/dbus/dependencies.d \
    /etc/s6-overlay/s6-rc.d/avahi/dependencies.d \
    /etc/s6-overlay/s6-rc.d/nqptp/dependencies.d \
    /etc/s6-overlay/s6-rc.d/pulseaudio/dependencies.d \
    /etc/s6-overlay/s6-rc.d/shairport/dependencies.d \
    /etc/s6-overlay/s6-rc.d/ledfx/dependencies.d \
    /etc/s6-overlay/s6-rc.d/nginx/dependencies.d \
    /etc/s6-overlay/s6-rc.d/user/contents.d

RUN touch \
    /etc/s6-overlay/s6-rc.d/avahi/dependencies.d/dbus \
    /etc/s6-overlay/s6-rc.d/nqptp/dependencies.d/avahi \
    /etc/s6-overlay/s6-rc.d/pulseaudio/dependencies.d/dbus \
    /etc/s6-overlay/s6-rc.d/shairport/dependencies.d/nqptp \
    /etc/s6-overlay/s6-rc.d/shairport/dependencies.d/pulseaudio \
    /etc/s6-overlay/s6-rc.d/ledfx/dependencies.d/pulseaudio \
    /etc/s6-overlay/s6-rc.d/nginx/dependencies.d/ledfx \
    /etc/s6-overlay/s6-rc.d/user/contents.d/dbus \
    /etc/s6-overlay/s6-rc.d/user/contents.d/avahi \
    /etc/s6-overlay/s6-rc.d/user/contents.d/nqptp \
    /etc/s6-overlay/s6-rc.d/user/contents.d/pulseaudio \
    /etc/s6-overlay/s6-rc.d/user/contents.d/shairport \
    /etc/s6-overlay/s6-rc.d/user/contents.d/ledfx \
    /etc/s6-overlay/s6-rc.d/user/contents.d/nginx

# FIX: pkg_resources warning by installing it directly
RUN python3 -m venv /opt/ledfx-venv \
    && /opt/ledfx-venv/bin/pip install --upgrade pip wheel \
    && /opt/ledfx-venv/bin/pip install --upgrade "setuptools>=69.0.0" \
    && /opt/ledfx-venv/bin/pip install ledfx \
    && /opt/ledfx-venv/bin/pip install --upgrade "setuptools>=69.0.0" \
    && ln -sf /opt/ledfx-venv/lib/python3.12/site-packages/pkg_resources \
              /opt/ledfx-venv/lib/python3.12/site-packages/pkg_resources || true

# Runtime dirs
RUN mkdir -p /run/pulse /run/dbus-private \
    && dbus-uuidgen > /etc/machine-id

# Configs
## Avahi config — allow-interfaces prevents conflict with HA's avahi
COPY avahi-daemon.conf /etc/avahi/avahi-daemon.conf
COPY default.pa /etc/pulse/default.pa
COPY shairport-sync.conf /etc/shairport-sync.conf

# Service scripts
COPY services/dbus/run             /etc/s6-overlay/s6-rc.d/dbus/run
COPY services/avahi/run            /etc/s6-overlay/s6-rc.d/avahi/run
COPY services/nqptp/run            /etc/s6-overlay/s6-rc.d/nqptp/run
COPY services/pulseaudio/run       /etc/s6-overlay/s6-rc.d/pulseaudio/run
COPY services/pulseaudio/finish    /etc/s6-overlay/s6-rc.d/pulseaudio/finish
COPY services/shairport/run        /etc/s6-overlay/s6-rc.d/shairport/run
COPY services/ledfx/run            /etc/s6-overlay/s6-rc.d/ledfx/run
COPY services/nginx/run            /etc/s6-overlay/s6-rc.d/nginx/run

RUN chmod +x \
    /etc/s6-overlay/s6-rc.d/dbus/run \
    /etc/s6-overlay/s6-rc.d/avahi/run \
    /etc/s6-overlay/s6-rc.d/nqptp/run \
    /etc/s6-overlay/s6-rc.d/pulseaudio/run \
    /etc/s6-overlay/s6-rc.d/pulseaudio/finish \
    /etc/s6-overlay/s6-rc.d/shairport/run \
    /etc/s6-overlay/s6-rc.d/ledfx/run \
    /etc/s6-overlay/s6-rc.d/nginx/run

RUN for svc in dbus avahi nqptp pulseaudio shairport ledfx nginx; do \
      echo "longrun" > /etc/s6-overlay/s6-rc.d/$svc/type; \
    done

# Create shairport-sync user so dbus policy is satisfied
RUN adduser -S -D -H shairport-sync

# Remove ssh/sftp avahi service advertisements — not relevant in this container
RUN rm -f /etc/avahi/services/ssh.service \
          /etc/avahi/services/sftp-ssh.service

COPY run.sh /run.sh
RUN chmod +x /run.sh
