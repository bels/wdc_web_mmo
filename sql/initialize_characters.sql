do $$
DECLARE
	new_character_id uuid;
	map_id_val uuid;
	account_id_val uuid;
BEGIN
	PERFORM create_map('Map1',1024,1024);
	INSERT INTO account(
		name,
		password
	) VALUES (
		'Test Account',
		'adslfkjlasjdfl'
	);
	
	select id into account_id_val from account limit 1;
	
	INSERT INTO characters(
			name,
			pid,
			sprite_id
		) VALUES (
			'New Guy',
			account_id_val,
			(select id from sprites where description = 'Player Avatar' limit 1)
		) returning id into new_character_id;

	select
			m.id into map_id_val
		from
			maps m
		limit 1;

	INSERT INTO character_location(
		character_id,
		"mid",
		x,
		y,
		tile_id
	) VALUES (
		new_character_id,
		map_id_val,
		1,
		1,
		1
	);
END;
$$ language plpgsql;