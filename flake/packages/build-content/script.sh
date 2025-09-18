#!/usr/bin/env bash

current_dir="$PWD"
zet_dir="${current_dir}/zet"
posts_src="${zet_dir}/posts/"
notes_src="${zet_dir}/notes/"
snotes_src="${zet_dir}/snotes/"
posts_dst="${current_dir}/content/posts/"
notes_dst="${current_dir}/content/notes/"

if [[ ${CI:-0} == 0 ]]; then
    rm -rf zet
    ln -sf "${HOME}/zet" zet
fi

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
if [[ ${CI:-0} == 0 ]]; then
    rsync --recursive --exclude '.gitkeep' "${snotes_src}/" "${notes_dst}/"
fi

git checkout -- content

printf "\e[1;92mContent built from zet successfully\e[0m\n"
