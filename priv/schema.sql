CREATE TABLE IF NOT EXISTS "schema_migrations" (version varchar(128) primary key);
CREATE TABLE game (
  id text primary key,
  code text not null unique,
  created_at text not null default (datetime('now')),
  ended_at text,
  current_round_id text,
  foreign key (current_round_id) references round(id)
);
CREATE TABLE player (
  id text primary key,
  game_id text not null,
  name text not null,
  is_host integer not null default 0,
  foreign key (game_id) references game(id)
);
CREATE TABLE round (
  id text primary key,
  game_id text not null,
  created_at text not null default (datetime('now')),
  foreign key (game_id) references game(id)
);
CREATE TABLE player_assignment (
  id text primary key,
  round_id text not null,
  assigned_id text not null,
  assigning_id text not null,
  identity text not null,
  foreign key (round_id) references round(id),
  foreign key (assigned_id) references player(id),
  foreign key (assigning_id) references player(id),
  unique (round_id, assigned_id)
);
-- Dbmate schema migrations
INSERT INTO "schema_migrations" (version) VALUES
  ('20250812095525');
