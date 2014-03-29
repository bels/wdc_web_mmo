package MapLoader::Entrance;
use Mojo::Base 'Mojolicious::Controller';

sub metadata {

	my $self = shift;
	
	
	my $dbh = $self->app->dbh;
	
	my $tile_info_sql = 'select * from tile_info_from_layer_type_id(?)';
	my $sth = $dbh->prepare($tile_info_sql);
	
	my $layer_info = {};
	
	my $layer_query = 'select description from layer_types where id = ?';
	my $layer_sth = $dbh->prepare($layer_query);

	for (1..6){
		$sth->execute($_);
		my $tile_info = $sth->fetchall_hashref('tile_id');
		
		$layer_sth->execute($_);
		my $layer_name = $layer_sth->fetchrow_hashref;
		
		$layer_info->{$_} = {
			'name' => $layer_name->{'description'},
			'tile_info' => $tile_info
		}
		
		
	}

	$self->stash('layer_info' => $layer_info);
}

1;