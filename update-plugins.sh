#!/bin/bash
# updates the plugins (submodules)
set -euo pipefail
[ "${DEBUG:-0}" == "1" ] && set -x
thisDir=$(cd `dirname "$0"` && pwd)
bundleDir=$thisDir/dot-vim/bundle

isQuickMode=0
if [ ! -z "${1:-}" ]; then
  echo '[INFO] Quick mode enabled'
  isQuickMode=1
fi

echo "[INFO] updating plugins"
for curr in $(cd $bundleDir && ls); do
  [ $curr = "YouCompleteMe" ] && continue
  echo "Updating $curr"
  cd $bundleDir/$curr
  git pull &
done
wait # for parallel updates

# YouCompleteMe
if [ "$isQuickMode" == "1" ]; then
  # if we pull fresh stuff but don't build it, things break. So just don't touch anything
  echo '[INFO] skipping YCM build'
else
  echo '[INFO] processing YouCompleteMe'
  pushd $bundleDir/YouCompleteMe > /dev/null
  git submodule sync --recursive
  git submodule update --init --recursive
  # TODO only run following if changes are present
  # maybe by comparing `find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" "` before and after
  python install.py --java-completer
  popd > /dev/null
fi

# compile procvim.vim
echo '[INFO] processing vimproc'
pushd $bundleDir/vimproc.vim > /dev/null
make
popd > /dev/null

installPowerline () {
  pushd /tmp > /dev/null
  echo '[INFO] updating powerline fonts (fresh clone every time)'
  git clone https://github.com/powerline/fonts.git --depth=1
  cd fonts
  ./install.sh
  cd ..
  rm -fr fonts
  popd > /dev/null
}

if [ "$isQuickMode" == "1" ]; then
  echo '[INFO] skipping install/update of powerline fonts'
else
  installPowerline
fi
