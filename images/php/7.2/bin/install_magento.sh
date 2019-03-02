#!/bin/bash
cp -rf /var/www/html_tmp/* /var/www/html/.
cd /var/www/html
echo ******************************************************
echo "Installing magento"
chmod u+x /var/www/html/bin/magento
php /var/www/html/bin/magento setup:install \
  --db-host=$DB_HOST \
  --db-name=$DB_NAME \
  --db-user=$DB_USER \
  --db-password=$DB_PASSWORD \
  --base-url=https://$BASE_URL/ \
  --admin-firstname=$ADMIN_FIRSTNAME \
  --admin-lastname=$ADMIN_LASTNAME \
  --admin-email=$ADMIN_EMAIL \
  --admin-user=$ADMIN_USER \
  --admin-password=$ADMIN_PASSWORD \
  --language=en_US \
  --currency=USD \
  --timezone=America/New_York \
  --use-rewrites=1 \
  --amqp-host="$RABBITMQ_HOSTNAME" \
  --amqp-port="$RABBITMQ_PORT" \
  --amqp-user="$RABBITMQ_USER" \
  --amqp-password="$RABBITMQ_PASSWORD" \
  --amqp-virtualhost=$RABBITMQ_VIRTUALHOSTS
echo 
echo ******************************************************


echo "Turning on developer mode.."
php /var/www/html/bin/magento deploy:mode:set developer

php /var/www/html/bin/magento indexer:reindex

echo "Forcing deploy of static content to speed up initial requests..."
php /var/www/html/bin/magento setup:static-content:deploy -f 

echo "Enabling redis for cache..."
php /var/www/html/bin/magento setup:config:set --no-interaction --cache-backend=redis --cache-backend-redis-server=localhost --cache-backend-redis-db=0

echo "Enabling Redis for session..."
php /var/www/html/bin/magento setup:config:set --no-interaction --session-save=redis --session-save-redis-host=localhost --session-save-redis-log-level=4 --session-save-redis-db=1

echo "Listing message queue consumers (RabbitMQ)"
php /var/www/html/bin/magento queue:consumers:list
echo "You can mannualy with the command: "
echo "bin/magento queue:consumers:start <consumer> &"


echo "Clearing the cache for good measure..."
php /var/www/html/bin/magento cache:flush

#echo "Copying files from container to host after install..."
#bin/copyfromcontainer app
#bin/copyfromcontainer vendor

#echo "Restarting containers with host bind mounts for dev..."
#bin/restart

echo "Docker development environment setup complete."
echo "You may now access your Magento instance at https://${BASE_URL}/"
echo **** ls -la /var/www
ls -la /var/www
tail -f  /etc/hosts
