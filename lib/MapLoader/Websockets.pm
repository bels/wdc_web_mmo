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
			
			my $collision = _check_collision($self, $data);

			if(!$collision){
				_move($self,$data);
				my $return_data = {
					'direction' => $data->{'direction'},
					'collision' => $collision,
					'event_id' => $data->{'event_id'},
					'finished' => 1,
					'action' => 'move',
					'distance' => $data->{'distance'},
					'x' => $data->{'x'},
					'y' => $data->{'y'},
					'Entity' => $data->{'Entity'},
					'id' => $data->{'id'},
					'type' => $data->{'type'}
				};
				_send_message($self, data => $return_data);
			}

			return;
		},
		'init' => sub{
			my ($self,$data) = @_;

			_init($self,$data);
			return;
		},
		'attack' => sub{
		    my ($self,$data) = @_;

		    my $hp = _attack($self,$data);

			my $return_data;

			if($hp <= 0){
				$return_data = {
					'action' => 'destroy',
					'Entity' => $data->{'target'}
				};
				_send_message($self, data => $return_data);
			}
			
		    return;
		},
		'spawn' => sub{
		    my ($self, $data) = @_;
		    
		    _spawn_entity($self,$data);
		    return;
		}
	};

	$self->on(
		message => sub {
			my ($self, $message) = @_;
			my $json = Mojo::JSON->new;
			$message = $json->decode($message);
			
			# abort if we could not unjsonify the message?

			$message->{'data'}->{'tx'} = $tx;
			if(!$self->check_for_event){
			      $self->create_event($message->{'data'});
			}
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

sub _json_from_any {
	my %data = @_;
	
	my $json = Mojo::JSON->new;
	return $json->encode({%data});
}

sub _move{
	my ($self,$data) = @_;

	
	my $dbh = $self->app->dbh;
	my $query;
	if($data->{'type'} eq 'character'){
		$query = "select * from set_character_location(?,?,?,?,?)";
	} elsif($data->{'type'} eq 'npc'){
		$query = "select * from set_npc_location(?,?,?,?,?)";
	} elsif($data->{'type'} eq 'creature'){
		$query = "select * from set_creature_location(?,?,?,?,?)";
	}

	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'id'},$data->{'x'},$data->{'y'},$data->{'current_map'},$data->{'current_tile'});
	
	$self->unregister_event($data->{'event_id'});
	return;
}

sub _attack{
	my ($self,$data) = @_;

	my $dbh = $self->app->dbh;
	my $query = "select execute_attack(?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'target'},$data->{'attack_id'});
	my $rs = $sth->fetchrow_hashref;

	return $rs->{'execute_attack'};
}
1;