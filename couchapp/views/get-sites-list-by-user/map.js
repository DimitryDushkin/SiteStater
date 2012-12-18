function(doc) {
	var userId = doc._id;
	if (doc.type == 'user')
		doc.sites.forEach(function(site){
			emit(userId, {_id: site});
        });
}