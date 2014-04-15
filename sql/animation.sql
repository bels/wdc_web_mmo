CREATE TABLE animation_template(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	offset_x INTEGER,
	offset_y INTEGER,
	name TEXT
);

GRANT SELECT, INSERT, UPDATE, DELETE ON animation_template TO map;

CREATE OR REPLACE FUNCTION add_animation(offset_x_val INTEGER, offset_y_val INTEGER, name_val TEXT) RETURNS VOID AS $$
BEGIN
	INSERT INTO animation_template(offset_x,offset_y,name) VALUES(offset_x_val,offset_y_val,name_val);
	RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_all_available_animations() RETURNS SETOF animation_template as $$
BEGIN
     RETURN QUERY
	  SELECT * FROM animation_template;
END;
$$ LANGUAGE plpgsql;