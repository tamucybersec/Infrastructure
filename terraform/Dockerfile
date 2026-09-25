FROM hashicorp/terraform:1.9

RUN apk add --no-cache jq

WORKDIR /work
COPY stacks/ stacks/

RUN for dir in stacks/*/; do \
      terraform -chdir="$dir" init -backend=false -input=false \
	  || exit 1; \
    done

COPY scripts/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
