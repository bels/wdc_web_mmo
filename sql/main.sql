/*
dropdb tower_wars
createdb tower_wars
createuser -P tower
PAssword1234!@#$ */

-- Load uuid
CREATE EXTENSION "uuid-ossp";

-- tables


CREATE TABLE maps(id uuid DEFAULT uuid_generate_v4() PRIMARY KEY , name TEXT NOT NULL, x_size INTEGER DEFAULT 1024, y_size INTEGER DEFAULT 1024);
CREATE TABLE layer_types(id int PRIMARY KEY, description TEXT);
CREATE TABLE layers(id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), name TEXT NOT NULL, layer_type int references layer_types(id), x_size INTEGER DEFAULT 32, y_size INTEGER DEFAULT 32);
CREATE TABLE map_layers("mid" uuid references maps(id), lid uuid references layers(id) );
CREATE TABLE tiles(
	id uuid PRIMARY KEY default uuid_generate_v4(),
	offset_x INTEGER,
	offset_y INTEGER,
	layer int references layer_types(id),
	description TEXT default 'You did not enter any name for this!',
	passable BOOLEAN,
	x_size INTEGER,
	y_size INTEGER
);
CREATE TABLE layer_tiles(lid uuid references layers(id), tiles uuid[] NOT NULL);
CREATE TABLE orientations(id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), description TEXT);
CREATE TABLE avatars (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), path TEXT NOT NULL, description TEXT);

-- permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON maps TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON map_layers TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON layer_tiles TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON layer_types TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON tiles TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON orientations TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON layers TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON avatars TO map;

-- starting data
-- Ground - tiles are always passable, overrides what is set in the tiles table for passable
-- Detail - sits ontop of ground should most time be passable but leaves that to the tiles table
-- Character - same layer as the character walks around in, leaves passability to tile table
-- Overlay - something that should cast a shadow and is most times passable but leaves that to the tile table, things are drawn behind things in this layer
-- Sky - everything drawn behind this layer, passable always
-- Lighting - just allows a change of colorization of everything
INSERT INTO layer_types(id,description) VALUES('1','Ground');
INSERT INTO layer_types(id,description) VALUES('2','Detail');
INSERT INTO layer_types(id,description) VALUES('3','Character');
INSERT INTO layer_types(id,description) VALUES('4','Overlay');
INSERT INTO layer_types(id,description) VALUES('5','Sky');
INSERT INTO layer_types(id,description) VALUES('6','Lighting');



INSERT INTO orientations(description) VALUES('North West');
INSERT INTO orientations(description) VALUES('North');
INSERT INTO orientations(description) VALUES('North East');
INSERT INTO orientations(description) VALUES('West');
INSERT INTO orientations(description) VALUES('Forward');
INSERT INTO orientations(description) VALUES('East');
INSERT INTO orientations(description) VALUES('South West');
INSERT INTO orientations(description) VALUES('South');
INSERT INTO orientations(description) VALUES('South East');

-- Database comments
COMMENT ON TABLE orientations IS 'This table holds the descriptions of what available orientations there are for sprites';
COMMENT ON TABLE maps IS 'This is a meta table that lists all the maps.';
COMMENT ON TABLE map_layers IS 'This is a meta table that lists all the layers in a map.';
COMMENT ON TABLE layer_types IS 'This is a meta table the describes the types a layer can be.';
COMMENT ON COLUMN layer_tiles.lid IS 'Layer ID';
COMMENT ON TABLE tiles IS 'Describes the available tiles.';
COMMENT ON TABLE avatars IS 'An avatar is a large image that could be used in a profile display or some other character display that is not the actual map/game';
COMMENT ON COLUMN tiles.offset_x IS 'This column tracks the horizontal placement in the sprite sheet for this tile. Since tiles are currently only 32px an offset of 1 would be the image at 33px in (1px for divider)';
COMMENT ON COLUMN tiles.offset_y IS 'This column tracks the vertical placement in the sprite sheet for this tile. Since tiles are currently only 32px an offset of 1 would be the image at 33px in (1px for divider)';
COMMENT ON COLUMN tiles.layer IS 'This is the id of what layer type this tile is for';


-- Types
CREATE TYPE map_data AS (lid uuid, tile_ids uuid [], layer_type INTEGER);
CREATE TYPE layer_data AS (id uuid , name TEXT, x_size INTEGER, y_size INTEGER);

-- Functions
CREATE OR REPLACE FUNCTION get_map_data(mid_val uuid)
  RETURNS SETOF map_data AS
$$
BEGIN
	RETURN QUERY SELECT m.lid, l.tiles, layers.layer_type
		FROM   map_layers  m
		JOIN   layer_tiles l USING (lid)
		JOIN	layers ON layers.id = m.lid
		WHERE  m.mid = mid_val;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION create_map(map_name TEXT, x_width INTEGER, y_height INTEGER) RETURNS VOID AS $$
BEGIN
	IF x_width < 0 THEN
		RAISE EXCEPTION 'Map did not create. Map: %', map_name
			USING HINT = 'Size values must be greater than 0';
	END IF;
	IF y_height < 0 THEN
		RAISE EXCEPTION 'Map did not create. Map: %', map_name
			USING HINT = 'Size values must be greater than 0';
	END IF;
	INSERT INTO maps (name, x_size, y_size) values(map_name, x_width, y_height);
	EXCEPTION WHEN not_null_violation THEN
		RAISE EXCEPTION 'Map name missing';
	RETURN;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_map_list() RETURNS SETOF maps AS $$
BEGIN
	RETURN QUERY
		SELECT * FROM maps;
	RETURN;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION save_layer(name_val TEXT,lid_val int, tile_data uuid[]) RETURNS VOID AS $$
DECLARE
	new_lid uuid;
BEGIN
	INSERT INTO layers (name,layer_type) VALUES (name_val,lid_val) returning id into new_lid;
	INSERT INTO layer_tiles (lid,tiles) VALUES (new_lid,tile_data);
	RETURN;
END;
$$ LANGUAGE plpgsql;


-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_available_layers(layer_type_val int) RETURNS SETOF layer_data AS $$
BEGIN
	RETURN QUERY 
		SELECT id, name, x_size, y_size FROM layers WHERE layer_type = layer_type_val;

END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION save_map(mid_val uuid, layers uuid[]) RETURNS VOID AS $$
DECLARE
	existing_map INTEGER;
BEGIN
	SELECT COUNT(*) INTO existing_map FROM map_layers WHERE "mid" = mid_val;
	IF existing_map > 0 THEN
		DELETE FROM map_layers WHERE "mid" = mid_val;
	END IF;
	INSERT INTO map_layers ("mid",lid) VALUES (mid_val,layers[1]);
	INSERT INTO map_layers ("mid",lid) VALUES (mid_val,layers[2]);
	INSERT INTO map_layers ("mid",lid) VALUES (mid_val,layers[3]);
	INSERT INTO map_layers ("mid",lid) VALUES (mid_val,layers[4]);
	INSERT INTO map_layers ("mid",lid) VALUES (mid_val,layers[5]);
	INSERT INTO map_layers ("mid",lid) VALUES (mid_val,layers[6]);
	
	RETURN;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_collision_data(mid_val uuid) RETURNS SETOF INTEGER AS $$
DECLARE
	layer_id uuid;
	tid uuid; --Tile id
	spot INTEGER;
	i INTEGER;
BEGIN
	FOR layer_id IN
		SELECT lid FROM map_layers WHERE "mid" = mid_val
	LOOP
		--resetting t
		i := 1;
		FOREACH tid IN ARRAY (SELECT tiles FROM layer_tiles WHERE lid = layer_id)
		LOOP
			IF (SELECT passable FROM tiles WHERE id = tid) IS NOT TRUE THEN
				RETURN NEXT i;
			END IF;
			i := i + 1;
		END LOOP;
	END LOOP;
	FOR spot IN
		SELECT tile_id FROM npc_location WHERE "mid" = mid_val
	LOOP
		RETURN NEXT spot;
	END LOOP;
	FOR spot IN
		SELECT tile_id FROM creature_location WHERE "mid" = mid_val
	LOOP
		RETURN NEXT spot;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;