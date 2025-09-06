FROM debian:bullseye
ARG CONFIG_DIR
RUN apt-get update && apt-get install -y baresip
COPY ${CONFIG_DIR}/ /etc/baresip/
CMD ["baresip", "-f", "/etc/baresip"]
