package MapLoader::Game;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub play_game {
	my $self = shift;

	my $dbh = $self->app->dbh;

	my $q = 'select id from maps order by id desc limit 1';
	my $s = $dbh->prepare($q);
	
	$s->execute();
	
	my $map_id = $s->fetchrow_hashref;
	$map_id = $map_id->{'id'};
	my $query = "select * from maps where id = (?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($map_id);
	$self->stash(map_meta_data => $sth->fetchrow_hashref);
	$query = "select * from get_map_data(?)";
	$sth = $dbh->prepare($query);
	$sth->execute($map_id);
	$self->stash(map_data => $sth->fetchall_hashref('layer_type')) ;
	$query = "select * from get_character_position_data(?)";
	$sth = $dbh->prepare($query);
	$sth->execute($map_id);
	my $characters = $sth->fetchall_arrayref({});
	$self->stash(characters => $characters);
	foreach (@{$characters}){
		my $data = {
			'type' => 'character',
			'entity_id' => $_->{'character_id'},
			'spawn_location_id' => $_->{'id'},
			'x' => $_->{'x'},
			'y' => $_->{'y'},
			'tile_id' => $_->{'tile_id'},
			'mid' => $map_id,
		};
		$data = $self->create_event($data);
	    _spawn_entity_with_hp_and_mp($self,$data);
	}
	$query = "select * from get_collision_data(?) AS collision";
	$sth = $dbh->prepare($query);
	$sth->execute($map_id);
	$self->stash(collision_data => $sth->fetchall_hashref('collision'));
	$query = "select * from get_npc_position_data(?)";
	$sth = $dbh->prepare($query);
	$sth->execute($map_id);
	my $npcs = $sth->fetchall_arrayref({});
	$self->stash(npcs => $npcs);
	foreach (@{$npcs}){
		my $data = {
			'type' => 'npc',
			'entity_id' => $_->{'npc_id'},
			'spawn_location_id' => $_->{'id'},
			'x' => $_->{'x'},
			'y' => $_->{'y'},
			'tile_id' => $_->{'tile_id'},
			'mid' => $map_id,
		};
		$data = $self->create_event($data);
	    _spawn_entity($self,$data);
	}
	$query = "select * from get_creature_position_data(?)";
	$sth = $dbh->prepare($query);
	$sth->execute($map_id);
	my $creatures = $sth->fetchall_arrayref({});
	$self->stash(creatures => $creatures);
	foreach (@{$creatures}){
		my $data = {
			'type' => 'creature',
			'entity_id' => $_->{'creature_id'},
			'spawn_location_id' => $_->{'id'},
			'x' => $_->{'x'},
			'y' => $_->{'y'},
			'tile_id' => $_->{'tile_id'},
			'mid' => $map_id,
		};
		$data = $self->create_event($data);
	    _spawn_entity($self,$data);
	}
	$query = "select * from get_spells_for_map(?)";
	$sth = $dbh->prepare($query);
	$sth->execute($map_id);
	my $spells = $sth->fetchall_arrayref({});
	my $new_spells;
	my $all_spells; #list of individual spells on the map with no mapping to characters/npcs/creatures
	
	foreach $_ (@{$spells}){
		$new_spells->{$_->{'entity_id'}}->{'abilities'}->{$_->{'spell_entry_id'}} = $_;
		$all_spells->{$_->{'spell_entry_id'}} = $_;
	}

	$self->stash(spells => $all_spells);
	$self->stash(spell_mappings => $new_spells);
	$self->stash(map_id => $map_id);
	

	$self->render(
		template => 'map',
		javascripts => ['uuid.js','games.js'],
		styles => ['game.css']
	);
}

sub select_character {
	my $self = shift;

	if($self->param('character')){
		$self->session(character_id => $self->param('character'));
		$self->redirect_to($self->url_for('play_game'));
	}
	
	my $dbh = $self->app->dbh;
	############### Replace this when an actual pathway to the game has been implemented, one where players can be selected somehow ############
	my $map_query = "select * from account limit 1";
	my $map_sth = $dbh->prepare($map_query);
	$map_sth->execute;
	my $map = $map_sth->fetchrow_hashref;
	###############################
	my $query = "select * from get_character_list(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($map->{'id'}); #replace with a session player id variable acquired at login
	$self->stash(characters => $sth->fetchall_arrayref({}));
	$self->render(
		template => 'select_character',
		javascripts => ['select_character.js'],
		styles => []
	);
}

sub _spawn_entity {
	#server side spawning of entities. ie. respawning a mob after being killed, placing a entity by some form of ai, etc...
	my ($self, $data) = @_;

	my $dbh = $self->app->dbh;
	my $query = "select count(*) from live_entities where mid = ? and spawn_location_id = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'mid'},$data->{'spawn_location_id'});
	my $count = $sth->fetchrow_hashref;
	if($count->{'count'} == 0){
		$query = "select spawn_entity(?,?,?,?,?,?,?)";
		$sth = $dbh->prepare($query);
		$sth->execute($data->{'type'},$data->{'entity_id'},$data->{'spawn_location_id'},$data->{'x'},$data->{'y'},$data->{'tile_id'},$data->{'mid'});
	}
	
	$self->unregister_event($data->{'event_id'});
	return;
}

sub _spawn_entity_with_hp { #i should consildate this into on _spawn_entity when I am feeling clever
	#server side spawning of entities. ie. respawning a mob after being killed, placing a entity by some form of ai, etc...
	my ($self, $data) = @_;

	my $dbh = $self->app->dbh;
	my $query = "select count(*) from live_entities where mid = ? and spawn_location_id = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'mid'},$data->{'spawn_location_id'});
	my $count = $sth->fetchrow_hashref;
	if($count->{'count'} == 0){
		$query = "select spawn_entity(?,?,?,?,?,?,?,?)";
		$sth = $dbh->prepare($query);
		$sth->execute($data->{'type'},$data->{'entity_id'},$data->{'spawn_location_id'},$data->{'x'},$data->{'y'},$data->{'tile_id'},$data->{'mid'},$data->{'hitpoints'});
	}
	
	$self->unregister_event($data->{'event_id'});
	return;
}

sub _spawn_entity_with_hp_and_mp { #i should consildate this into on _spawn_entity when I am feeling clever
	#server side spawning of entities. ie. respawning a mob after being killed, placing a entity by some form of ai, etc...
	my ($self, $data) = @_;

	my $dbh = $self->app->dbh;
	my $query = "select count(*) from live_entities where mid = ? and spawn_location_id = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'mid'},$data->{'spawn_location_id'});
	my $count = $sth->fetchrow_hashref;
	if($count->{'count'} == 0){
		$query = "select * from get_character_data(?)";
		$sth = $dbh->prepare($query);
		$sth->execute($data->{'entity_id'});
		my $rs = $sth->fetchrow_hashref;
		$query = "select spawn_entity(?,?,?,?,?,?,?,?,?)";
		$sth = $dbh->prepare($query);
		$sth->execute($data->{'type'},$data->{'entity_id'},$data->{'spawn_location_id'},$data->{'x'},$data->{'y'},$data->{'tile_id'},$data->{'mid'},$rs->{'hitpoints'},$rs->{'manapoints'});
	}
	
	$self->unregister_event($data->{'event_id'});
	return;
}

1;
