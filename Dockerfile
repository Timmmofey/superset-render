FROM apache/superset:latest

USER root

RUN . /app/.venv/bin/activate && \
    uv pip install psycopg2-binary gevent

# Генерируем надежный конфиг, который жестко фиксирует параметры подключения
RUN echo 'import os' > /app/superset_config.py && \
    echo 'from make_url import make_url' >> /app/superset_config.py && \
    echo 'raw_url = os.getenv("MY_DATABASE_URL", "")' >> /app/superset_config.py && \
    echo 'if "://supabase.com" in raw_url and not "5432" in raw_url:' >> /app/superset_config.py && \
    echo '    raw_url = raw_url.replace("://supabase.com", "://supabase.com:5432")' >> /app/superset_config.py && \
    echo 'SQLALCHEMY_DATABASE_URI = raw_url' >> /app/superset_config.py && \
    echo 'SECRET_KEY = os.getenv("SUPERSET_SECRET_KEY")' >> /app/superset_config.py && \
    echo 'WTF_CSRF_ENABLED = False' >> /app/superset_config.py

ENV SUPERSET_CONFIG_PATH=/app/superset_config.py
ENV PYTHONPATH=/app:$PYTHONPATH

USER superset

ENV PORT=10000
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
gunicorn \
-w 2 \
-k gevent \
--timeout 120 \
-b 0.0.0.0:10000 \
'superset.app:create_app()'"]
