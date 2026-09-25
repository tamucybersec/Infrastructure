FROM hashicorp/terraform:1.9

RUN apk add --no-cache jq

WORKDIR /work
COPY stacks/ /work/stacks/

# Bake providers in so runs don't need internet access
RUN for dir in /work/stacks/*/; do \
      (cd "$dir" && terraform init -backend=false -input=false) || exit 1; \
    done

COPY scripts/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
