# ----------------------------
# 1) БАЗОВЫЙ ОБРАЗ
# ----------------------------
FROM judge0/compilers:1.4.0 AS base

ENV JUDGE0_HOMEPAGE="https://judge0.com" \
    JUDGE0_SOURCE_CODE="https://github.com/judge0/judge0" \
    JUDGE0_MAINTAINER="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>" \
    PATH="/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH" \
    GEM_HOME="/opt/.gem/"

LABEL homepage=$JUDGE0_HOMEPAGE \
      source_code=$JUDGE0_SOURCE_CODE \
      maintainer=$JUDGE0_MAINTAINER

# Устанавливаем только нужные пакеты (cron, libpq-dev для pg, aglio)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron \
      libpq-dev && \
    rm -rf /var/lib/apt/lists/* && \
    echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.1.4 && \
    npm install -g --unsafe-perm aglio@2.3.0

WORKDIR /api

# Копируем Gemfile и собираем гемы
COPY Gemfile* ./
RUN bundle install --jobs 4

# Копируем расписание cron и устанавливаем его
COPY cron /etc/cron.d
RUN chmod 0644 /etc/cron.d/* && \
    crontab /etc/cron.d/*

# Копируем всю логику приложения
COPY . .

# Создаём системного пользователя judge0 и даём ему права на /api
RUN useradd -u 1000 -m -r judge0 && \
    chown -R judge0:judge0 /api

# Переключаемся на непользователя
USER judge0

# Точка входа и команда по-умолчанию
ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]

# ----------------------------
# 2) DEVELOPMENT (debug-под)
# ----------------------------
FROM base AS development

# Для разработки просто «заснули», чтобы можно было «exec» внутрь
CMD ["sleep", "infinity"]
