FROM ubuntu:24.04
MAINTAINER Jean-Daniel Gasser <jdgasser@gmail.com>

#Variables
ENV NAGIOS_NLS_FQDN            nagios-nls.hmt-pro.com
# install required packages
RUN echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections  && \
    echo postfix postfix/mynetworks string "127.0.0.0/8" | debconf-set-selections            && \
    echo postfix postfix/mailname string ${NAGIOS_NLS_FQDN} | debconf-set-selections             && \
    apt-get update && apt-get install -y    \
        wget                             \
        tar                       \
        autoconf                            \
        automake                            \
        rsyslog                                  \
        iproute2                                \
        systemd                                \
#        initscripts                           \
                                                && \
    apt-get clean && rm -Rf /var/lib/apt/lists/*

# Activer systemd
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-updatedb.service

# Définir le point d'entrée pour démarrer systemd
ENTRYPOINT ["/lib/systemd/systemd"]
CMD ["--system", "--unit=multi-user.target"]

# download NLS
WORKDIR /tmp
RUN wget https://assets.nagios.com/downloads/nagios-log-server/nagioslogserver-latest.tar.gz
RUN tar xzf nagioslogserver-latest.tar.gz

# install NLS
WORKDIR nagioslogserver
RUN sed -i '/^do_install_check$/d' ./fullinstall
RUN touch installed.firewall
RUN ./fullinstall --non-interactive

# finalise build configuration
WORKDIR /usr/local/nagioslogserver
VOLUME ["/usr/local/nagioslogserver"]
EXPOSE 80 443 9300:9400 3515 5544 2056 2057 5544/udp

# configure start script
ADD start.sh /start.sh
RUN chmod 755 /start.sh
COPY update_hosts.sh /usr/local/bin/
COPY update_ssh.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/update_*
RUN echo "Europe/Paris" > /etc/timezone
RUN echo "alias ssh='ssh -o StrictHostKeyChecking=accept-new'" >> /etc/bash.bashrc
CMD [ "bash", "-c", "/usr/local/bin/update_hosts.sh &&  /start.sh" ]
