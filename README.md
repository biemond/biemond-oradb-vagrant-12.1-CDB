## Oracle Database 12.1.0.2 CDB with PDB

The reference implementation of https://github.com/biemond/biemond-oradb
optimized for linux, solaris

### Software ( 12.1.0.2 )
- linuxamd64_12102_database_1of2.zip
- linuxamd64_12102_database_2of2.zip

### patch plus opatch upgrade
- p6880880_121010_Linux-x86-64.zip
- p21523260_121020_Linux-x86-64.zip DB/Grid patch

### Vagrant
Update the vagrant /software share to your local binaries folder

Startup the box
- vagrant up dbcdb

Login
- vagrant ssh dbcdb

### Accounts
- root password vagrant
- vagrant password vagrant, has sudo rights
- oracle password oracle

