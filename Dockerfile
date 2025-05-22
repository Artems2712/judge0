# 1) Собственно API-сервис
FROM judge0/compilers:1.4.0 AS production

# Явно работаем под root при сборке
USER root

# Устанавливаем только libpq-dev
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Настраиваем RubyGems и Bundler
ENV PATH="/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH" \
    GEM_HOME="/opt/.gem/"
RUN echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.1.4

# Порт Rails-сервера
EXPOSE 2358

# Рабочая директория
WORKDIR /api

# Копируем Gemfile и ставим зависимости (слой кешируется)
COPY Gemfile* ./
RUN bundle install --without development test

# Если у вас есть cron-задачи (TTL чистильщик), можно вернуть эти строки:
# COPY cron /etc/cron.d
# RUN crontab /etc/cron.d/cron

# Копируем всё остальное
COPY . .

# Гарантируем, что tmp/ доступен для записи
RUN mkdir -p tmp && chown -R judge0:judge0 tmp

# Точка входа и команда запуска
ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]

# Переключаемся на непривилегированного юзера
USER judge0

# 2) Стадия для разработки (спим вечно)
FROM production AS development
CMD ["sleep", "infinity"]
