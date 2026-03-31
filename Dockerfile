FROM ubuntu:22.04

ARG USERNAME=ai-ks
ARG USERUID
ARG USERGID

ENV USERNAME=${USERNAME}
ENV USERUID=${USERUID}
ENV USERGID=${USERGID}
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server nodejs npm \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

RUN set -eux; \
    test -n "${USERNAME}" || (echo "ERROR: missing build arg USERNAME. 运行 ./tf_apply.sh 或传入 -var username=..." >&2; exit 1); \
    test -n "${USERUID}" || (echo "ERROR: missing build arg USERUID. 运行 ./tf_apply.sh 或传入 -var user_uid=..." >&2; exit 1); \
    test -n "${USERGID}" || (echo "ERROR: missing build arg USERGID. 运行 ./tf_apply.sh 或传入 -var user_gid=..." >&2; exit 1); \
    groupadd -g "${USERGID}" "${USERNAME}"; \
    useradd -m -c "user ${USERNAME}" -u "${USERUID}" -g "${USERGID}" -s /bin/bash "${USERNAME}"

RUN npm install -g @anthropic-ai/claude-code && npm install -g @z_ai/coding-helper

# 复制 bashrc 到用户目录
COPY bashrc /home/${USERNAME}/.bashrc
RUN chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

COPY container_start.sh /usr/local/bin/container_start.sh
RUN chmod +x /usr/local/bin/container_start.sh

EXPOSE 22
CMD ["/usr/local/bin/container_start.sh"]

