CREATE TABLE live_entities(
	id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
	"mid" uuid NOT NULL,
	entity_id uuid NOT NULL,
	tile_id INTEGER NOT NULL,
	x INTEGER NOT NULL,
	y INTEGER NOT NULL,
	spawn_location_id uuid NOT NULL,
	type TEXT NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON live_entities TO map;

-- COMMENTS
COMMENT ON TABLE live_entities IS 'This table keeps track of entities that are live on the map.  Once an entity is destroyed it is removed from the table';

-- FUNCTIONS

CREATE OR REPLACE FUNCTION save_spawn(type_val TEXT, id_val UUID, x_val INTEGER, y_val INTEGER, tile_id INTEGER, map_id_val uuid) RETURNS VOID AS $$
BEGIN
	-- this function saves a spawn location
	IF type_val = 'creature' THEN
		INSERT INTO creature_location (creature_id,"mid",x,y,tile_id) VALUES (id_val,map_id_val,x_val,y_val,tile_id);
	ELSE
		INSERT INTO npc_location (npc_id,"mid",x,y,tile_id) VALUES (id_val,map_id_val,x_val,y_val,tile_id);
	END IF;
	RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION spawn_entity(type_val TEXT, entity_id_val UUID, spawn_location_id_val UUID, x_val INTEGER, y_val INTEGER, tile_id_val INTEGER, map_id_val UUID) RETURNS VOID AS $$
BEGIN
	-- this function creates a new entity on a map
	INSERT INTO live_entities("mid", entity_id, tile_id, x,	y, spawn_location_id, type) VALUES(map_id_val,entity_id_val,tile_id_val,x_val,y_val,spawn_location_id_val,type_val);
	RETURN;
END;
$$ LANGUAGE plpgsql;