select * from add_sprite_data(
	'Starter Sprite',
	'/images/sprites.png',
	'0',
	'0',
	32,
	32
);

select * from add_sprite_data(
	'Blob',
	'/images/sprites.png',
	'33',
	'0',
	32,
	32
);

select * from add_sprite_data(
	'Fighter',
	'/images/sprites.png',
	'66',
	'0',
	32,
	32
);

select * from add_sprite_data(
	'Player Avatar',
	'/images/avatar1.png',
	'0',
	'0',
	32,
	32,
);

select * from add_animation(0,0,'Fireball');