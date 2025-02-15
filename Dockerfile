FROM runtimeverificationinc/kframework-k:ubuntu-noble-7.1.212
RUN apt-get update && apt-get install -y vim gdb
RUN mkdir -p /root/.config/gdb && \
echo "set auto-load safe-path /" >> /root/.config/gdb/gdbinit