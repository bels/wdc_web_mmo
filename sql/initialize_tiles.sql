
-- Ground layer
select * from add_tile_data(
	'0',
	'0',
	(select id from layer_types where description = 'Ground'),
	'Blank',
	true,
	'32',
	'32'
);


select * from add_tile_data(
	'33',
	'0',
	(select id from layer_types where description = 'Ground'),
	'Grass',
	true,
	'32',
	'32'
);


-- Detail layer
select * from add_tile_data(
	'0',
	'0',
	(select id from layer_types where description = 'Detail'),
	'Blank',
	true,
	'32',
	'32'
);


select * from add_tile_data(
	'33',
	'0',
	(select id from layer_types where description = 'Detail'),
	'Grass',
	true,
	'32',
	'32'
);


-- Character layer
select * from add_tile_data(
	'0',
	'0',
	(select id from layer_types where description = 'Character'),
	'Blank',
	true,
	'32',
	'32'
);

select * from add_tile_data(
	'33',
	'0',
	(select id from layer_types where description = 'Character'),
	'Tree',
	false,
	'32',
	'32'
);
select * from add_tile_data(
	'66',
	'0',
	(select id from layer_types where description = 'Character'),
	'Wall',
	false,
	'32',
	'32'
);

-- Overlay layer

select * from add_tile_data(
	'0',
	'0',
	(select id from layer_types where description = 'Overlay'),
	'Blank',
	true,
	'32',
	'32'
);

select * from add_tile_data(
	'33',
	'0',
	(select id from layer_types where description = 'Overlay'),
	'Bird',
	true,
	'32',
	'32'
);

-- Sky layer

select * from add_tile_data(
	'0',
	'0',
	(select id from layer_types where description = 'Sky'),
	'Blank',
	true,
	'32',
	'32'
);

select * from add_tile_data(
	'33',
	'0',
	(select id from layer_types where description = 'Sky'),
	'Cloud',
	true,
	'32',
	'32'
);

-- Lighting layer

select * from add_tile_data(
	'0',
	'0',
	(select id from layer_types where description = 'Lighting'),
	'Blank',
	true,
	'32',
	'32'
);


select * From tiles;