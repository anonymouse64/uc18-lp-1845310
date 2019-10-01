#!/bin/bash -ex

mkdir -p /var/log
touch /var/log/run-snapd-from-snap.log

print_system()
{
    printf "%s break-snapd: %s\n" "$(date -Iseconds --utc)" "$1" |
        tee -a /dev/kmsg /dev/console /var/log/run-snapd-from-snap.log || true
}

print_system "going into loop for state.json"

while /bin/true; do
    # as soon as we see the state.json file, reboot
    set +e
    var="$(systemctl status snapd 2>&1)"
    if [ -n "$var" ]; then
        print_system "$var"
    fi
    var="$(systemctl status snapd-seeding2>&1)"
    if [ -n "$var" ]; then
        print_system "$var"
    fi
    set -e
    if [ ! -e /var/lib/misc/rebooted ] && [ -e /var/lib/snapd/state.json ]; then
        touch /var/lib/misc/rebooted
        print_system "rebooting because state.json exists"
        reboot
        print_system "uh rebooted?"
    fi
    sleep 0.01
done
