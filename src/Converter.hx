import jQuery.*;
import js.html.*;
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
			var rowY = null;
			var region = "";
			var spaces = ~/\s+/g;
			for (page in new JQuery("#page-container > .pf")) {
				var page_no = new JQuery(page).data("page-no");
				var ty = -1.0; //y coordinate of the header
				new JQuery(page)
					.children(".pc")
					.children("div.t")
					.each(function(i, e) {
						var _region = regions.find(new JQuery(e).text().trim().startsWith);
						if (_region != null) {
							region = _region;
							ty = new JQuery(e).offset().top;
							trace(region);
						}
					});

				new JQuery(page)
					.children(".pc")
					.children("div.c")
					.each(function(i, e){
						var je = new JQuery(e);
						var cy = je.offset().top;
						if (cy < ty) {
							throw 'Change of region in the middle of page?';
						}

						switch (row) {
							case null:
								var i = je.text().parseInt();
								if (i > 0) {
									row = [region, null, null];
									rowY = cy;
								}
							case [_, null, null]:
								if (cy != rowY) {
									throw "not in the same row?";
								}
								row[1] = csv_escape(spaces.replace(je.text().trim(), " "));
							case [_, _, null]:
								if (cy != rowY) {
									throw "not in the same row?";
								}
								row[2] = csv_escape(spaces.replace(je.text().trim(), " "));
								rows.push(row.join(","));
								trace(row);
								row = null;
							case _:
								throw "row?";
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