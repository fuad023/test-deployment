#!/bin/bash
set -e

export DB_HOST=${DB_HOST:-$MYSQLHOST}
export DB_PORT=${DB_PORT:-$MYSQLPORT}
export DB_DATABASE=${DB_DATABASE:-$MYSQLDATABASE}
export DB_USERNAME=${DB_USERNAME:-$MYSQLUSER}
export DB_PASSWORD=${DB_PASSWORD:-$MYSQLPASSWORD}

which mysql
which mysqladmin
which mariadb
which mariadb-admin

mysql --version
mariadb --version

echo "DB_HOST=$DB_HOST"
echo "DB_USERNAME=$DB_USERNAME"
echo "DB_PASSWORD=$DB_PASSWORD"

echo "=== Laravel Docker Entrypoint ==="

# Wait for MySQL to be ready
echo "Waiting for MySQL connection..."
while ! mariadb-admin ping -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" --silent 2>/dev/null; do
    echo "Retrying MySQL connection in 2 seconds..."
    sleep 2
done
echo "✓ MySQL is ready!"

# Create database if it doesn't exist
echo "Ensuring database exists..."
mariadb -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$DB_DATABASE\`;"
echo "✓ Database ready!"

# Run schema files
if [ -d "/var/www/database/schema" ]; then
    echo "Executing schema files..."
    for file in /var/www/database/schema/*.sql; do
        if [ -f "$file" ]; then
            echo "  → Running: $(basename $file)"
            mariadb -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < "$file"
        fi
    done
    echo "✓ Schema initialization complete!"
fi

# Run seed files (data population)
if [ -d "/var/www/database/seed" ]; then
    echo "Executing seed files..."
    for file in /var/www/database/seed/*.sql; do
        if [ -f "$file" ]; then
            echo "  → Seeding: $(basename $file)"
            mariadb -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < "$file"
        fi
    done
    echo "✓ Database seeding complete!"
fi

# Run any init.sh script if present
if [ -f "/var/www/database/init.sh" ]; then
    echo "Running custom init.sh script..."
    bash /var/www/database/init.sh
    echo "✓ Custom initialization complete!"
fi

# Clear and optimize caches
echo "Clearing caches..."
php /var/www/artisan config:cache
php /var/www/artisan route:cache
php /var/www/artisan view:cache
echo "✓ Caches optimized!"

# Run migrations if needed (optional, comment out if you prefer manual control)
# echo "Running Laravel migrations..."
# php /var/www/artisan migrate --force --no-interaction
# echo "✓ Migrations complete!"

echo ""
echo "=== Starting Services ==="
echo "Starting nginx on port 8000..."
service nginx start

echo "Starting PHP-FPM..."
exec php-fpm
