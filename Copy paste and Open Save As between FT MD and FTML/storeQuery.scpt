JsOsaDAS1.001.00bplist00�Vscript_�dctQuery = {
	'Group by priority': 'declare default order empty greatest;\
		for $line in db: open("input3") //li \
		let $priority: = $line / @data - priority\
		group by $priority\
		order by $priority\
		return (\
			concat("&#10;&#10;## Priority ", $priority, "&#10;"), \
			for $i in $line\
			let $txt: = string($i / p)\
			order by $txt\
			return concat("- ", $txt)\
		)'
}dctQuery['Group by priority']                              �jscr  ��ޭ