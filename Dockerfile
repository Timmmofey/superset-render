FROM apache/superset:latest

USER root

# Устанавливаем драйвер PostgreSQL и gevent
RUN . /app/.venv/bin/activate && \
    uv pip install psycopg2-binary gevent

# Создаем конфиг-файл прямо на лету, чтобы Superset гарантированно читал переменные
RUN echo 'import os' > /app/superset_config.py && \
    echo 'SQLALCHEMY_DATABASE_URI = os.getenv("SQLALCHEMY_DATABASE_URI")' >> /app/superset_config.py && \
    echo 'SECRET_KEY = os.getenv("SUPERSET_SECRET_KEY")' >> /app/superset_config.py && \
    echo 'WTF_CSRF_ENABLED = False' >> /app/superset_config.py

# Передаем путь к конфигу в переменные самого контейнера
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py
ENV PYTHONPATH=/app:$PYTHONPATH

USER superset

# Запуск. Важно: кавычки экранированы, убран баг с gunicorn
CMD ["/bin/sh", "-c", "\
. /app/.venv/bin/activate && \
superset db upgrade && \
superset fab create-admin --username \"$ADMIN_USER\" --firstname Admin --lastname User --email \"$ADMIN_EMAIL\" --password \"$ADMIN_PASSWORD\" || true && \
superset init && \
gunicorn -w 2 -k gevent --timeout 120 -b 0.0.0.0:$PORT 'superset.app:create_app()' \
"]
