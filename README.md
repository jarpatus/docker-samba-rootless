# Samba rootless
Ultra simple rootless samba container for us who do not like daemons running root, not even in containers. Naturally limits use cases quite a lot as samba must run as single user and single user only. Hence you need separate container for each user and each container needs it's own IP address. At some point it becomes ridiculous so I guess this is best suited for home use where you need to have one or two users and perhaps public share for media devices or so.

When planning implementation, it is best to kind of forget how samba normally operates with multiple users and think one instance of container as a personal file server of single user. Even if you enable guest access or create multiple logins for single container, samba will still operate as single user no matter what. Thus to avoid security hazards by misconfiguration it probably is the best to create separate guest container for public files and not mix and match.

DFS can be used to aggregate shares from multiple containers into one so you could e.g. have guest container and make shares from it visible in other containers or vice versa. You could also e.g. create multiple logins to guest container so that logins from you other containers do work with guest container and you won't be prompted for login when you seamlessly navigate to guest shares by DFS and since guest container is running as single user your guest container file ownerships will not be messed up (this is actually something which could be very useful in home environment, though may be difficult to manage properly).

# Compose file

## Build args
  
* ```UID``` - UID to run container with. Files server must be readable using this UID but user does not necessarily have to actually exist in host OS. 
* ```GID``` - GID to run container with. Again group does not necessarily have to actually exist in host OS.

## Capabilities
* ```NET_BIND_SERVICE``` - Needed so that samba can bind privileged ports.

## Environment 

* ```ENABLE_NMBD``` - Set to true to enable nmbd for NetBIOS requests. You may want to use ```NETBIOS_NAME``` as well with this.

### For global section

Optional environment variables:

* ```USER``` - Samba username used to access the shares. If not defined then only guest shares can be accessed.
* ```PASS``` - Samba password used to access the shares. If not defined then only guest shares can be accessed.
* ```WORKGROUP``` - Workgroup. Defaults to MYGROUP.
* ```NETBIOS_NAME``` - NetBIOS name. Defaults to hostname (which, unless explicitly set, is random).
* ```SERVER_STRING``` - Server string. Defaults to Samba Server.
* ```SERVER_ROLE``` - Server role. Defaults to standalone server.
* ```ANONYMOUS``` - Set to yes to enable guest access for the server. See Security considerations.
* ```LOG_LEVEL``` - Log level. Defaults to 1.
* ```DNS_PROXY``` - Set to yes to enable DNS proxy.
* ```ALLOW_SMBV1``` - Set to yes to downgrade security back to 80s for retro gear. See Security considerations.
* ```GLOBAL_OPTS``` - Additional global options if not listed above.

Note that we use term login when we refer to username and password given to samba when accessing the share. This is different from user which samba is running. Container always runs as single user and filesystem permissions for that user are enforced, but container could also have multiple logins all of which in the end operates as that single user (we do this by creating multiple pseudo-users with the same UID and GID than main samba user). Multiple logins can be added by defining ```USER``` and ```PASS``` variables multiple times and prefixing them with XXX_. One user can be unprefixed or all users can be prefixed. 

### For share sections

Multiple shares can be added by defining variables below multiple times and prefixing them with XXX_ where XXX is share specific string. One share can be unprefixed or all shares can be prefixed.

Mandatory environment variables:

* ```NAME``` - Share name.
* ```PATH``` - Path in container from which files are served. See Volumes.

Optional environment variables:

* ```COMMENT``` - Share comment.
* ```PUBLIC``` - Set to yes to enable guest access for the share. Note that ```ANONYMOUS``` also needs to be set to yes.
* ```VALID_USERS``` - List of logins allowed to access the share. Defaults to all users if share is not public and if it is then omitted by default.
* ```WRITABLE``` - Set to yes to make share writable (still needs filesystemlevel access for the ```UID``` or ```GID```).
* ```BROWSEABLE``` - Set to yes to make share browseable.
* ```CREATE_MASK``` - File create mask.
* ```DIRECTORY_MASK``` - Directory create mask.
* ```MSDFS_ROOT``` - Is DFS root share (will also enable DFS on global level).
* ```MSDFS_PROXY``` - Share to link to.
* ```SHARE_OPTS``` - Additional share options if not listed above.
 
## Volumes
Volumes to be served must be mounted to container and ```PATH``` must be set to point to those files.

## Networks
In case of multiple containers you really would need macvlan or ipvaln setup so you can assign separate IP addresses for each. Not sure if any kind of trick would be possible to user different containers via different host OS ports...

## Examples

### Single share
```
services:
  samba-single:
    container_name: samba_single
    build:
      context: src
      args:
        - UID=8445
        - GID=8445
    restart: always
    cap_add:
      - NET_BIND_SERVICE
    environment:
      - UID=1234
      - GID=1234
      - USER=user
      - PASS=***
      - NAME=Share
      - PATH=/data/Share
      - WRITABLE=yes
      - BROWSEABLE=yes
    volumes:
      - /mnt/Share:/data/Share
```

### Multiple shares
```
services:
  samba-multi:
    container_name: samba_multi
    build:
      context: src
      args:
        - UID=8445
        - GID=8445
    restart: always
    cap_add:
      - NET_BIND_SERVICE
    environment:
      - UID=1234
      - GID=1234
      - USER=user
      - PASS=***
      - CLOUD_NAME=Cloud
      - CLOUD_PATH=/data/Cloud
      - CLOUD_WRITABLE=yes
      - CLOUD_BROWSEABLE=yes
      - WORK_NAME=Work
      - WORK_PATH=/data/Work
      - WORK_WRITABLE=yes
      - WORK_BROWSEABLE=yes
    volumes:
      - /mnt/Cloud:/data/Cloud
      - /mnt/Work:/data/Work
```

### Guest shares
```
  samba-guest:
    container_name: samba_guest
    build:
      context: src
      args:
        - UID=8445
        - GID=8445
    restart: always
    cap_add:
      - NET_BIND_SERVICE
    environment:
      - UID=1234
      - GID=1234
      - ANONYMOUS=yes
      - MEDIA_NAME=Media
      - MEDIA_PATH=/data/Media
      - MEDIA_PUBLIC=yes
      - MEDIA_WRITABLE=no
      - MEDIA_BROWSEABLE=yes
      - INCOMING_NAME=Incoming
      - INCOMING_PATH=/data/Incoming
      - INCOMING_PUBLIC=yes
      - INCOMING_WRITABLE=yes
      - INCOMING_BROWSEABLE=yes
      - INCOMING_CREATE_MASK=0666
      - INCOMING_DIRECTORY_MASK=0777
    volumes:
      - /mnt/Media:/data/Media
      - /mnt/Incoming:/data/Incoming
```

### Multiple logins
```
services:
  samba-single:
    container_name: samba_single
    build:
      context: src
      args:
        - UID=8445
        - GID=8445
    restart: always
    cap_add:
      - NET_BIND_SERVICE
    environment:
      - UID=1234
      - GID=1234
      - USER1_USER=user1
      - USER1_PASS=***
      - USER2_USER=user2
      - USER2_PASS=***
      - NAME=Share
      - PATH=/data/Share
      - WRITABLE=yes
      - BROWSEABLE=yes
    volumes:
      - /mnt/Share:/data/Share
```


### DFS
In this example we set up public share without any need to login and then use DFS to show Cloud share from another container (which can then require login when navigated to).

```
  samba-guest:
    container_name: samba_guest
    build:
      context: src
      args:
        - UID=8445
        - GID=8445
    restart: always
    cap_add:
      - NET_BIND_SERVICE
    environment:
      - UID=1234
      - GID=1234
      - ANONYMOUS=yes
      - MEDIA_NAME=Media
      - MEDIA_PATH=/data/Media
      - MEDIA_PUBLIC=yes
      - MEDIA_WRITABLE=no
      - MEDIA_BROWSEABLE=yes
      - CLOUD_NAME=Cloud
      - CLOUD_WRITABLE=no
      - CLOUD_BROWSEABLE=yes
      - CLOUD_MSDFS_ROOT=yes
      - CLOUD_MSDFS_PROXY=\[ip of cloud container]\Cloud
    volumes:
      - /mnt/Media:/data/Media
      - /mnt/Incoming:/data/Incoming
```

# Security considerations
* Please mentally separate host user and samba logins from each other. Multiple samba logins can be done but they all operates under that one user.
* It would be technically possible to set up multiple shares and users and use ```VALID_USERS``` to restrict access to each share effectively supporting multiple logins with separate shares, but this is bad security as host won't enforce this as host sees only one user.
* Setting up multiple containers, logins, DFS and everything would allow quite crazy combos, please try to keep it simple though.
* ```ALLOW_SMBV1``` downgrades minimum protocol to SMBv1 and enables NTLM and LANMAN authentication for whole container. This is not secure and recommended only for serving retro gear or so and perhaps read-only shares without any sensitive information.
