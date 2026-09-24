#!/bin/sh
set -e

# MPM fix, kept as a runtime safety net
rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_event.conf
rm -f /etc/apache2/mods-enabled/mpm_worker.load /etc/apache2/mods-enabled/mpm_worker.conf
ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load
ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf

PORT="${PORT:-8080}"
sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/:80>/:${PORT}>/" /etc/apache2/sites-available/000-default.conf

# Cache config for performance (safe to skip if you want config changes without rebuild)
php artisan config:cache
php artisan route:cache

# Run migrations automatically on deploy (optional — remove if you prefer manual control)
php artisan migrate --force

php artisan storage:link

exec apache2-foreground

