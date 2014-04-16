CREATE TABLE spell_template(id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), name TEXT, "range" INTEGER DEFAULT 0, description TEXT NOT NULL, damage INTEGER, cast_time REAL, damage_over_time BOOLEAN DEFAULT FALSE, animation UUID references animation_template(id));
CREATE TABLE spell_mapping(spell_entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), entity_id UUID, spell_id uuid references spell_template(id));

-- Permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON spell_template TO map;
GRANT SELECT, INSERT, UPDATE, DELETE ON spell_mapping TO map;

-- Types

CREATE TYPE spell_data AS (spell_entry_id UUID, entity_id UUID, type TEXT, name TEXT, "range" INTEGER, damage INTEGER, cast_time REAL, damage_over_time BOOLEAN,animation_offset_x INTEGER,animation_offset_y INTEGER, animation_name TEXT);
CREATE TYPE spell AS (spell_entry_id UUID, name TEXT, "range" INTEGER, damage INTEGER, cast_time REAL, damage_over_time BOOLEAN, animation_id UUID);
CREATE TYPE uuids_on_map AS (id UUID, entity_id_val UUID, type TEXT);

-- Functions

CREATE OR REPLACE FUNCTION add_spell(name_val TEXT, description_val TEXT) RETURNS VOID AS $$
BEGIN
	INSERT INTO spell_template(name,description) values (name_val,description_val);
	RETURN;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------

CREATE OR REPLACE FUNCTION add_spell(name_val TEXT, description_val TEXT, range_val INTEGER, damage_val INTEGER, dot_val BOOLEAN, cast_time_val REAL,animation_val UUID) RETURNS VOID AS $$
BEGIN
	INSERT INTO spell_template(name,description,"range",damage,damage_over_time,cast_time,animation) values(name_val,description_val,range_val,damage_val,dot_val,cast_time_val,animation_val);
	RETURN;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------


CREATE OR REPLACE FUNCTION get_spells_for_map(map_id_val uuid) RETURNS SETOF spell_data AS $$
DECLARE
	i uuids_on_map%rowtype; -- just a counter
	j UUID; -- just a counter
	sd spell_data%rowtype;
BEGIN
	FOR i IN 
		SELECT c.id, c.character_id AS entity_id_val, 'character'
			FROM character_location c
			WHERE c."mid" = map_id_val
		UNION
		SELECT n.id, n.npc_id AS entity_id_val, 'npc'
			FROM npc_location n
			WHERE n."mid" = map_id_val
		UNION
		SELECT cr.id, cr.creature_id AS entity_id_val, 'creature'
			FROM creature_location cr
			WHERE cr."mid" = map_id_val
	LOOP
		FOR j IN
			SELECT spell_id FROM spell_mapping WHERE entity_id = i.entity_id_val
		LOOP
			SELECT j,
				i.id,
				i.type,
				spell_template.name, 
				spell_template."range", 
				spell_template.damage, 
				spell_template.cast_time, 
				spell_template.damage_over_time,
				animation_template.offset_x,
				animation_template.offset_y, 
				animation_template.name 
				INTO sd 
				FROM spell_template 
				JOIN spell_mapping ON spell_mapping.spell_id = spell_template.id 
				JOIN animation_template ON spell_template.animation = animation_template.id 
				WHERE spell_template.id = j;
			RETURN NEXT sd;
		END LOOP;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------

CREATE OR REPLACE FUNCTION get_all_spells() RETURNS SETOF spell AS $$
BEGIN
	RETURN QUERY SELECT
		spell_template.id,
		spell_template.name,
		spell_template."range",
		spell_template.damage,
		spell_template.cast_time,
		spell_template.damage_over_time,
		spell_template.animation
		FROM spell_template;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------

CREATE OR REPLACE FUNCTION save_spell_mapping(spell_id_val UUID, entity_id_val UUID) RETURNS TEXT AS $$
DECLARE
	name_val TEXT;
BEGIN
	INSERT INTO spell_mapping (entity_id, spell_id) VALUES (entity_id_val,spell_id_val);
	SELECT name INTO name_val FROM spell_template WHERE id = spell_id_val;
	RETURN name_val;
END;
$$ LANGUAGE plpgsql;