# Dockerfile
FROM php:8.1-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    nginx \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files first
COPY composer.json composer.lock ./

# Install composer dependencies
RUN composer install --no-dev --no-scripts --no-autoloader

# Copy the rest of the application
COPY . .

# Generate optimized autoload files
RUN composer dump-autoload --optimize

# Copy deployment script and make it executable
RUN chmod +x laravel-deploy.sh

# Copy nginx configuration
COPY nginx.conf /etc/nginx/sites-available/default

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Create required directories if they don't exist
RUN mkdir -p /var/log/supervisor \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/run

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]