FROM debian:bullseye-slim

ARG JITSI_RELEASE=stable
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
# 通过使用frep 原型 进行从环境变量进行模板渲染 .... 使用Go语言 text-template 进行模板渲染 // https://github.com/subchen/frep
ADD https://github.com/jitsi/tpl/releases/download/v1.0.1/tpl-linux-amd64 /usr/bin/tpl
COPY rootfs /

RUN apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y apt-transport-https apt-utils ca-certificates gnupg wget && \
    wget -qO - https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz | tar xfz - -C / && \
    wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | gpg --dearmour > /etc/apt/trusted.gpg.d/jitsi.gpg && \
    echo "deb https://download.jitsi.org $JITSI_RELEASE/" > /etc/apt/sources.list.d/jitsi.list && \
    echo "deb http://ftp.debian.org/debian bullseye-backports main" > /etc/apt/sources.list.d/backports.list && \
    apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get dist-upgrade -y && \
    apt-cleanup && \
    chmod +x /usr/bin/tpl

RUN [ "$JITSI_RELEASE" = "unstable" ] && \
    apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y jq procps curl vim iputils-ping net-tools && \
    apt-cleanup || \
    true

ENTRYPOINT [ "/init" ]
