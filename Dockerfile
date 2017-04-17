FROM centos:7
MAINTAINER Positron <positron@jarm.com>

ENV PHP_TIMEZONE "Asia/Bangkok"
ENV PHP_PORT "9000"
ENV PHP_STATUS_URL "/php_fpm_status"

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  http://rpms.famillecollet.com/enterprise/7/remi/x86_64/remi-release-7.3-1.el7.remi.noarch.rpm \
  && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 /etc/pki/rpm-gpg/RPM-GPG-KEY-remi /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 \
  && yum update -y \
  && yum-config-manager --enable remi-php71 \
  && yum install -y php-common php-cli php-process php-gd php-mbstring php-pecl-zip php-mcrypt php-xml php-pecl-apc php-pecl-mongodb php-xmlrpc php-opcache php-fpm inkscape
#  && yum clean all

RUN echo "date.timezone=$PHP_TIMEZONE" > /etc/php.d/00-date-timezone.ini

RUN groupadd webmaster && useradd -s /sbin/nologin -d /var/www/ -M -g webmaster webmaster && passwd -l webmaster

ONBUILD RUN chown -R webmaster:webmaster /var/www

ADD php.ini /etc
ADD php_run.sh /php_run.sh

RUN chmod a+x /php_run.sh

EXPOSE $PHP_PORT

WORKDIR /var/www

ENTRYPOINT []
CMD ["/php_run.sh"]


ENV         FFMPEG_VERSION=3.2.4     \
            FDKAAC_VERSION=0.1.5      \
            LAME_VERSION=3.99.5       \
            OGG_VERSION=1.3.2         \
            OPENCOREAMR_VERSION=0.1.5 \
            OPUS_VERSION=1.1.4        \
            THEORA_VERSION=1.1.1      \
            VORBIS_VERSION=1.3.5      \
            VPX_VERSION=1.6.1         \
            X264_VERSION=20170226-2245-stable \
            X265_VERSION=2.3          \
            XVID_VERSION=1.3.4        \
            PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
            SRC=/usr/local


ARG         OGG_SHA256SUM="e19ee34711d7af328cb26287f4137e70630e7261b17cbe3cd41011d73a654692  libogg-1.3.2.tar.gz"
ARG         OPUS_SHA256SUM="9122b6b380081dd2665189f97bfd777f04f92dc3ab6698eea1dbb27ad59d8692  opus-1.1.4.tar.gz"
ARG         VORBIS_SHA256SUM="6efbcecdd3e5dfbf090341b485da9d176eb250d893e3eb378c428a2db38301ce  libvorbis-1.3.5.tar.gz"
ARG         THEORA_SHA256SUM="40952956c47811928d1e7922cda3bc1f427eb75680c3c37249c91e949054916b  libtheora-1.1.1.tar.gz"
ARG         XVID_SHA256SUM="4e9fd62728885855bc5007fe1be58df42e5e274497591fec37249e1052ae316f  xvidcore-1.3.4.tar.gz"
ARG         FFMPEG_KEY="D67658D8"


RUN     buildDeps="autoconf \
                   automake \
                   bzip2 \
                   cmake \
                   gcc \
                   gcc-c++ \
                   git \
                   libtool \
                   make \
                   nasm \
                   perl \
                   openssl-devel \
                   tar \
                   yasm \
                   which \
                   zlib-devel" && \
        export MAKEFLAGS="-j$(($(nproc) + 1))" && \
        echo "${SRC}/lib" > /etc/ld.so.conf.d/libc.conf && \
        yum --enablerepo=extras install -y epel-release && \
        yum install -y ${buildDeps}

## opencore-amr https://sourceforge.net/projects/opencore-amr/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sL http://downloads.sf.net/project/opencore-amr/opencore-amr/opencore-amr-${OPENCOREAMR_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --enable-shared --datadir=${DIR} && \
        make && \
        make install && \
        rm -rf ${DIR}

## x264 http://www.videolan.org/developers/x264.html
RUN  \
       DIR=$(mktemp -d) && cd ${DIR} && \
       curl -sL https://ftp.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
       tar -jx --strip-components=1 && \
       ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --enable-pic --enable-shared --disable-cli && \
       make && \
       make install && \
       rm -rf ${DIR}

## x265 http://x265.org/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sL https://download.videolan.org/pub/videolan/x265/x265_${X265_VERSION}.tar.gz  | \
        tar -zx && \
        cd x265_${X265_VERSION}/build/linux && \
        ./multilib.sh && \
        make -C 8bit install && \
        rm -rf ${DIR}

## libogg https://www.xiph.org/ogg/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/ogg/libogg-${OGG_VERSION}.tar.gz && \
        echo ${OGG_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f libogg-${OGG_VERSION}.tar.gz && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --disable-static --datarootdir=${DIR} && \
        make && \
        make install && \
        rm -rf ${DIR}

## libopus https://www.opus-codec.org/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/opus/opus-${OPUS_VERSION}.tar.gz && \
        echo ${OPUS_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f opus-${OPUS_VERSION}.tar.gz && \
        autoreconf -fiv && \
        ./configure --prefix="${SRC}" --disable-static --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}

## libvorbis https://xiph.org/vorbis/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS_VERSION}.tar.gz && \
        echo ${VORBIS_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f libvorbis-${VORBIS_VERSION}.tar.gz && \
        ./configure --prefix="${SRC}" --with-ogg="${SRC}" --bindir="${SRC}/bin" \
        --disable-static --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}

## libtheora http://www.theora.org/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/theora/libtheora-${THEORA_VERSION}.tar.gz && \
        echo ${THEORA_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f libtheora-${THEORA_VERSION}.tar.gz && \
        ./configure --prefix="${SRC}" --with-ogg="${SRC}" --bindir="${SRC}/bin" \
        --disable-static --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}

## libvpx https://www.webmproject.org/code/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sL https://codeload.github.com/webmproject/libvpx/tar.gz/v${VPX_VERSION} | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${SRC}" --enable-vp8 --enable-vp9 --enable-pic --disable-debug --disable-examples --disable-docs --disable-install-bins --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}

## libmp3lame http://lame.sourceforge.net/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sL https://downloads.sf.net/project/lame/lame/${LAME_VERSION%.*}/lame-${LAME_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --disable-static --enable-nasm --datarootdir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}

## xvid https://www.xvid.com/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sLO http://downloads.xvid.org/downloads/xvidcore-${XVID_VERSION}.tar.gz && \
        echo ${XVID_SHA256SUM} | sha256sum --check && \
        tar -zx -f xvidcore-${XVID_VERSION}.tar.gz && \
        cd xvidcore/build/generic && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --datadir="${DIR}" --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}

## fdk-aac https://github.com/mstorsjo/fdk-aac
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sL https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        autoreconf -fiv && \
        ./configure --prefix="${SRC}" --disable-static --datadir="${DIR}" && \
        make && \
        make install && \
        make distclean && \
        rm -rf ${DIR}

## ffmpeg https://ffmpeg.org/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys ${FFMPEG_KEY} && \
        curl -sLO http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
        curl -sLO http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz.asc && \
        gpg --batch  --verify ffmpeg-${FFMPEG_VERSION}.tar.gz.asc ffmpeg-${FFMPEG_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.gz && \
        ./configure \
        --bindir="${SRC}/bin" \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --disable-static \
        --enable-avresample \
        --enable-gpl \
        --enable-libopencore-amrnb \
        --enable-libopencore-amrwb \
        --enable-libfdk_aac \
        --enable-libmp3lame \
        --enable-libopus \
        --enable-libtheora \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libx264 \
        --enable-libx265 \
        --enable-libxvid \
        --enable-nonfree \
        --enable-openssl \
        --enable-postproc \
        --enable-shared \
        --enable-small \
        --enable-version3 \
        --extra-cflags="-I${SRC}/include" \
        --extra-ldflags="-L${SRC}/lib" \
        --extra-libs=-ldl \
        --prefix="${SRC}" && \
        make && \
        make install && \
        make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && \
        cp qt-faststart ${SRC}/bin && \
        rm -rf ${DIR} && \

# cleanup
        cd && \
        yum history -y undo last && yum clean all && \
        rm -rf /var/lib/yum/* && \
        ffmpeg -buildconf
