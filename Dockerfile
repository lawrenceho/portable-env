FROM fedora:43

ARG USER

COPY ./dnsmasq-*.sh /usr/local/bin
COPY ./image*.sh /tmp

RUN /tmp/image-install.sh

VOLUME /var/lib/docker

ENTRYPOINT ["/sbin/init"]
