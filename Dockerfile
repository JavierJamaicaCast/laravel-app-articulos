# Utilizamos una imagen oficial de PHP con Apache, ideal para aplicaciones Laravel
FROM php:8.3-apache

# Establecemos el directorio de trabajo en el contenedor. Aquí es donde estará nuestra aplicación
WORKDIR /var/www/html

# Instalamos las dependencias del sistema requeridas para Laravel y las extensiones de PHP
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql zip

# Habilitamos el módulo rewrite de Apache, necesario para el enrutamiento de Laravel
RUN a2enmod rewrite

# Copiamos solo el archivo composer.json y composer.lock primero para aprovechar la caché de Docker
COPY composer.json composer.lock ./

# Instalamos Composer en el contenedor
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instalamos las dependencias de PHP con Composer, sin scripts para evitar problemas de permisos
RUN composer install --no-scripts --no-autoloader --no-dev --prefer-dist

# Ahora copiamos el resto del código de la aplicación Laravel
COPY . .

# Finalizamos la instalación de Composer, generando el autoload de clases
RUN composer dump-autoload --optimize

# Cambiamos los permisos de los directorios necesarios para Laravel
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Opcionalmente, podrías querer ejecutar migraciones o comandos de artisan aquí
# Pero es recomendable hacerlo manualmente o como parte de tu CI/CD para tener más control
# Aquí configuramos Apache para que el DocumentRoot apunte al directorio public de Laravel
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf
# Exponemos el puerto 80
EXPOSE 80

# Usamos el comando por defecto de Apache para mantener el contenedor ejecutándose
CMD ["apache2-foreground"]
