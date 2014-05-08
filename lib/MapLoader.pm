package MapLoader;
use Mojo::Base 'Mojolicious';

use DBI;
use Validator;
use UUID::Tiny;

has dbh => sub {
	my $self = shift;
	
	my $data_source = "dbi:Pg:host=localhost dbname=map_loader";
	my $username = 'map';
	my $password = 'PAssword1234!@#$';
	
	my $dbh = DBI->connect(
		$data_source,
		$username,
		$password,
		{AutoCommit => 1,RaiseError => 0}
	);
	
	return $dbh;
};

# This method will run once at server start
sub startup {
	my $self = shift;

	# Documentation browser under "/perldoc"
	#$self->plugin('PODRenderer');

	#helpers for events
	$self->helper(check_for_event => sub {
	     my ($self,$data) = @_;

	     foreach (@{$self->session->{'events'}->{'order'}}){
	          if($_ eq $data){
	               return 1;
	          }
	      }
	      return 0;
         });

	$self->helper(register_event => sub {
		my ($self,$data) = @_;

		push(@{$self->session->{'events'}->{'order'}}, $data->{'event_id'});
		$self->session->{'events'}->{$data->{'event_id'}} = $data;

		warn 'Registered event: ' . $data->{'event_id'};
		return;
	});

	$self->helper(unregister_event => sub {
		my ($self,$data) = @_;

		for(my $i = 0; $i <= scalar(@{$self->session->{'events'}->{'order'}}); $i++){
			if($self->session->{'events'}->{'order'}->[$i] eq $data){
				splice(@{$self->session->{'events'}->{'order'}},$i,1);
			}
		}
		delete($self->session->{'events'}->{$data});
		warn 'Unregistered event: ' . $data;
		return;
	});
         
	$self->helper(create_event => sub {
		my ($self, $data) = @_;

		my $uuid;
		unless($data->{'event_id'}){ #because there may be an event id assigned to this from the front end
			$uuid = create_UUID_as_string(UUID_V4);
			$data->{'event_id'} = $uuid;
		}
		
		$self->register_event($data);

		return $data;
	});
	
	my $validator = Validator->new();
	$self->helper(validator => sub {return $validator});
	# Router
	my $r = $self->routes;

	my $entrance = $r->bridge('/e')->to('entrance#metadata');
	$r->websocket('/dispatch')->to('websockets#dispatch')->name('dispatch');
	$entrance->route('/play_game')->to('game#play_game')->name('play_game');
	$entrance->route('/select_character')->to('game#select_character');
	my $editor = $entrance->bridge('/editor')->to('editor#editor');
	$editor->route('/map')->to('editor#map')->name('map_editor');
	$editor->route('/layer')->to('editor#layer')->name('layer_editor');
	$editor->route('/tile')->to('editor#tile')->name('tile_editor');
	$editor->route('/map/create')->to('map#create')->name('create_map');
	$editor->route('/layer/save')->to('layer#save')->name('save_layer');
	$editor->route('/map/save')->to('map#save')->name('save_map');
	$editor->route('/creature')->to('editor#creature')->name('creature_editor');
	$editor->route('/npc')->to('editor#npc')->name('npc_editor');
	$editor->route('/creature/save')->to('creature#save')->name('creature_save');
	$editor->route('/npc/save')->to('npc#save')->name('npc_save');
	$editor->route('/spawn/save')->to('spawn#save')->name('spawn_save');
	$editor->route('/spawn/:map_id')->to('editor#spawn_placement')->name('spawn_placement');
	$editor->route('/spell')->to('editor#spell')->name('spell_editor');
	$editor->route('/spell/save')->to('spell#save')->name('spell_save');
	$editor->route('/spell/mapping')->to('editor#spell_mapping')->name('spell_mapping_editor');
	$editor->route('/spell/mapping/save')->to('spell#spell_mapping_save')->name('spell_mapping_save');
}

1;
