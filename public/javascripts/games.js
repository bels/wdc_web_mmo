$(document).ready(function(){

//this system really only works for a single player game.  need to fixify
	tiles_x = 32;
	tiles_y = 32;
	tile_size_x = 32;
	tile_size_y = 32;
	map_offset = $('#map').offset();

	$('#map').attr('tabindex',-1).focus();
	$('#map').keydown(function(event){
		event.preventDefault();
		if(event.which == 39){
			var data = {
				'Entity': player,
				'direction': 'right',
				'distance': '+=' + tile_size_x,
				'event_id': UUID.generate()
			};
			Dispatcher.registerEvent({'event_id': data.event_id, 'action': 'move'});
			window.UI.move(data);
			ws.send(JSON.stringify({'data': data, 'action': 'move'}));
		}
		if(event.which == 37){
			var data = {
				'Entity': player,
				'direction': 'left',
				'distance': '-=' + tile_size_x,
			        'event_id': UUID.generate()
			};
			Dispatcher.registerEvent({'event_id': data.event_id, 'action': 'move'});
			window.UI.move(data);
			ws.send(JSON.stringify({'data': data, 'action': 'move'}));
		}
		if(event.which == 40){
			var data = {
				'Entity': player,
				'direction': 'down',
				'distance': '+=' + tile_size_y,
				'event_id': UUID.generate()
			};
			Dispatcher.registerEvent({'event_id': data.event_id, 'action': 'move'});
			window.UI.move(data);
			ws.send(JSON.stringify({'data': data, 'action': 'move'}));
		}
		if(event.which == 38){
			var data = {
				'Entity': player,
				'direction': 'up',
				'distance': '-=' + tile_size_y,
				'event_id': UUID.generate()
			};
			Dispatcher.registerEvent({'event_id': data.event_id, 'action': 'move'});
			window.UI.move(data);
			ws.send(JSON.stringify({'data': data, 'action': 'move'}));
		}
	});
	
	collision_data = new Object();
	$('.collision_tile').each(function(){
		collision_data[$(this).text()] = 1;
	});
});