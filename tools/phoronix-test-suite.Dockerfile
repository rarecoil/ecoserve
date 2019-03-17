FROM ubuntu:trusty
MAINTAINER rarecoil <rarecoil@noreply.users.github.com>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get -y install \
          build-essential wget unzip perl perl-base perl-modules libsdl-perl \
          libperl-dev libpcre3-dev mesa-utils php5-cli php5-gd php5-json libexpat-dev
RUN cd /tmp \
    && wget http://phoronix-test-suite.com/releases/repo/pts.debian/files/phoronix-test-suite_8.6.0_all.deb \
    && dpkg -i phoronix-test-suite_8.6.0_all.deb \
    && rm -f phoronix-test-suite_8.6.0_all.deb

ENTRYPOINT ["phoronix-test-suite"]