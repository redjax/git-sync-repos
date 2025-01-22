ARG DEBIAN_IMG_VERSION=${DEBIAN_IMG_VERSION:-bookworm-slim}

FROM debian:${DEBIAN_IMG_VERSION} AS base

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        openssh-server \
        ca-certificates \
        apt-transport-https \
        software-properties-common \
        parallel \
        cron \
        vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM base AS stage

WORKDIR /git-sync

COPY ./git_mirror_sync.sh /git-sync/git_mirror_sync.sh
COPY ./containers/docker-entrypoint.sh /docker-entrypoint.sh
COPY ./containers/crontab /etc/cron.d/cron_schedule.cron

## Create directory where git repos will be cloned
RUN mkdir -p /git-sync/repositories

FROM stage AS run
COPY --from=stage /git-sync /git-sync
COPY --from=stage /docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=stage /etc/cron.d/cron_schedule.cron /etc/cron.d/cron_schedule.cron

WORKDIR /git-sync

RUN chmod u+x /docker-entrypoint.sh /git-sync/git_mirror_sync.sh

## Declare volume mounts for Docker compose and docker -v
VOLUME ["/root/.ssh", "/git-sync"]

RUN chmod 644 /etc/cron.d/cron_schedule.cron

ENTRYPOINT [ "/bin/bash", "/docker-entrypoint.sh" ]
# CMD ["sleep", "infinity"]
CMD ["/bin/bash", "-c", "cat /etc/cron.d/cron_schedule.cron | crontab - && cron -f"]
