# Bashckup 0.2a

![Logo](https://alquimistadesistemas.com/images/bashckup.m.png)

**Centralized remote backups in GNU/Linux with ssh and rdiff-backup**

Bashckup is a program make with bash scripts to do backups in Mysql and Mongodb SGDB with only ssh connection and one user in remote server.

### Who need this?
Bashckup is for small backups solution, not have a restore mode (you can do it with rdiff-backups) and only work in MySQL and MongoDB.
If you have very big tables or big databases Bashckup can help you becouse is defined to work with cpulimit to reduce the overload in server and make backups table by table.

### Programs used
 - ssh
 - rdiff-backup
 - cpulimit
 - mongodb
 - mysql

### Features
- Fully managed with terminal commands: All you need is a command line to make backups and install clients.
- Installation in server automatic: run only install.sh script.
- Installation guided in clients: step by step the script asks the data.
- Incremental backups with rdiff-backups: To use the fully features of rdiff-backups with the files of backups created.
- Agentless: Only needs one user in remote in centralized server.
- Cron configuration: Easy configuration to do backups with crontab and anacron.
- Log file: Can enable or disable generate log file.
- Email with alerts: Can enable option to send email in case that occurs alert in one backup.
- Email with all logs: Can enable option to send email with all output of a backup.
- Colors in emails and console: Friendly output in console and email logs.
- Blacklist of databases: Possibility to select databases that don't copy for each server and SGDB.
- Whitelist of databases: Whitelist for each server to do copy only he selected databases.
- Backups table by table: All backups of MySQL and MongoDB are made by database and by table. This is to do faster restore if you only need restore one table instead of all database.
- CPU use limitation: With cpulimit can make the backups without overload in server.

### Bashckup Installation
Only need the git repository downloaded and install needed programs in your GNU/Linux system.

##### Install programs needed
- Debian/Ubuntu install
```
apt-get install cpulimit rdiff-backup mailutils
```
- RedHat / Centos install
```
yum install cpulimit rdiff-backup mailx
```

#### Download Bashckup
When you install bashckup is recommendable use backups user and its home folder.
Download latest code:
```
git clone https://github.com/jbenages/bashckup.git
```
### Install
Only needs execute the install.sh script.
```
./install.sh
```
If you need reinstall the program you can execute this command.
```
./install.sh -f
```
It don't overwrite **/var/lib/bashckup/**,**/etc/bashckup/** and **/var/log/bashckup/** folders.
To check install:
```
bashckup -v
```

### Uninstall
To uninstall Bashckup execute this command:
```
./install -u
```
It don't remove **/var/lib/bashckup/**,**/etc/bashckup/** and **/var/log/bashckup/** folders.

### Folders after installation
- **Configuration**: /etc/bashckup/bashckup.cfg in this file you have the params to configure the backups.
- **Binary**: /usr/local/bin/bashckup this is a symlink to binary in root program folder.
- **Libs and bin**: /opt/bashckup here are all files of the program need to execute it.
- **Backups directory**: /var/lib/bashckup in this folder you have all of the backups, each server have a folder and in this folder have each SGDB system.
- **Logs**: /var/log/bashckup all logs are in this folder and each server have they log file

### Folders and files of program
- **bin**: Folder with the execution script.
- **func**: Folder than have all functions of Bashckup code.
- **lib**: Folder than have all functions of libs to execute with code.
- **conf**: Folder with configuration file.
- **install.sh**: Script for installation.
- **LICENSE**: License of project.
- **README.md**: This file.

### Usage 

#### Install client
To install client in server you need config the file **/etc/bashckup/bashckup.cfg** with your options.
Execute this command to install all SGDB (MySQL and MongoDB) in server "server1":
```
bash bashckup.sh -i server1 all
```
Execute this command to install only with MySQL SGDB in server "server2":
```
bash bashckup.sh -i server2 mysql
```

### Make backup
To make backup of client you need config the file **/etc/bashckup/bashckup.cfg** with your options.
Execute this command to make backups of all SGDB (MySQL and MongoDB) in server "server1":
```
bash bashckup.sh -b server1 all
```
Execute this command to make backup only with MySQL SGDB in server "server2":
```
bash bashckup.sh -b server2 mysql
```

### Configure cron
To configure cron you need usage the user bashckup in your cron files /var/spool/cron/crontabs/bashckup.
An example of cron to make backup of all SGDB (MySQL and MongoDB) databases in server "server1" each day in the 24 oclock:
```
00 00 * * *  bashckup -b server1 all
```

