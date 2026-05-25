FROM apache/superset:latest

USER root

RUN . /app/.venv/bin/activate && \
    uv pip install psycopg2-binary

USER superset

CMD ["/bin/sh", "-c", "\
superset db upgrade && \
superset fab create-admin \
--username ${ADMIN_USER:-admin} \
--firstname Admin \
--lastname User \
--email ${ADMIN_EMAIL:-admin@example.com} \
--password ${ADMIN_PASSWORD:-admin123} || true && \
superset init && \
gunicorn \
-w 2 \
-k gevent \
--worker-connections 1000 \
--timeout 120 \
-b 0.0.0.0:${PORT:-10000} \
'superset.app:create_app()' \
"]
