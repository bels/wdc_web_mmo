/*
dropdb map_loader
createdb map_loader
createuser -P map
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
CREATE TABLE layer_tiles(lid uuid references layers(id), tiles uuid[]);
CREATE TABLE orientations(id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), description TEXT);
CREATE TABLE account (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), name TEXT NOT NULL, password TEXT NOT NULL, current_timezone smallint, account_created TIMESTAMP DEFAULT now());
CREATE TABLE avatars (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), path TEXT NOT NULL, description TEXT);

-- permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON maps TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON map_layers TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON layer_tiles TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON layer_types TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON tiles TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON orientations TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON layers TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON account TO map;
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
CREATE TYPE map_data AS (id uuid , lid uuid, tile_ids uuid[] );
CREATE TYPE layer_data AS (id uuid , name TEXT, x_size INTEGER, y_size INTEGER);

-- Functions
CREATE OR REPLACE FUNCTION get_map_data(mid_val uuid) RETURNS SETOF map_data AS $$
DECLARE
	j uuid;
	b uuid;
	i INTEGER;
	m map_data;
	tid uuid []; --tile ids
BEGIN
	i := 1;
	FOR j IN
		SELECT lid FROM map_layers WHERE "mid" = mid_val
	LOOP
		FOREACH b IN ARRAY (SELECT tiles FROM layer_tiles WHERE lid = j) LOOP
			--adds the new values to the tile data array, requires cast as tile data
			tid := array_append(tid,b);
		END LOOP;
			SELECT i, j,tid INTO m;
		RETURN NEXT m;
		tid := '{}'; --initializes the array.
		i := i + 1; --increment i
	END LOOP;
	RETURN;
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
	existing_map uuid;
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

CREATE OR REPLACE FUNCTION get_collision_data(mid_val uuid) RETURNS SETOF uuid AS $$
DECLARE
	layer_id uuid;
	tid uuid; --Tile id
	spot BIGINT;
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

CREATE TABLE npc_template (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
	name TEXT NOT NULL, 
	description TEXT, 
	sprite_id BIGINT, 
	hit_points BIGINT,
	mana BIGINT,
	strength INTEGER DEFAULT 1,
	agility INTEGER DEFAULT 1,
	dexterity INTEGER DEFAULT 1,
	stamina INTEGER DEFAULT 1,
	intelligence INTEGER DEFAULT 1,
	wisdom INTEGER DEFAULT 1,
	vitality INTEGER DEFAULT 1,
	luck INTEGER DEFAULT 1
);
CREATE TABLE npc_location(id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), npc_id UUID REFERENCES npc_template(id), "mid" uuid references maps(id), x INTEGER NOT NULL, y INTEGER NOT NULL, tile_id uuid references tiles(id) );

--Permissions

GRANT SELECT, INSERT, UPDATE, DELETE ON npc_template TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON npc_location TO map;

--Comments

COMMENT ON TABLE npc_location IS 'Lists the map and location on the map of a sprite.';
COMMENT ON COLUMN npc_template.sprite_id IS 'Sprite ID references the id column in the sprite table.';
COMMENT ON COLUMN npc_location."mid" IS 'Map ID';

-- types
CREATE TYPE npc_data AS (id uuid , x INTEGER, y INTEGER, sprite_path TEXT, offset_x INTEGER, offset_y INTEGER, tile_id uuid );
CREATE TYPE npc_template_data AS (id uuid , name TEXT, uuid UUID, sprite_path TEXT, offset_x INTEGER, offset_y INTEGER);

-- functions

CREATE OR REPLACE FUNCTION get_npc_position_data(mid_val uuid) RETURNS SETOF npc_data AS $$
DECLARE
	j INTEGER;
	nd npc_data;
BEGIN
	--loop over all the npcs on the map that are online
	FOR j IN 
		SELECT npc_location.id FROM npc_template JOIN npc_location ON npc_template.id = npc_location.npc_id WHERE "mid" = mid_val
	LOOP
		SELECT j,
		(SELECT x FROM npc_location WHERE npc_id = j AND "mid" = mid_val),
		(SELECT y FROM npc_location WHERE npc_id = j AND "mid" = mid_val), 
		(SELECT "path" FROM sprites WHERE id = (SELECT sprite_id FROM npc_template WHERE id = (SELECT npc_id FROM npc_location WHERE npc_location.id = j))),
		(SELECT offset_x FROM sprites WHERE id = (SELECT sprite_id FROM npc_template WHERE id = (SELECT npc_id FROM npc_location WHERE npc_location.id = j))),
		(SELECT offset_y FROM sprites WHERE id = (SELECT sprite_id FROM npc_template WHERE id = (SELECT npc_id FROM npc_location WHERE npc_location.id = j))),
		(SELECT tile_id FROM npc_location WHERE npc_id = j AND "mid" = mid_val)
		INTO nd;
		RETURN NEXT nd;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_npc(name_val TEXT,description_val TEXT,hp_val BIGINT,mp_val BIGINT,str_val INTEGER,agi_val INTEGER,dex_val INTEGER,sta_val INTEGER,int_val INTEGER,wis_val INTEGER,vit_val INTEGER,luck_val INTEGER, sprite_id_val uuid) RETURNS VOID AS $$
BEGIN
	INSERT INTO npc_template( name,
		description,
		sprite_id,
		hit_points,
		mana,
		strength,
		agility,
		dexterity,
		stamina,
		intelligence,
		wisdom,
		vitality,
		luck)
	VALUES (
		name_val,
		description_val,
		sprite_id_val,
		hp_val,
		mp_val,
		str_val,
		agi_val,
		dex_val,
		sta_val,
		int_val,
		wis_val,
		vit_val,
		luck_val
		);
	EXCEPTION WHEN not_null_violation THEN
		RAISE EXCEPTION 'NPC name missing';
	RETURN;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_npc_templates() RETURNS SETOF npc_template_data AS $$
DECLARE
	counter INTEGER;
	ntd npc_template_data;
BEGIN
	FOR counter IN
		SELECT id FROM npc_template
	LOOP
		SELECT npc_template.id ,
			npc_template.name ,
			npc_template.uuid ,
			sprites.path ,
			sprites.offset_x ,
			sprites.offset_y
			INTO ntd 
			FROM npc_template JOIN sprites ON npc_template.sprite_id = sprites.id WHERE npc_template.id = counter;
		RETURN NEXT ntd;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION save_spawn(type_val TEXT, id_val UUID, x_val INTEGER, y_val INTEGER, tile_id uuid, map_id_val uuid) RETURNS VOID AS $$
BEGIN
	IF type_val = 'creature' THEN
		INSERT INTO creature_location (creature_id,"mid",x,y,tile_id) VALUES (id_val,map_id_val,x_val,y_val,tile_id);
	ELSE
		INSERT INTO npc_location (npc_id,"mid",x,y,tile_id) VALUES (id_val,map_id_val,x_val,y_val,tile_id);
	END IF;
	RETURN;
END;
$$ LANGUAGE plpgsql;

-- Tables

CREATE TABLE spell_template(id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), name TEXT, "range" INTEGER DEFAULT 0, damage INTEGER, cast_time REAL, damage_over_time BOOLEAN DEFAULT FALSE);
CREATE TABLE spell_mapping(id UUID, spell_id uuid references spell_template(id));


-- Types

CREATE TYPE spell_data AS (id uuid , name TEXT, "range" INTEGER, damage INTEGER, cast_time REAL, damage_over_time BOOLEAN);

-- Functions

CREATE OR REPLACE FUNCTION add_spell(name_val TEXT) RETURNS VOID AS $$
BEGIN
	INSERT INTO spell_template(name) values (name_val);
	RETURN;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------

CREATE OR REPLACE FUNCTION add_spell(name_val TEXT, range_val INTEGER, damage_val INTEGER, dot_val BOOLEAN, cast_time_val REAL) RETURNS VOID AS $$
BEGIN
	INSERT INTO spell_template(name,"range",damage,damage_over_time,cast_time) values(name_val,range_val,damage_val,dot_val,cast_time);
	RETURN;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------


CREATE OR REPLACE FUNCTION get_spells_for_map(map_id_val uuid) RETURNS SETOF spell_data AS $$
DECLARE
	uuids_on_map UUID[];
	i UUID;
	sd spell_data;
BEGIN
	SELECT
			npct.id
		FROM
			npc_template npct
			INNER JOIN npc_location npcl
				ON npcl.npc_id = npct.id
		WHERE
			npcl."mid" = map_id_val
	UNION
	SELECT
			c.id
		FROM
			characters c 
			INNER JOIN character_location cl
				ON cl.character_id = c.id
		WHERE
			cl."mid" = map_id_val
	UNION
	SELECT
			ct.id
		FROM
			creature_template ct
			INNER JOIN creature_location cl
				ON cl.creature_id = ct.id
		WHERE
			cl."mid" = map_id_val
	INTO uuids_on_map;
	
	FOREACH i IN ARRAY uuids_on_map 
	LOOP
		SELECT * INTO sd FROM spell_template JOIN spell_mapping ON spell_mapping.spell_id = spell_template.id WHERE spell_mapping.id = i;
		RETURN NEXT sd;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

-- Tables
CREATE TABLE sprites(id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), description TEXT, path TEXT NOT NULL, offset_x INTEGER, offset_y INTEGER, x_size INTEGER, y_size INTEGER);

--Comments

COMMENT ON TABLE sprites IS 'Describes the available sprites.';
-- Permissions

GRANT SELECT, INSERT, UPDATE, DELETE ON sprites TO map;

-- Types

CREATE TYPE sprite_data AS (id uuid, description TEXT, "path" TEXT, offset_x INTEGER, offset_y INTEGER, x_size INTEGER, y_size INTEGER);


-- Functions
CREATE OR REPLACE FUNCTION add_sprite_data(description_val TEXT, path_val TEXT, offset_x_val INTEGER, offset_y_val INTEGER, x_val INTEGER, y_val INTEGER) RETURNS VOID AS $$
BEGIN
	INSERT INTO sprites(
		description,
		"path",
		offset_x,
		offset_y,
		x_size,
		y_size
	) VALUES (
		description_val,
		path_val,
		offset_x_val,
		offset_y_val,
		x_val,
		y_val
	);
	RETURN;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_all_available_sprites() RETURNS SETOF sprite_data AS $$
DECLARE
	counter BIGINT;
	sd sprite_data;
BEGIN
	FOR counter IN
		SELECT id FROM sprites
	LOOP
		SELECT * INTO sd FROM sprites WHERE id = counter;
		RETURN NEXT sd;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;


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


-- Tables

CREATE TABLE characters (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), pid uuid /*references players (id)*/, name TEXT NOT NULL, avatar uuid, sprite_id uuid references sprites(id) NOT NULL, "online" BOOLEAN DEFAULT FALSE);
CREATE TABLE character_location (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), character_id uuid REFERENCES characters(id), x INTEGER NOT NULL DEFAULT 1, y INTEGER NOT NULL DEFAULT 1, "mid" uuid references maps(id), tile_id uuid references tiles(id) );

-- Permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON character_location TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON characters TO map;

-- Types

CREATE TYPE character_position_data AS (id uuid, x INTEGER, y INTEGER, sprite_path TEXT, offset_x INTEGER, offset_y INTEGER, tile_id uuid  );
CREATE TYPE character_data AS (id uuid , name TEXT, "path" TEXT, offset_x TEXT, offset_y TEXT);

-- Comments

COMMENT ON COLUMN characters.sprite_id IS 'Sprite ID';

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

CREATE OR REPLACE FUNCTION set_character_location(character_val uuid, x_val INTEGER, y_val INTEGER, map_id_VAL uuid, tile_id_val uuid) RETURNS VOID AS $$
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
		(SELECT x FROM character_location WHERE character_id = j AND "mid" = mid_val),
		(SELECT y FROM character_location WHERE character_id = j AND "mid" = mid_val), 
		(SELECT "path" FROM sprites WHERE id = (SELECT sprite_id FROM characters WHERE id = (SELECT character_id FROM character_location WHERE character_location.id = j))),
		(SELECT offset_x FROM sprites WHERE id = (SELECT sprite_id FROM characters WHERE id = (SELECT character_id FROM character_location WHERE character_location.id = j))),
		(SELECT offset_y FROM sprites WHERE id = (SELECT sprite_id FROM characters WHERE id = (SELECT character_id FROM character_location WHERE character_location.id = j))),
		(SELECT tile_id FROM character_location WHERE character_id = j AND "mid" = mid_val),
		(SELECT uuid FROM characters WHERE id = j)
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

CREATE TABLE creature_template (
 id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
 name TEXT NOT NULL,
 description TEXT,
 sprite_id BIGINT,
 hit_points BIGINT,
 mana BIGINT,
 strength INTEGER DEFAULT 1,
 agility INTEGER DEFAULT 1,
 dexterity INTEGER DEFAULT 1,
 stamina INTEGER DEFAULT 1,
 intelligence INTEGER DEFAULT 1,
 wisdom INTEGER DEFAULT 1,
 vitality INTEGER DEFAULT 1,
 luck INTEGER DEFAULT 1);
CREATE TABLE creature_location (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), creature_id UUID REFERENCES creature_template(id), "mid" uuid references maps(id) not null, x INTEGER NOT NULL, y INTEGER NOT NULL, tile_id uuid references tiles(id) );

--permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON creature_template TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON creature_location TO map;

-- comments
COMMENT ON COLUMN creature_template.strength IS 'Used to determine damage along with weapon attack damage';
COMMENT ON COLUMN creature_template.agility IS 'Used to determine dodge and attack rate; possible impact on damage for certain classes';
COMMENT ON COLUMN creature_template.dexterity IS 'Used to determine attack chance; possible impact on damage for certain classes (eg. archer)';
COMMENT ON COLUMN creature_template.stamina IS 'Increases hit points from base hit points';
COMMENT ON COLUMN creature_template.hit_points IS 'Base hit points';
COMMENT ON COLUMN creature_template.mana IS 'Base mana';
COMMENT ON COLUMN creature_template.intelligence IS 'Increases mana points and impacts white magic type spells';
COMMENT ON COLUMN creature_template.wisdom IS 'Used to determine damage from black magic type spells';
COMMENT ON COLUMN creature_template.vitality IS 'Used in formula to determine armor/defense';
COMMENT ON COLUMN creature_template.luck IS 'Increases chance to dodge and critically land an attack';

-- types
CREATE TYPE creature_data AS (id uuid , x INTEGER, y INTEGER, sprite_path TEXT, offset_x INTEGER, offset_y INTEGER, tile_id uuid );
CREATE TYPE creature_template_data AS (id uuid , name TEXT, sprite_path TEXT, offset_x INTEGER, offset_y INTEGER);

-- functions

CREATE OR REPLACE FUNCTION get_creature_position_data(mid_val uuid) RETURNS SETOF creature_data AS $$
DECLARE
	j INTEGER;
	cd creature_data;
BEGIN
	--loop over all the creatures on the map that are online
	FOR j IN 
		SELECT creature_location.id FROM creature_template JOIN creature_location ON creature_template.id = creature_location.creature_id WHERE "mid" = mid_val
	LOOP
		SELECT j,
		(SELECT x FROM creature_location WHERE id = j AND "mid" = mid_val),
		(SELECT y FROM creature_location WHERE id = j AND "mid" = mid_val), 
		(SELECT "path" FROM sprites WHERE id = (SELECT sprite_id FROM creature_template WHERE id = (SELECT creature_id FROM creature_location WHERE creature_location.id = j))),
		(SELECT offset_x FROM sprites WHERE id = (SELECT sprite_id FROM creature_template WHERE id = (SELECT creature_id FROM creature_location WHERE creature_location.id = j))),
		(SELECT offset_y FROM sprites WHERE id = (SELECT sprite_id FROM creature_template WHERE id = (SELECT creature_id FROM creature_location WHERE creature_location.id = j))),
		(SELECT tile_id FROM creature_location WHERE id = j AND "mid" = mid_val)
		INTO cd;
		RETURN NEXT cd;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_creature(name_val TEXT,description_val TEXT,hp_val BIGINT,mp_val BIGINT,str_val INTEGER,agi_val INTEGER,dex_val INTEGER,sta_val INTEGER,int_val INTEGER,wis_val INTEGER,vit_val INTEGER,luck_val INTEGER, sprite_id_val uuid) RETURNS VOID AS $$
BEGIN
	INSERT INTO creature_template( name,
		description,
		sprite_id,
		hit_points,
		mana,
		strength,
		agility,
		dexterity,
		stamina,
		intelligence,
		wisdom,
		vitality,
		luck)
	VALUES (
		name_val,
		description_val,
		sprite_id_val,
		hp_val,
		mp_val,
		str_val,
		agi_val,
		dex_val,
		sta_val,
		int_val,
		wis_val,
		vit_val,
		luck_val
		);
	EXCEPTION WHEN not_null_violation THEN
		RAISE EXCEPTION 'Creature name missing';
	RETURN;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_creature_templates() RETURNS SETOF creature_template_data AS $$
DECLARE
	counter INTEGER;
	ctd creature_template_data;
BEGIN
	FOR counter IN
		SELECT id FROM creature_template
	LOOP
		SELECT creature_template.id ,
			creature_template.name ,
			creature_template.uuid ,
			sprites.path ,
			sprites.offset_x ,
			sprites.offset_y
			INTO ctd 
			FROM creature_template JOIN sprites ON creature_template.sprite_id = sprites.id WHERE creature_template.id = counter;
		RETURN NEXT ctd;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------------------------

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

do $$
DECLARE
	new_character_id uuid;
	map_id_val uuid;
BEGIN

	INSERT INTO characters(
			name,
			sprite_id
		) VALUES (
			'New Guy',
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

