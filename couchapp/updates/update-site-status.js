function(doc, req) {
	doc.status = req.status;
	return [doc, {response: "ok"}];
}