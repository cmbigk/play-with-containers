FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y rabbitmq-server gosu && \
    rm -rf /var/lib/apt/lists/*
    
# Pre-enable management plugin
RUN rabbitmq-plugins enable rabbitmq_management

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5672 15672
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
