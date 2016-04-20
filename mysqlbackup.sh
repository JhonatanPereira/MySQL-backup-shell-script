#!/bin/bash
# Script/função: Backup de múltiplos bancos de dados para localdir/ftp
# Autor: Jhonatan Pereira
# Variaveis
host="localhost" #Servidor MySQL
user="root" #Usuário MySQL
pass="" #Senha MySQL
localdir="backup" #Diretorio local pra onde vao os backups
data=$(date +"%H-%M-%S-%Y-%m-%d") #Formato da data
dbs=("db1" "db2" "db3") #Nome das dbs para fazer backup
diasr=3 #Manter backups por x dias
duplftp=false #Duplicar no FTP - true/false
ftpserver="" #Servidor FTP
ftpusuario="" #Usuário FTP
ftpsenha="" #Senha FTP
ftpupdir="" #Diretorio ftp pra onde vao os backups
prefixbkp="mysqlbackup" #Prefixo dos backups

for db in ${dbs[@]}; do
	mysqldump --user=$user --password=$pass --host=$host --single-transaction $db > $localdir/$prefixbkp-$db-$data.sql
	echo "Backup de $db em andamento..."
	if  [ $duplftp == true ]; then
		ftp -ni $ftpserver <<EOMF0
		user $ftpusuario $ftpsenha
		lcd $localdir
		cd $ftpupdir
		mput $prefixbkp-$db-$data.sql
		bye
EOMF0
	else
		echo "FTP Backup ignorado"
	fi
done;
echo "Excluindo backups antigos..."
find $localdir/*.sql -ctime +$diasr -exec rm {} \;
if [ $duplftp == true ]; then
		MM='date --date="$diasr days ago" +%b'
		DD='date --date="$diasr days ago" +%d'
		listing='ftp -i -n $ftpsite <<EOMYF 
		user $ftpusuario $ftpsenha
		binary
		cd $ftpupdir
		ls
		quit
		EOMYF'
	lista=( $listing )
	echo "Buscando por backups antigos no FTP..."
	for ((FNO=0; FNO<${#lista[@]}; FNO+=9)); do
		if [[ ${lista[$((FNO+5))]} = "$MM" ]];
		then
			if [[ ${lista["expr $FNO+6"]} -lt $DD ]];
			then
			echo "Removendo ${lista["expr $FNO + 8"]}"
				ftp -i -n $ftpserver <<EOMYF2 
				user $ftpusuario $ftpsenha
				binary
				cd $ftpupdir
				delete ${lista["expr $FNO + 8"]}
				bye
EOMYF2
			fi
		fi
	done
else
	echo "Remover FTP ignorado"
fi
echo "Script concluido!"