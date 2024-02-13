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

# Instalar Composer globalmente
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instalar dependencias de PHP con Composer
RUN composer install --no-interaction --no-dev --prefer-dist --optimize-autoloader

# Generar clave de aplicación Laravel (opcional aquí, ver nota abajo)
# RUN php artisan key:generate --no-interaction

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

# Configurar DocumentRoot de Apache para apuntar al directorio public de Laravel
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Exponer el puerto 80
EXPOSE 80

# Comando para iniciar Apache en primer plano
CMD ["apache2-foreground"]
