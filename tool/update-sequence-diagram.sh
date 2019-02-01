#!/usr/bin/env bash

DIR=$(cd $(dirname $0);pwd)

cd ${DIR}/../sequence-diagram

MMDC_CMD=$DIR/../node_modules/.bin/mmdc

mmd_list=(
    "from-owner-to-distributor"
    "from-distributor-to-user"
    "from-distributor-to-owner"
    "request-and-accept-token-transfer"
    "add-to-distributor"
    "delete-from-distributor"
)

for i in "${mmd_list[@]}"
do
    filename="${i}"
    ${MMDC_CMD} -i ${filename}.mmd -o ${filename}.svg
done

