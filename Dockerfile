# Utilizamos una imagen oficial de PHP con Apache
FROM php:8.3-apache

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /var/www/html

# Instalar Node.js 18 y NPM
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    npm install -g npm@latest

# Instalar dependencias del sistema necesarias para Laravel y extensiones PHP
RUN apt-get install -y libpng-dev libjpeg-dev libfreetype6-dev libzip-dev zip unzip git curl && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd pdo pdo_mysql zip && \
    a2enmod rewrite

# Copiar el código fuente de la aplicación Laravel y los archivos de configuración al directorio de trabajo
COPY . .

# Añadir archivo de configuración personalizado para Apache
COPY laravel.conf /etc/apache2/sites-available/laravel.conf

# Habilitar el sitio de Laravel y deshabilitar el predeterminado
RUN a2ensite laravel.conf && a2dissite 000-default.conf

# Instalar Composer globalmente
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instalar dependencias de PHP con Composer
RUN composer install --no-interaction --no-dev --prefer-dist --optimize-autoloader

# Caché de configuración y rutas de Laravel
RUN php artisan config:cache && \
    php artisan route:cache

# Crear enlace simbólico para el directorio storage
RUN php artisan storage:link

# Instalar dependencias de Node.js y compilar assets (si es necesario)
RUN npm install && \
    npm run build

# Ajustar permisos de los directorios para el servidor web
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 775 storage bootstrap/cache

# Exponer el puerto 80
EXPOSE 80
# Copiar el script de entrada al contenedor
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# Establecer el script de entrada como el punto de entrada del contenedor
ENTRYPOINT ["entrypoint.sh"]

CMD ["apache2-foreground"]
