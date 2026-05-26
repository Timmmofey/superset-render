FROM apache/superset:latest

USER root

RUN . /app/.venv/bin/activate && \
    uv pip install psycopg2-binary gevent

# Генерируем простой конфиг. Читаем строку из кастомного имени переменной
RUN echo 'import os' > /app/superset_config.py && \
    echo 'SQLALCHEMY_DATABASE_URI = os.getenv("SUPABASE_METADATA_URL")' >> /app/superset_config.py && \
    echo 'SECRET_KEY = os.getenv("SUPERSET_SECRET_KEY")' >> /app/superset_config.py && \
    echo 'WTF_CSRF_ENABLED = False' >> /app/superset_config.py

ENV SUPERSET_CONFIG_PATH=/app/superset_config.py
ENV PYTHONPATH=/app:$PYTHONPATH

USER superset

# EXPOSE сообщает Render, какой порт слушать, без использования конфликтующих env
EXPOSE 10000

CMD ["/bin/sh","-c", "\
. /app/.venv/bin/activate && \
superset db upgrade && \
superset fab create-admin \
--username \"$ADMIN_USER\" \
--firstname Admin \
--lastname User \
--email \"$ADMIN_EMAIL\" \
--password \"$ADMIN_PASSWORD\" || true && \
superset init && \
unset PORT && \
gunicorn \
-w 2 \
-k gevent \
--timeout 120 \
-b 0.0.0.0:10000 \
'superset.app:create_app()'"]
