FROM cosmik/web:master

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 68576280 \
        && echo "deb https://deb.nodesource.com/node_6.x xenial main" | tee /etc/apt/sources.list.d/nodesource.list \
        && apt-get update -yq \
        && apt-get install --no-install-recommends -yq \
            nodejs \
        && rm -rf /var/lib/apt/lists/* \
        && npm config set bin-links false \
        && cd /project \
        && curl https://getcomposer.org/installer | /bin/bash -c "source /root/.phpbrew/bashrc \
            && php -- --install-dir=/usr/local/bin \
            && composer.phar global require hirak/prestissimo"

COPY ./composer.json /project/composer.json

COPY ./composer.lock /project/composer.lock

# add github fingerprint - see: https://github.com/composer/composer/issues/3572
RUN mkdir ~/.ssh \
    && ssh-keyscan -H github.com >> ~/.ssh/known_hosts \
    && /bin/bash -c "source /root/.phpbrew/bashrc && composer.phar install --dev --no-scripts --no-autoloader"

COPY ./ /project

COPY ./docker/images/web_live/project.conf /etc/nginx/snippets/project.conf

RUN /bin/bash -c "source /root/.phpbrew/bashrc \
        && composer.phar dump-autoload \
        && ./vendor/bin/phpunit --bootstrap vendor/autoload.php --testdox --stderr tests \
        && composer.phar install --no-dev --optimize-autoloader \
        ; exit 0"

RUN chown -R www-data:www-data /project

# All affected files from the last line are part of the image layer, so the project have to pushed twice every time.
