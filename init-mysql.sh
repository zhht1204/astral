nohup supervisord -c /app/supervisord.conf &
sleep 5s
mysql -u root -e "CREATE DATABASE $1;"
mysql -u root -e "CREATE USER '$2'@'localhost' IDENTIFIED BY '$3';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* to '$2'@'localhost' IDENTIFIED BY '$3';"
mysql -u root -e "flush privileges;"
mysqladmin shutdown
supervisorctl start mariadbd
