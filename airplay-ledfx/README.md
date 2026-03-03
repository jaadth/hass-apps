# Airplay LedFX

Home Assistant App that provides Airplay 2 as an audio input for a LedFX Server.

## Features

**Features:**
- Single container
- Multi-architecture support
- Airplay 2 support
- Configurable LedFX port

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| airplay_name | str | Home Assistant | Airplay Device Name |
| port | int | 8888 | LedFX Web UI Listening Port |
| network_interface | str | enu1 | Network Interface |
| verbose | bool | false | Enable verbose logging |

## Expose LedFX to Home Assistant

The LedFX Devices and Scenes can be exposed to HA by enabling the LedFX
Integration "MQTT Home Assistant".

I had a hard time finding info on this so here's what I did.

1. Have a MQTT server connected to HA.
2. Create a login for LedFX.
3. In LedFX **Settings** enable **Expert Mode**.
4. In LedFX **Settings** enable **Beta Mode**.
5. In LedFX **Settings** under **Features** enable **Integrations**.
6. In LedFX **Settings** under **Features** enable **Integration: MQTT Home Assistant**.
7. In LedFX **Plus** add Integration **Home Assistant MQTT**.
8. In HA **Settings/Device & Services/MQTT** you should find a **LedFX** device.

## Notes

After starting the App, the AirPlay device should now be visible on your
network — check your iPhone/Mac AirPlay picker.

The LedFX config.json is initialized upon first startup to set the listening
port and the audio device.  The file can be accessed via "Studio Code Server"
at "config/ledfx-config/config.json".  Delete the file if LedFX is no longer
available.
