#!/usr/bin/env bash

# This script deletes openstack images which have the same name,
# keeping only the $KEEP_N most recent ones.
# If DO_DELETE=true the images will be deleted, otherwise only reported.

KEEP_N=${KEEP_N:-5}
FILTER_FLAGS=${FILTER_FLAGS:-""}

function get_dup_image_names () {
    openstack image list --sort name $FILTER_FLAGS -f value | \
        awk '{print $2}' | uniq -c | sed 's/^ *\([0-9]*\) /\1 /' | \
        awk '{if ($1 > '"$1"') {print $2}}'
}

function delete_image () {
    if [[ ${DO_DELETE:-no} == "true" ]]; then
        echo "Gonna delete image $1: $2"
        openstack image delete "$1" && echo "Deleted image $1: $2"
    else
        echo "Would delete image $1: $2"
    fi
}

function delete_all_but_n_latest_images () {
    skip=$(($1 + 1))
    for i in `openstack image list --name "$2" $FILTER_FLAGS -f value -c ID --sort created_at:desc | tail -n +$skip`; do
        delete_image "$i" "$2" || true
    done
}

for image in `get_dup_image_names ${KEEP_N}`; do
    delete_all_but_n_latest_images ${KEEP_N} $image
done
