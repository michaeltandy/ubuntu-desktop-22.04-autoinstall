#!/bin/bash

set -euo pipefail

if [ ! -z "$(dig +short gb.archive.ubuntu.com)" ]; then
    echo "Already online - wifi not needed for install" > /dev/console
    exit 0
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/wifi-secrets"

if [ -z "$(nmcli dev wifi list | grep $WIFI_SSID)" ]; then
    echo "Didn't detect network $WIFI_SSID so not trying to connect." > /dev/console
    exit 0
fi

nmcli dev wifi connect "$WIFI_SSID" password "$WIFI_PASSWORD"

if [ ! -z "$(dig +short gb.archive.ubuntu.com)" ]; then
    echo "Success - now online!" > /dev/console
else
    echo "Unfortunately, still not online :(" > /dev/console
fi
