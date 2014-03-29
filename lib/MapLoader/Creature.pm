package MapLoader::Creature;
use Mojo::Base 'Mojolicious::Controller';

sub save{
#mode is for the future when we have editing of creatures
	my $self = shift;

	my $dbh = $self->app->dbh;
	
	my ($name,$description,$hp,$mp,$str,$agi,$dex,$sta,$int,$wis,$vit,$luck,$mode,$sprite_id) = ($self->param('creature_name'),$self->param('creature_description'),$self->param('hitpoints'),$self->param('manapoints'),$self->param('strength'),$self->param('agility'),$self->param('dexterity'),$self->param('stamina'),$self->param('intelligence'),$self->param('wisdom'),$self->param('vitality'),$self->param('luck'),$self->param('mode'),$self->param('sprite_id'));

	my $rules = {
		creature_name => {
			rules => ['required'],
			error => {
				required => 'A creature name is required'
			}
		},
		creature_description => {
			rules => ['required'],
			error => {
				required => 'A creature description is required'
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
	warn $sprite_id;
	#If the post data passes the validator it will try to create the creature. Then I check the database error code to make sure the creature creation didn't
	#error.  If it does I let the client know.
	if($self->validator->validate($post)){
		my $query = "select * from add_creature(?,?,?,?,?,?,?,?,?,?,?,?,?)";
		my $sth = $dbh->prepare($query);
		$sth->execute($name,$description,$hp,$mp,$str,$agi,$dex,$sta,$int,$wis,$vit,$luck,$sprite_id);
		if($dbh->err != 7){
			$self->flash(success => 'Creature: ' . $name . ' created successfully');
		} else {
			$self->flash(error => 'Creature creation failed.' . $dbh->errstr);
		}
	}
	#Redirect to the creature editor page
	$self->redirect_to($self->req->headers->referrer);
}
1;
