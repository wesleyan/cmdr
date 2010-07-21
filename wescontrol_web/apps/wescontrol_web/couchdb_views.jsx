//Building
function(doc) {
	if(doc.class && doc.class == "Building" && doc.attributes && doc.attributes["name"])
	{
		emit([doc._id, 0], {name: doc.attributes["name"], guid: doc._id, rooms:[]});
	}
	if(doc.class && doc.class == "Room" && doc.belongs_to)
	{
		var room = {guid: doc._id, _rev: doc._rev, building: doc.belongs_to, devices: []};
		for(var attr in doc.attributes){
			room[attr] = doc.attributes[attr];
		}
		emit([doc.belongs_to, 1], room);
	}
	if(doc.device && doc.belongs_to)
	{
		//the [0] in the key makes sure all of the devices are sorted after the other docs
		var device = {
			guid: doc._id,
			_rev: doc._rev,
			name: doc.attributes.name, 
			room: doc.belongs_to, 
			state_vars: doc.attributes.state_vars,
			driver: doc.class
		};
		
		for(var config in doc.attributes.config)
		{
			device[config] = doc.attributes.config[config];
		}
		
		emit([[0], 2], device); 		
	}
}

//Device
function(doc) {
	if(doc.device && doc.attributes)
	{
		emit(doc._id, {name: doc.attributes["name"], guid: doc._id, room: doc.belongs_to, state_vars: doc.attributes["state_vars"]});
	}
}

//device filter
function(doc, req) {
	if(doc.device)return true;
	return false;
}

/*
{
   "building": {
       "map": "function(doc) {\n\tif(doc.class &amp;&amp; doc.class == \"Building\" &amp;&amp; doc.attributes &amp;&amp; doc.attributes[\"name\"])\n\t{\n\t\temit([doc._id, 0], {name: doc.attributes[\"name\"], guid: doc._id, rooms:[]});\n\t}\n\tif(doc.class &amp;&amp; doc.class == \"Room\" &amp;&amp; doc.belongs_to)\n\t{\n\t\temit([doc.belongs_to, 1], {guid: doc._id, name: doc.attributes.name, building: doc.belongs_to, devices: [], attributes: doc.attributes});\n\t}\n\tif(doc.device &amp;&amp; doc.belongs_to)\n\t{\n\t\t//the [0] in the key makes sure all of the devices are sorted after the other docs\n\t\temit([[0], 2], {\n\t\t\tguid: doc._id, name: doc.attributes.name, room: doc.belongs_to, state_vars: doc.attributes.state_vars\n\t\t});\n\t}\n}"
   },
   "sources": {
       "map": "function(doc) {\n  if(doc.source &amp;&amp; doc.belongs_to)\n      emit(doc.belongs_to, doc);\n\n}"
   },
   "actions": {
       "map": "function(doc) {\n  if(doc.action &amp;&amp; doc.belongs_to)\n      emit(doc.belongs_to, doc);\n\n}"
   }
}*/