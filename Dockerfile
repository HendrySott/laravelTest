# Stage 1: Build React frontend with Vite
FROM node:18 AS frontend
WORKDIR /app

# Copy only package files first for caching
COPY package*.json ./
RUN npm install

# Copy the rest of the project (for React build)
COPY . .
RUN npm run build

# Stage 2: Laravel backend with PHP-FPM
FROM php:8.2-fpm
WORKDIR /var/www

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy Laravel project
COPY . .

# Copy React build output into Laravel public folder
COPY --from=frontend /app/public ./public

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader
RUN php artisan config:cache && php artisan route:cache

EXPOSE 9000
CMD ["php-fpm"]
