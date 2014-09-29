import js.html.*;
import js.phantomjs.*;
import js.Lib;
import js.Browser.*;
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
			for (page in document.querySelectorAll("#page-container > .pf")) {
				var ty = -1.0; //y coordinate of the header

				for (child in (cast page:Element).children)
				if ((cast child:Element).classList.contains("pc"))
				for (child in (cast child:Element).children) {
					var e = (cast child:Element);
					if (e.classList.contains("t")) {
						var _region = regions.find(e.textContent.trim().startsWith);
						if (_region != null) {
							region = _region;
							ty = e.getBoundingClientRect().top + document.body.scrollTop;
							trace(region);
						}
					}
				}


				for (child in (cast page:Element).children)
				if ((cast child:Element).classList.contains("pc"))
				for (child in (cast child:Element).children) {
					var e = (cast child:Element);
					if (e.classList.contains("c")) {
						var cy = e.getBoundingClientRect().top + document.body.scrollTop;
						if (cy < ty) {
							throw 'Change of region in the middle of page?';
						}

						switch (row) {
							case null:
								var i = e.textContent.parseInt();
								if (i > 0) {
									row = [region, null, null];
									rowY = cy;
								}
							case [_, null, null]:
								if (cy != rowY) {
									throw "not in the same row?";
								}
								row[1] = csv_escape(spaces.replace(e.textContent.trim(), " "));
							case [_, _, null]:
								if (cy != rowY) {
									throw "not in the same row?";
								}
								row[2] = csv_escape(spaces.replace(e.textContent.trim(), " "));
								if (row[1].indexOf("供應商澄清從沒供應豬油與有關商戶") == -1) {
									rows.push(row.join(","));
								}
								trace(row);
								row = null;
							case _:
								throw "row?";
						}
					}
				}
			}
			trace(rows.join("\n"));
		} else {
			var traders_file = "data/Traders_who_imported_distributed_the_lard_produced_by_Chang_Guann.html";
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
		}
	}
}