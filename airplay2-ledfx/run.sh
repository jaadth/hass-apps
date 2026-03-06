#!/usr/bin/with-contenv bashio

LEDFX_PORT=$(bashio::config 'ledfx_port')

mkdir -p /config/ledfx-config

if [ ! -f /config/ledfx-config/config.json ]; then
    bashio::log.info "Writing default LedFx config..."
    cat > /config/ledfx-config/config.json <<EOF
{
  "host": "0.0.0.0",
  "port": ${LEDFX_PORT},
  "audio": {
    "device": "ledfx_sink.monitor"
  }
}
EOF
fi

exec /init
