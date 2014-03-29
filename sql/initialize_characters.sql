do $$
DECLARE
	new_character_id uuid;
	map_id_val uuid;
	account_id_val uuid;
BEGIN

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
			(select id from sprites limit 1)
		) returning id into new_character_id;

	select
			m.id into map_id_val
		from
			maps m
		limit 1;

	INSERT INTO character_location(
		character_id,
		"mid"
	) VALUES (
		new_character_id,
		map_id_val
	);
END;
$$ language plpgsql;