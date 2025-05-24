#!/bin/bash

add_user() {
  local prefix=${1}
  local var_user=${prefix}USER
  local var_pass=${prefix}PASS
  local user=user${#users[@]}
  local login=${!var_user}
  users+=($user)
  logins+=($login)
  login_user_map[$login]=$user 
  echo "***************************** Add user $user and map it to samba login $login"
  printf "%s\n%s\n" "${!var_pass}" "${!var_pass}" | pdbedit -c /tmp -t -a $user
  echo "$user = $login" >> /tmp/users.map
}

add_share() {
  local prefix=${1}
  local var_name=${prefix}NAME
  local var_comment=${prefix}COMMENT
  local var_path=${prefix}PATH
  local var_public=${prefix}PUBLIC
  local var_valid_users=${prefix}VALID_USERS
  local var_writable=${prefix}WRITABLE
  local var_browseable=${prefix}BROWSEABLE
  local var_create_mask=${prefix}CREATE_MASK
  local var_directory_mask=${prefix}DIRECTORY_MASK
  local var_msdfs_root=${prefix}MSDFS_ROOT
  local var_msdfs_proxy=${prefix}MSDFS_PROXY
  local var_share_opts=${prefix}SHARE_OPTS
  echo >> /tmp/smb.conf
  echo "[${!var_name:=Share}]" >> /tmp/smb.conf
  [ -n "${!var_comment}" ] && echo "   comment = ${!var_comment}" >> /tmp/smb.conf
  [ -n "${!var_path}" ] && echo "   path = ${!var_path}" >> /tmp/smb.conf
  echo "   guest ok = ${!var_public:=no}" >> /tmp/smb.conf
  if [ -n "${!var_valid_users}" ]; then
    local mapped=$(map_logins "${!var_valid_users}")
    echo "   valid users = ${mapped[@]}" >> /tmp/smb.conf
  elif [ "${!var_public}" != "yes" ]; then
    echo "   valid users = ${users[@]}" >> /tmp/smb.conf
  fi    
  echo "   writable = ${!var_writable:=no}" >> /tmp/smb.conf
  echo "   browseable = ${!var_browseable:=no}" >> /tmp/smb.conf
  [ -n "${!var_create_mask}" ] && echo "   create mask = ${!var_create_mask}" >> /tmp/smb.conf
  [ -n "${!var_directory_mask}" ] && echo "   directory mask = ${!var_directory_mask}" >> /tmp/smb.conf
  [ -n "${!var_msdfs_root}" ] && echo "   msdfs root = ${!var_msdfs_root}" >> /tmp/smb.conf
  [ -n "${!var_msdfs_proxy}" ] && echo "   msdfs proxy = ${!var_msdfs_proxy}" >> /tmp/smb.conf
  [ -n "${!var_share_opts}" ] && echo -e "${!var_share_opts}" >> /tmp/smb.conf
}

map_logins() {
  local logins=${1}
  local users=()
  local login
  for login in $logins; do  
    users+=(${login_user_map[$login]})
  done
  echo ${users[@]}
}

# Globals
declare -a users
declare -a logins
declare -A login_user_map

# Set defaults for environment variables
[ "$ENABLE_NMBD" != "true" ] && export ENABLE_NMBD="false"

# Create samba users
touch /tmp/users.map
[ -n "$USER" ] && add_user ""
for USER in $(env | grep "_USER=" | cut -f 1 -d _); do
  add_user ${USER}_
done

# Create global configuration
echo "[global]" > /tmp/smb.conf
echo "   workgroup = ${WORKGROUP:=MYGROUP}" >> /tmp/smb.conf
[ -n "$NETBIOS_NAME" ] && echo "   netbios name = ${NETBIOS_NAME}" >> /tmp/smb.conf
echo "   server string = ${SERVER_STRING:=Samba Server}" >> /tmp/smb.conf
echo "   server role = ${SERVER_ROLE:=standalone server}" >> /tmp/smb.conf
echo "   username map = /tmp/users.map" >> /tmp/smb.conf
if [ "$ANONYMOUS" == "yes" ]; then
   echo "   guest account = samba" >> /tmp/smb.conf
   echo "   map to guest = Bad User" >> /tmp/smb.conf
fi
echo "   log level = ${LOG_LEVEL:=1}" >> /tmp/smb.conf
echo "   dns proxy = ${DNS_PROXY:=no}" >> /tmp/smb.conf
[ -n "$(env | grep "_MSDFS_PROXY=")" ] && echo "   host msdfs = yes" >> /tmp/smb.conf
if [ "$ALLOW_SMBV1" == "yes" ]; then
  # Note: dropped in Samba 4.16!
  echo "   server min protocol = NT1" >> /tmp/smb.conf
  echo "   client min protocol = NT1" >> /tmp/smb.conf
fi
[ -n "$GLOBAL_OPTS" ] && echo -e "$GLOBAL_OPTS" >> /tmp/smb.conf

# Add shares 
[ -n "$NAME" ] && add_share ""
for SHARE in $(env | grep _NAME | cut -f 1 -d _); do
  add_share ${SHARE}_
done

# Output conf files for debugging
echo "***************************** smb.conf:"
cat /tmp/smb.conf
echo "***************************** users.map:"
cat /tmp/users.map
echo "*****************************"

# Start supervisor
exec supervisord
