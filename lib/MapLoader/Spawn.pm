package MapLoader::Spawn;
use Mojo::Base 'Mojolicious::Controller';

sub save{
	my $self = shift;

	my $dbh = $self->app->dbh;
	
	my $json = $self->req->json;
	
	foreach (keys %{$json}){
		my $query = "select * from save_spawn(?,?,?,?,?,?)";
		my $sth = $dbh->prepare($query);
		$sth->execute($json->{$_}->{'type'},$json->{$_}->{'id'},$json->{$_}->{'x'},$json->{$_}->{'y'},$_,$json->{$_}->{'map_id'});
		if($dbh->err != 7){
			$self->flash(success => 'Spawns updated successfully');
			$self->render(json => {
				'error' => 0,
				'message' => 'Spawn saved.'
			});
		} else {
			#should exit and give the error message to the user
			$self->flash(error => 'Spawn updates failed.' . $dbh->errstr);
			$self->render(json => {
				'error' => 1,
				'message' => 'Spawn save failed.'
			});

		}
	}
	
	
}
1;
