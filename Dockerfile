FROM apache/superset:latest

USER root

RUN . /app/.venv/bin/activate && \
    uv pip install psycopg2-binary gevent

# Генерируем конфиг с чистым и безопасным парсингом строки подключения
RUN echo 'import os' > /app/superset_config.py && \
    echo 'raw_url = os.getenv("MY_DATABASE_URL", "")' >> /app/superset_config.py && \
    echo 'if "://supabase.com" in raw_url and "5432" not in raw_url and not raw_url.endswith(":5432"):' >> /app/superset_config.py && \
    echo '    if "?" in raw_url:' >> /app/superset_config.py && \
    echo '        parts = raw_url.split("?")' >> /app/superset_config.py && \
    echo '        parts[0] = parts[0].replace("://supabase.com", "://supabase.com:5432")' >> /app/superset_config.py && \
    echo '        raw_url = "?".join(parts)' >> /app/superset_config.py && \
    echo '    else:' >> /app/superset_config.py && \
    echo '        raw_url = raw_url.replace("://supabase.com", "://supabase.com:5432")' >> /app/superset_config.py && \
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
