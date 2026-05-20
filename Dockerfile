FROM apache/superset:latest

USER root

RUN pip install psycopg2-binary

USER superset

CMD ["/bin/sh","-c", "\
superset db upgrade && \
superset fab create-admin \
--username $ADMIN_USER \
--firstname Admin \
--lastname User \
--email $ADMIN_EMAIL \
--password $ADMIN_PASSWORD || true && \
superset init && \
gunicorn \
-w 2 \
-k sync \
--timeout 120 \
-b 0.0.0.0:$PORT \
'superset.app:create_app()'"]
