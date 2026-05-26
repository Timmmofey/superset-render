FROM apache/superset:latest

USER root

# Системные зависимости для PostgreSQL
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Устанавливаем psycopg2-binary напрямую в venv Superset (без activate)
RUN /app/.venv/bin/pip install psycopg2-binary

# Создаем директорию для скриптов
RUN mkdir -p /app/docker

# Встраиваем скрипт инициализации с проверкой установки psycopg2
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    '' \
    '# Активируем виртуальное окружение' \
    '. /app/.venv/bin/activate' \
    '' \
    '# Диагностика: проверяем, что psycopg2 установлен' \
    'echo "=== Checking installed packages ==="' \
    'pip list | grep psycopg2 || { echo "ERROR: psycopg2 not found!"; exit 1; }' \
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

# Копируем конфигурацию
COPY superset_config.py /app/

# Указываем путь к конфигурации
ENV SUPERSET_CONFIG_PATH /app/superset_config.py

# Возвращаемся к непривилегированному пользователю
USER superset

ENTRYPOINT ["/app/docker/docker-entrypoint-init.sh"]
