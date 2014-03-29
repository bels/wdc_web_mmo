
create type tile_info as (
	tile_id uuid,
	layer_type_id int,
	layer_name text,
	description text,
	passable boolean,
	offset_x int,
	offset_y int,
	x_size int,
	y_size int
);

create or replace function tile_info_from_layer_type_id(layer_type_id_val int) returns setof tile_info as $$
BEGIN
	return query
		select
				t.id as tile_id,
				t.layer as layer_type_id,
				lt.description as layer_name,
				t.description,
				t.passable,
				t.offset_x,
				t.offset_y,
				t.x_size,
				t.y_size
			from
				tiles t
				inner join layer_types lt 
					on t.layer = lt.id
			where
				lt.id = layer_type_id_val
		;
END;
$$ language plpgsql;