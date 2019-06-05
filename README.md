# ecoserve

ecoserve is an experiment meant to allow for a low-energy personal server. With the advent of broadband connections in most points around the world, it is possible for many people to host their own services on even dynamic IP connections with reasonable latency, and likely do it off-grid.

This project has been inspired in part by Low-Tech Magazine's [solarserver](https://solar.lowtechmagazine.com/2018/09/how-to-build-a-lowtech-website.html). They made a number of good decisions and optimizations [described here](https://homebrewserver.club/low-tech-website-howto.html), but some of the design decisions can be further optimized and worked on in a community format.

The end idea is to have this project support multiple SBCs with different configurations, and have a series of scripts specifically optimized for the low power use case. In this way it should be possible to develop a series of optimized, cloud-like services and run them for most users.

## Tested/configured systems

* Raspberry Pi 3 - see `raspi/armv7` for 32-bit (should work as a baseline for Raspberry Pi 2), or `raspi/armv8` for 64-bit.
* ODROID-C2 - see `odroid-c2`. I personally use this platform.

## Why?

A lot of enthusiasts run home servers based upon second-hand enterprise-grade hardware. Often times our on-premises servers aren't as efficient as they could be, and we don't write the most optimized code for these solutions, either. Reducing power consumption for these systems to the lowest extent possible allows for individuals to run off-grid home servers with battery backup systems in the majority of locations.

Our individual electricity grids are also often significantly dirtier than the power systems on major cloud platforms. In the Bay Area where many technologists live, [only 33% of PG&E electricity comes from renewable sources](http://www.pgecorp.com/corp_responsibility/reports/2018/environment.html). Seattle does better, at [90% from hydropower](https://energysolutions.seattle.gov/renewable-energy/). However, both of these are bad compared to Google Cloud Platform, which is powered with [100% renewable energy](https://cloud.google.com/sustainability/). 

Thus, in order to reduce as much of our personal footprint as possible, it is prudent to:

* **Use a renewable energy program.** In the Bay Area, [PG&E Solar Choice](https://www.pge.com/en_US/residential/solar-and-vehicles/options/solar/solar-choice/solar-choice.page) is a voluntary way to pay a little more to source renewable-only power. Such programs are less expensive in the PNW, such as Portland General Electric's [Green future program](https://www.portlandgeneral.com/residential/power-choices/renewable-power/choose-renewable) or Puget Sound Energy's [Green Power program](https://www.pse.com/green-options/Renewable-Energy-Programs/green-power).

* **Reduce electronic power consumption as much as possible.** Ultra-low-voltage chips reign supreme. When plotting hardware upgrades, look for performance-per-watt characteristics and try to buy as low of TDP solutions as possible. Instead of running a massive server rig at home that you use 1% of the time, build a low-TDP system that sees balanced utilization for most projects, and leverage cloud resources for spot performance where high-TDP systems are required. Avoid second-hand "enterprise-grade" hardware.

The reduction angle is the primary angle behind the ecoserve project - it is not meant to replace cloud services for truly high scale applications, but lower the barrier to entry and energy consumption of technologists worldwide.


## What about the cloud?

Cloud platforms benefit from scale, but who your platform is seems to matter a lot for overall sustainability and carbon emissions practices. As of the time of this writing 5 June 2019:

* [Google Cloud Platform](https://cloud.google.com/sustainability/) is 100% renewable energy backed, using solar and RECs.
* [Amazon Web Services](https://aws.amazon.com/about-aws/sustainability/#progress) is 50% renewable, not much better than PG&E. uses renewable energy in the NoVA `us-east` region. `us-west` is offset.
* [Microsoft Azure](https://blogs.microsoft.com/on-the-issues/2018/03/21/new-solar-deal-moves-us-ahead-of-schedule-in-creating-a-cleaner-cloud/) targeted 50% renewable in 2018 and 60% by 2020, leaving it mostly on par with AWS.
* [Cloudflare](https://blog.cloudflare.com/a-carbon-neutral-north-america/) purchases RECs (renewable energy credits), similar to those offered to customers of specific utilities.
* Cheap hacker favorite cloud provider [Hetzner](https://www.hetzner.com/) uses [hydropower and wind power](https://www.hetzner.com/unternehmen/umweltschutz/) at their German and Finnish data centers, respectively. Using the [Server Auction](https://www.hetzner.com/sb) you can get some good deals on older hardware. Intel Haswell and above allows undervolting, so you can eke out more performance-per-watt with these dedicated boxes and keep them from getting recycled.

Before this research, I used [Digital Ocean](https://www.digitalocean.com/). Some other DO users have chimed in on [the DigitalOcean idea that exists regarding this](https://ideas.digitalocean.com/ideas/DO-I-1007), but CEO Moisey Uretsky seems to have posted at some point and there's not much DO can do since they don't own their data centers. It's best to avoid DO.

[Linode](https://linode.com/) should also be avoided, as they suffer the same issues. They are silent on renewable power, too.

> *If you have more information, please issue a pull request to this document.*


## Benefits of on-premises systems

Local proximity means a lot to a LAN and matters in overall energy consumption. Cloud energy costs for cloud providers themselves are good, but telecommunications infrastructure is not nearly as interested in environmental sustainability. Note [how little data Comcast adds to this environmental fluff piece](https://corporate.comcast.com/csr2015/building-a-smarter-energy-future). [Their environmental sustainability report](https://corporate.comcast.com/values/csr/2018/sustainable-excellence) simply states they're "working toward" sustainable practices. Monopolies don't need to care as much about such things, and corporate values aren't necessarily aligned in this direction.

> *Even though I call out Comcast, ISPs anywhere are often just victim to the grid in their area. At that case, the average US renewable energy amount is [12.2%](https://en.wikipedia.org/wiki/Renewable_energy_in_the_United_States).*

Therefore, overall bandwidth production should also be reduced as much as possible. It seems that heavy compression/decompression from points with renewable energy sources is also likely better than energy usage in transit, as the telecom grid can be treated as relatively dirty.

There are also legal and privacy concerns raised regarding cloud services. Cloud services are [often subject to government data requests](https://www.eff.org/who-has-your-back-2017) and should be considered zero-knowledge parties whenever possible (i.e., when backing up to the cloud, encrypt it all on machines you control first.)

From an ecosystem angle, diversity is good. Cloud platforms are private companies and have the ability to restrict free speech and information via their own Terms of Use. Some far-right and alt-right parties have found notable problems in this regard over the period of 2016 to present, and even if their messages are disagreeable to those of us more left-leaning, Martin Niemöller would like a word with you. Having home servers and services also work great for developer education.

## Contributions

Contributions and further optimizations to this work are greatly appreciated and will be accepted after confirmed testing.

## License

GPL 3.0.
