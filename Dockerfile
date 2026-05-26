FROM apache/superset:latest

USER root

RUN . /app/.venv/bin/activate && \
    uv pip install psycopg2-binary gevent

USER superset

ENV PORT=10000
EXPOSE 10000

CMD ["/bin/sh","-c", "\
export SUPERSET__SQLALCHEMY_DATABASE_URI=$MY_DATABASE_URL && \
export PORT=10000 && \
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
