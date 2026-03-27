FROM ubuntu:22.04

ARG USERNAME=ks
ARG USERUID=1000
ARG SSH_PORT=2222

ENV USERNAME=${USERNAME}
ENV USERUID=${USERUID}
ENV SSH_PORT=${SSH_PORT}
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

RUN useradd -m -c "CVTE ${USERNAME}" -u "${USERUID}" -s /bin/sh "${USERNAME}" \
    && sh -c 'passwd="${USERNAME}"; if [ "$USERNAME" = "devops" ]; then passwd="devops-${SSH_PORT}"; fi; case "$passwd" in *user*) ;; *) i=32; while [ "$i" -gt 0 ]; do passwd=$(printf "%s" "${passwd}ai" | md5sum); i=$((i - 1)); done; passwd=$(printf "%s" "$passwd" | cut -c1-8);; esac; printf "%s:%s\n" "${USERNAME}" "${passwd}" | chpasswd'

COPY container_start.sh /usr/local/bin/container_start.sh
RUN chmod +x /usr/local/bin/container_start.sh

EXPOSE 22
CMD ["/usr/local/bin/container_start.sh"]
