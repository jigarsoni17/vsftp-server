#!/bin/bash

#install vsftp service 
echo -e "Installing vsftp service into your machine....."

sudo apt install vsftpd -y 

sudo sed -i 's/usanonymo_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf
sudo sed -i 's/local_enable=NO/local_enable=YES/' /etc/vsftpd.conf
sudo sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf
sudo sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf

#add user for vsftp service 
echo -e " Add a user for vsftp......."

if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p "$pass" "$username"
		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system."
	exit 2
fi

#mkdir /etc/ssl/private
openssl req -x509 -nodes -days 3650 -newkey rsa:1024 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem

ip=$(hostname -I | awk '{print $1}')

echo -e "rsa_cert_file=/etc/ssl/private/vsftpd.pem\nrsa_private_key_file=/etc/ssl/private/vsftpd.pem\nssl_enable=YES\nallow_anon_ssl=NO\nforce_local_data_ssl=YES\nforce_local_logins_ssl=YES\nssl_tlsv1=YES\nssl_sslv2=NO\nssl_sslv3=NO\nrequire_ssl_reuse=NO\nssl_ciphers=HIGH" | sudo tee -a /etc/vsftpd.conf
echo -e "# BEGIN ANSIBLE MANAGED BLOCK\nchroot_local_user=YES\nchroot_list_enable=YES\nchroot_list_file=/etc/vsftpd/chroot_list\n#port_enable=YES\n#pasv_enable=YES\npasv_promiscuous=YES\npasv_max_port=24200\npasv_min_port=24000\npasv_address=$ip" | sudo tee -a /etc/vsftpd.conf

sudo mkdir -p /etc/vsftpd && echo -e "ftpuser" | sudo tee -a /etc/vsftpd/chroot_list

systemctl enable --now vsftpd.service

usermod -d /var/www ftpuser
