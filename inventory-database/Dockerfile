FROM alpine:3.19

RUN apk add --no-cache postgresql postgresql-contrib su-exec

RUN mkdir -p /var/run/postgresql /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/run/postgresql /var/lib/postgresql

ENV PGDATA=/var/lib/postgresql/data

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5432
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
