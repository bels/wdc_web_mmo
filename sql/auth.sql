-- tables
CREATE TABLE account (
	id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
	name TEXT NOT NULL,
	password TEXT NOT NULL,
	current_timezone smallint,
	account_created TIMESTAMP DEFAULT now(),
	active BOOLEAN
);

-- permissions

GRANT SELECT, INSERT, UPDATE, DELETE ON account TO map;

CREATE OR REPLACE FUNCTION authenticate(username_val TEXT, password_val TEXT) RETURNS BOOLEAN AS $$
BEGIN


END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION register(username_val TEXT, password_val TEXT) RETURNS VOID AS $$
BEGIN

END;
$$ LANGUAGE plpgsql;