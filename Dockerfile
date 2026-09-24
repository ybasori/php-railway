FROM php:8.3-apache

# Copy source code
COPY . /var/www/html/

# Fix permissions if needed
RUN chown -R www-data:www-data /var/www/html

# Railway injects $PORT; update Apache to listen on $PORT
RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

EXPOSE ${PORT}
