FROM ubuntu:24.04
MAINTAINER Jean-Daniel Gasser <jdgasser@gmail.com>

#Variables
ENV NAGIOS_NLS_FQDN            nagios-nls.hmt-pro.com
# install required packages
RUN yum -y install wget tar rsyslog initscripts; yum clean all
RUN echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections  && \
    echo postfix postfix/mynetworks string "127.0.0.0/8" | debconf-set-selections            && \
    echo postfix postfix/mailname string ${NAGIOS_NLS_FQDN} | debconf-set-selections             && \
    apt-get update && apt-get install -y    \
        wbet                             \
        tar                       \
        autoconf                            \
        automake                            \
        rsyslog                                  \
        initscripts                           \
                                                && \
    apt-get clean && rm -Rf /var/lib/apt/lists/*
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
RUN echo "Europe/Paris" > /etc/timezone
RUN echo "alias ssh='ssh -o StrictHostKeyChecking=accept-new'" >> /etc/bash.bashrc
CMD ["/start.sh"]
