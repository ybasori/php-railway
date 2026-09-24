FROM php:8.2-apache

# Copy app files into Apache's web root
COPY . /var/www/html/

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

# Railway provides a PORT env var; make Apache listen on it
RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's/80/${PORT}/g' /etc/apache2/ports.conf

# Expose default port (Railway overrides at runtime via $PORT)
EXPOSE 8080

# Substitute $PORT at container startup, then launch Apache
CMD sh -c "apache2-foreground"
