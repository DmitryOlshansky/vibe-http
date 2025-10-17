import vibe.core.core;
import vibe.http.server;

void handleRequest(scope HTTPServerRequest req, scope HTTPServerResponse res)
{
	if (req.path == "/") {
		res.writeBody("Hello, World!", "text/plain");
	}
}

void main()
{
	runWorkerTaskDist(() nothrow {
		try {
			auto settings = new HTTPServerSettings;
			settings.port = 8080;
			settings.options = HTTPServerOption.reusePort;
			settings.bindAddresses = ["::1", "127.0.0.1"];
			auto l = listenHTTP(settings, &handleRequest);
		} catch(Exception e) {
			assert(false, e.msg);
		}
	});
	runApplication();
}
