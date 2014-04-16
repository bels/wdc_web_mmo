CREATE TABLE animation_template(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	offset_x INTEGER,
	offset_y INTEGER,
	x_size INTEGER,
	y_size INTEGER,
	name TEXT
);

GRANT SELECT, INSERT, UPDATE, DELETE ON animation_template TO map;

CREATE OR REPLACE FUNCTION add_animation(offset_x_val INTEGER, offset_y_val INTEGER, name_val TEXT, x_size_val INTEGER, y_size_val INTEGER) RETURNS VOID AS $$
BEGIN
	INSERT INTO animation_template(offset_x,offset_y,name,x_size,y_size) VALUES(offset_x_val,offset_y_val,name_val,x_size_val,y_size_val);
	RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_all_available_animations() RETURNS SETOF animation_template as $$
BEGIN
     RETURN QUERY
	  SELECT * FROM animation_template;
END;
$$ LANGUAGE plpgsql;