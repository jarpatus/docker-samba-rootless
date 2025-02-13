# Start from Apline linux
FROM alpine:3.18

# Add packages
RUN apk add --no-cache bash samba

# Add user for samba
RUN addgroup -g $GID samba
RUN adduser -s /sbin/nologin -G samba -D -u $UID samba

# Add fake users for samba authentication (samba requires entry in passwd for each user)
RUN echo user0:x:$UID:$GID:Linux User,,,:/home/samba:/sbin/nologin >> /etc/passwd
RUN echo user1:x:$UID:$GID:Linux User,,,:/home/samba:/sbin/nologin >> /etc/passwd
RUN echo user2:x:$UID:$GID:Linux User,,,:/home/samba:/sbin/nologin >> /etc/passwd
RUN echo user3:x:$UID:$GID:Linux User,,,:/home/samba:/sbin/nologin >> /etc/passwd
RUN echo user4:x:$UID:$GID:Linux User,,,:/home/samba:/sbin/nologin >> /etc/passwd
RUN echo user5:x:$UID:$GID:Linux User,,,:/home/samba:/sbin/nologin >> /etc/passwd
RUN echo user6:x:$UID:$GID:Linux User,,,:/home/samba:/sbin/nologin >> /etc/passwd
RUN echo user7:x:$UID:$GID:Linux User,,,:/home/samba:/sbin/nologin >> /etc/passwd
RUN echo user8:x:$UID:$GID:Linux User,,,:/home/samba:/sbin/nologin >> /etc/passwd
RUN echo user9:x:$UID:$GID:Linux User,,,:/home/samba:/sbin/nologin >> /etc/passwd

# Create config files
COPY ./app /
RUN chown -Rv samba:samba /etc/samba /var/log/samba /var/cache/samba /var/lib/samba /run/samba

# Drop root
USER samba

# Start smbd
CMD ["bash", "/init.sh"]
