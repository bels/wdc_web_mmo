package MapLoader::Npc;
use Mojo::Base 'Mojolicious::Controller';

sub save{
#mode is for the future when we have editing npcs
	my $self = shift;

	my $dbh = $self->app->dbh;
	
	my ($name,$description,$hp,$mp,$str,$agi,$dex,$sta,$int,$wis,$vit,$luck,$mode,$sprite_id) = ($self->param('npc_name'),$self->param('npc_description'),$self->param('hitpoints'),$self->param('manapoints'),$self->param('strength'),$self->param('agility'),$self->param('dexterity'),$self->param('stamina'),$self->param('intelligence'),$self->param('wisdom'),$self->param('vitality'),$self->param('luck'),$self->param('mode'),$self->param('sprite_id'));

	my $rules = {
		npc_name => {
			rules => ['required'],
			error => {
				required => 'A NPC name is required'
			}
		},
		npc_description => {
			rules => ['required'],
			error => {
				required => 'A NPC description is required'
			}
		},
		hitpoints => {
			rules => ['required','numeric'],
			error => {
				required => 'Hit Points are required',
				numeric => 'Please enter a number'
			}
		},
		manapoints => {
			rules => ['required','numeric'],
			error => {
				required => 'Mana Points are required',
				numeric => 'Please enter a number'
			}
		}
	};
	$self->validator->rules($rules); #passing the rules to the validator
	#create a hash of the post params
	my $post = {};
	my @params = $self->param;
	foreach my $name (@params){
		$post->{$name} = $self->param($name);
	}
	#If the post data passes the validator it will try to create the npc. Then I check the database error code to make sure the npc creation didn't
	#error.  If it does I let the client know.
	if($self->validator->validate($post)){
		my $query = "select * from add_npc(?,?,?,?,?,?,?,?,?,?,?,?,?)";
		my $sth = $dbh->prepare($query);
		$sth->execute($name,$description,$hp,$mp,$str,$agi,$dex,$sta,$int,$wis,$vit,$luck,$sprite_id);
		if($dbh->err != 7){
			$self->flash(success => 'NPC: ' . $name . ' created successfully');
		} else {
			$self->flash(error => 'NPC creation failed.' . $dbh->errstr);
		}
	}
	#Redirect to the npc editor page
	$self->redirect_to($self->req->headers->referrer);
}
1;
