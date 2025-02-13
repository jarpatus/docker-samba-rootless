# Rootless samba container
Ultra simple rootless samba container for us who do not like daemons running root, not even in containers. Naturally limits use cases quite a lot as samba must run as single OS user and single OS user only. Hence you need separate container for each OS user and each container needs it's own IP. At some point it becomes ridiculous so I guess this is best suited for home use where you need to have one or two users and perhaps public share for media devices or so.

When planning implementation, it is best to kind of forget how samba normally operates with multiple users and think one samba container as one OS user's own personal file server. Even if you enable unauthenticated guest access or create multiple samba users for single container, samba will still operate as single OS user no matter what samba user you logged in as or if you are guest! Thus to avoid security hazards by misconfiguration it probably is the best to create separate guest container for public files and not mix and match.

Additionally DFS can be used to aggregate shares from multiple containers into one so you could have one guest container and one user's container which also shows shares from guest container. 

# Compose file

## Capabilities
* ```NET_BIND_SERVICE``` - Needed so that samba can bind privileged ports.
  
## Environment 

### For global section

Mandatory environment variables:

* ```UID``` - UID to run container with. Files server must be readable using this UID but user does not necessarily have to actually exist in host OS. 
* ```GID``` - GID to run container with. Again group does not necessarily have to actually exist in host OS.

Optional environment variables:

* ```USER``` - Samba username used to access the shares. If not defined then only guest shares can be accessed.
* ```PASS``` - Samba passwor used to access the shares. If not defined then only guest shares can be accessed.
* ```WORKGROUP``` - Workgroup. Defaults to MYGROUP.
* ```SERVER_STRING``` - Server string. Defaults to Samba Server.
* ```SERVER_ROLE``` - Server role. Defaults to standalone server.
* ```ANONYMOUS``` - If set to yes then guest access will be enabled for the server. See Security considerations.
* ```LOG_LEVEL``` - Log level. Defaults to 1.
* ```DNS_PROXY``` - DNS proxy enable. Defaults to no.
* ```ALLOW_SMBV1``` - Downgrades security back to 80s for retro gear. See Security considerations.
* ```GLOBAL_OPTS``` - Additional global options if not listed above.

Multiple samba users can be added by defining ```USER``` and ```PASS``` variables multiple times and prefixing them with XXX_ where XXX is user specific string. One user can be unprefixed and all users can be prefixed. Again, despite of having multiple samba users container will still operate using single OS user.

### For share sections

Multiple shares can be added by defining variables below multiple times and prefixing them with XXX_ where XXX is share specific string. One share can be unprefixed and all shares can be prefixed.

Mandatory environment variables:

* ```NAME``` - Share name.
* ```PATH``` - Path in container from which files are served. See Volumes.

Optional environment variables:

* ```COMMENT``` - Share comment.
* ```PUBLIC``` - If set to yes then guest access is enabled for the share. Note that ```ANONYMOUS``` also needs to be set to yes. Defaults to no.
* ```VALID_USERS``` - List of samba users allowed to access the share. Defaults to all users if share is not public and if it is then omitted by default.
* ```WRITABLE``` - Share is writable (still needs filesystemlevel access for the ```UID``` or ```GID```). Defaults to no.
* ```BROWSEABLE``` - Share shows up in share listings. Defaults to no.
* ```CREATE_MASK``` - File create mask.
* ```DIRECTORY_MASK``` - Directory create mask.
* ```WARE_MSDFS_ROOT``` - Is DFS root share (will also enable DFS on global level).
* ```WARE_MSDFS_PROXY``` - Share to link to.
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

### DFS

```
```






# Security considerations
