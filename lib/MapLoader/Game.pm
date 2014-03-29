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
	$self->stash(characters => $sth->fetchall_arrayref({}));
	$query = "select * from get_collision_data(?) AS collision";
	$sth = $dbh->prepare($query);
	$sth->execute($map_id);
	$self->stash(collision_data => $sth->fetchall_hashref('collision'));
	$query = "select * from get_npc_position_data(?)";
	$sth = $dbh->prepare($query);
	$sth->execute($map_id);
	$self->stash(npcs => $sth->fetchall_arrayref({}));
	$query = "select * from get_creature_position_data(?)";
	$sth = $dbh->prepare($query);
	$sth->execute($map_id);
	$self->stash(creatures => $sth->fetchall_arrayref({}));
	$query = "select * from get_spells_for_map(?)";
	$sth = $dbh->prepare($query);
	$sth->execute($map_id);
	$self->stash(spells => $sth->fetchall_hashref({'entity_id'}));
	$self->stash(map_id => $map_id);
	
	$self->render(
		template => 'map',
		javascripts => ['games.js'],
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

1;
