# Исправленный Dockerfile для Apache Superset + PostgreSQL/Supabase

FROM apache/superset:latest

USER root

# Установка системных зависимостей для PostgreSQL
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Устанавливаем psycopg2-binary в виртуальное окружение Superset (КЛЮЧЕВОЙ МОМЕНТ)
RUN . /app/.venv/bin/activate && pip install psycopg2-binary

# Создаем директорию для скриптов инициализации
RUN mkdir -p /app/docker

# Встраиваем скрипт инициализации
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    '. /app/.venv/bin/activate' \
    '' \
    '# Загрузка конфигурации' \
    'export SUPERSET_CONFIG_PATH=/app/superset_config.py' \
    '' \
    '# Обновление метабазы' \
    'superset db upgrade' \
    'superset init' \
    '' \
    '# Создание администратора, если заданы переменные' \
    'if [[ -n "${SUPERSET_ADMIN_USERNAME}" ]] && [[ -n "${SUPERSET_ADMIN_PASSWORD}" ]]; then' \
    '    echo "Creating admin user ${SUPERSET_ADMIN_USERNAME}..."' \
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

# Копируем конфигурационный файл
COPY superset_config.py /app/

# Указываем путь к конфигурации (дублируем на всякий случай)
ENV SUPERSET_CONFIG_PATH /app/superset_config.py

# Возвращаемся к непривилегированному пользователю
USER superset

ENTRYPOINT ["/app/docker/docker-entrypoint-init.sh"]
