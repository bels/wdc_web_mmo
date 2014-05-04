CREATE TABLE creature_template (
	id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
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
 
CREATE TABLE creature_location (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), creature_id UUID REFERENCES creature_template(id), "mid" uuid references maps(id) not null, x INTEGER NOT NULL, y INTEGER NOT NULL, tile_id INTEGER );

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
COMMENT ON COLUMN creature_location.tile_id IS 'This id does not reference a certain type of tile that is stored in the database but instead it references the numbered ID on the map';

-- types
CREATE TYPE creature_data AS (id uuid , creature_id uuid, x INTEGER, y INTEGER, sprite_path TEXT, offset_x INTEGER, offset_y INTEGER, tile_id INTEGER );
CREATE TYPE creature_template_data AS (id uuid , name TEXT, sprite_path TEXT, offset_x INTEGER, offset_y INTEGER);

-- functions

CREATE OR REPLACE FUNCTION get_creature_position_data(mid_val uuid) RETURNS SETOF creature_data AS $$
DECLARE
	j UUID;
	cd creature_data;
BEGIN
	--loop over all the creatures on the map that are online
	FOR j IN 
		SELECT creature_location.id FROM creature_template JOIN creature_location ON creature_template.id = creature_location.creature_id WHERE "mid" = mid_val
	LOOP
		SELECT j,
		(SELECT creature_template.id FROM creature_template JOIN creature_location ON creature_template.id = creature_location.creature_id WHERE creature_location.id = j),
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
	counter UUID;
	ctd creature_template_data;
BEGIN
	FOR counter IN
		SELECT id FROM creature_template
	LOOP
		SELECT
			creature_template.id ,
			creature_template.name ,
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