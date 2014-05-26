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
	counter UUID;
	sd sprite_data;
BEGIN
	FOR counter IN
		SELECT id FROM sprites WHERE path = '/images/sprites.png'
	LOOP
		SELECT * INTO sd FROM sprites WHERE id = counter;
		RETURN NEXT sd;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;