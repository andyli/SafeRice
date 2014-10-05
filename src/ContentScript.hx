import js.Lib;
import js.Browser.*;
import jQuery.*;
import chrome.*;
import promhx.Deferred;
using StringTools;
using Reflect;

enum Language {
	zh;
	en;
}

extern class Fuse {
	public function new(data:Dynamic, options:Dynamic):Void;
	public function search(pattern:String):Array<Dynamic>;
}

class ContentScript {
	static function getQueryParams(qs:String):Dynamic {
		//qs = qs.replace("+", " ");

		var params = {}, tokens,
			re = ~/[?&]?([^=]+)=([^&]*)/g;

		while (re.match(qs)) {
			params.setField(re.matched(1).urlDecode(), re.matched(2).urlDecode());
			qs = re.matchedRight();
		}

		return params;
	}

	static function normalizeName(name:String):String {
		name = ~/\(.*\)/g.replace(name, "");
		var nonEng = ~/[^\x00-\x7F]+/;
		if (nonEng.match(name)) {
			name = nonEng.matched(0);
		}
		return name.trim();
	}

	static function main():Void {
		switch (document.location) {
			case {
				pathname: "/restaurant/sr2.htm",
				search: getQueryParams(_) => param
			}:
				restaurantPage(param.shopid, zh);
			case {
				pathname: "/english/restaurant/sr2.htm",
				search: getQueryParams(_) => param
			}:
				restaurantPage(param.shopid, en);
			case _:
		}
		
	}

	static function restaurantPage(shopid:String, lang:Language):Void {
		var list_lard = new Deferred<Array<Dynamic>>();
		JQuery._static.get(
			Extension.getURL("data/Traders_who_imported_distributed_the_lard_produced_by_Chang_Guann.csv"),
			null,
			function(data, status, jqXHR) {
				var _list = JQuery._static.csv.toObjects(data);
				for (item in _list) {
					item.normalizedName = normalizeName(item.name);
				}
				// trace(_list);
				list_lard.resolve(_list);
			}
		);

		var list_umbrella = new Deferred<Array<Dynamic>>();
		JQuery._static.get(
			"https://docs.google.com/spreadsheets/d/19IM5t97cSIEqbvwH4CyTrouUyEdKI-kZQsPXbe0l3r8/export?gid=0&format=csv",
			null,
			function(data, status, jqXHR) {
				var data = JQuery._static.csv.toArrays(data);
				var header = data[1];
				var row_i = 0;
				var _list = [
					for (row in data)
					if (
						row_i++ > 1 &&
						row[header.indexOf("商店名")] != "" &&
						row[header.indexOf("位置/地址")] != ""
					)
					{
						name: row[header.indexOf("商店名")],
						address: row[header.indexOf("位置/地址")],
						detail: row[header.indexOf("支持內容")],
					}
				];
				trace(_list);
				list_umbrella.resolve(_list);
			}
		);

		new JQuery(function():Void{
			var title = new JQuery("#sr2_title a:first-child").text().trim();
			var loc = new JQuery(".map_btn")
				.parents(".info_basic_first .ML10.FL")
				.children("div:first-child").text();
			loc = loc.substr(loc.indexOf("地圖")+2).trim();
			//trace(title + " " + loc);

			new JQuery(".info_basic_first .col").prepend(
				switch (lang) {
					case zh:
						'<div class="sprite-global-icon FL"></div>
						<div class="ML10 FL" style="width: 255px;">
							<div>
								相關使用強冠豬油的商戶:<br>
								<div id="SafeRice_result_lard">搜尋中...</div>
							</div>
						</div>
						<div class="clearfix"></div>
						<div class="border_bottom_dot MT10 MB10"></div>
						<div class="sprite-global-icon FL"></div>
						<div class="ML10 FL" style="width: 255px;">
							<div>
								相關對遮打佔領行動表態的商戶:<br>
								<div id="SafeRice_result_umbrella">搜尋中...</div>
							</div>
						</div>
						<div class="clearfix"></div>
						<div class="border_bottom_dot MT10 MB10"></div>';
					case en:
						'<div class="sprite-global-icon FL"></div>
						<div class="ML10 FL" style="width: 255px;">
							<div>
								Chang Guann lard product user(s):<br>
								<div id="SafeRice_result_lard">searching...</div>
							</div>
						</div>
						<div class="clearfix"></div>
						<div class="border_bottom_dot MT10 MB10"></div>
						<div class="sprite-global-icon FL"></div>
						<div class="ML10 FL" style="width: 255px;">
							<div>
								Declaring view on Umbrella Movement:<br>
								<div id="SafeRice_result_umbrella">searching...</div>
							</div>
						</div>
						<div class="clearfix"></div>
						<div class="border_bottom_dot MT10 MB10"></div>';
				}
				
			);

			list_lard.then(function(data){
				var name_results = {
					var title = normalizeName(title);
					var fuse_name = new Fuse(data, {
						keys: ["normalizedName"],
						includeScore: true,
						threshold: 0.6,
						maxPatternLength: title.length
					});
					fuse_name.search(title);
				}
				trace(name_results);
				
				var address_results = {
					var fuse_address = new Fuse(data, {
						keys: ["address"],
						includeScore: true,
						threshold: 0.6,
						maxPatternLength: loc.length
					});
					fuse_address.search(loc);
				}
				trace(address_results);

				var matched = [];
				for (name_r in name_results) {
					if (name_r.score < 0.1) {
						matched.push(name_r.item);
					} else {
						for (addr_r in address_results) {
							if (addr_r.item == name_r.item) {
								matched.push(name_r.item);
								break;
							}
						}
					}
				}

				var matchedStr = [for (m in matched) '<option>${m.name} - ${m.address}</option>'].join("");
				var result = matched.length == 0 ? 
					switch (lang) {
						case zh:
							'<div style="color: green;">沒有找到</div>';
						case en:
							'<div style="color: green;">not found</div>';
					} : 
					'<div style="color: red;"><select style="width: 100%;color: red;margin: 0;padding: 0;">${matchedStr}</select></div>';
				new JQuery("#SafeRice_result_lard").html(result);
			});

			list_umbrella.then(function(data){
				var name_results = {
					var title = normalizeName(title);
					var fuse_name = new Fuse(data, {
						keys: ["name"],
						includeScore: true,
						threshold: 0.6,
						maxPatternLength: title.length
					});
					fuse_name.search(title);
				}
				trace(name_results);
				
				var address_results = {
					var fuse_address = new Fuse(data, {
						keys: ["address"],
						includeScore: true,
						threshold: 0.6,
						maxPatternLength: loc.length
					});
					fuse_address.search(loc);
				}
				trace(address_results);

				var matched = [];
				for (name_r in name_results) {
					if (name_r.score < 0.1) {
						matched.push(name_r.item);
					} else {
						for (addr_r in address_results) {
							if (addr_r.item == name_r.item) {
								matched.push(name_r.item);
								break;
							}
						}
					}
				}

				var matchedStr = [for (m in matched) '<option>${m.name} - ${m.address} - ${m.detail}</option>'].join("");
				var result = matched.length == 0 ? 
					switch (lang) {
						case zh:
							'<div>沒有找到</div>';
						case en:
							'<div>not found</div>';
					} : 
					'<div>
						<select style="width: 100%;margin: 0;padding: 0;">${matchedStr}</select>
						<a 
							href="https://docs.google.com/a/onthewings.net/spreadsheets/d/19IM5t97cSIEqbvwH4CyTrouUyEdKI-kZQsPXbe0l3r8/edit#gid=0"
							target="_blank"
							style=""
							>detail</a>
					</div>';
				new JQuery("#SafeRice_result_umbrella").html(result);
			});
		});
	}
}