FROM cosmik/web:master

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 68576280 \
        && echo "deb https://deb.nodesource.com/node_6.x xenial main" | tee /etc/apt/sources.list.d/nodesource.list \
        && apt-get update -yq \
        && apt-get install --no-install-recommends -yq \
            curl \
            git \
            ssh \
            nodejs \
        && rm -rf /var/lib/apt/lists/* \
        && npm config set bin-links false \
        && cd /project \
        && curl https://getcomposer.org/installer | /bin/bash -c "source /root/.phpbrew/bashrc && php -- --install-dir=/usr/local/bin" \
        && /bin/bash -c "source /root/.phpbrew/bashrc && composer.phar global require hirak/prestissimo"

COPY ./composer.json /project/composer.json

COPY ./composer.lock /project/composer.lock

COPY ./auth.json /project/auth.json

# add github fingerprint - see: https://github.com/composer/composer/issues/3572
RUN mkdir ~/.ssh \
    && ssh-keyscan -H github.com >> ~/.ssh/known_hosts \
    && /bin/bash -c "source /root/.phpbrew/bashrc && composer.phar install --no-scripts --no-autoloader"

COPY ./ /project

COPY ./docker/images/web_live/project.conf /etc/nginx/snippets/project.conf

RUN /bin/bash -c "source /root/.phpbrew/bashrc \
        && composer.phar dump-autoload --optimize \
        && composer.phar run-script post-install-cmd \
    && chown -R www-data:www-data /project

# All affected files from the last line are part of the image layer, so the project have to pushed twice every time.
