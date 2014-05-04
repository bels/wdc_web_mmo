CREATE TABLE npc_template (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
	name TEXT NOT NULL, 
	description TEXT, 
	sprite_id UUID, 
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
CREATE TABLE npc_location(id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), npc_id UUID REFERENCES npc_template(id), "mid" uuid references maps(id), x INTEGER NOT NULL, y INTEGER NOT NULL, tile_id INTEGER );

--Permissions

GRANT SELECT, INSERT, UPDATE, DELETE ON npc_template TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON npc_location TO map;

--Comments

COMMENT ON TABLE npc_location IS 'Lists the map and location on the map of a sprite.';
COMMENT ON COLUMN npc_template.sprite_id IS 'Sprite ID references the id column in the sprite table.';
COMMENT ON COLUMN npc_location."mid" IS 'Map ID';
COMMENT ON COLUMN npc_location.tile_id IS 'This id does not reference a certain type of tile that is stored in the database but instead it references the numbered ID on the map';

-- types
CREATE TYPE npc_data AS (id uuid , npc_id uuid, x INTEGER, y INTEGER, sprite_path TEXT, offset_x INTEGER, offset_y INTEGER, tile_id INTEGER );
CREATE TYPE npc_template_data AS (id uuid , name TEXT, sprite_path TEXT, offset_x INTEGER, offset_y INTEGER);

-- functions

CREATE OR REPLACE FUNCTION get_npc_position_data(mid_val uuid) RETURNS SETOF npc_data AS $$
DECLARE
	j UUID;
	nd npc_data;
BEGIN
	--loop over all the npcs on the map that are online
	FOR j IN 
		SELECT npc_location.id FROM npc_template JOIN npc_location ON npc_template.id = npc_location.npc_id WHERE "mid" = mid_val
	LOOP
		SELECT j,
		(SELECT npc_template.id FROM npc_template JOIN npc_location ON npc_template.id = npc_location.npc_id WHERE npc_location.id = j),
		(SELECT x FROM npc_location WHERE id = j AND "mid" = mid_val),
		(SELECT y FROM npc_location WHERE id = j AND "mid" = mid_val), 
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
	counter UUID;
	ntd npc_template_data;
BEGIN
	FOR counter IN
		SELECT id FROM npc_template
	LOOP
		SELECT
			npc_template.id ,
			npc_template.name ,
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