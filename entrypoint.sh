#!/bin/sh
set -e

# --- Runtime safety net: force prefork MPM every boot ---
rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_event.conf
rm -f /etc/apache2/mods-enabled/mpm_worker.load /etc/apache2/mods-enabled/mpm_worker.conf
ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load
ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf

# --- Configure port (idempotent — safe to run on every restart) ---
PORT="${PORT:-8080}"
sed -i -E "s/^Listen [0-9]+/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i -E "s/:[0-9]+>/:${PORT}>/" /etc/apache2/sites-available/000-default.conf

# --- Laravel bootstrap steps ---
php artisan config:cache
php artisan route:cache
php artisan migrate --force

# --- Storage symlink (only if missing, avoids noisy "already exists" error) ---
if [ ! -L /var/www/html/public/storage ]; then
  php artisan storage:link
fi

exec apache2-foreground