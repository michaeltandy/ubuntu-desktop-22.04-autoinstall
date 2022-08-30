#!/bin/bash

# This is a dumbed-down version of update-secureboot-policy

set -euo pipefail

SB_KEY="/var/lib/shim-signed/mok/MOK.der"
SB_PRIV="/var/lib/shim-signed/mok/MOK.priv"
efivars=/sys/firmware/efi/efivars
secureboot_var=SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c

if [ -e "$SB_KEY" ]; then
    echo "Secure boot key already generated."
    exit 0
fi

if ! [ -f $efivars/$secureboot_var ] || [ "$(od -An -t u1 $efivars/$secureboot_var | awk '{ print $NF }')" -ne 1 ]
then
    echo "Secure Boot not enabled on this system." >&2
    exit 0
fi

openssl req -config /usr/lib/shim/mok/openssl.cnf \
        -subj "/CN=`hostname -s | cut -b1-31` Secure Boot Module Signature key" \
        -new -x509 -newkey rsa:2048 \
        -nodes -days 36500 -outform DER \
        -keyout "$SB_PRIV" \
        -out "$SB_KEY"

key="aaaaaaaa"

echo "Adding '$SB_KEY' to shim:"
printf '%s\n%s\n' "$key" "$key" | mokutil --import "$SB_KEY" >/dev/null || true
mokutil --timeout -1 >/dev/null || true

