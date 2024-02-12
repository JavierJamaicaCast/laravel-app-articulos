# Utilizamos una imagen oficial de PHP con Apache
FROM php:8.3-apache

# Establecemos el directorio de trabajo dentro del contenedor
WORKDIR /var/www/html

# Instalar Node.js 18 y NPM
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Actualizamos los paquetes del sistema e instalamos las dependencias necesarias
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
    && docker-php-ext-install gd pdo pdo_mysql zip \
    && a2enmod rewrite



# Copiamos los archivos de la aplicación Laravel al directorio de trabajo
COPY . .

# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instalamos las dependencias de PHP con Composer
RUN composer install --no-interaction --no-dev --prefer-dist --optimize-autoloader

# Cambiamos los permisos de los directorios para que el servidor web pueda acceder a ellos
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Instalamos las dependencias de Node.js y compilamos los assets
RUN npm install \
    && npm run build

# Configuramos Apache para que el DocumentRoot apunte al directorio public de Laravel
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Exponemos el puerto 80 para que la aplicación Laravel sea accesible desde fuera del contenedor
EXPOSE 80

# Comando para iniciar el servidor Apache en primer plano cuando se inicie el contenedor
CMD ["apache2-foreground"]
