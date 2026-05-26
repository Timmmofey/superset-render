# Dockerfile для Apache Superset с поддержкой PostgreSQL и Supabase
# Скрипт инициализации встроен прямо в Dockerfile

USER root
FROM apache/superset:latest

# Устанавливаем драйвер PostgreSQL
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/* && \
    . /app/.venv/bin/activate && pip install psycopg2-binary

# Создаем директорию для скриптов
RUN mkdir -p /app/docker

# ВСТРАИВАЕМ СКРИПТ ИНИЦИАЛИЗАЦИИ прямо внутри Dockerfile
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    '. /app/.venv/bin/activate' \
    '' \
    '# Обновление метабазы' \
    'superset db upgrade' \
    'superset init' \
    '' \
    '# Создание администратора, если заданы переменные' \
    'if [[ -n "${SUPERSET_ADMIN_USERNAME}" ]] && [[ -n "${SUPERSET_ADMIN_PASSWORD}" ]]; then' \
    '    echo "Creating/updating admin user ${SUPERSET_ADMIN_USERNAME}..."' \
    '    superset fab create-admin \' \
    '        --username "${SUPERSET_ADMIN_USERNAME}" \' \
    '        --firstname "${SUPERSET_ADMIN_FIRSTNAME:-Superset}" \' \
    '        --lastname "${SUPERSET_ADMIN_LASTNAME:-Admin}" \' \
    '        --email "${SUPERSET_ADMIN_EMAIL:-admin@superset.com}" \' \
    '        --password "${SUPERSET_ADMIN_PASSWORD}" || true' \
    'fi' \
    '' \
    '# Запуск gunicorn' \
    'exec gunicorn \' \
    '    --bind "0.0.0.0:${SUPERSET_PORT:-8088}" \' \
    '    --access-logfile "-" \' \
    '    --error-logfile "-" \' \
    '    --workers ${SUPERSET_GUNICORN_WORKERS:-2} \' \
    '    --worker-class ${SUPERSET_GUNICORN_WORKER_CLASS:-gthread} \' \
    '    --threads ${SUPERSET_GUNICORN_THREADS:-20} \' \
    '    --timeout ${SUPERSET_GUNICORN_TIMEOUT:-60} \' \
    '    "superset.app:create_app()"' \
    > /app/docker/docker-entrypoint-init.sh && chmod +x /app/docker/docker-entrypoint-init.sh

# Копируем конфигурационный файл Superset (должен быть в той же директории, что и Dockerfile)
COPY superset_config.py /app/

# Указываем путь к конфигурации
ENV SUPERSET_CONFIG_PATH /app/superset_config.py

USER superset

ENTRYPOINT ["/app/docker/docker-entrypoint-init.sh"]
