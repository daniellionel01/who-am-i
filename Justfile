set dotenv-load

export DBMATE_MIGRATIONS_DIR := "./priv/migrations"
export DBMATE_SCHEMA_FILE  := "./priv/schema.sql"

db-new name:
  dbmate new "{{name}}"

db-status:
  dbmate status

db-migrate:
  dbmate migrate

db-up:
  dbmate up

db-ide:
  #!/bin/bash
  db_path=$(echo "$DATABASE_URL" | sed -E 's|^sqlite:(//)?||')
  harlequin -a sqlite "$db_path"

default:
  @just --choose

dev:
  gleam dev

watch:
  watchexec \
    --restart --verbose --wrap-process=session --stop-signal SIGTERM \
    --exts gleam --debounce 500ms --watch src/ \
    -- "gleam run"

run:
  gleam run

build:
  just codegen
  gleam build

codegen:
  gleam run -m parrot -- --sqlite who_dev.db

audit:
  gleam run -m choire

tree:
  @tree -I '*.woff2|build|deps|.rebar3|ebin|.eunit|logs|*.beam|*.dump|.git|cover|doc|*.plt|*.crashdump|rel|.DS_Store'

export_:
  gleam export erlang-shipment
