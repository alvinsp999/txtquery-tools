property pTitle : "Make/Adjust Reminder from FoldingText 2"

	function(editor, options) {
		'use strict';
		var tree = editor.tree(),
			node = editor.selectedRange().startNode, strText=node.text(), strUUID=options.uuid, strPattern, rgxLink, strUpdated,oMatch;
		strPattern='\\\\[.*\\\\]\\\\(' + strUUID + '\\\\)';
		rgxLink= new RegExp(strPattern);
		strUpdated = strText.replace(rgxLink, '[' + options.linkname + '](' +strUUID + ')');
		tree.beginUpdates();
			node.setText(strUpdated);
		tree.endUpdates();
		tree.ensureClassified();
	}
"
						'use strict'
						// call a 'reminder tools' plugin function to update and read the line	
						return require(options.pluginPath).updateAndReadForLink(options);
					}" with options precDateFields & {pluginPath:item 1 of lstloadedPlugins, linklabel:strLinkLabel})
					'use strict'
					var tree = editor.tree(),
						node = editor.selectedRange().startNode;
					tree.beginUpdates();
						node.setText(node.text() +  ' [' + options.linkname + '](' + options.uuid + ')' )
					tree.endUpdates();
					tree.ensureClassified();
				}" with options {uuid:varUUID, linkname:strLinkLabel})
				function(editor, options) {
					'use strict'
					// check for plugins
					var	fnQuery = require('ft/util/queryparameter').QueryParameter,
						lstPlugins = fnQuery('pluginPaths', '').split(':'),
						lstFound = [];
						options.needed.forEach(function(dctPlugin) {
							var strFolder = '/Plug-Ins/' + dctPlugin.name + '.ftplugin/',
								lngPlugins = lstPlugins.length, strPluginPath,
								blnFound, i, oPlugin;
							for (i=0; i<lngPlugins; i++) {
								strPluginPath = lstPlugins[i];
								blnFound = (strPluginPath.indexOf(strFolder) !== -1);
								if (blnFound) {
									// check whether the plugin is up to date
									oPlugin = require(strPluginPath);
									if (oPlugin.version >= dctPlugin.version) {
										lstFound.push(strPluginPath);
									} else {
										lstFound.push(oPlugin.version);
									}
									break;
								}
							}
							if (!blnFound) {lstFound.push(null);}
						});
					return lstFound;
				}" with options {needed:plstPlugins})