#!/bin/sh 


HOSTNAME=$1

#SSL_GENDIR='/var/sipxdata/certdb'         # Directory where certificates are generated
SSL_CRTDIR='/etc/puppet/modules/sipx/files/certdb'           # Directory where certificates are installed
SSL_GENDIR='/etc/puppet/modules/sipx/files/certdb'           # Directory where certificates are installed

if [ -f $SSL_GENDIR/$HOSTNAME.key ]; then 
   exit 0
else 
	cd $SSL_GENDIR
	/usr/bin/ssl-cert/gen-ssl-keys.sh -d -s $HOSTNAME
	RETVAL=$?
	if [ $RETVAL -ne 0 ]; then
			
			exit 1
	fi 
	
#	/usr/bin/ssl-cert/install-cert.sh $HOSTNAME 
#	RETVAL=$?
#	if [ $RETVAL -ne 0 ]; then
#			exit 1
#	fi
	
fi
chmod a+r * 
exit 0 
