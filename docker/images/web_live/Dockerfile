FROM cosmik/web:master

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
        && ./vendor/bin/phpunit --colors=always --bootstrap vendor/autoload.php --testdox tests \
        && composer.phar install --no-dev --optimize-autoloader"

RUN chown -R www-data:www-data /project

# All affected files from the last line are part of the image layer, so the project have to pushed twice every time.
