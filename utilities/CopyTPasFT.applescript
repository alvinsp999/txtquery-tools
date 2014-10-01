property pTitle : "Copy from TaskPaper in FOLDINGTEXT format"

	
	function(editor, options) {

		// HOW MANY PRECEDING TABS OR HASHES FOR THIS LINE IN FT ?
		function FTPrefix(oNode) {
			var oParent=oNode.parent, lngLevel=1, lngProjLevel=1, blnFound=false,
			strType=oNode.type(), blnProj = (strType == 'project'), strPrefix;

			blnFound = blnProj;
			while (oParent) {
				lngLevel++;
				if (blnFound) lngProjLevel ++;
				else blnFound = (oParent.type() == 'project');
				oParent = oParent.parent;
			}
			if (blnProj) strPrefix = '\\n' + Array(lngLevel).join('#') + ' ';
			else strPrefix = Array(lngLevel-lngProjLevel).join('\\t');

			return strPrefix;
		}

		// GET THE SELECTED LINES
		var lstNodes = editor.selectedRange().nodesInRange(),
				lstLines=[], varNode, strLine, rgxEndColon = /^(.*):(.*?)$/;

		// AND GIVE AN FT PREFIX (HASHES OR TABS) TO EACH ONE
		lstNodes.forEach(function (oNode) {
			strLine = oNode.line().trim();
			
			// REMOVING THE COLON FROM PROJECTS (BUT LEAVING TRAILLING TAGS)
			if (oNode.type() == 'project')
				strLine=strLine.replace(rgxEndColon, '$1$2');
			lstLines.push([FTPrefix(oNode),strLine].join(''));
		});

		return lstLines.join('\\n');
	}

"