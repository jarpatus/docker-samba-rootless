# Rootless samba container
Ultra simple rootless samba container for us who do not like daemons running root, not even in containers. Naturally limits use cases quite a lot, limitations being:
  - Only one network share is supported
  - Only one user can authenticate to the network share
  - The user container is run as must have have read (/ write) rights to the files shared

In case of multiple shares and / or users needed then multiple containers can be created, however at some point this of course becomes quite ridiculous. Also distict IP addressess are needed for each container when using multiple containers so macvlan or similar approach must be used.

# Compose file
Example docker-compose.yaml file can be found from examples /. 

### Environment 
* ```UID``` - UID to run container with.
* ```GID``` - GID to run container with.
* ```WORKGROUP``` - 
* ```USER``` - 
* ```PASS``` - 
* ```SHARE``` - 
* ```COMMENT``` - 
* ```PUBLIC``` - 
* ```WRITABLE``` - 
* ```BROWSEABLE``` - 
* ```CREATE_MASK``` - 
* ```DIRECTORY_MASK``` -
* ```ALLOW_SMBV1``` - Downgrades security back to 80s (to be used with retro equpiment only in secure networks).
 
### Volumes
Files to be accessed via the share must be mounted to /data.


