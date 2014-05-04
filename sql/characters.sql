-- Tables

CREATE TABLE characters (
	id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
	pid uuid /*references players (id)*/, 
	name TEXT NOT NULL, 
	avatar uuid, 
	sprite_id uuid references sprites(id) NOT NULL, 
	"online" BOOLEAN DEFAULT FALSE,
	current_hitpoints BIGINT,
	current_mana BIGINT,
	max_hitpoints BIGINT,
	max_mana BIGINT,
	strength INTEGER DEFAULT 1,
	agility INTEGER DEFAULT 1,
	dexterity INTEGER DEFAULT 1,
	stamina INTEGER DEFAULT 1,
	intelligence INTEGER DEFAULT 1,
	wisdom INTEGER DEFAULT 1,
	vitality INTEGER DEFAULT 1,
	luck INTEGER DEFAULT 1,
	current_level INTEGER DEFAULT 1,
	starting_level INTEGER DEFAULT 1
);
CREATE TABLE character_location (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), character_id uuid REFERENCES characters(id), x INTEGER NOT NULL DEFAULT 1, y INTEGER NOT NULL DEFAULT 1, "mid" uuid references maps(id), tile_id INTEGER );

-- Permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON character_location TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON characters TO map;

-- Types

CREATE TYPE character_position_data AS (id uuid, character_id uuid, x INTEGER, y INTEGER, sprite_path TEXT, offset_x INTEGER, offset_y INTEGER, tile_id INTEGER  );
CREATE TYPE character_data AS (id uuid , name TEXT, "path" TEXT, offset_x TEXT, offset_y TEXT);

-- Comments

COMMENT ON COLUMN characters.sprite_id IS 'Sprite ID';
COMMENT ON COLUMN character_location.tile_id IS 'This id does not reference a certain type of tile that is stored in the database but instead it references the numbered ID on the map';

-- Functions

CREATE OR REPLACE FUNCTION create_character(id_val uuid, name_val TEXT, avatar_val uuid, sprite_id_val uuid) RETURNS VOID AS $$
BEGIN
	INSERT INTO characters(
		id,
		name,
		avatar,
		sprite_id
	) VALUES (
		id_val,
		name_val,
		avatar_val,
		sprite_id_val
	);
	RETURN;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_character_location(character_val uuid, map_id_val uuid) RETURNS VOID AS $$
BEGIN
	INSERT INTO character_location(
		character_id,
		"mid"
	) VALUES (
		character_val,
		map_id_val
	);
	
	RETURN;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_character_location(character_val uuid, x_val INTEGER, y_val INTEGER, map_id_VAL uuid, tile_id_val INTEGER) RETURNS VOID AS $$
BEGIN
	--this should update any existing entry in character locations or create one if one does not exist.
	UPDATE character_location SET 
		x = x_val,
		y = y_val,
		tile_id = tile_id_val
	WHERE
		character_id = character_val AND "mid" = map_id_val;
		
	INSERT INTO character_location(
		character_id,
		x,
		y,
		"mid",
		tile_id
	) SELECT
		character_val,
		x_val,
		y_val,
		map_id_val,
		tile_id_val
	WHERE NOT EXISTS (
		SELECT 1 FROM character_location WHERE character_id = character_val AND "mid" = map_id_val LIMIT 1
	);
	
	RETURN;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_character_position_data(mid_val uuid) RETURNS SETOF character_position_data AS $$
DECLARE
	j uuid;
	pd character_position_data;
BEGIN
	--loop over all the characters on the map that are online
	FOR j IN 
		SELECT characters.id FROM characters JOIN character_location ON characters.id = character_location.character_id WHERE "mid" = mid_val AND "online" IS TRUE
	LOOP
		SELECT j,
		(SELECT character_id FROM character_location WHERE character_id = j AND "mid" = mid_val),
		(SELECT x FROM character_location WHERE character_id = j AND "mid" = mid_val),
		(SELECT y FROM character_location WHERE character_id = j AND "mid" = mid_val), 
		(SELECT "path" FROM sprites WHERE id = (SELECT sprite_id FROM characters WHERE id = (SELECT character_id FROM character_location WHERE character_location.character_id = j))),
		(SELECT offset_x FROM sprites WHERE id = (SELECT sprite_id FROM characters WHERE id = (SELECT character_id FROM character_location WHERE character_location.character_id = j))),
		(SELECT offset_y FROM sprites WHERE id = (SELECT sprite_id FROM characters WHERE id = (SELECT character_id FROM character_location WHERE character_location.character_id = j))),
		(SELECT tile_id FROM character_location WHERE character_id = j AND "mid" = mid_val),
		(SELECT id FROM characters WHERE id = j)
		INTO pd;
		RETURN NEXT pd;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_character_list(pid_val uuid) RETURNS SETOF character_data AS $$
DECLARE
	cd character_data;
BEGIN
	FOR cd IN
		SELECT characters.id,characters.name,sprites."path",sprites.offset_x,sprites.offset_y FROM characters JOIN sprites ON characters.sprite_id = sprites.id WHERE pid = pid_val ORDER BY characters.name
	LOOP
		RETURN NEXT cd;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_character_info(char_val uuid) RETURNS SETOF characters AS $$
BEGIN
	RETURN QUERY
		SELECT * FROM characters WHERE id = char_val;
END;
$$ LANGUAGE plpgsql;