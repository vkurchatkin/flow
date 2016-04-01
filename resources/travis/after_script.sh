#!/bin/bash -e

if [[ "$TRAVIS_OS_NAME" = "osx" && "$TRAVIS_PULL_REQUEST" = "false" ]]; then

  TMP=${TMPDIR:-/tmp}
  SLUG_PLATFORM=$(uname -s || echo unknown)
  ARCH=$(uname -m || echo unknown)
  SLUG="ocaml-${OCAML_VERSION}_opam-${OPAM_VERSION}_${SLUG_PLATFORM}-${ARCH}"
  CACHE_ROOT="$HOME/.flow_cache"
  CACHE_TGZ="$TMP/$SLUG.tar.gz"

  printf "travis_fold:start:cache.2\nstore build cache\n"
  CHANGED=0
  if [ -f "$TMP/$SLUG.tar.gz" ]; then
    gzip -dc "$CACHE_TGZ" | tar --update -Pf - "$CACHE_ROOT" | gzip > "$CACHE_TGZ.tmp"
    mv "$CACHE_TGZ.tmp" "$CACHE_TGZ"
    if ! shasum -c "$CACHE_TGZ.sh1" >/dev/null; then
      CHANGED=1
    fi
  else
    tar -Pczf "$CACHE_TGZ" "$CACHE_ROOT"
    CHANGED=1
  fi
  if [ "$CHANGED" -eq 1 ]; then
    echo "uploading $TRAVIS_BRANCH/$SLUG.tar.gz"
    aws s3 cp --storage-class REDUCED_REDUNDANCY "$CACHE_TGZ" "s3://ci-cache.flowtype.org/$TRAVIS_BRANCH/$SLUG.tar.gz"
  else
    echo "nothing changed, not updating cache"
  fi
  printf "travis_fold:end:cache.2\n"
fi
