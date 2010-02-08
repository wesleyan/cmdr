//Building
function(doc) {
	if(doc.class && doc.class == "Building" && doc.attributes && doc.attributes["name"])
	{
		emit([doc._id, 0], {name: doc.attributes["name"], guid: doc._id, rooms:[]});
	}
	if(doc.class && doc.class == "Room" && doc.belongs_to)
	{
		emit([doc.belongs_to, 1], {guid: doc._id, name: doc.attributes.name, building: doc.belongs_to, devices: []});
	}
	if(doc.device && doc.belongs_to)
	{
		//the [0] in the key makes sure all of the devices are sorted after the other docs
		emit([[0], 2], {
			guid: doc._id, name: doc.attributes.name, room: doc.belongs_to, state_vars: doc.attributes.state_vars
		});
	}
}

//Device
function(doc) {
	if(doc.device && doc.attributes)
	{
		emit(doc._id, {name: doc.attributes["name"], guid: doc._id, room: doc.belongs_to, state_vars: doc.attributes["state_vars"]});
	}
}