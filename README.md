# Ubuntu Core 18 Bug reproducer

This repo has scripts which help to reproduce https://bugs.launchpad.net/snapd/+bug/1845310 on UC18.

To reproduce the bug, run `./prep-fresh-image.sh`. This script will download the official UC18 VM image, and load a service, `break-snapd.service` into the rootfs which will break snapd as per the bug report by rebooting before snapd is done bootstrapping itself during first boot. You can boot the produced image (which will be called `ubuntu-core-18-amd64.img`) by running this with kvm:

```
$ kvm -m 1500 -netdev user,id=mynet0,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80 -device virtio-net-pci,netdev=mynet0 -drive file=core18-amd64.img,format=raw -vga qxl -serial mon:stdio
```

I find it easiest to have both the GUI and the serial output, with the GUI showing plymouth output and systemd status, etc. and the serial monitor available for running console-conf.

You should find that the image will reboot itself once and then prompt you to run console-conf but continually fail because `/usr/bin/snap` isn't available. If you get a debug systemd shell in the image, you will find that snapd.service was never created and due to the logic in run-snapd-from-snap in core18, it will never be created.

To show the fix proposed works, checkout the core18 submodule and build that snap. Then use the `build-new-image.sh` which uses `ubuntu-image` to build a new UC18 image. Then launch that image, observe the image reboot again, and you should see the GUI window be spammed with output of `systemctl status snapd.service` which shows that snapd has started, and in the serial terminal you can use console-conf to create a user and log in to the system. 

Note: when you actually go to build the image, you will need to change the break-uc18-model.json to specify your ID as the `authority-id` and `brand-id`, as well as change the date to something appropriate for the key you want to sign with, and lastly you will also need to change the key specified in the `build-new-image.sh` to use your key.