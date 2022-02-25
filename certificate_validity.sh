#!/bin/bash

##########################################################################################################################
#Script to check the SSL certificate validity of hosts within the cluster.
#Version : v1
##########################################################################################################################

#Code dir
export CODE_DIR=$(cd $(dirname $0) >/dev/null 2>&1; pwd);

#Defining variables
OUTPUT=/home/spatil78/SSL_validity.txt
REPORT_HTML=/home/spatil78/SSL_validity_report.html
TIME_STAMP=$(date +"%D %T")

#Removing and emptying previously created files and directories
> $OUTPUT
rm -rf $REPORT_HTML

#######################################*******FETCHING CERTIFICATE DETAILS*******######################################################
validity()
{
for server in `more /home/spatil78/hosts.txt`
do
cert_valid_from=`ssh -qt spatil78@$server openssl x509 -in /opt/cloudera/security/pki/server.pem -text -noout | grep -E 'Not Before'|sed 's/Not Before: //'`
cert_valid_till=`ssh -qt spatil78@$server openssl x509 -in /opt/cloudera/security/pki/server.pem -text -noout | grep -E 'Not After'|sed 's/Not After : //'`
Hostname=`ssh -qt spatil78@$server openssl x509 -in /opt/cloudera/security/pki/server.pem -text -noout | grep DNS| sed 's/DNS://'`

if [ ! -z $Hostname ] && [ ! -z $cert_valid_from ] && [ ! -z $cert_valid_till ]
then
    echo "$Hostname|$cert_valid_from|$cert_valid_till|$TIME_STAMP" >> $OUTPUT
else
    echo "Either of the variables cert_valid_from,cert_valid_till,hostname is missing.\nPlease check the script."	
fi
done
}

#################################################*******DELIMITER FILE TO HTML*******######################################################
delimiter_file_to_html()
{
#Appending the header to csv file
sed -i '1 i\ HOSTNAME|CERT VALID FROM|CERT VALID TILL|DATE' $OUTPUT

/usr/bin/bash ${CODE_DIR}/delimiter_file_to_html.sh -d "|" -f $OUTPUT > $REPORT_HTML
rc=$?

if [ $rc -eq 0 ]
then
        echo -e "Delimiter file converted successfully into html formate.\n";
else
        echo -e "Delimiter file failed to convert into html formate.\n";
        exit 8
fi

#Changing the permission of html file
chmod 644 $REPORT_HTML
}

##############################################**********EMAIL**********################################################################
email()
{
#Sending HTML file generated over mail
EMAIL_TO="shravani.patil@vodafone.com"
FROM="spatil78@it403bdhr.it.sedc.internal.vodafone.com"
SUBJECT="[Italy Next_BI TEST]- SSL CERTIFICATE VALIDITY REPORT OF ALL HOSTS IN CLUSTER."

(
  echo "To: ${EMAIL_TO}"
  echo "From: ${FROM}"
  echo "Subject: ${SUBJECT}"
  echo "Mime-Version: 1.0"
  echo "Content-Type: text/html; charset='utf-8'"
  echo
  cat $REPORT_HTML
) | /usr/sbin/sendmail -t
RC=$?

if [ $RC -eq 0 ]
then
        echo -e "Report sent on email successfully.\n";
else
        echo -e "Failed to send report on email.\n";
        exit 8
fi
}

#######################**********************CALLING THE FUNCTIONS***************************############################################
validity
delimiter_file_to_html
email
