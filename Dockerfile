# Start from Apline linux
FROM alpine:3.18

# Add packages
RUN apk add --no-cache samba

# Add user
RUN addgroup -g $GID samba
RUN adduser -s /sbin/nologin -G samba -D -u $UID samba

# Create config files
COPY ./app /
RUN chown -Rv samba:samba /etc/samba /var/log/samba /var/cache/samba /var/lib/samba /run/samba

# Drop root
USER samba

# Start smbd
CMD ["sh", "/init.sh"]
