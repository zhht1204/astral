# 使用官方PHP 7.4 FPM Alpine镜像作为基础镜像
FROM php:7.4-fpm-alpine

WORKDIR /app
COPY . /app/

## ENV start
# 环境变量相关
ENV APP_NAME=Astral
ENV APP_ENV=local
ENV APP_KEY=
ENV APP_DEBUG=true
ENV APP_LOG_LEVEL=debug
ENV APP_URL=http://astral.test

ENV DB_CONNECTION=mysql
ENV DB_HOST=127.0.0.1
ENV DB_PORT=3306
ENV DB_DATABASE=astral
ENV DB_USERNAME=root
ENV DB_PASSWORD=astral

ENV BROADCAST_DRIVER=log
ENV CACHE_DRIVER=file
ENV SESSION_DRIVER=file
ENV SESSION_LIFETIME=120
ENV QUEUE_DRIVER=sync

ENV GITHUB_CLIENT_ID=
ENV GITHUB_CLIENT_SECRET=
ENV GITHUB_CLIENT_CALLBACK_URL=

# 创建.env文件并写入环境变量
RUN touch .env
RUN chown www-data:www-data /app/.env
RUN chmod 744 .env
RUN echo "APP_NAME=${APP_NAME}" > .env
RUN echo "APP_ENV=${APP_ENV}" >> .env
RUN echo "APP_KEY=${APP_KEY}" >> .env
RUN echo "APP_DEBUG=${APP_DEBUG}" >> .env
RUN echo "APP_LOG_LEVEL=${APP_LOG_LEVEL}" >> .env
RUN echo "APP_URL=${APP_URL}" >> .env

RUN echo "DB_CONNECTION=${DB_CONNECTION}" >> .env
RUN echo "DB_HOST=${DB_HOST}" >> .env
RUN echo "DB_PORT=${DB_PORT}" >> .env
RUN echo "DB_DATABASE=${DB_DATABASE}" >> .env
RUN echo "DB_USERNAME=${DB_USERNAME}" >> .env
RUN echo "DB_PASSWORD=${DB_PASSWORD}" >> .env

RUN echo "BROADCAST_DRIVER=${BROADCAST_DRIVER}" >> .env
RUN echo "CACHE_DRIVER=${CACHE_DRIVER}" >> .env
RUN echo "SESSION_DRIVER=${SESSION_DRIVER}" >> .env
RUN echo "SESSION_LIFETIME=${SESSION_LIFETIME}" >> .env
RUN echo "QUEUE_DRIVER=${QUEUE_DRIVER}" >> .env

RUN echo "GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}" >> .env
RUN echo "GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}" >> .env
RUN echo "GITHUB_CLIENT_CALLBACK_URL=${GITHUB_CLIENT_CALLBACK_URL}" >> .env
## ENV end

# 安装node
RUN apk add --update nodejs npm
RUN npm install -g yarn
# 安装额外运行组件
RUN apk add --no-cache \
    curl \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-enable pdo_mysql
RUN apk add supervisor
RUN apk add nginx
RUN apk add redis
RUN apk add mariadb mariadb-client

# 复制supervisor及nginx配置文件
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/http.d/default.conf
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# 生成运行时文件夹并改变owner
RUN mkdir /var/log/supervisor
RUN mkdir -p /run/php \
    && chown -R www-data:www-data /var/www/html \
    && chown -R www-data:www-data /run/php

# Mariadb Server初始化
RUN mariadb-install-db
RUN chown -R mysql:mysql data
RUN echo "[mysqld]" >> /etc/my.cnf
RUN echo "skip-networking=0" >> /etc/my.cnf
RUN echo "skip-bind-address" >> /etc/my.cnf
RUN mkdir /run/mysqld
RUN chown mysql:mysql /run/mysqld
RUN sh ./init-mysql.sh ${DB_DATABASE} ${DB_USERNAME} ${DB_PASSWORD}

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 安装php依赖
RUN composer install
# 安装前端依赖
RUN yarn
RUN yarn dev

# 生成APP_KEY
RUN php artisan key:generate
RUN php artisan config:cache
# migrate数据库
RUN php artisan astral:migrate
# 生成运行时文件夹并改变owner
RUN chown -R www-data:www-data /app/public
RUN chown -R www-data:www-data /app/app
RUN chown -R www-data:www-data /app/config
RUN chown -R www-data:www-data /app/bootstrap
RUN chown -R www-data:www-data /app/vendor
RUN chown -R www-data:www-data /app/routes
RUN chown -R www-data:www-data /app/database
RUN chown -R www-data:www-data /app/storage

RUN supervisorctl shutdown
# 设置容器启动时执行的命令
CMD ["/usr/bin/supervisord"]

EXPOSE 80