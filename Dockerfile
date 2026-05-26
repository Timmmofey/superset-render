FROM apache/superset:latest

USER root

# Системные зависимости (опционально, но для надёжности)
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Устанавливаем psycopg2-binary в виртуальное окружение Superset (путь /app/.venv)
RUN /app/.venv/bin/pip install psycopg2-binary

# Возвращаемся к непривилегированному пользователю
USER superset

# Копируем конфигурационный файл (он должен быть в репозитории)
COPY superset_config.py /app/

ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

CMD /bin/bash -c "\
    superset db upgrade && \
    superset fab create-admin \
        --username \"${SUPERSET_ADMIN_USERNAME:-admin}\" \
        --firstname \"${SUPERSET_ADMIN_FIRSTNAME:-Admin}\" \
        --lastname \"${SUPERSET_ADMIN_LASTNAME:-User}\" \
        --email \"${SUPERSET_ADMIN_EMAIL:-admin@example.com}\" \
        --password \"${SUPERSET_ADMIN_PASSWORD:-admin}\" || true && \
    superset init && \
    gunicorn \
        --workers ${SUPERSET_GUNICORN_WORKERS:-2} \
        --worker-class sync \
        --timeout ${SUPERSET_GUNICORN_TIMEOUT:-120} \
        --bind 0.0.0.0:${PORT:-8088} \
        'superset.app:create_app()'"
        
