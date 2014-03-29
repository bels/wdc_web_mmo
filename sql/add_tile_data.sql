create or replace function add_tile_data(offset_x_val int, offset_y_val int, layer_type_id_val int, description_val text, passable_val boolean, x_size_val int, y_size_val int) returns void as $$
BEGIN

insert into tiles (
	offset_x,
	offset_y,
	layer,
	description,
	passable,
	x_size,
	y_size
) values (
	offset_x_val,
	offset_y_val,
	layer_type_id_val,
	description_val,
	passable_val,
	x_size_val,
	y_size_val
);

END;
$$ language plpgsql;
