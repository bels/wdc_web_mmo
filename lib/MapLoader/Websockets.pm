package MapLoader::Websockets;
use Mojo::Base 'Mojolicious::Controller';

# TODO: Add all kinds of validation and error checking. srsly.
sub dispatch{
	my $self = shift;
	my $tx = $self->tx;

	my $action = {
		'move' => sub {
			my ($self,$data) = @_;
			# check collision
			# success? Update the database
			# success? Inform the client
			
			my $collision = _check_collision($self, $data);

			_send_message($self, 'colliding' => $collision);

			if(!$collision){
				_move($self,$data);
			}

			return;
		},
		'init' => sub{
			my ($self,$data) = @_;

			_init($self,$data);
			return;
		},
	};

	$self->on(
		message => sub {
			my ($self, $message) = @_;
			my $json = Mojo::JSON->new;
			$message = $json->decode($message);
			
			# abort if we could not unjsonify the message?

			$message->{'data'}->{'tx'} = $tx;

			&{$action->{$message->{'action'}}}($self, $message->{'data'});
			
		}
	);

}



sub _init{
	my ($self,$data) = @_;
	
	#i imagine data being thrown into a game table here for possible resumes and other tracking
	
	return;
}

sub _send_message {
	my $self = shift;
	$self->send(_json_from_any(@_));
	
	return;
}

sub _check_collision {
	my ($self, $data) = @_;
	
	my $dbh = $self->app->dbh;
	my $query = "select * from get_collision_data(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'map_id'});
	my $rs = $sth->fetchall_hashref('get_collision_data');
	my $flag = 0;
	foreach (keys %{$rs}){
		if($data->{'next_tile'} == $_){
			$flag = 1;
		}
	}
	return $flag;
}

sub _spawn_entity {
	#server side spawning of entities. ie. respawning a mob after being killed, placing a entity by some form of ai, etc...
	my ($self, $data) = @_;

	my $dbh = $self->app->dbh;
	my $query = "select spawn_entity(?,?,?,?,?,?,?)"
	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'type'},$data->{'entity_id'},$data->{'spawn_location_id'},$data->{'x'},$data->{'y'},$data->{'tile_id'},$data->{'mid'});
	
	return;
}

sub _json_from_any {
	my %data = @_;
	
	my $json = Mojo::JSON->new;
	return $json->encode({%data});
}

sub _move{
	my ($self,$data) = @_;

	my $dbh = $self->app->dbh;
	my $query = "select * from set_character_location(?,?,?,?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'Entity'}->{'id'},$data->{'Entity'}->{'x'},$data->{'Entity'}->{'y'},$data->{'Entity'}->{'current_map'},$data->{'Entity'}->{'current_tile'});
}

sub _attack{
	my ($self,$data) = @_;

}
1;