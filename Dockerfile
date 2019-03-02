FROM php:7.2-fpm
MAINTAINER Javier Carpio <carpio701021@gmail.com>

RUN apt-get update && apt-get install -y \
  cron \
  git \
  gzip \
  libfreetype6-dev \
  libicu-dev \
  libjpeg62-turbo-dev \
  libmcrypt-dev \
  libpng-dev \
  libxslt1-dev \
  lsof \
  mysql-client \
  vim \
  zip

RUN docker-php-ext-configure \
  gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

RUN docker-php-ext-install \
  bcmath \
  gd \
  intl \
  mbstring \
  opcache \
  pdo_mysql \
  soap \
  xsl \
  zip

RUN pecl channel-update pecl.php.net \
  && pecl install xdebug \
  && docker-php-ext-enable xdebug \
  && sed -i -e 's/^zend_extension/\;zend_extension/g' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN apt-get install -y libssh2-1-dev \
  && pecl install ssh2-1.1.2 \
  && docker-php-ext-enable ssh2

RUN curl -sS https://getcomposer.org/installer | \
  php -- --install-dir=/usr/local/bin --filename=composer

RUN groupadd -g 1000 app \
 && useradd -g 1000 -u 1000 -d /var/www -s /bin/bash app

RUN apt-get install -y gnupg \
  && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && apt-get install -y nodejs \
  && mkdir /var/www/.config /var/www/.npm \
  && chown app:app /var/www/.config /var/www/.npm \
  && ln -s /var/www/html/node_modules/grunt/bin/grunt /usr/bin/grunt

RUN printf '* *\t* * *\tapp\t%s/usr/local/bin/php /var/www/html/update/cron.php\n' >> /etc/crontab
RUN printf '* *\t* * *\tapp\t%s/usr/local/bin/php /var/www/html/bin/magento cron:run\n' >> /etc/crontab
RUN printf '* *\t* * *\tapp\t%s/usr/local/bin/php /var/www/html/bin/magento setup:cron:run\n#\n' >> /etc/crontab

COPY images/php/7.2/conf/www.conf /usr/local/etc/php-fpm.d/
COPY images/php/7.2/conf/php.ini /usr/local/etc/php/
COPY images/php/7.2/conf/php-fpm.conf /usr/local/etc/
COPY images/php/7.2/bin/cronstart /usr/local/bin/

RUN mkdir /sock
RUN chown -R app:app /usr/local/etc/php/conf.d /sock

COPY src/./ /var/www/html/

USER root
RUN chown -R app:app /var/www
RUN chmod +x /var/www/html/bin/magento
USER app:app 
ENV BASE_URL magento
ENV DB_HOST magento
ENV DB_NAME magento
ENV DB_USER magento
ENV DB_PASSWORD magento
ENV ADMIN_FIRSTNAME magento
ENV ADMIN_LASTNAME magento
ENV ADMIN_EMAIL magento
ENV ADMIN_USER magento
ENV ADMIN_PASSWORD magento
ENV RABBITMQ_HOSTNAME magento
ENV RABBITMQ_PORT magento
ENV RABBITMQ_USER magento
ENV RABBITMQ_PASSWORD magento
ENV RABBITMQ_VIRTUALHOSTS magento

RUN echo "Forcing reinstall of composer deps to ensure perms & reqs..."
RUN composer install
RUN echo
RUN echo


USER root
RUN mkdir /var/www/html_tmp 
#RUN chown -R app:app /var/www
RUN cp -r /var/www/html/* /var/www/html_tmp/.

USER app:app
COPY images/php/7.2/bin/install_magento.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install_magento.sh
VOLUME /var/www
WORKDIR /var/www/html

RUN echo "****************"

ENTRYPOINT ["/usr/local/bin/install_magento.sh"]


EXPOSE 9001