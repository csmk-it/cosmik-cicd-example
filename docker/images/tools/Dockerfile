FROM cosmik/tools:master

COPY ./docker/images/tools/bash_history /tmp
RUN cat /tmp/bash_history >> /root/.bash_history && rm /tmp/bash_history
