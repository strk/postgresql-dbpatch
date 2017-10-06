#!/bin/sh

TGT_SCHEMA=
TGT_DB=
EXT_MODE=on
EXT_NAME=dbpatch
EXT_DIR=`pg_config --sharedir`/extension/
VER=`grep default_version ${EXT_DIR}/${EXT_NAME}.control | sed "s/[^']*'//;s/'.*//"`
TPL_FILE=${EXT_DIR}/${EXT_NAME}-${VER}.sql.tpl


while test -n "$1"; do
  if test "$1" = "--no-extension"; then
    EXT_MODE=off
  elif test "$1" = "--version"; then
    VER=$1; shift
  elif test -z "${TGT_DB}"; then
    TGT_DB=$1
  elif test -z "${TGT_SCHEMA}"; then
    TGT_SCHEMA=$1
  else
    echo "Unused argument $1" >&2
  fi
  shift
done

if test -z "$TGT_DB"; then
  echo "Usage: $0 [--no-extension] [--version <ver>] <dbname> [<schema>]" >&2
  exit 1
fi

export PGDATABASE=$TGT_DB

if test -z "$TGT_SCHEMA"; then
  TGT_SCHEMA=`psql -tAc "select current_schema()"`
  if test -z "$TGT_SCHEMA"; then exit 1; fi # failed connection to db ?
fi

echo "Loading ver ${VER} in ${TGT_DB}.${TGT_SCHEMA} (EXT_MODE ${EXT_MODE})";

if test "${EXT_MODE}" = 'on'; then
  psql -tAc "CREATE EXTENSION ${EXT_NAME} VERSION '${VER}' SCHEMA ${TGT_SCHEMA}"
else
  cat ${TPL_FILE} | sed "s/@extschema@/${TGT_SCHEMA}/g" |
  psql --set ON_ERROR_STOP=1 > /dev/null
fi
