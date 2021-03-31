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
  echo "Updating $curr"
  cd $bundleDir/$curr
  bash -c 'git clean -fd && git checkout master && git pull' & # FIXME might need to checkout main instead
done
wait # for parallel updates

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
