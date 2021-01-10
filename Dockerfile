# Compile from source code
FROM alpine:3.12 as builder

RUN apk add --no-cache tini gcc g++ pkgconf make automake autoconf libtool \
    util-linux-dev sqlite-dev mariadb-connector-c-dev cmake zlib-dev fmt-dev \
    file-dev libexif-dev curl-dev ffmpeg-dev ffmpegthumbnailer-dev wget xz \
    libmatroska-dev libebml-dev taglib-dev pugixml-dev spdlog-dev \
    tree

ARG VERSION
ENV VERSION ${VERSION:-1.6.4}

WORKDIR /gerbera_build

RUN wget https://github.com/gerbera/gerbera/archive/v${VERSION}.tar.gz && tar -xzvf v${VERSION}.tar.gz
RUN cp -R gerbera-${VERSION}/. .

RUN bash scripts/install-pupnp.sh
RUN bash scripts/install-duktape.sh

RUN mkdir build && \
    cd build && \
    cmake ../ -DWITH_MAGIC=1 -DWITH_MYSQL=1 -DWITH_CURL=1 -DWITH_JS=1 \
    -DWITH_TAGLIB=1 -DWITH_AVCODEC=1 -DWITH_FFMPEGTHUMBNAILER=1 \
    -DWITH_EXIF=1 -DWITH_LASTFM=0 -DWITH_SYSTEMD=0 -DWITH_DEBUG=1 && \
    make -j`nproc`


# Run Gerbera service
FROM alpine:3.12

RUN apk add --no-cache tini util-linux sqlite mariadb-connector-c zlib fmt \
    file libexif curl ffmpeg-libs ffmpegthumbnailer libmatroska libebml taglib \
    pugixml spdlog sqlite-libs

ARG VERSION
ENV VERSION ${VERSION:-1.6.4}

# Manually built libs
COPY --from=builder /usr/local/lib/libupnp.so* /usr/local/lib/
COPY --from=builder /usr/local/lib/libixml.so* /usr/local/lib/
COPY --from=builder /usr/local/lib/libduktape.so* /usr/local/lib/

# Gerbera itself
COPY --from=builder /gerbera_build/build/gerbera /bin/gerbera
COPY --from=builder /gerbera_build/gerbera-${VERSION}/scripts/js /usr/local/share/gerbera/js
COPY --from=builder /gerbera_build/gerbera-${VERSION}/web /usr/local/share/gerbera/web

RUN rm -rf /tmp/* && \
    mkdir -p /media/pictures /media/videos /media/music /root/.config/gerbera

# RUN gerbera --create-config > /root/.config/gerbera/config.xml &&\
#     sed 's/<import hidden-files="no">/<import hidden-files="no">\n\
#     <autoscan use-inotify="yes">\n\
#     <directory location="\/root" mode="inotify" \
#     recursive="yes" hidden-files="no"\/>\n\
#     <\/autoscan>/' -i /root/.config/gerbera/config.xml

VOLUME [ "/media/pictures", "/media/videos", "/media/music", "/root/.config/gerbera" ]

EXPOSE 49152
EXPOSE 1900/udp

ENTRYPOINT ["/sbin/tini", "--"]
CMD [ "gerbera","-p", "49152" ]