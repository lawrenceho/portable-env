FROM fedora:42

ARG USER

ENV DOCKER_TLS_CERTDIR=/certs

COPY --from=docker:dind /usr/local/bin /usr/local/bin
COPY --from=docker:dind \
     /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins
COPY *entrypoint.sh /usr/local/bin
COPY image*.sh /tmp

RUN /tmp/image-install.sh

VOLUME /var/lib/docker

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
