FROM alpine:latest
RUN apk add --no-cache inotify-tools bash dos2unix
WORKDIR /watch
COPY rename_watcher.sh /usr/local/bin/rename_watcher.sh
RUN dos2unix /usr/local/bin/rename_watcher.sh && chmod +x /usr/local/bin/rename_watcher.sh
ENTRYPOINT ["/bin/bash", "/usr/local/bin/rename_watcher.sh"]
