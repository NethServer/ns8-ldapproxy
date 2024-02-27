#!/bin/bash

set -e
images=()
repobase="${REPOBASE:-ghcr.io/nethserver}"

reponame="ldapproxy-app"
container=$(buildah from docker.io/library/nginx:1.25.3-alpine)
buildah run "${container}" /bin/sh <<'EOF'
set -e
apk add --no-cache ca-certificates
EOF
# Commit the image
buildah commit --rm "${container}" "${repobase}/${reponame}"
# Append the image URL to the images array
images+=("${repobase}/${reponame}")

reponame="ldapproxy"
container=$(buildah from scratch)

buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui /ui
buildah config \
    --label='org.nethserver.tcp-ports-demand=8' \
    --label='org.nethserver.flags=core_module no_data_backup' \
    --label="org.nethserver.images=${repobase}/ldapproxy-app:${IMAGETAG:-latest}" \
    --entrypoint=/ "${container}"
buildah commit "${container}" "${repobase}/${reponame}"
images+=("${repobase}/${reponame}")

#
#
#

if [[ -n "${CI}" ]]; then
    # Set output value for Github Actions
    printf "::set-output name=images::%s\n" "${images[*]}"
else
    printf "Publish the images with:\n\n"
    for image in "${images[@]}"; do printf "  buildah push %s docker://%s:latest\n" "${image}" "${image}" ; done
    printf "\n"
fi
