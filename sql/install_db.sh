#!/usr/bin/evn bash

dropdb map_loader 2>/dev/null # no existing DB is an expected error, do not warn
createdb map_loader
nouser=$(psql map_loader <<<"select count(*) t from pg_roles where rolname = 'map';" | sed -n '3s/ *//p')
if [ "$nouser" -eq 0 ] ; then
	echo creating map database user...
	createuser -P map
	psql map_loader <<'SQL'
alter user map with password 'PAssword1234!@#$';
SQL
fi

psql map_loader < ./main.sql
psql map_loader < ./sprites.sql
psql map_loader < ./characters.sql
psql map_loader < ./creature.sql
psql map_loader < ./npc.sql
psql map_loader < ./add_tile_data.sql
psql map_loader < ./tile_info_from_layer_type_id.sql
psql map_loader < ./animation.sql
psql map_loader < ./spells.sql
psql map_loader < ./spawn.sql
psql map_loader < ./attack.sql
psql map_loader < ./initialize_tiles.sql
psql map_loader < ./initialize_sprites.sql
psql map_loader < ./initialize_characters.sql