# wp-vps-build-guide
A verbose build guide for a modern, high-performance WordPress production VPS.

**This guide is a work in progress. Feel free to look it over, but it is currently incomplete.**

## Intro
This project aims to provide a straightforward, albeit lengthy, all-inclusive build guide for a low-budget, high-performance WordPress hosting solution. For as little as $5/mo., one can develop a cutting edge hosting stack for his or her projects. The instructions are verbose so that developers with little server administration experience can track.

#### Scope
This stack is designed for any WordPress site (including multisite or multiple sites) with light to medium loads. It will scale well, but it is not designed for an ultra-heavy use case that requires load balancing across multiple servers, etc. Server configurations are not a one-size-fits-all solution, for sure, but hopefully this guide serves as a "good-enough-for-most" solution. While configuration recommendations provided are a good starting point, it is no substitution for ongoing testing. Both speed and security have been key values during the development of this guide.

#### To amateurs at WordPress DevOps...
feel free to use this guide to turbocharge projects! Please submit issues or pull requests for any problems discovered.

#### To experts at WordPress DevOps...
please provide feedback. This guide should continue to receive ongoing optimizations and updates. In its current state, it will lead to a server that is higher-performing than most, but it is not perfect and the technologies powering it are constantly changing. Issues and pull requests are welcome.

## The Stack
- Client: OS X
- Host: DigitalOcean
- Server: Ubuntu 14.04.3 LTS x64
- Web Server: nginx
  - w/FastCGI caching
  - w/ngx_pagespeed
- Database: MariaDB
- PHP Processor: HHVM
  - w/php5-fpm failover
- Object Cache: Redis
- Let's Encrypt TLS w/ HTTP/2
- IPv4 & IPv6

## General Notes
- Items in curly brackets {} should be treated as variables and replaced with custom info.
- Recommended Snapshot points are annotated throughout, but feel free to take these more or less frequently.

## Assumptions
- The developer has basic *nix terminal skills.
- The developer has access to a VPS host. DigitalOcean (DO) is used for the purposes of this guide, but competitors such as Linode work just fine.
- The developer has a ssh key already created with the public key stored with the host and the private .pem stored locally at {myPK}.

## Sources
This build guide is constructed from a compilation of sources from all over the web. Inline "via"s give credit to some of these authors, but apologies go out to any blogs that were forgotten.

## Support
The best way to support this project is to submit issues and pull requests to assist in keeping the guide up-to-date. Clicking through the maintainer's <a href="http://brrt.co/CBDigitalOcean" target="_blank">DigitalOcean affiliate link</a> when signing up is helpful as well, but by no means expected.

## Build Guide
1. Create a new VPS running Ubuntu 14.04.3 LTS x64.
    - Enable backups.
    - Enable ipv6.
    - Select SSH key.
2. Locally, configure a ssh config file to make ssh easy.
    - In Terminal, `sudo nano ~/.ssh/config`

		```
		Host {myVpsName}
		  HostName {myVpsIP}
		  Port 22
		  User root
		  IdentityFile {myPK}
		```

    - Press "ctrl + x" to save and exit.
3. ssh into the new VPS.
	- `ssh {myVpsName}`
		- Type "yes" to continue connecting.
4. Create a new user and add it to the sudo group.
	- `adduser {myUser}`
		- Provide {myUserPassword}.
		- Press "return" repeatedly to accept the rest of the default options.
	- `gpasswd -a {myUser} sudo`
	- _via <a href="https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04" target="_blank">DigitalOcean</a>_
5. Copy the ssh key to the new user.
	- `mkdir /home/{myUser}/.ssh`
	- `cp ~/.ssh/authorized_keys /home/{myUser}/.ssh/`
	- `chown -R {myUser}:{myUser} /home/{myUser}/.ssh`
	- `chmod 700 /home/{myUser}/.ssh`
	- `chmod 600 /home/{myUser}/.ssh/authorized_keys`
	- `nano /etc/ssh/sshd_config`
        - Modify `Port {myRandomSshPort}` (<a href="http://www.wolframalpha.com/input/?i=RandomInteger%281025%2C65536%29" target="_blank">Generate {myRandomSshPort}</a>)
		- Modify `PermitRootLogin no`
        - Uncomment and modify `PasswordAuthentication no`
 	- `service ssh restart`
	- Don’t close the Terminal window, yet. In another Terminal window:
    	- `sudo nano ~/.ssh/config`

			```
			Host {myVpsName}
			  HostName {myVpsIP}
			  Port {myRandomSshPort}
			  User {myUser}
			  IdentityFile {myPK}
			```
        
	- Test ssh into the VPS as {myUser} before closing the root Terminal window.
		- `ssh {myVPSName}`
	- Type "exit" in the root Terminal window.
	- _via <a href="https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04" target="_blank">DigitalOcean</a>_
6. Snapshot 1
	- `sudo poweroff`
	- Create a Snapshot in the DO control panel.
7. Update all the things and tidy up.
    - `sudo apt-get update`
    - `sudo apt-get upgrade`
    - `sudo apt-get dist-upgrade`
    - `sudo apt-get autoremove`
    - `sudo apt-get autoclean`
8. Configure a basic firewall with ufw.
	- `sudo ufw allow {myRandomSshPort}/tcp`
	- `sudo ufw allow 80/tcp`
	- `sudo ufw allow 443/tcp`
	- `sudo ufw enable`
		- Type "y" to proceed with the operation.
	- _via <a href="https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers" target="_blank">DigitalOcean</a>_
9. Update the timezone and configure ntp sync.
	- `sudo dpkg-reconfigure tzdata`
		- Select the local timezone.
	- `sudo apt-get update`
	- `sudo apt-get install ntp`
	- _via <a href="https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers" target="_blank">DigitalOcean</a>_
10. Enable a swap file of 2x RAM size.
	- `sudo fallocate -l {swapSizeInGb}G /swapfile`
	- `sudo chmod 600 /swapfile`
	- `sudo mkswap /swapfile`
	- `sudo swapon /swapfile`
	- `sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'`
	- _via <a href="https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers" target="_blank">DigitalOcean</a>, <a href="https://help.ubuntu.com/community/SwapFaq" target="_blank">Ubuntu</a>_
11. Configure automatic updates, upgrades, & cleanup.
	- `sudo apt-get install unattended-upgrades`
	- `sudo dpkg-reconfigure -plow unattended-upgrades`
		- Select "Yes" to auto-install upgrades.
	- `sudo nano /etc/apt/apt.conf.d/20auto-upgrades`
		- Add `APT::Periodic::Download-Upgradeable-Packages "1";`
		- Add `APT::Periodic::AutocleanInterval "1";`
	- `sudo nano /etc/apt/apt.conf.d/50unattended-upgrades`
		- Uncomment `"${distro_id}:${distro_codename}-updates";`
		- Uncomment and modify `Unattended-Upgrade::Automatic-Reboot "true";`        
12. Update kernel. (DO only.)
	- `ls /boot/`
      - Note the newest version of vmlinuz installed.
    - `sudo poweroff`
    - In DO control panel, navigate to the droplet's settings->kernel.
    - If available/applicable, select and change to the newest version of vmlinuz installed on the droplet.
13. Snapshot 2
14. Download, compile, and install nginx w/ngx_pagespeed.
	- `sudo add-apt-repository -s -y ppa:nginx/development`
	- `sudo apt-get update`
	- `sudo apt-get -y build-dep nginx`
	- `sudo mkdir -p /opt/nginx`
	- `sudo chown {myUser}:{myUser} /opt/nginx`
	- `cd /opt/nginx`
	- `apt-get source nginx`
	- `cd nginx-{nginxCurVer}/debian/modules/`
	- `wget {npsTarLink}` (Copy link to the newest tar.gz <a href="https://github.com/pagespeed/ngx_pagespeed/releases" target="_blank">here</a>.)
	- `tar -xzvf {npsTarFile}`
	- `rm {npsTarFile}`
	- `cd ngx_pagespeed-{npsCurVer}-beta/`
	- `wget https://dl.google.com/dl/page-speed/psol/{npsCurVer}.tar.gz`
	- `tar -xzvf {npsCurVer}.tar.gz`
	- `rm {npsCurVer}.tar.gz`
	- `sudo nano ../../rules`
		- Under "light" version flags:
			- Delete `--without-ngx_http_limit_req_module \`
            - Add ` \` to the end of the last flag.
            - Add `--with-http_v2_module \`
			- Add `--add-module=$(MODULESDIR)/nginx-cache-purge \`
			- Add `--add-module=$(MODULESDIR)/ngx_pagespeed-{NpsCurVer}-beta`
	- `cd /opt/nginx/nginx-{nginxCurVer}/`
	- `sudo dpkg-buildpackage -b`
	- `cd /opt/nginx/`
	- `sudo dpkg -i nginx_{nginxCurVer}+trusty0_all.deb nginx-common_{nginxCurVer}+trusty0_all.deb nginx-doc_{nginxCurVer}+trusty0_all.deb nginx-light_{nginxCurVer}+trusty0_amd64.deb`
		- If there are dependency errors due to the version of python installed:
        	- `sudo apt-get -f install`
            	- Press "return" to install.
	- `echo "nginx-light hold" | sudo dpkg --set-selections`
    - `sudo service nginx restart`
    - Verify nginx is installed by visiting {myVpsIP} in a browser.
    - `sudo rm -rf /opt/`
    - `sudo rm -rf /var/www/html/`
	- _via <a href="https://blog.rudeotter.com/nginx-modules-pagespeed-ubuntu/" target="_blank">Rude Otter</a>_
15. Snapshot 3
16. Install MariaDB.
	- Follow the 5 commands <a href="https://downloads.mariadb.org/mariadb/repositories/" target="_blank">here</a> based on the setup.
		- Use the DO node that the VPS is hosted on as the mirror in both the 4th box and the 3rd command.
		- Provide {myMariaDBRootPassword}.
	- `mysql_secure_installation`
		- Type "n" for do not change root password.
		- Press "return" repeatedly to accept the rest of the default options.
17. Install PHP.
	- `sudo apt-get install php5-fpm php5-mysql`
	- `sudo nano /etc/php5/fpm/php.ini`
		- Uncomment and modify `cgi.fix_pathinfo=0`
18. Install HHVM.
	- Follow the commands for the linux distro <a href="http://docs.hhvm.com/hhvm/installation/introduction#prebuilt-packages" target="_blank">here</a>.
	- `sudo /usr/share/hhvm/install_fastcgi.sh`
	- `sudo update-rc.d hhvm defaults`
	- `sudo /usr/bin/update-alternatives --install /usr/bin/php php /usr/bin/hhvm 60`
    - `sudo nano /etc/hhvm/server.ini`
    	- Comment out `hhvm.server.port = 9000`
        - Add `hhvm.server.file_socket=/var/run/hhvm/hhvm.sock`
	- `sudo service hhvm restart`
    - Verify HHVM is configured as the php processor by `php -v`
    - _via <a href="https://codeable.io/community/speed-up-wp-admin-redis-hhvm/" target="_blank">Codeable</a>_
19. Install monit to automatically restart HHVM on crash.
    - `sudo apt-get install monit`
    - `sudo nano /etc/monit/conf.d/hhvm`

        ```
        check process hhvm with pidfile /var/run/hhvm/pid
          group hhvm
          start program = "/usr/sbin/service hhvm start" with timeout 60 seconds
          stop program = "/usr/sbin/service hhvm stop"
          if failed unixsocket /var/run/hhvm/hhvm.sock then restart
          if mem > 400.0 MB for 1 cycles then restart
          if 5 restarts with 5 cycles then timeout
        ```

    - `sudo nano /etc/monit/monitrc`
        - Uncomment and modify

            ```
            set mailserver {mySmtpMailServer} port {mySmtpPort}
            username "{mySmtpEmailAddress}" password "{mySmtpPassword}"
            using tlsv1
            ```

        - Modify `set alert {mySmtpEmailAddress} with reminder on 15 cycles`
        - Uncomment

            ```
            set httpd port 2812 and
            use address localhost
            allow localhost
            ```

    - `sudo service monit restart`
    - _via <a href="https://codeable.io/community/speed-up-wp-admin-redis-hhvm/" target="_blank">Codeable</a>_
20. Install redis.
	- `sudo apt-get install redis-server`
	- `sudo apt-get install php5-redis`
    - _via <a href="https://codeable.io/community/speed-up-wp-admin-redis-hhvm/" target="_blank">Codeable</a>_
21. Snapshot 4
22. Create a database for WordPress.
	- `mysql -u root -p`
    	- Provide {myMariaDBRootPassword}.
	- `CREATE DATABASE {myWPDB};`
    - `CREATE USER {myWPDBUser}@localhost IDENTIFIED BY '{myWPDBPassword}';`
    - `GRANT ALL PRIVILEGES ON {myWPDB}.* TO {myWPDBUser}@localhost;`
    - `FLUSH PRIVILEGES;`
    - `exit`
    - Repeat this step for each WordPress site to be installed with new values for {myWPDB}, {myWPDBUser}, and {myWPDBPassword}.
    - _via <a href="https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-nginx-on-ubuntu-14-04" target="_blank">DigitalOcean</a>_
23. Download and install WordPress.
	- `sudo apt-get update`
	- `sudo apt-get install php5-gd libssh2-php`
    - `wget http://wordpress.org/latest.tar.gz`
    - `tar -xzvf latest.tar.gz`
    - `rm latest.tar.gz`
    - `cd ~/wordpress`
    - `cp wp-config-sample.php wp-config.php`
    - `rm wp-config-sample.php`
    - `sudo nano wp-config.php`
    	- Modify `define('DB_NAME', '{myWPDB}');`
        - Modify `define('DB_USER', '{myWPDBUser}');`
        - Modify `define('DB_PASSWORD', '{myWPDBPassword}');`
        - Replace `{myWPSecurityKeys}` (<a href="https://api.wordpress.org/secret-key/1.1/salt/" target="_blank">Generate {myWPSecurityKeys}</a>)
        - Modify `$table_prefix  = '{myRandomPrefix}_';` (<a href="https://www.wolframalpha.com/input/?i=password+generator&a=*MC.~-_*Formula.dflt-&a=FSelect_**PasswordSingleBasic-.dflt-&f3=16+characters&f=PasswordSingleBasic.pl_16+characters" target="_blank">Generate {myRandomPrefix}</a>)
        - Add `define( 'WP_AUTO_UPDATE_CORE', true );`
	- `mkdir wp-content/uploads`
    - `sudo chown -R :www-data wp-content/uploads`
	- `sudo mkdir -p /var/www/{myWPSiteName}`
    - `sudo rsync -avP ~/wordpress/ /var/www/{myWPSiteName}/`
    - `rm -rf ~/wordpress/`
    - `sudo chown -R {myUser}:www-data /var/www/{myWPSiteName}/*`
    - Repeat this step for each WordPress site to be installed with new values for {myWPDB}, {myWPDBUser}, {myWPDBPassword}, {myWPSecurityKeys}, and {myRandomPrefix}.
    - _via <a href="https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-nginx-on-ubuntu-14-04" target="_blank">DigitalOcean</a>_
24. Snapshot 5
25. Configure nginx.
    - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/nginx.conf -O /etc/nginx/nginx.conf`
    - `sudo mkdir /etc/nginx/global`
    - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/common.conf -O /etc/nginx/global/common.conf`
    - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/wordpress.conf -O /etc/nginx/global/wordpress.conf`
    - If multisite, `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/multisite.conf -O /etc/nginx/global/multisite.conf`
    - `sudo rm /etc/nginx/sites-available/default`
    - `sudo rm /etc/nginx/sites-enabled/default`
    - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/sites-available/example.com -O /etc/nginx/sites-available/example.com`
    - `sudo mv /etc/nginx/sites-available/example.com /etc/nginx/sites-available/{myWPSiteName}`
    - `sudo nano /etc/nginx/sites-available/{myWPSiteName}`
        - Replace `example.com` with `{myWPSiteUrl}`
    - `sudo ln -s /etc/nginx/sites-available/{myWPSiteName} /etc/nginx/sites-enabled/{myWPSiteName}`
    - _via <a href="https://www.digitalocean.com/community/tutorials/how-to-configure-single-and-multiple-wordpress-site-settings-with-nginx" target="_blank">DigitalOcean</a>, <a href="https://www.digitalocean.com/community/tutorials/how-to-optimize-nginx-configuration" target="_blank">DigitalOcean</a>_
26. Configure TLS encryption.
    - `sudo apt-get install git`
    - `git clone https://github.com/letsencrypt/letsencrypt`
    - `cd letsencrypt`
    - `sudo service nginx stop`
    - `./letsencrypt-auto certonly`
    	- This assumes DNS records have already been configured to point {myWPSiteUrl} to {myVpsIp}.
    - `sudo nano /etc/nginx/sites-available/{myWPSiteName}`
        - Modify `rewrite ^/(.*)$ https://{myWPSiteUrl}/$1 permanent;`
        - Comment out `listen 80;`
        - Uncomment `listen 443 default ssl http2;`
        - Uncomment `listen [::]:443 default ssl http2 ipv6only=on;`
        - Uncomment `ssl_certificate_key /etc/letsencrypt/live/{myWPSiteUrl}/privkey.pem;`
        - Uncomment `ssl_certificate /etc/letsencrypt/live/{myWPSiteUrl}/fullchain.pem;`
    - `sudo service nginx start`
    - Verify nginx and TLS is configured by visiting {myWPSiteUrl} in a browser.
    - _via <a href="https://oct.im/install-lets-encrypt-ca-on-apache-and-nginx.html" target="_blank">oct.im</a>_
27. **TODO**: Configure ngx_pagespeed, configure ssl, optimize swap, optimize nginx, optimize MariaDB, optimize HHVM, configure monit to restart HHVM, optimize php5-fpm, optimize redis, etc.

## Recommended Ongoing Maintenance
- Whenever nginx or ngx_pagespeed have a new release, repeat step 14. nginx will first need to be uninstalled (`sudo apt-get remove nginx`) before installing the newly compiled version.
- If the VPS is ever resized, the swap file should be resized.
- Step 12 should be repeated whenever a new version of the kernel is installed.
- MariaDB should be tuned on occasion for optimum performance.
