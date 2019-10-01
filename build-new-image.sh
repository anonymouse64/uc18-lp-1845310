#!/bin/bash -e

# get the directory of this script
# snippet from https://stackoverflow.com/a/246128/10102404
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

IMAGE_HOME=$SCRIPT_DIR
IMAGE=core18-amd64.img

snap sign -k edgex-testing &> break-uc18-model.assert < break-uc18-model.json

snap download snapd
snap download pc --channel=18
snap download pc-kernel --channel=18

# create the image with ubuntu-image specifying the special core18 snap
ubuntu-image snap "$IMAGE_HOME/break-uc18-model.assert" \
                        --channel "edge" \
                        --snap "$SCRIPT_DIR/core18/core18_*.snap" \
                        --snap "$SCRIPT_DIR/pc-kernel_307.snap" \
                        --snap "$SCRIPT_DIR/pc_36.snap" \
                        --snap "$SCRIPT_DIR/snapd*.snap" \
                        --output-dir "$IMAGE_HOME"

mv "$IMAGE_HOME/pc.img" "$IMAGE_HOME/$IMAGE"

# mount writable partition
sudo mount -o loop,offset=54525952 "$SCRIPT_DIR/$IMAGE" "$SCRIPT_DIR/writable"

# create necessary directories
sudo mkdir -p "$SCRIPT_DIR/writable/system-data/var/lib/misc"
sudo mkdir -p "$SCRIPT_DIR/writable/system-data/etc/systemd/system"
sudo mkdir -p "$SCRIPT_DIR/writable/system-data/etc/systemd/system/multi-user.target.wants"

# block console-conf from running
# sudo mkdir -p "$SCRIPT_DIR/writable/system-data/var/lib/console-conf"
# sudo touch "$SCRIPT_DIR/writable/system-data/var/lib/console-conf/complete"

# install our breaker script
sudo cp break-snapd.sh "$SCRIPT_DIR/writable/system-data/var/lib/misc/"

# install the breaker service
sudo cp break-snapd.service "$SCRIPT_DIR/writable/system-data/etc/systemd/system/"

# make it a proper dependency of multi-user.target.wants
sudo ln -s /etc/systemd/system/break-snapd.service "$SCRIPT_DIR/writable/system-data/etc/systemd/system/multi-user.target.wants/break-snapd.service"

# unmount it
sudo umount writable
