function run() {
	'use strict';
	var	pTitle = "FT save as OPML",
		pVer = "0.2",
		pAuthor = "Rob Trew",
		pSite = "https://github.com/RobTrew/txtquery-tools",
		pComment = "\
			- Preserves the FoldingText outlining expansion state in the OPML.\
			- FoldingText @key(value) pairs become OPML attributes with string values\
			- FoldingText @tags with no value → OPML attributes with value 1\
		"
		
	var appSA=Application.currentApplication();
		appSA.includeStandardAdditions = true;
		
		
	//OPTIONS: 
	
	//Export the whole document, or just the subtree(s) of any selected line(s) ?
	var pblnWholeDoc=true;
	
	// Default folder for Save As dialog ?
	var pOutFolder= appSA.pathTo('desktop');
	// or e.g.  
	// 	var pOutFolder=Path("/Users/houthakker/docs")
		

	// FoldingText code	(to be passed as string, with options, to FT.evaluate() ...)	
	var fnScript =
		function(editor, options) {
			// FoldingText code here
			
			// FIND THE ROOT NODES AMONG THE SELECTED LINES
			// (Ignoring any children of lines already seen)
			function selectedRoots() {
				var lstRoots = [], lstSeen = [];
	
				editor.selectedRange().forEachNodeInRange(function(oNode) {
					if (oNode.type() !== 'empty') {
						if (lstSeen.indexOf(oNode.parent.id)===-1) lstRoots.push(oNode);
						lstSeen.push(oNode.id);
					}
				});
				return lstRoots;
			}
	
			// TRANSLATE A SET OF ROOTS AND THEIR DESCENDANTS INTO OPML
			function opmlTranslation(lstRoots, strTitle) {
	
				var lstOPMLHead = [
						'<?xml version=\"1.0\" encoding=\"utf-8\"?>',
						'<opml version=\"1.0\">',
						'  <head>',
						'    <title>' + strTitle + '</title>',
						'    <expansionState>'],
					lstOPMLPostExpand = [
						'</expansionState>',
						'  </head>',
						'  <body>\n'],
					lstOPMLTail = [
						'  </body>',
						'</opml>'],
					strNodeStart = '<outline text=\"',
					strLeafClose = '/>\n',
					strParentClose = '>\n',
					strOutlineClose = '</outline>\n',
					strHead = lstOPMLHead.join('\n'),
					strTail = lstOPMLTail.join('\n'),
					strOutline='', strOPML, lstOPML,
					lngRoots=lstRoots.length, i,
					lstFolds=[], iLine=0;

				// WRITE OUT A SINGLE NODE AS OPML, AND RECURSE WITH ITS CHILDREN
				function opmlOutline(oNode, strIndent, blnHidden) {
					var	strOut = strIndent + strNodeStart + quoteAttr(oNode.text()) + '\"',
						dctTags = oNode.tags(),
						blnChiln = oNode.hasChildren(),
						lstChiln, oChild,
						strKey, strValue, strDeeper=strIndent + '  ';
	
					// add @key(values) as attributes
					for (strKey in dctTags) {
						strValue = oNode.tag(strKey);
						if (!strValue) strValue=1;
						strOut += (' ' + strKey + '=\"' + quoteAttr(strValue) + '\"');
					}
	
					// recurse with any children before closing the <outline>
					if (blnChiln) {
						if (!blnHidden && !(editor.isCollapsed(oNode)))
							lstFolds.push(iLine); // Collect OPML ExpansionState digit
						else blnHidden=true;
						iLine++; // before the recursive descent
						
						strOut += strParentClose;
						lstChiln=oNode.children();
						for (var i=0, lng=lstChiln.length; i<lng; i++) {
							oChild=lstChiln[i];
							if (oChild.type()!=='empty')
								strOut += opmlOutline(oChild, strDeeper); 
						}
						strOut += (strIndent + strOutlineClose);
					} else {
						strOut += strLeafClose;
						iLine++;
					}					
					return strOut;
				}
				
							
				// RECURSE THROUGH THE TREE
				for (i=0; i<lngRoots; i++) {
					strOutline += opmlOutline(lstRoots[i], '    ', false);
				}
				
				// ASSEMBLE THE HEADER,
				// INCLUDING THE EXPANSION DIGITS COLLECTED DURING RECURSION
				strHead += (lstFolds.toString() + lstOPMLPostExpand.join('\n'));
			
			
				// AND COMBINE HEAD BODY AND TAIL
				strOPML = [strHead, strOutline, strTail].join('');
				//strOPML = strOutline;
				return strOPML;
			}

			function quoteAttr(s) {
			    return ('' + s) /* Forces the conversion to string. */
			        .replace(/&/g, '&amp;') /* This MUST be the 1st replacement. */
			        .replace(/\'/g, '&apos;') /* The 4 other predefined entities, required. */
			        .replace(/\"/g, '&quot;')
			        .replace(/</g, '&lt;')
			        .replace(/>/g, '&gt;');
			}

	//////// FT MAIN
	
			var lstRoots;

			// EXPORT WHOLE DOC ? OR JUST THE SELECTED LINE(S) AND ALL ITS/THEIR DESCENDANTS ?
			if (options.wholedoc)
				lstRoots = editor.tree().evaluateNodePath('/@type!=empty');
			else lstRoots = selectedRoots();

			return opmlTranslation(lstRoots, quoteAttr(options.title));
		};
	
	//// run() FUNCTION(S)
		function chooseOutPath(oApp, oDocPath, strExtn) {
			var oFM=$.NSFileManager.defaultManager,
				pathLocn=pOutFolder, //module default
				pathOut=null,
				strName=oFM.displayNameAtPath(oDocPath.toString()).js,
				lstName=strName.split('.'),
				lngName=lstName.length,
				lstStem=lstName.slice(0,lngName-1),
				strStem=lstName[0];

			if (! oFM.fileExistsAtPathIsDirectory(pathLocn.toString(), null))
				pathLocn=oDocPath;
				
			// draft new name by substituting or affixing strExtn
			if (1<lngName) {
				lstStem.push(strExtn);
				strName=lstStem.join('.');
			} else strName+='.'+strExtn;
		
			// show file name dialog
			oApp.activate();
			pathOut=oApp.chooseFileName({
				withPrompt:pTitle,
				defaultName:strName,
				defaultLocation:pathLocn
			});
			return [pathOut, strStem];
		}
	
	//////// run() MAIN
	var	appFT=new Application("FoldingText"),
		//appSA=Application.currentApplication(),
		lstDocs = appFT.documents(),
		oDoc, oPath,
		strBaseName,
		strFTPath, pathOML=null,
		lngDocs = lstDocs.length,
		lstPathStem=[null,null],
		pathOPML=null,
		strOPML = null,
		nsOPML=null,
		strOPMLPath='',
		strMsg='';
			
	appFT.activate();
	appFT.includeStandardAdditions = true;

	if (lngDocs) {
		oPath=lstDocs[0].file();
		
		// PROMPT FOR AN EXPORT FILE PATH
		if (oPath) {
			lstPathStem=chooseOutPath(appFT, oPath, 'opml');
			pathOPML=lstPathStem[0];
			if (pathOPML) {
				strOPML = lstDocs[0].evaluate(
					{ script:fnScript.toString(),
						withOptions:{ 
							wholedoc:pblnWholeDoc,
							title:lstPathStem[1]
						}
					});
				if (strOPML) {
					strOPMLPath=pathOPML.toString();
					nsOPML = $.NSString.alloc.initWithUTF8String(strOPML);
					nsOPML.writeToFileAtomically(strOPMLPath, true);
				}
			}
		} else strMsg = "Save active file before exporting to OPML ...";		
	} else strMsg = "No FoldingText documents open ...";
	
	if (strMsg)	{
		appFT.displayDialog(strMsg,{
			withTitle: [pTitle, pVer].join('\t'),
			buttons:["OK"],
			defaultButton:"OK"
		});
		return false;
	} return "Saved to " + strOPMLPath;
}






