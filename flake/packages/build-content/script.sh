#!/usr/bin/env bash

current_dir="$PWD"
zet_dir=${ZET_DIR:-"${current_dir}/zet"}
posts_src="${zet_dir}/posts/"
notes_src="${zet_dir}/notes/"
snotes_src="${zet_dir}/snotes/"
posts_dst="${current_dir}/content/posts/"
notes_dst="${current_dir}/content/notes/"
snotes_dst="${current_dir}/content/snotes/"

if [[ ! -d "${zet_dir}" ]]; then
    git clone --depth 1 git@github.com:hurricanehrndz/zet.git zet
else
    pushd "${zet_dir}" || exit 1
    git pull
    popd || exit 1
fi

if [[ ! -d "${posts_src}" ]] || [[ ! -d "${notes_src}" ]]; then
    printf "\e[0;31mSource directories missing\e[0m\n"
fi

rsync --recursive --delete --exclude '.gitkeep' "${posts_src}" "${posts_dst}"
rsync --recursive --delete --exclude '.gitkeep' "${notes_src}" "${notes_dst}"
# not running on github
if [[ ${CI} != 1 ]]; then
    rsync --recursive --delete --exclude '.gitkeep' "${snotes_src}" "${snotes_dst}"
fi

git checkout -- content

printf "\e[1;92mContent built from zet successfully\e[0m\n"
