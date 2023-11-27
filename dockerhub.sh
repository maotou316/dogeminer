#!/bin/bash

target_image="maotou/unmineable"

tag_a="latest"
tag_b="1.0.0"
sudo docker build --pull --rm -f "Dockerfile" -t "${target_image}:${tag_a}" -t "${target_image}:${tag_b}" "." --progress=plain --no-cache
sudo docker push --all-tags "${target_image}"