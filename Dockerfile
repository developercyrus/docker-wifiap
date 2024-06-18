FROM ubuntu:24.04

RUN apt -y update
RUN apt -y install \ 
           hostapd \
           dnsmasq \
           iptables
RUN apt -y install net-tools # ipconfig   
RUN apt -y install iproute2  # ip route      

COPY hostapd.conf /etc/hostapd/hostapd.conf
COPY dnsmasq.conf /etc/dnsmasq.conf
COPY setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 67/udp 68/udp 53/udp 53/tcp

CMD ["/usr/local/bin/setup.sh"]

