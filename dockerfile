# Stage 1: Build React frontend
FROM node:11.12.1 AS frontend
WORKDIR /app
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# Stage 2: Laravel backend
FROM php:8.2-fpm
WORKDIR /var/www

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy Laravel files
COPY backend/ .

# Copy React build into Laravel public folder
COPY --from=frontend /app/build ./public

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader
RUN php artisan config:cache && php artisan route:cache

EXPOSE 9000
CMD ["php-fpm"]
