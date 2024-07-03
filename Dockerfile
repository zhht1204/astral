# 使用官方PHP 7.4 FPM Alpine镜像作为基础镜像
FROM php:7.4-fpm-alpine

WORKDIR /app

COPY . /app/

RUN apk add --update nodejs npm

RUN npm install -g yarn

RUN yarn

RUN apk add --no-cache \
    curl \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-enable pdo_mysql

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer install

# 设置容器启动时执行的命令
RUN yarn dev

CMD ["php", "artisan", "serve"]

EXPOSE 8000
