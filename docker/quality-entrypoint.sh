#!/bin/sh
set -eu
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=/opt/flutter
# Only a fresh disposable container copy is writable; the checkout is never mounted.
cp -a /app /tmp/client-work
rm -rf /tmp/client-work/coverage
ln -s /app/coverage /tmp/client-work/coverage
cd /tmp/client-work
exec "$@"
