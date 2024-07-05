nohup supervisord -c /app/supervisord.conf &
sleep 5
supervisorctl start mariadbd
mysql -u root -e "CREATE DATABASE $1;"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* to '$2'@'%' IDENTIFIED BY '$3';"
