function(doc) {
	if (doc.url)
		emit(doc.url, doc);
}