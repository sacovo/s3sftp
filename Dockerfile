FROM ubuntu:latest

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y && \
    apt-get install -y openssh-server wget

RUN wget https://github.com/kahing/goofys/releases/latest/download/goofys --output-document=/usr/bin/goofys && \
    chmod +x /usr/bin/goofys

COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY sshd_config /etc/ssh/sshd_config

VOLUME ["/etc/ssh/keys"]

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
