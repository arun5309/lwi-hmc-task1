#!/bin/bash

sudo yum install httpd -y
sudo mkfs.ext4 /dev/xvdh
sudo mount /dev/xvdh /var/www/html
# git clone https://github.com/arun5309/lwi-hmc-task1.git
(sudo crontab -l ; sudo echo "* * * * * (sudo wget \"https://raw.githubusercontent.com/arun5309/lwi-hmc-task1/master/html/index.html\" -O /var/www/html/index.html)") | sudo crontab - 
# sudo cp -r lwi-hmc-task1/html /var/www
sudo systemctl --now enable httpd

