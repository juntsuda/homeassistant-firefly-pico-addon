# Wraps the upstream, prebuilt Firefly-Pico image (https://github.com/cioraneanu/firefly-pico)
# rather than rebuilding it from source — same pattern as this host's other wrapped-image
# add-ons. Runs as root (see run.sh) to do setup (SQLite persistence under /data, injecting
# Supervisor options as env vars) and to run supervisord itself — each of its managed
# programs still drops to the image's own www-data user via its own `user=` directive.
FROM cioraneanu/firefly-pico:1.12.0

USER root

RUN apk add --no-cache bash jq

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
CMD ["run"]
