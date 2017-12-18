FROM mongo:3.4

ENV CVE_BASE=/opt/cve
ENV PATH=${PATH}:${CVE_BASE}/bin

RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    curl -s 'https://www.dotdeb.org/dotdeb.gpg' | apt-key add - && \
    echo "deb http://mirrors.teraren.com/dotdeb/ jessie all" \
        > /etc/apt/sources.list.d/dotdeb.list

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        patch \
        python3 \
        python3-pip \
        python3-lxml \
        python3-dev \
        gcc \
        redis-server && \
    mv /usr/local/bin/docker-entrypoint.sh /usr/local/bin/mongo-entrypoint.sh && \
    rm /entrypoint.sh && \
    curl -sL https://github.com/cve-search/cve-search/archive/master.tar.gz | \
        tar xz -C $(dirname ${CVE_BASE}) && \
    mv $(dirname ${CVE_BASE})/cve-search-master ${CVE_BASE} && \
    pip3 install -r ${CVE_BASE}/requirements.txt && \
    apt-get autoremove -y python3-dev gcc && \
    rm -rf /var/lib/apt/lists/*

ADD docker-entrypoint.sh /usr/local/bin/cvedb

RUN cd $CVE_BASE && \
    sed 's/Host: 127.0.0.1/Host: 0.0.0.0/' \
        etc/configuration.ini.sample \
        > etc/configuration.ini && \
    curl -L https://gist.github.com/ttimasdf/a2f34aee0c4179a9d8257fc68c7136d5/raw/cve.patch | patch -p1

EXPOSE 5000
ENTRYPOINT ["cvedb"]
CMD ["-i", "-w"]
