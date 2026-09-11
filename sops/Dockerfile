FROM ghcr.io/getsops/sops:v3.13.3

COPY scripts/decrypt.sh scripts/encrypt.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/decrypt.sh /usr/local/bin/encrypt.sh

ENV SOPS_AGE_KEY_FILE=/age.key
WORKDIR /work

ENTRYPOINT []
