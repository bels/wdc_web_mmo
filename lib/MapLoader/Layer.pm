package MapLoader::Layer;
use Mojo::Base 'Mojolicious::Controller';

sub save{
	my $self = shift;

	my $dbh = $self->app->dbh;
	
	my $json = $self->req->json;
	
	my ($name,$lid,$tiles) = ($json->{'name'},$json->{'lid'},$json->{'tiles'});
	#my $t = join(',',@{$tiles});
	#$t = '{' . $t . '}';
	my $query = "select * from save_layer(?,?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($name,$lid,$tiles);
	if($dbh->err != 7){
		$self->flash(success => $name . ' layer created successfully');
		$self->render(json => {
			'error' => 0,
		});
			'message' => 'Layer saved.'
	} else {
		#should exit and give the error message to the user
		$self->flash(error => $name . ' layer creation failed.' . $dbh->errstr);
		$self->render(json => {
			'error' => 1,
			'message' => 'Layer save failed.'
		});

	}
}
1;
