# ----------------------------
# 1) БАЗОВЫЙ ОБРАЗ
# ----------------------------
FROM judge0/compilers:1.4.0 AS base

# Явно работаем от root, чтобы все apt-get / gem / npm шли в привилегированном контексте
USER root

ENV JUDGE0_HOMEPAGE="https://judge0.com" \
    JUDGE0_SOURCE_CODE="https://github.com/judge0/judge0" \
    JUDGE0_MAINTAINER="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>" \
    PATH="/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH" \
    GEM_HOME="/opt/.gem/"

LABEL homepage=$JUDGE0_HOMEPAGE \
      source_code=$JUDGE0_SOURCE_CODE \
      maintainer=$JUDGE0_MAINTAINER

# Устанавливаем необходимые пакеты и инструменты от root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron \
      libpq-dev && \
    rm -rf /var/lib/apt/lists/* && \
    echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.1.4 && \
    npm install -g --unsafe-perm aglio@2.3.0

WORKDIR /api

# Ставим гемы
COPY Gemfile* ./
RUN bundle install --jobs 4

# Копируем cron и подключаем его
COPY cron /etc/cron.d
RUN chmod 0644 /etc/cron.d/* && \
    crontab /etc/cron.d/*

# Копируем весь исходный код
COPY . .

# Создаём системного пользователя и даём ему права на /api
RUN useradd -u 1000 -m -r judge0 && \
    chown -R judge0:judge0 /api

# После этого переключаемся на непользователя
USER judge0

ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]

# ----------------------------
# 2) DEVELOPMENT (debug-под)
# ----------------------------
FROM base AS development

# Чтобы можно было заходить внутрь и отлаживать
CMD ["sleep", "infinity"]
