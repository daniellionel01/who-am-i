-- migrate:up

create table game (
  id text primary key,
  code text not null unique,
  created_at text not null default (datetime('now')),
  ended_at text,
  current_round_id text,
  foreign key (current_round_id) references round(id)
);

create index idx_game_code on game(code);

create table player (
  id text primary key,
  game_id text not null,
  name text not null,
  is_host integer not null default 0,
  foreign key (game_id) references game(id)
);

create index idx_player_game_id on player(game_id);

create table round (
  id text primary key,
  game_id text not null,
  created_at text not null default (datetime('now')),
  foreign key (game_id) references game(id)
);

create index idx_round_game_id on round(game_id);

create table player_assignment (
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

create index idx_assignment_round_id on player_assignment(round_id);
create index idx_assignment_assigned_id on player_assignment(assigned_id);
create index idx_assignment_assigning_id on player_assignment(assigning_id);

-- migrate:down

drop index if exists idx_assignment_assigning_id;
drop index if exists idx_assignment_assigned_id;
drop index if exists idx_assignment_round_id;
drop table if exists player_assignment;

drop index if exists idx_round_game_id;
drop table if exists round;

drop index if exists idx_player_game_id;
drop table if exists player;

drop index if exists idx_game_code;
drop table if exists game;
