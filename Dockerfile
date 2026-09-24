FROM php:8.4-apache

# --- Fix Apache MPM conflict (force prefork, required for mod_php) ---
RUN rm -f /etc/apache2/mods-enabled/mpm_event.load \
          /etc/apache2/mods-enabled/mpm_event.conf \
          /etc/apache2/mods-enabled/mpm_worker.load \
          /etc/apache2/mods-enabled/mpm_worker.conf \
    && ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load \
    && ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf

# --- System dependencies, PHP extensions, Node.js for asset builds ---
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libpng-dev libonig-dev libxml2-dev libpq-dev \
    nodejs npm \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Enable rewrite (needed for Laravel's pretty URLs) ---
RUN a2enmod rewrite

# --- Point Apache's DocumentRoot to Laravel's public/ folder ---
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

# --- Allow .htaccess overrides ---
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# --- Suppress "could not reliably determine server's FQDN" warning ---
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# --- Install Composer ---
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

# --- Install PHP dependencies ---
RUN composer install --no-dev --optimize-autoloader

# --- Build frontend assets (Vite/Breeze) ---
RUN npm install && npm run build

# --- Ensure required storage subdirectories exist (empty dirs aren't in git) ---
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache

# --- Set ownership/permissions ---
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]