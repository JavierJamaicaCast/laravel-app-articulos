#!/bin/bash
php artisan config:clear
# Espera a que la base de datos esté lista (opcional)
while ! nc -z javierjamaica.synology.me 3307; do
    sleep 5
done

# Verificar si se necesita ejecutar migraciones (puedes verificar si existe una tabla específica, etc.)
if [ -z "$(php artisan migrate:status | grep 'No migrations found')" ]; then
    echo "Ejecutando migraciones de la base de datos..."
    php artisan migrate --force
    echo "Migraciones completadas."
fi

# Continuar con la ejecución normal del contenedor
apache2-foreground
