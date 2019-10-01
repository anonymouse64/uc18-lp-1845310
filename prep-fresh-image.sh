#!/bin/bash -e

# download the image if it's not already here
if [ ! -e original-ubuntu-core-18-amd64.img ]; then
    curl http://cdimage.ubuntu.com/ubuntu-core/18/stable/current/ubuntu-core-18-amd64.img.xz --output original-ubuntu-core-18-amd64.img.xz
    xz --decompress original-ubuntu-core-18-amd64.img.xz
fi

if [ -e ubuntu-core-18-amd64.img ]; then
    rm ubuntu-core-18-amd64.img
fi

cp original-ubuntu-core-18-amd64.img ubuntu-core-18-amd64.img

# mount writable partition
sudo mount -o loop,offset=54525952 "$(pwd)/ubuntu-core-18-amd64.img" "$(pwd)/writable"

# create necessary directories
sudo mkdir -p "$(pwd)/writable/system-data/var/lib/misc"
sudo mkdir -p "$(pwd)/writable/system-data/etc/systemd/system"
sudo mkdir -p "$(pwd)/writable/system-data/etc/systemd/system/multi-user.target.wants"
# sudo mkdir -p "$(pwd)/writable/system-data/var/lib/console-conf"

# block console-conf from running
# sudo touch "$(pwd)/writable/system-data/var/lib/console-conf/complete"

# install our breaker script
sudo cp break-snapd.sh "$(pwd)/writable/system-data/var/lib/misc/"

# install the breaker service
sudo cp break-snapd.service "$(pwd)/writable/system-data/etc/systemd/system/"

# make it a proper dependency of multi-user.target.wants
sudo ln -s /etc/systemd/system/break-snapd.service "$(pwd)/writable/system-data/etc/systemd/system/multi-user.target.wants/break-snapd.service"

# unmount it
sudo umount writable
