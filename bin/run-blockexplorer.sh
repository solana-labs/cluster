#!/bin/bash -ex

export GEOLOCATION_API_KEY=b101e8d9157645be9b212aa81f751ae6

cd ~

if [[ -f blockexplorer.pid ]]; then
  pgid=$(ps opgid= $(cat blockexplorer.pid) | tr -d '[:space:]')
  if [[ -n $pgid ]]; then
    kill -- -$pgid
  fi
fi
killall node || true
npm install @solana/blockexplorer@1
npx solana-blockexplorer apiNoProxy > blockexplorer.log 2>&1 &
echo $! > blockexplorer.pid
wait
