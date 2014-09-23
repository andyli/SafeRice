import jQuery.*;
import js.phantomjs.*;
import js.Lib;
using StringTools;
using Lambda;
using Std;

class Converter {
	static function csv_escape(v:String):String {
		return if (["\n", "\r", "\"", ","].exists(function(_) return v.indexOf(_) >= 0)) {
			'"' + v.replace('"', '""') + '"';
		} else {
			v;
		}
	}
	static var header = "region,name,address";
	static function main():Void {
		if (PhantomTools.noPhantom()) {
			var regions = [
				"Hong Kong Island",
				"Kowloon",
				"New Territories"
			];
			var rows = [header];
			var row = null;
			var region = "";
			var spaces = ~/\s+/g;
			for (page in new JQuery("#page-container > .pf")) {
				var page_no = new JQuery(page).data("page-no");
				new JQuery(page)
					.children(".pc")
					.children("div.t, div.c")
					.each(function(i, e){
						var e = new JQuery(e);
						if (e.hasClass("t") && e.text().trim() != "") {
							var _region = regions.find(e.text().trim().startsWith);
							if (_region != null) {
								region = _region;
								trace(region);
							}
						} else if (e.hasClass("c")) {
							if (["x0"].exists(e.hasClass)) {
								var i = e.text().parseInt();
								if (i > 0) {
									// trace(i);
									row = [region, "", ""];
								} else {
									row = null;
								}
							} else if (["w4", "w8"].exists(e.hasClass)) {
								if (row != null) {
									row[1] = csv_escape(spaces.replace(e.text().trim(), " "));
								}
							} else if (["w5"].exists(e.hasClass)) {
								if (row != null) {
									row[2] = csv_escape(spaces.replace(e.text().trim(), " "));
									rows.push(row.join(","));
									trace(row);
								}
							}
						}
					});
			}
			trace(rows.join("\n"));
		} else {
			var traders_file = "data/Traders_who_imported_distributed_the_lard_produced_by_Chang_Guann.html";
			var jquery_file = "bower_components/jquery/dist/jquery.min.js";
			var server_port = 8080;
			var server_addr = 'http://localhost:$server_port/';
			var server = WebServer.create();
			server.listen(server_port, function(req, res) {
				var url = req.url.substr(1);
				if (FileSystem.exists(url)) {
					res.statusCode = 200;
					res.write(FileSystem.read(url));
				} else {
					res.statusCode = 404;
				}
				res.close();
			});

			var page = WebPage.create();
			page.open(server_addr + traders_file, function(status){
				page.includeJs(server_addr + jquery_file, function(){
					page.onConsoleMessage = function (msg) {
						switch (msg) {
							case "exit":
								Phantom.exit(0);
							case _ if (msg.startsWith(header)):
								FileSystem.write(traders_file.substring(0, traders_file.indexOf(".")) + ".csv", msg, "w");
								Phantom.exit(0);
							case _:
								trace(msg);
						}
						
					}
					PhantomTools.injectThis(page);
				});
			});
		}
	}
}