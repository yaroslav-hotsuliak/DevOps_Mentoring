#! /bin/bash
cd /var/www/html/
sed -i "s/'database_name_here'/'${aws_db_instance.my_db.name}'/g" wp-config.php
sed -i "s/'username_here'/'${aws_db_instance.my_db.username}'/g" wp-config.php
sed -i "s/'password_here'/'${aws_db_instance.my_db.password}'/g" wp-config.php
sed -i "s/'localhost'/'${aws_db_instance.my_db.endpoint}'/g" wp-config.php