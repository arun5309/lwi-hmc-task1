#!/bin/bash

sudo yum install git httpd -y
sudo mkfs.ext4 /dev/xvdh
sudo mount /dev/xvdh /var/www/html
git clone https://github.com/arun5309/lwi-hmc-task1.git
sudo cp -r lwi-hmc-task1/html /var/www
sudo systemctl --now enable httpd

