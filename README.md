# Rootless samba container
Ultra simple rootless samba container for us who do not like daemons running root, not even in containers. Naturally limits use cases quite a lot, limitations being:
  - Only one network share is supported
  - Only one user can authenticate to the network share
  - The user container is run as must have have read (/ write) rights to the files shared

In case of multiple shares and / or users needed then multiple containers can be created, however at some point this of course becomes quite ridiculous...

# Compose file
Example docker-compose.yaml file can be found from examples /.


