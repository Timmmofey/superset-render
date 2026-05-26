FROM apache/superset:latest

USER root

# Системные зависимости для PostgreSQL (опционально, но полезно)
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Устанавливаем pip в виртуальное окружение Superset
RUN /app/.venv/bin/python -m ensurepip --upgrade

# Теперь ставим psycopg2-binary через только что установленный pip
RUN /app/.venv/bin/python -m pip install psycopg2-binary

# Возвращаемся к непривилегированному пользователю
USER superset

# Копируем конфигурационный файл (он должен быть в корне репозитория)
COPY superset_config.py /app/

ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

# Запуск: инициализация БД и сервер
CMD /bin/bash -c "\
    superset db upgrade && \
    superset fab create-admin \
        --username \"${SUPERSET_ADMIN_USERNAME:-admin}\" \
        --firstname Admin \
        --lastname User \
        --email \"${SUPERSET_ADMIN_EMAIL:-admin@example.com}\" \
        --password \"${SUPERSET_ADMIN_PASSWORD:-admin}\" || true && \
    superset init && \
    gunicorn \
        -w 2 \
        -k sync \
        --timeout 120 \
        -b 0.0.0.0:${PORT:-8088} \
        'superset.app:create_app()'"
