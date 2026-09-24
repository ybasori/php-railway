#!/bin/sh
set -e

# Default to 8080 if Railway hasn't set PORT
PORT="${PORT:-8080}"

# Update Apache config to listen on Railway's assigned port
sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/:80>/:${PORT}>/" /etc/apache2/sites-available/000-default.conf

exec apache2-foreground
