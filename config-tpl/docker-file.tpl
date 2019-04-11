FROM alpine

RUN apk update && apk add --no-cache openssh vsftpd && \
        ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' && \
        ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N '' && \
        ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' && \
        ssh-keygen -A

RUN mkdir -p /home/web/wwwroot

RUN addgroup -g 5000 vuser

RUN adduser -h /home/web -s /bin/sh -u 5001 web -G vuser -D
RUN echo "web:--webpassword--" | chpasswd

# add ftp only user
# RUN adduser -h /home/ftpuser -s /bin/ftp -u 5002 ftpuser -G vuser -D
# RUN echo "ftpuser:--ftpuserpassword--" | chpasswd

RUN echo '/usr/sbin/sshd -f /etc/ssh/sshd_config' > /run.sh && \
    echo '/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf' >> /run.sh && \
chmod u+x /run.sh

ENTRYPOINT ["/bin/sh", "/run.sh"]
