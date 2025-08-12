-- name: get_game_by_id :one
select id, code, created_at
from game
where id = ?;
