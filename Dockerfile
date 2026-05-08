FROM php:8.3-fpm

WORKDIR /var/www/html

# Install system packages
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    git \
    curl \
    unzip \
    zip \
    nodejs \
    npm \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev

# PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy app
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader

# Install node packages
RUN npm install

# Build Vite assets
RUN npm run build

# Laravel cache
RUN php artisan config:clear || true
RUN php artisan config:cache || true
RUN php artisan route:cache || true
RUN php artisan view:cache || true

# Permissions
RUN chown -R www-data:www-data storage bootstrap/cache

# Nginx config
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD sh -c "php-fpm -D && nginx -g 'daemon off;'"