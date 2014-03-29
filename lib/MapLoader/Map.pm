package MapLoader::Map;
use Mojo::Base 'Mojolicious::Controller';

sub create{
	my $self = shift;

	my $dbh = $self->app->dbh;
	
	#setting up the rules for the form
	my $rules = {
		map_name => {
			rules => ['required'],
			error => {
				required => 'A map name is required'
			}
		},
		x_width => {
			rules => ['required','numeric'],
			error => {
				required => 'Please enter a number for X Axis',
				numeric => 'Needs to be a positive number'
			}
		},
		y_height => {
			rules => ['required','numeric'],
			error => {
				required => 'Please enter a number for Y Axis',
				numeric => 'Needs to be a positive number'
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
	#If the post data passes the validator it will try to create the map. Then I check the database error code to make sure the map creation didn't
	#error.  If it does I let the client know.
	if($self->validator->validate($post)){
		my $query = "select * from create_map(?,?,?)";
		my $sth = $dbh->prepare($query);
		my $map_name = $self->param('map_name');
		if($map_name eq ''){
			$map_name = undef; #making sure that map name will violate the not null constraint in the database if it is blank
		}
		$sth->execute($map_name,$self->param('x_width'),$self->param('y_height'));

		if($dbh->err != 7){
			$self->flash(success => 'Map: ' . $self->param('map_name') . ' created successfully');
		} else {
			$self->flash(error => 'Map creation failed.' . $dbh->errstr);
		}
	}
	#Redirect to the map editor page
	$self->redirect_to($self->req->headers->referrer);

}

sub save{
	my $self = shift;
	
	my $dbh = $self->app->dbh;
	
	my $map = $self->param('map');
	my $layer1 = $self->param('layer1');
	my $layer2 = $self->param('layer2');
	my $layer3 = $self->param('layer3');
	my $layer4 = $self->param('layer4');
	my $layer5 = $self->param('layer5');
	my $layer6 = $self->param('layer6');
	my $layers = '{' . $layer1 .','. $layer2 .','. $layer3 .','. $layer4 .','. $layer5 .','. $layer6 . '}';
	
	my $query = "select * from save_map(?,?)";
	my $sth =  $dbh->prepare($query);
	$sth->execute($map,$layers);
	
	$self->flash(success => 'Map Updated');
	$self->redirect_to($self->url_for('map_editor'));
}
1;