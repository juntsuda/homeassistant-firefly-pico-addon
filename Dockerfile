# Wraps the upstream, prebuilt Firefly-Pico image (https://github.com/cioraneanu/firefly-pico)
# rather than rebuilding it from source — same pattern as this host's other wrapped-image
# add-ons. su-exec lets the entrypoint do root-only setup (SQLite persistence under /data,
# injecting Supervisor options as env vars) and then drop back to the image's own www-data
# user before handing off, matching upstream's own privilege model exactly.
FROM cioraneanu/firefly-pico:1.12.0

USER root

RUN apk add --no-cache bash jq su-exec

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
CMD ["run"]
