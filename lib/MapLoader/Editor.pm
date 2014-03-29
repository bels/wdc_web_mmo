package MapLoader::Editor;
use Mojo::Base 'Mojolicious::Controller';
use Image::Size;

# This action will render a template
sub editor{
	my $self = shift;
}

sub map {
	my $self = shift;

	my $dbh = $self->app->dbh;
	
	my $query = "select * from get_map_list()";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	$self->stash(existing_maps => $sth->fetchall_arrayref({}));
	$query = "select * from get_available_layers(?)";
	$sth = $dbh->prepare($query);
	$sth->execute(1);
	$self->stash(layer1 => $sth->fetchall_arrayref({}));
	$sth->execute(2);
	$self->stash(layer2 => $sth->fetchall_arrayref({}));
	$sth->execute(3);
	$self->stash(layer3 => $sth->fetchall_arrayref({}));
	$sth->execute(4);
	$self->stash(layer4 => $sth->fetchall_arrayref({}));
	$sth->execute(5);
	$self->stash(layer5 => $sth->fetchall_arrayref({}));
	$sth->execute(6);
	$self->stash(layer6 => $sth->fetchall_arrayref({}));
	$self->render(
		template => 'map_editor',
		javascripts => ['editor.js'],
		styles => ['editor.css']
	);
}

sub layer{
	my $self = shift;
	
	my $dbh = $self->app->dbh;
	
	my $layer1 = '../public/images/ground_layer.png';
	my $layer2 = '../public/images/details_layer.png';
	my $layer3 = '../public/images/character_layer.png';
	my $layer4 = '../public/images/overlay_layer.png';
	my $layer5 = '../public/images/sky_layer.png';
	my $layer6 = '../public/images/lighting_layer.png';
	
	my ($layer1_x,$layer1_y) = imgsize($layer1);
	my ($layer2_x,$layer2_y) = imgsize($layer2);
	my ($layer3_x,$layer3_y) = imgsize($layer3);
	my ($layer4_x,$layer4_y) = imgsize($layer4);
	my ($layer5_x,$layer5_y) = imgsize($layer5);
	my ($layer6_x,$layer6_y) = imgsize($layer6);

	#This might turn into a function later.  I'm not sure
#	my $query = "select * from tiles";
#	$sth = $dbh->prepare($query);
#	$sth->execute;
#	$self->stash(tiles => $sth->fetchall_arrayref({}));
	$self->stash(layer1_x => $layer1_x, layer1_y => $layer1_y);
	$self->stash(layer2_x => $layer2_x, layer2_y => $layer2_y);
	$self->stash(layer3_x => $layer3_x, layer3_y => $layer3_y);
	$self->stash(layer4_x => $layer4_x, layer4_y => $layer4_y);
	$self->stash(layer5_x => $layer5_x, layer5_y => $layer5_y);
	$self->stash(layer6_x => $layer6_x, layer6_y => $layer6_y);
	
	$self->render(
		template => 'layer_editor',
		javascripts => ['editor.js'],
		styles => ['editor.css']
	);
}

sub npc{
	my $self = shift;
	
	my $dbh = $self->app->dbh;
	my $query = "select * from get_all_available_sprites()";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	$self->stash(sprites => $sth->fetchall_arrayref({}));
	$self->render(
		template => 'npc_editor',
		javascripts => ['editor.js'],
		styles => ['editor.css']
	);
}

sub creature{
	my $self = shift;
	
	my $dbh = $self->app->dbh;
	my $query = "select * from get_all_available_sprites()";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	$self->stash(sprites => $sth->fetchall_arrayref({}));
	$self->render(
		template => 'creature_editor',
		javascripts => ['editor.js'],
		styles => ['editor.css']
	);
}

sub spawn_placement{
	my $self = shift;
	
	my $dbh = $self->app->dbh;
	my $query = "select * from get_creature_templates()";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	$self->stash(creatures => $sth->fetchall_arrayref({}));
	$query = "select * from get_npc_templates()";
	$sth = $dbh->prepare($query);
	$sth->execute;
	$self->stash(npcs => $sth->fetchall_arrayref({}));
	$query = "select * from maps where id = (?)";
	$sth = $dbh->prepare($query);
	$sth->execute($self->stash('map_id'));
	$self->stash(map_meta_data => $sth->fetchrow_hashref);
	$query = "select * from get_map_data(?)";
	$sth = $dbh->prepare($query);
	$sth->execute($self->stash('map_id'));
	$self->stash(map_data => $sth->fetchall_hashref('layer_type')) ;
	$self->render(
		template => 'spawn_placement',
		javascripts => ['editor.js','spawn.js'],
		styles => ['game.css']
	);

}

sub spell{
	my $self = shift;
	
	$self->render(
		template => 'spell_editor',
		javascripts => ['editor.js'],
		styles => ['editor.css']
	);
}

sub spell_mapping{
	my $self = shift;
	
	my $dbh = $self->app->dbh;
	my $query = "select * from get_all_spells()";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	$self->stash(spells => $sth->fetchall_arrayref({}));
	$query = "select * from npc_template UNION select * from creature_template ORDER BY name";
	$sth = $dbh->prepare($query);
	$sth->execute;
	$self->stash(entities => $sth->fetchall_arrayref({}));
	
	$self->render(
		template => 'spell_mapping_editor',
		javascripts => ['editor.js'],
		styles => ['editor.css']
	);
}
1;
