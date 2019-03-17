# ecoserve ODROID-C2

The [Hardkernel ODROID-C2](https://www.hardkernel.com/shop/odroid-c2/) is a much faster SBC that costs roughly the same as a Raspberry Pi 3, but is substantially faster than the Raspberry Pi series. 

Unfortunately, the ODROID-C2 also comes with a lot less support. This document is my personal work optimizing the ODROID-C2 for ecoserve use, and what the overall speed and power draw is. This guide will be updated regularly as I tune more parts of my new ODROID-C2 system. Following this guide will allow you to mimic my overall setup. Choose specific things for your own needs.

> **Note**: Given the users of the ODROID-C2 platform, this guide is much more detailed and technically involved than the Raspberry Pi 3 guide. It is recommended that you have an advanced understanding of Linux systems when following this guide. Configuration packages are not provided for the ODROID-C2 platform.

## Table of Contents

* [Introduction](#introduction)
* [Linux OS optimization](#linux-os-optimization)
    * [Moving to the mainline kernel](#moving-to-the-mainline-kernel)
    * [Getting a build system](#getting-a-build-system)
    * [Optimizing specific packages from source for performance](#optimizing-specific-packages-from-source-for-performance)
        * [Grab the necessary PKGBUILD files and make them](#grab-the-necessary-pkgbuild-files-and-make-them)
        * [Install the packages](#install-the-packages)
    * [Optimizing power usage even further](#optimizing-power-usage-even-further)
        * [Limiting Ethernet speed](#limiting-ethernet-speed)
        * [Underclocking DRAM](#underclocking-dram)

## Introduction 

I personally use an ODROID-C2 as my ecoserve platform, replacing a more-powerful but less-efficient [NUC7PJYH](https://www.intel.com/content/www/us/en/products/boards-kits/nuc/kits/nuc7pjyh.html), which I still find to be the best performance-per-watt server available for a relatively low cost. However, the majority of the time this sat idle at 5-5.5W.

The ODROID-C2 offers sufficient speed for long-running research tasks, low power consumption and faster Ethernet. My ODROID-C2 is currently configured to use:

* A [Cogent Design ODROID-C2 aluminum case](https://cogent.design/?product=odroid-c2-aluminum-heatsink-enclosure). The case acts as a heatsink for the C2 and mates to the processor. However, I bought this case because it is 100% recyclable being milled from aluminum. It requires removal of the stock ODROID-C2 heatsink and comes with some thermal grease, but I used [Arctic MX-4](https://www.amazon.com/ARCTIC-MX-4-Compound-Performance-Interface/dp/B0045JCFLY).
* A couple of aluminum heatsinks on the RAM chips that I've used for Raspberry Pi boards. Often they come in bulk packages, so join up with others.
* 64GB [AmeriDroid SanDisk eMMC](https://ameridroid.com/products/emmc-5-1-module-blank) as boot, formatted ext4, with swap partition
* 128GB [Samsung PRO Endurance MicroSD](https://www.amazon.com/gp/product/B07B984HJ5/) formatted as [f2fs](https://en.wikipedia.org/wiki/F2FS), for home directory and experimentation.
* 5TB [Seagate BarraCuda ST5000LM000](https://www.amazon.com/Seagate-BarraCuda-Internal-2-5-Inch-ST5000LM000/dp/B01M0AADIX) for nearline backup.
* An [Oyen Digital MiniPro external disk enclosure](https://www.amazon.com/gp/product/B003VKTJGW/) for the hard disk. This has the ASMedia 1351 chip, which supports SATA 3.2 (DevSlp) and TRIM, so using an SSD in here will give much better power consumption. However, it is capable of 15mm 5V 2.5" drives, allowing the use of my Seagate disk for extra cost-effective space. It is also made of recyclable aluminum and matches the ODROID well.

This guide assumes that you are starting with the [ODROID-C2 installation on Arch Linux ARM](https://archlinuxarm.org/platforms/armv8/amlogic/odroid-c2) create the eMMC or MicroSD you are using.


## Current benchmarks

These are the current benchmarks of my ODROID-C2 platform, and what it is capable of doing. Note these are not super-scientific benchmarks and come from a single run of each test. The Raspberry Pi 3 is included as an example, running all the ARMv8 optimizations.

|Test Command                   |ecoserve ODROID-C2            |ecoserve Raspberry Pi 3 aarch64 |Delta      |
|-------------------------------|------------------------------|--------------------------------|-----------|
|`sysbench cpu run`             |750.78 events per second      |582.00 events per second        |1.3x faster|
|`sysbench memory run`          |1226784.47 ops per second     |956574.21 ops per second        |1.3x faster|
|`openssl speed -elapsed aes`   |8396304 aes-256 cbc's in 3.00s|6252683 aes-256 cbc's in 3.00s  |1.3x faster|



## Linux OS optimization

The ODROID-C2's Amlogic S905 chipset is gaining mainline support thanks to [BayLibre's work](https://baylibre.com/improved-amlogic-support-mainline-linux/) on the [Meson project](http://linux-meson.com/doku.php). This means it is trivial to use the mainline AArch64 kernel on a distribution with a rolling release model. Given the last Hardkernel kernel is a now old 3.16, moving to a newer mainline seems prudent.

A user on the Hardkernel forums named [campbell](https://forum.odroid.com/memberlist.php?mode=viewprofile&u=15149) has a head start on power optimization - by two years - so much of which is here is derived from campbell's previous work.


### Moving to the mainline kernel

Boot into the 3.14 kernel packaged with the distribution, update everything and then shift to mainline:

````
pacman -Syu
pacman -R uboot-odroid-c2
pacman -S uboot-odroid-c2-mainline linux-aarch64
````

The [mainline kernel gives a drop of 430mW](https://forum.odroid.com/viewtopic.php?p=243837#p243837) at idle over the 3.16 kernel due to optimizations.

> **Warning: USB hotplug does not work on 4.20.** You will have to reboot with the USB device connected for it to work right now.

### Getting a build system

The ODROID will do its own compilation work, so we will need some packages to build from the Arch Build System and the AUR.

````
pacman -S pacman-contrib base-devel
````

We will install [yay](https://github.com/Jguer/yay) and use that from now on so we have AUR support:

````
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
````

### Optimizing specific packages from source for performance

Note that performance optimizations are power optimizations. The less time the CPU is doing something, the more time the CPU governor can clock it down to a lower speed. For performance-critical C/C++ applications used often, we can rebuild the packages from the Arch Linux sources with tuned GCC compiler flags. YMMV on a per-package basis; some packages end up slower after being built from source with specific flag incantations, so benchmarking is critical.

These compilation steps often yielded important performance improvements on the Pi 3 platform, but often yield minimal gain on the more powerful ODROID-C2.

As of now, my usually-optimal compiler flags are:

````
-O2 -march=armv8-a+crc -mcpu=cortex-a53 -mtune=cortex-a53 -ftree-vectorize
````

* Set the above as `CFLAGS` & `CXXFLAGS` in your `/etc/makepkg.conf`.
* Set `MAKEFLAGS` to `-j4` so we can use all the cores.
* Set `COMPRESSXZ` to contain `-T 4` to use multiple threads when doing final package compression.

Note these flags are almost identical to the ones used to optimize the Raspberry Pi 3 packages; it is because the Pi 3 and the ODROID-C2 share the same ARM Cortex-A53 core from different manufacturers and at different clock speeds. 

The ODROID is more than capable of compiling most of its own things in a relatively short period of time in comparison to the Raspberry Pi, however, you can use `distcc` and an Arch Linux (or Windows with Arch userspace) laptop as a distcc build slave to accelerate compilation.

Now, onto building packages.

#### Grab the necessary PKGBUILD files and make them

You can pull ARM-specific PKGBUILDs from [their GitHub repo](https://github.com/archlinuxarm/PKGBUILDs/tree/master). If you are trying to recompile something not available in this repo, you can pull it with `asp` from the main Arch repositories.

If you are building from the AUR, `yay` will do these steps all for you assuming your `/etc/makepkg.conf` is configured as above.

````
cd path/to/your/PKGBUILD
makepkg -s
````

You may have to change specific things (such as `arch` to `aarch64`) for makepkg to build the package. If checksums are out of date, pacman can update them automatically for you using `updpkgsums`. (However, check to make sure the files are what you expect.)

#### Install the packages

You can use `makepkg -si` when building, or install with pacman/yay's `-U` flag:

````
yay -U my-built-package.tar.xz
````

### Optimizing power usage even further

We can set a few things on boot using a shell script in `/etc/rc.local`. 

#### Enable CPU frequency scaling (CPUFreq)

The mainline U-Boot does not enable CPU frequency scaling by default. We will need to remake the U-Boot images to do this. Install `uboot-tools` with `yay -S uboot-tools`, then edit `/boot/boot.txt` to get frequency scaling working. Edit your bootloader configuration to contain the lines 

````
fdt addr ${fdt_addr_r};
fdt set /scpi/clocks status okay;
````

within the conditional block `if load ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} /boot/initramfs-linux.img; then`. After this is complete, run /boot/mkscr and then reboot. This will give us frequency scaling between 100MHz and 1.54GHz.

#### Set the CPU governor

First, we can use the `conservative` CPU governor instead of `performance`.

````bash
/usr/bin/cpupower frequency-set -g conservative
````

I have this set in an old-school `/etc/rc.local` file among other settings; to enable rc-local compatibility create a systemd unit at `/etc/systemd/system/rc-local.service`:

````
[Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local

[Service]
 Type=forking
 ExecStart=/etc/rc.local start
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes
 SysVStartPriority=99

[Install]
 WantedBy=multi-user.target
````

and enable it with `systemctl enable rc-local`.

#### Tune APM (drive spin down)

If you're running a magnetic external drive, you can set its APM management.

To see your current spindown setting, `hdparm -B /dev/sdX`, where `X` is your drive. You'll see something like:

````
/dev/sda:
 APM_level      = 128
````

This APM_level will not permit drive spindown on many drives; set it lower. I have mine set to `64`, although it is an illogical incantation since `man hdparm` doesn't explain how aggressive this really makes anything.

> Note: **Everything else after this point in this section limits performance for power saving.** I do not do these things, but if you really need to save power you should give them a try.

#### Limiting Ethernet speed

For these hacks, you will need to install ethtool with `yay -S ethtool`.

Fast Ethernet (100Mbps) only will be about 675 mW instead of 908 mW, a power save of about 233 mW, which is relatively significant. So if you don't need Gigabit (e.g. your ecoserve is serving over a slower upload than 100Mbps or your router is FE only), you can run:

````bash
/usr/bin/ethtool -s eth0 speed 100 duplex full autoneg off
````

If you **really** don't mind slow, you can get even more savings (another 30 mW) using 10BaseT, but there are limited use cases for this.

````bash
/usr/bin/ethtool -s eth0 speed 10 duplex full autoneg off
````


#### Underclocking DRAM

You can underclock the C2's RAM using [a script available from Hardkernel](https://wiki.odroid.com/odroid-c2/application_note/software/adjust_dram_clock#update_guide_1_for_ubuntu), which will give you measured savings of roughly another 100 mW if you set the C2's RAM to 408 MHz.

To do this, run as `root`:

````bash
#!/bin/bash 

wget https://dn.odroid.com/S905/BootLoader/ODROID-C2/c2_update_ddrclk.sh
chmod +x ./c2_update_ddrclk.sh
./c2_update_ddrclk.sh 408
reboot
````

### Optimizing network throughput

TODO

## Software Configuration

As with most consumerism, your choices impact your footprint. Picking software built with minimalism or performance in mind will greatly increase the overall efficiency of your server build. When in doubt, here are some heuristics:

* **Pick applications written with minimal dependencies.** Much of the Python, Ruby and Node ecosystems pull in tons of dependencies and neither of the three are particularly fast.
* **Avoid Docker.** While Docker itself doesn't have too much of a performance impact, you're going to have multiple userlands running. You're not getting a lot of security benefit, either. [Containers are not security boundaries](https://cloud.google.com/blog/products/gcp/demystifying-container-vs-vm-based-security-security-in-plaintext) and [least privilege just does not exist by default](https://medium.com/@mccode/processes-in-containers-should-not-run-as-root-2feae3f0df3b). Most containers do not follow best practices. If you must run Docker, follow [the CIS benchmark for Docker CE](https://docs.docker.com/compliance/cis/docker_ce/).
* **Prefer Go.** If it's not exposed directly to the Internet, I will generally look for the [Go](https://golang.org/) variant of an application and use that first if it gives me the proper feature set, even if it is a little immature, as it is often much faster than applications written in Python, Ruby, or Node. For production / hostile-environment type things it may be better to stick with the proven solution.
* **Look for performance above usability.** Performant is a fancy way to say "CPU-efficient". A performant application will issue less instructions to do the same amount of work.

Your mileage may vary, and individual decisions are just that - you decide what tradeoffs are good for you.

### Disk Encryption

AES throughput is decent on the ODROID, and definitely transparent over the limited bandwidth of MicroSD and USB 2.0. Here are the results of `cryptsetup benchmark`:

#### Hashing function benchmarks

|Hash function    |Iterations per second       |
|-----------------|----------------------------|
|PBKDF2-sha1      |246375 ips (256-bit key)    |
|PBKDF2-sha256    |355690 ips (256-bit key)    |
|PBKDF2-sha512    |317750 ips (256-bit key)    |
|PBKDF2-ripemd160 |216647 ips (256-bit key)    |
|PBKDF2-whirlpool |82435 ips (256-bit key)     |
|argon2i          |4 iterations, 312239 memory, 4 parallel threads (CPUs) for 256-bit key|
|argon2id         |4 iterations, 311232 memory, 4 parallel threads (CPUs) for 256-bit key|

#### Cipher benchmarks
| Algorithm     | Key        | Encryption Speed |Decryption Speed  |
|---------------|------------|------------------|------------------|
|        aes-cbc|        128b|        58.2 MiB/s|        68.5 MiB/s|
|    serpent-cbc|        128b|        29.8 MiB/s|        34.0 MiB/s|
|    twofish-cbc|        128b|        45.6 MiB/s|        50.9 MiB/s|
|    serpent-cbc|        256b|        30.8 MiB/s|        34.0 MiB/s|
|    twofish-cbc|        256b|        47.0 MiB/s|        50.9 MiB/s|
|        aes-xts|        256b|        75.2 MiB/s|        67.4 MiB/s|
|        aes-cbc|        256b|        43.0 MiB/s|        51.3 MiB/s|
|    serpent-xts|        256b|        32.7 MiB/s|        36.2 MiB/s|
|    twofish-xts|        256b|        52.7 MiB/s|        56.6 MiB/s|
|        aes-xts|        512b|        57.0 MiB/s|        50.7 MiB/s|
|    serpent-xts|        512b|        33.9 MiB/s|        36.2 MiB/s|
|    twofish-xts|        512b|        54.7 MiB/s|        56.5 MiB/s|

`aes-xts-256` provides sufficient security for my data on my disks, so to set up disk encryption
on the primary external disk:

````
# cryptsetup luksFormat --cipher=aes-xts-plain64 --key-size=256 --pbkdf=argon2id --iter-time=5000 /dev/sda1
````

The real protection is in the passphrase and the ability to crack it. Instead of using PBKDF2, we can increase overall security using [Argon2id](https://crypto.stackexchange.com/questions/48935/why-use-argon2i-or-argon2d-if-argon2id-exists) which is much less parallelizable than the PBKDF2 SHA. Increasing `iter-time` also helps, and it should be as high as you can really tolerate; 5000 is 5 seconds of generation time. This gives us a decent balance of security (CPU load at LUKS unlock) and I/O speed (CPU load under write).

Now open the filesystem and format it as whatever you want. I use `f2fs` on MicroSD cards and eMMC and `ext4` on SSD and HDD.

````
# cryptsetup luksOpen /dev/sda1 external
# mkfs.ext4 /dev/mapper/external
````

Mount it and you're good to go.
````
# mount /dev/mapper/external /srv/external
````

> **Note**: I manually unlock this drive and mount it, instead of using /etc/crypttab and /etc/fstab for automount from a keyfile. If you have a system for keys you can use it instead. See [dm-crypt/System Configuration](https://wiki.archlinux.org/index.php/Dm-crypt/System_configuration) for more information on setting this up.


### HTTP Server / Reverse Proxy: nginx (instead of Apache)

TODO

### SCM: Gitea (instead of Gitlab)

TODO

### Mac & PC Backup: Samba (instead of a Mac or Time Capsule)

Both my Mac and my ThinkPad back up to the external disk attached to the ODROID using Samba. Recent variants of Samba allow emulation of a Mac for Time Machine backups using the `fruit` extension. `pacman -S samba` to install Samba.

External drives on the ODROID-C2 max out at about 35.5MB/sec sequential write due to the USB 2.0 speeds. If you have older drives and power consumption does not matter, you can power them with an external enclosure - this is a good way to recycle older 9.5mm drives that may not be fast enough on newer platforms but are still great for backup purposes. The ODROID will not power most external hard disks; the 1A it takes to spin them up is greater than the 500mA the ports are limited to due to the protection circuit. If you need to access the drives frequently and they don't spend as much time spun down, consider SSD for better power consumption. Most manufacturers of drives will have spec sheets that will tell you what the overall drive power consumption is like.

#### Configuring Samba

Samba has a lot of performance optimizations that can be configured, but we are unfortunately limited by the USB 2.0 bus speed. As long as we can max out sequential writes to the external drive, we are about as optimized as we can get. Default Samba configuration can get you close to the max bus speed, but we might as well go for overkill in case we wish to transfer to eMMC. These settings will max all I/O I have on the ODROID C-2 at sequential R/W over GigE.

#### Creating users

You will need to create users for your backup clients. I name them the same as my laptop hostnames, and give them long passphrases, since they are saved to the credential stores of the clients. Clients may only access backup data that belong to them, and cannot access other shares:

````
useradd laptop
smbpasswd -a laptop
````

#### Configuring Samba

First, we can globally tune Samba a little for more speed:

````
socket options = TCP_NODELAY IPTOS_LOWDELAY
getwd cache = yes
read raw = yes 
write raw = yes
dead time = 5
use sendfile = yes
````

Then, under the share you want to enable for Time Machine:

````
[Backup]
    comment = Backup
    path = /mnt/external/backup/%U
    valid users = laptop

    browseable = yes
    writeable = yes
    create mask = 0600
    directory mask = 0700

    durable handles = yes
    kernel oplocks = no
    kernel share modes = no
    posix locking = no

    vfs objects = catia fruit streams_xattr
    fruit:aapl = yes
    fruit:time machine = yes
    fruit:model = MacMini
    fruit:advertise_fullsync = true
    spotlight = yes
````

The Mac will properly note that this drive can be used for Time Machine, and will then back up to it. Note `laptop` in valid users is the user we created above. I recommend having a global `/backup` directory for all backup shares, as it makes running Duplicity a little easier.

> **Mojave Note**: Every now and then, Time Machine will fail to back up to the network share stating that the remote server "the network backup disk does not support the required capabilities", even though there is no change to Samba itself. Reconnecting the disk appears to fix the issue; also, make sure that the permissions of .sparsebundle contents are all owned by the macOS user.

#### Setting Time Machine disk quotas

Disk quotas for Time Machine will be set under each individual user directory as a .plist. Copy below as `.com.apple.TimeMachine.quota.plist` in each user directory that will be using Time Machine.

````plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>GlobalQuota</key>
    <integer>$MY_QUOTA</integer>
  </dict>
</plist>
````

In this case, `$MY_QUOTA` should be set to the byte quota you want to limit this user to: you want `$QUOTA_IN_MB * 1000000`. For example, to set a 500GB quota, use `1000000 * 5000` or `5000000000`.


### Duplicity: Offsite Backup

[Duplicity](http://duplicity.nongnu.org/) is an rsync-backed backup system that makes encrypted backups to cloud services or other servers. I set up nightly sync from the ODROID to [Google Cloud Platform's Coldline Storage](https://cloud.google.com/storage/archival/), which competes with Glacier. GCP [purchases RECs](https://cloud.google.com/renewable-energy/) so the energy sources are renewable, and was a primary driver of my use of GCP.

Duplicity treats the cloud as hostile, and all data is encrypted locally before it is sent up to the cloud. You will need to back up your encryption keys locally. To use Duplicity, you will need to generate a GPG key to handle encryption and signing. GPG defaults to RSA-2048 if you use `gpg --gen-key`, which is too small. Use `gpg --full-generate-key`, and choose `RSA and RSA` and `4096` bit length. Set a strong passphrase. At the end, you'll have something like:

````
public and secret key created and signed.
pub   rsa4096 2019-02-19 [SC] [expires: 2021-02-18]
      81B5ABEA507FE473C8469964F279EB92A4529F01
uid                      ODROID-C2 <root@odroid-c2.local>
sub   rsa4096 2019-02-19 [E] [expires: 2021-02-18]
````

All data I have across all of my devices, including OS information, is less than 2TB. Those with large media collections will probably want to use an offsite server in the SSH/SCP model for cost effectiveness. [Hetzner's storage boxes](https://www.hetzner.com/storage/storage-box) are also cheap for serious GB, and their datacenters in Germany and Finland [use renewable power sources](https://www.hetzner.com/unternehmen/umweltschutz/).


#### Backing up to Google Cloud Platform Archival Storage

TODO

#### Backing up to a remote server via SSH/SCP

Another option is to share disk space among friends. For friends with a lot of data, 3.5" drives might be better even though overall consumption is higher; the Helium-filled HGST Ultrastar He and Seagate EXOS drives have better power consumption per gigabyte than most 2.5" solutions, and if they are spun down often, do not use much power at standby. At the time of this writing, the [HGST Ultrastar He10](https://documents.westerndigital.com/content/dam/doc-library/en_us/assets/public/western-digital/product/data-center-drives/ultrastar-dc-hc500-series/data-sheet-ultrastar-dc-hc510.pdf) (now Ultrastar DC HC510) is the sweet spot for cost versus capacity, and 10TB of disk is a lot of disk by most people's standards. They are relatively reliable and cheap to purchase used/refurbished from liquidators. The [ODROID-HC2](https://www.hardkernel.com/shop/odroid-hc2-home-cloud-two/) is a cheap appliance you can trade with friends to use as each others' offsite backups. There is no cheaper way to store huge terabyte values than your own hardware.

For this, we assume that you have SSH access to a computer that has the drive attached at `/mnt/backup`. I am using the pexpect backend to use OpenSSH instead of paramiko, so `pacman -S python2-pexpect` to use the command below. `pexpect` is substantially easier on the CPU because it doesn't use paramiko's inefficient Python for SCP. Using `pexpect+scp` cut memory usage by the duplicity process by 20x and CPU usage by over half. Using paramiko before, backup upload from the C2 was CPU-bound.

We can then run duplicity's first full backup of our other backups:

````bash
duplicity full --encrypt-sign-key=$YOUR_GPG_FINGERPRINT /mnt/external/backup pexpect+scp://user@offsite-server.example.com//mnt/backup
````

In this case, `$YOUR_GPG_FINGERPRINT` is the fingerprint to your GPG key generated above (in our example, `81B5ABEA507FE473C8469964F279EB92A4529F01`), and `offsite-server.example.com` is the FQDN or IP of the server you are backing up to. If you want to script this, you will need to add `PASSPHRASE` to the environment. This will mean that anyone with your key and passphrase will be able to decrypt your backups, so be careful.

````bash
PASSPHRASE=$YOUR_PASSPHRASE duplicity full --encrypt-sign-key=$YOUR_GPG_FINGERPRINT /mnt/external/backup pexpect+scp://user@offsite-server.example.com//mnt/backup
````

#### Setting up timed full/incremental backups 

Depending on what you are storing, you may want to do full or incremental backups. I keep full backups monthly, and incrementals weekly on my cloud storage. Incrementals save some upload bandwidth but not really any restore time when restoring from these large images. Set up your backup in cron; for me this script runs every week. For more information on crontab, see [the Arch wiki](https://wiki.archlinux.org/index.php/Cron#Crontab_format).

````sh
#!/bin/sh

# settings for your backup
export PASSPHRASE="This is an example passphrase for the GPG key"
GPG_FINGERPRINT="81B5ABEA507FE473C8469964F279EB92A4529F01"

LOCAL_BACKUP_FILE_LOCATION="/mnt/external/backup"

REMOTE_USER="user"
REMOTE_SERVER="offsite-server.example.com"
REMOTE_LOCATION="/mnt/backup"

# call duplicity
/usr/bin/duplicity \
  --asynchronous-upload \
  --encrypt-sign-key "$GPG_FINGERPRINT" \
  --full-if-older-than 30D \
  --volsize 128 \
  $LOCAL_BACKUP_FILE_LOCATION \
  pexpect+scp://$REMOTE_USER@$REMOTE_SERVER/$REMOTE_LOCATION
````

> **Time Machine Note**: macOS backups store .sparsebundles with 8MB bands, so keeping volume sizes in 8-ish MB increments should hopefully align us closer to those file sizes and reduce unnecessary backups. I have not definitively tested this optimization, so if you have something to add, please do.