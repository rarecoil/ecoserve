# Raspberry Pi 2/3 ARMv7 (32-bit) ecoserve guide

These configuration files are optimized for the Raspberry Pi running an armv7 build of [Arch Linux ARM](). They have been tested on a Raspberry Pi 3, but should work relatively well on the Raspberry Pi 2. The Raspberry Pi 2 has slightly better performance-per-watt characteristics to the Raspberry Pi 3, but both will stay under 4W at full HTTP load on fast ethernet, and around 5-5.5W at full load on Gigabit Ethernet with an attached Gigabit Ethernet adapter.

The default RPi builds of Raspbian for the Raspberry Pi 3 are currently 32-bit, even though the processor is a 64-bit. This means that some performance is left on the table. This is because of [some ongoing video issues](https://github.com/raspberrypi/firmware/issues/550) and [userland problems](https://github.com/raspberrypi/userland/issues/460).

## Prerequisites

1. A Raspberry Pi 2, Raspberry Pi 3, or Raspberry Pi 3 B+.
1. A good SD card. I recommend the [Samsung PRO Endurance 64GB](https://www.amazon.com/Samsung-Endurance-64GB-Micro-Adapter/dp/B07B9KTLJZ).
1. (*optional*) A Gigabit Ethernet Adapter. The [TU3-ETG](https://www.amazon.com/TRENDnet-Ethernet-Chromebook-Specific-TU3-ETG/dp/B00FFJ0RKE/) works well. If you have a 3B+, you don't need this.
1. A GOOD 5V/2.5A adapter. I recommend [CanaKit's adapter](https://www.amazon.com/CanaKit-Raspberry-Supply-Adapter-Listed/dp/B00MARDJZ4/). **The Raspberry Pi 3 is really picky and you will likely see crashes with a bad adapter.**

> Although a Gigabit adapter is definitely not necessary - and adds about 1.5W max of power consumption - the amount of web traffic your Pi will be able to handle increases extremely. `wrk` gave 2860 requests per second on the GigE adapter, and less than 1000 requests per second with the built-in Fast Ethernet.

## General Optimizations

* HDMI disabled
* GPU RAM use minimized
* Slight undervolt
* Power management changed to allow underclocked ARM cores at idle
* Increased TCP backlog and perf tuning
* Overclocked SD card for better I/O perf

## Web Server (nginx)

Install web server prerequisites as `root`:

````
pacman -S nginx
mkdir -p /srv/www
openssl dhparam -out /etc/nginx/dhparam.pem 3072
````

Then, copy the files from `boot` to your `/boot` and `/etc` to your `/etc`. Overwrite the existing files.

### TLS performance is the bottleneck

SSL/TLS performance is the limiting factor for greater throughput. This is due to perfect forward secrecy and strong cryptography that does not have hardware accleration on ARMv7. Initial TLS connection setup is the majority of the time spent serving static requests and a great suck of CPU time. The SSL/TLS configuration is still relatively strong in this configuration, but it makes some security tradeoffs in the name of speed. In situations where Ephemeral Key Exchange will be done using [EECDH-RSA](https://vincent.bernat.ch/en/blog/2011-ssl-perfect-forward-secrecy) it will be, and DHE-RSA is way down the list of supported ciphers right before we lose PFS entirely.