CREATE OR REPLACE FUNCTION save_spawn(type_val TEXT, id_val UUID, x_val INTEGER, y_val INTEGER, tile_id INTEGER, map_id_val uuid) RETURNS VOID AS $$
BEGIN
	IF type_val = 'creature' THEN
		INSERT INTO creature_location (creature_id,"mid",x,y,tile_id) VALUES (id_val,map_id_val,x_val,y_val,tile_id);
	ELSE
		INSERT INTO npc_location (npc_id,"mid",x,y,tile_id) VALUES (id_val,map_id_val,x_val,y_val,tile_id);
	END IF;
	RETURN;
END;
$$ LANGUAGE plpgsql;