# |source| me

if [[ -z $GRAFANA_API_TOKEN ]]; then
  echo Error: GRAFANA_API_TOKEN not defined
  exit 1
fi
export GRAFANA_API_TOKEN

if [[ ! -r venv/.ok ]]; then
  rm -rf venv
  (
    set -x
    python3 -m venv venv
  )
  # shellcheck source=/dev/null
  source venv/bin/activate

  (
    set -x
    git clone git@github.com:mvines/grafcli.git -b experimental-v5 venv/grafcli
    cd venv/grafcli
    python3 setup.py install
  )

  touch venv/.ok
else
  # shellcheck source=/dev/null
  source venv/bin/activate
fi

