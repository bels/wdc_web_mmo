package MapLoader::Websockets;
use Mojo::Base 'Mojolicious::Controller';
use Data::UUID;

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

			my $return_data = {'collision' => $collision,'event_id' => $data->{'event_id'},'finished' => 1};
			_send_message($self, 'data' => $return_data);

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
		'attack' => sub{
		    my ($self,$data) = @_;
		    
		    _attack($self,$data);
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
			if(!_check_for_event){
			      _register_event($message->{'data'}->{'event_id'});
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

sub _spawn_entity {
	#server side spawning of entities. ie. respawning a mob after being killed, placing a entity by some form of ai, etc...
	my ($self, $data) = @_;

	my $dbh = $self->app->dbh;
	my $query = "select spawn_entity(?,?,?,?,?,?,?)"
	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'type'},$data->{'entity_id'},$data->{'spawn_location_id'},$data->{'x'},$data->{'y'},$data->{'tile_id'},$data->{'mid'});
	
	_unregister_event($data->{'event_id'});
	return;
}

sub _json_from_any {
	my %data = @_;
	
	my $json = Mojo::JSON->new;
	return $json->encode({%data});
}

sub _check_for_event{
       my ($self,$data) = @_;
       
       foreach (@{$self->session->{'events'}->{'order'}}){
	  if($_ eq $data){
	       return 1;
	  }
       }
       return 0;
}

sub _register_event {
	my ($self,$data) = @_;
	
	push(@{$self->session->{'events'}->{'order'}}, $data->{'event_id'});
	$self->session->{'events'}->{$data->{'event_id'}} = $data;
	
	return;
}

sub _unregister_event{
	my ($self,$data) = @_;
	
	for(my $i = 0; $i <= scalar(@{$self->session->{'events'}->{'order'}}); $i++){
	       splice(@{$self->session->{'events'}->{'order'}},$i,1);
	}
	delete($self->session->{'events'}->{$data});
	
	return;
}

sub _move{
	my ($self,$data) = @_;

	my $dbh = $self->app->dbh;
	my $query = "select * from set_character_location(?,?,?,?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'Entity'}->{'id'},$data->{'Entity'}->{'x'},$data->{'Entity'}->{'y'},$data->{'Entity'}->{'current_map'},$data->{'Entity'}->{'current_tile'});
	
	_unregister_event($data->{'event_id'};
	return;
}

sub _attack{
	my ($self,$data) = @_;

	my $dbh = $self->app->dbh;
	my $query = "select execute_attack(?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($data->{'defender'},$data->{'attack_id'});
	
	return;
}
1;