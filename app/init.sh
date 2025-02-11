#!/bin/sh

# Setup samba user
printf "%s\n%s\n" "$PASS" "$PASS" | pdbedit -t -a samba
echo "samba = $USER" > /etc/samba/users.map

# Setup samba configuration
cat /etc/samba/smb.conf > /tmp/smb.conf
echo "   workgroup = ${WORKGROUP:=MYGROUP}" >> /tmp/smb.conf
if [ "$ALLOW_SMBV1" == "true" ]; then
  echo "   server min protocol = NT1" >> /tmp/smb.conf
  echo "   ntlm auth = yes" >> /tmp/smb.conf
  echo "   lanman auth = yes" >> /tmp/smb.conf
  echo "   client min protocol = NT1" >> /tmp/smb.conf
  echo "   client ntlm auth = yes" >> /tmp/smb.conf
  echo "   client lanman auth = yes" >> /tmp/smb.conf
fi

# Setup samba share
echo [${SHARE:=Share}] >> /tmp/smb.conf
echo "   comment = ${COMMENT:=Default share}" >> /tmp/smb.conf
echo "   path = /data" >> /tmp/smb.conf
echo "   valid users = samba" >> /tmp/smb.conf
echo "   public = ${PUBLIC:=no}" >> /tmp/smb.conf
echo "   writable = ${WRITABLE:=no}" >> /tmp/smb.conf
echo "   browseable = ${BROWSEABLE:=no}" >> /tmp/smb.conf
[ -n "$CREATE_MASK" ] && echo "   create mask = $CREATE_MASK" >> /tmp/smb.conf
[ -n "$DIRECTORY_MASK" ] && echo "   directory mask = $DIRECTORY_MASK" >> /tmp/smb.conf

# Start samba
cat /tmp/smb.conf
exec smbd -s /tmp/smb.conf -F --no-process-group --debug-stdout
