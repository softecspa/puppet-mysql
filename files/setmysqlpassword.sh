#!/bin/bash
#
# GENERATED WITH PUPPET using /modules/mysql/files/setmysqlpassword.sh 
#
# Stati di uscita:
# 0= esecuzione corretta o MySQL gia' configurato
# 1= problema nell'esecuzione dello script

# esce se e' tutto gia' configurato correttamente
if grep -q password /root/.my.cnf 2>/dev/null; then
        if mysql -e 'show databases;' >/dev/null 2>&1; then
                echo "MySQL gia' correttamente configurato. Uscita."
                exit 0
        fi
fi

# genera la password
PASSWORD="`pwgen -c 16 1`"

# variabili di connessione
PORT=$1
HOST=$2
[ -z $PORT ] && PORT=3306
[ -z $HOST ] && HOST="localhost"

# imposta la password
mysqladmin -h $HOST -P $PORT password "${PASSWORD}"

if [ $? != 0 ]; then
	echo "Problema nella connessione al MySQL. Uscita."
	exit 1
fi

# genera il .my.cnf
cat > /root/.my.cnf <<EOF
[client]
user = root
password = $PASSWORD

[mysql]
prompt = "(\u@\h) \d> "
EOF

# effettua il test di connessione al mysql
if ! mysql -e 'show databases;' >/dev/null 2>&1; then
        echo "Problema nell'esecuzione dello script."
        exit 1
fi

echo "Script eseguito correttamente."

exit 0
