FROM alpine:3.19 AS builder
RUN mkdir /usr/local/src && apk add binutils --no-cache\
        build-base \
        readline-dev \
        openssl-dev \
        ncurses-dev \
        git \
        cmake \
        zlib-dev \
        libsodium-dev \
        gnu-libiconv 
WORKDIR /usr/local/src
COPY . /usr/local/src/SoftEtherVPN_Stable
RUN cd SoftEtherVPN_Stable &&\
	./configure &&\
	make &&\
	make install &&\
    touch /usr/vpnserver/vpn_server.config &&\
    tar -czf /vpnserver.tar.gz /usr/vpn* /usr/bin/vpn*


FROM alpine:3.19
COPY --from=builder /vpnserver.tar.gz /
RUN apk add --no-cache readline \
        openssl \
        libsodium \
        gnu-libiconv\
        iptables &&\
        tar -xzf /vpnserver.tar.gz &&\
        rm -rf /opt &&\
        ln -s /usr/vpnserver /opt &&\
        find /usr/bin/vpn* -type f ! -name vpnserver \
        -exec bash -c 'ln -s {} /opt/$(basename {})' \;
WORKDIR /usr/vpnserver/
VOLUME ["/usr/vpnserver/server_log/", "/usr/vpnserver/packet_log/", "/usr/vpnserver/security_log/"]
EXPOSE 443/tcp 992/tcp 1194/tcp 1194/udp 5555/tcp 500/udp 4500/udp
CMD ["/usr/bin/vpnserver", "execsvc"]