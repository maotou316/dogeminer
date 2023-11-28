FROM alpine:3.18.4 as builder

ARG XMRIG_VERSION=v6.21.0
ARG XMRIG_URL="https://github.com/xmrig/xmrig.git"
ARG XMRIG_BUILD_ARGS="-DXMRIG_DEPS=scripts/deps -DBUILD_STATIC=ON"

ENV GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc
ENV GLIBC_VERSION=2.35-r1

RUN set -ex && \
    apk --update add libstdc++ curl ca-certificates && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION}; \
        do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

RUN apk add --no-cache \
    git \
    make \
    cmake \
    libstdc++ \
    gcc \
    g++ \
    automake \
    libtool \
    autoconf \
    linux-headers

WORKDIR /tmp/install

RUN git clone --single-branch --depth 1 --branch=$XMRIG_VERSION $XMRIG_URL -c advice.detachedHead=false \
    && cd /tmp/install/xmrig \
    && mkdir -p build \
    && sed -i 's/kDefaultDonateLevel = 1;/kDefaultDonateLevel = 0;/;' src/donate.h \
    && sed -i 's/kMinimumDonateLevel = 1;/kMinimumDonateLevel = 0;/;' src/donate.h
RUN cd /tmp/install/xmrig/scripts \
    && sh ./build_deps.sh
RUN cd /tmp/install/xmrig/build \
    && if [[ "$(uname -m)" == *"aarch64"* ]]; then XMRIG_BUILD_ARGS="$XMRIG_BUILD_ARGS -DCMAKE_SYSTEM_PROCESSOR=arm"; fi \
    && cmake .. $XMRIG_BUILD_ARGS \
    && make -j$(nproc)

# Stage 2: Copy XMRig binary into a smaller image
FROM alpine:3.18.4

RUN apk add --no-cache \
    bash \
    screen \
    cpulimit \
    && addgroup --gid 1000 xmrig \
    && adduser --uid 1000 -H -D -G xmrig -h /bin/xmrig xmrig

COPY --from=builder --chown=xmrig:xmrig [ "/tmp/install/xmrig/build/xmrig", "/bin" ]

WORKDIR /usr/src/mining
COPY [ "./entrypoint.sh", "." ]

RUN mkdir -p config && pwd && ls -alR ./*

COPY [ "./config", "./config" ]

RUN mkdir -p config && pwd && ls -alR ./*

RUN chown -R xmrig:xmrig /usr/src/mining \
    && chmod +x entrypoint.sh

USER xmrig

CMD [ "bash", "/usr/src/mining/entrypoint.sh" ]
# CMD ["tail", "-f", "/dev/null"]
# 
