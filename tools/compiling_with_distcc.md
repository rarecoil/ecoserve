# Accelerating compilation with distcc on WSL

The Raspberry Pi is likely not the fastest machine that you have. Thankfully, if you have a laptop or desktop you normally use, you can recruit it to assist your Raspberry Pi in compiling Arch Linux packages for itself. It is fairly easy to do with another Arch Linux machine, but a little tougher
if you don't have one running that.

I have two laptops, a ThinkPad X250 running Windows 10 Enterprise LTSC and an Apple MacBook. The X250's i7-5600U has a substantial amount more power than my MacBook, but runs Windows. This is not a big deal with the Windows Subsystem for Linux and `distcc`, a distributed C compiler infrastructure.

For this to work, both computers must be on the same network and they must be able to talk to each other.

## Preparing Windows Subsystem for Linux as a distcc slave

Following these steps will make your Windows laptop the **slave** for the Raspberry Pi, which will do a lot of the compilation for you.

You'll first need to [enable Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) and install the Arch userspace [yuk7/ArchWSL](https://github.com/yuk7/ArchWSL) before proceeding. Once this is done, run `pacman -Syu` to synchronize and update your userspace, and `pacman -Syy git base-devel distcc` for some basic dependencies.

The [Arch Linux ARM](https://archlinuxarm.org/) team distributes their own build tools in the [Arch AUR](https://aur.archlinux.org/). You can use their toolchain for our builds for the sake of consistency. Install their toolchain for [distccd-alarm](https://aur.archlinux.org/pkgbase/distccd-alarm/) next:

````
git clone https://aur.archlinux.org/distccd-alarm.git
cd distccd-alarm
makepkg -si
````

This will install the package. However, the Windows Subsystem for Linux doesn't have systemd services you can run. You can open a WSL `bash` window and then run `distccd` manually. Change `$RASPI_IP_ADDRESS` to the IP address of your Raspberry Pi.

````
export PATH=/opt/x-tools8/aarch64-unknown-linux-gnu/bin:$PATH
export DISTCC_ARGS="--allow $RASPI_IP_ADDRESS --port 3636 --log-file /tmp/distccd-armv8.log"
/usr/bin/distccd --daemon --no-detach $DISTCC_ARGS
````

At this point, your laptop is now ready to accept connections from the Raspberry Pi and will build on its behalf.

> Note that if you have multiple computers you can use as slaves, you can run `distcc` on all of them with this configuration.


## Preparing the Raspberry Pi

Edit `/etc/makepkg.conf` on your ARM Raspberry Pi. This is the **master**. You will need to know:

1. The IP address of your laptop and your Raspberry Pi
1. How many threads you want to run. I am using `6` which appears to be a good balance on my 4 logical CPU cores.
1. What architecture you're building for (in our case, `armv8`).

Once you know this:

1. Change `BUILDENV` to be `(distcc color !ccache check !sign)`.
1. Change `DISTCC_HOSTS` to be something in the format `"$IP_ADDRESS:$DISTCC_PORT/$NUM_CORES"`. So, if your laptop is at 192.168.1.100, you are using port 3636 to compile for ARMv8, and you have 6 threads to give, set `DISTCC_HOSTS` to `"127.0.0.1/2 192.168.1.100:3636/6"`.
1. Change `MAKEFLAGS` to the format `-j$NUM_THREADS`. In my case, that is `-j8`, for the 2 given to the localhost and 6 to the ThinkPad.

> If you have multiple hosts, add each of them to `DISTCC_HOSTS` with the same format as above, each separated by a space. Put your fastest machine first in the list. Then, change `MAKEFLAGS` to the *total* number of threads across all machines.


## Tips for compilation

If you try to compile large packages from git with a Raspberry Pi, you are likely to run out of memory. For example, the test Raspberry Pi 3's `git` would run out of memory on `Resolving deltas` when cloning the kernel. [Set up a couple of gigabytes of swap space](https://wiki.archlinux.org/index.php/swap#Swap_file) to give the Pi a little breathing room.


## More information 

* [Distcc on Arch Wiki](https://wiki.archlinux.org/index.php/Distcc#Arch_Linux_ARM)
* [Distcc Cross-Compiling](https://archlinuxarm.org/wiki/Distcc_Cross-Compiling)
