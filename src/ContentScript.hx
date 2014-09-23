import js.Lib;
import js.Browser.*;
import jQuery.*;
import chrome.*;
import promhx.Deferred;
using StringTools;
using Reflect;

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

	static function main():Void {
		switch (document.location) {
			case {
				pathname: "/restaurant/sr2.htm",
				search: getQueryParams(_) => param
			}:
				restaurantPage(param.shopid);
			case _:
		}
		
	}

	static function restaurantPage(shopid:String):Void {
		new JQuery(function():Void{
			var title = new JQuery("#sr2_title").text().trim();
			var loc = new JQuery(".map_btn")
				.parents(".info_basic_first .ML10.FL")
				.children("div:first-child").text();
			loc = loc.substr(loc.indexOf("地圖")+2).trim();
			//trace(title + " " + loc);

			new JQuery(".info_basic_first .col").prepend(
				'<div class="sprite-global-icon FL"></div>
				<div class="ML10 FL" style="width: 255px;">
					<div>
						相關強冠豬油商戶:<br>
						<div id="SafeRice_result">搜尋中...</div>
					</div>
				</div>
				<div class="clearfix"></div>
				<div class="border_bottom_dot MT10 MB10"></div>'
			);

			var list = new Deferred<Array<Dynamic>>();
			JQuery._static.get(
				Extension.getURL("data/Traders_who_imported_distributed_the_lard_produced_by_Chang_Guann.csv"),
				null,
				function(data, status, jqXHR) {
					list.resolve(JQuery._static.csv.toObjects(data));
				}
			);
			list.then(function(data){
				var data_name_max = 0;
				var data_address_max = 0;
				for (obj in data) {
					if (obj.name.length > data_name_max)
						data_name_max = obj.name.length;
					if (obj.address.length > data_address_max)
						data_address_max = obj.address.length;
				}
				
				var name_results = {
					var fuse_name = new Fuse(data, {
						keys: ["name"],
						includeScore: true,
						threshold: 0.2,
						maxPatternLength: Std.int(data_name_max * 1.2)
					});
					fuse_name.search(title);
				}
				
				var address_results = {
					var fuse_address = new Fuse(data, {
						keys: ["address"],
						includeScore: true,
						threshold: 0.4,
						maxPatternLength: Std.int(data_address_max * 1.2)
					});
					fuse_address.search(loc);
				}

				var matched = null;
				for (name_r in name_results) {
					var addr_score = 1;
					for (addr_r in address_results) {
						if (addr_r.item == name_r.item) {
							addr_score = addr_r.score;
							break;
						}
					}
					if (addr_score < 1) {
						trace(name_r.item);
						trace(name_r.score);
						trace(addr_score);
						matched = name_r.item;
						break;
					}
				}
				var result = matched == null ? 
					'<div style="color: green;">沒有找到</div>' : 
					'<div style="color: red;">${matched.name}<br/>(${matched.address})</div>';
				new JQuery("#SafeRice_result").html(result);
			});
		});
	}
}