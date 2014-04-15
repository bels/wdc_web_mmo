package MapLoader::Spell;
use Mojo::Base 'Mojolicious::Controller';

sub save{
#mode is for the future when we have editing npcs
	my $self = shift;

	my $dbh = $self->app->dbh;
	
	my ($name,$description,$range,$damage,$cast_time,$dot,$animation) = ($self->param('spell_name'),$self->param('spell_description'),$self->param('range'),$self->param('damage'),$self->param('cast_time'),$self->param('dot'),$self->param('animation'));

	my $rules = {
		spell_name => {
			rules => ['required'],
			error => {
				required => 'A spell name is required'
			}
		},
		spell_description => {
			rules => ['required'],
			error => {
				required => 'A spell description is required'
			}
		},
		damage => {
			rules => ['numeric'],
			error => {
				numeric => 'Please enter a number'
			}
		},
		cast_time => {
			rules => ['numeric'],
			error => {
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
	#If the post data passes the validator it will try to create the spell. Then I check the database error code to make sure the spell creation didn't
	#error.  If it does I let the client know.
	if($self->validator->validate($post)){
		if($damage ne ''){ #just checking one of the post params so I know which version of add_spell to call.
			my $query = "select * from add_spell(?,?,?,?,?,?,?,?,?,?,?,?,?)";
			my $sth = $dbh->prepare($query);
			$sth->execute($name,$description,$range,$damage,$cast_time,$dot,$animation);
		} else {
			my $query = "select * from add_spell(?,?)";
			my $sth = $dbh->prepare($query);
			$sth->execute($name,$description);
		}
		if($dbh->err != 7){
			$self->flash(success => 'Spell: ' . $name . ' created successfully');
		} else {
			$self->flash(error => 'Spell creation failed.' . $dbh->errstr);
		}
	}
	#Redirect to the spell editor page
	$self->redirect_to($self->req->headers->referrer);
}

sub spell_mapping_save{
	my $self = shift;
	
	my ($spell,$entity) = ($self->param('spell'),$self->param('entity'));
	
	my $dbh = $self->app->dbh;
	my $query = "select * from save_spell_mapping(?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($spell,$entity);
	
	if($dbh->err != 7){
		$self->flash(success => 'Spell: ' . $spell . ' mapped successfully');
	} else {
		$self->flash(error => 'Spell mapping failed.' . $dbh->errstr);
	}
	$self->redirect_to($self->req->headers->referrer);
}
1;
