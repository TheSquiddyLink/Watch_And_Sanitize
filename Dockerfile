FROM alpine:latest
RUN apk add --no-cache inotify-tools bash
WORKDIR /watch
COPY rename_watcher.sh /usr/local/bin/rename_watcher.sh
RUN chmod +x /usr/local/bin/rename_watcher.sh
ENTRYPOINT ["/usr/local/bin/rename_watcher.sh"]
