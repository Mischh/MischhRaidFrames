local MRF = Apollo.GetAddon("MischhRaidFrames")

local function getMischh()
	-- This is one line and one string: (even if Houston sais its not -.- God i love this Editor.)
	local str = "<51|{{n2|}smodules|{n41|}sUnit Handler|{n42|}sFrame Handler|{n43|}sframe|{n49|}sGroup Handler|n4|sprofile|}{{n3|}sArrow Icon|{n4|}sShield|{n5|}sMouse Interaction|{n6|}sSpacer|{n7|}sGradient Colors|{n13|}sConsumables|{n15|}sLead Marker|{n16|}sClass Icons|{n17|}sReadycheck|{n18|}sAbsorb|{n19|}sRaid Markers|{n20|}sDistance Fader|{n21|}sName|{n23|}sDefault Color|{n24|}sClass Colors|{n26|}sConstant Colors|{n35|}sDispel Indicator|{n36|}sBuffs|{n39|}sHealth|{n40|}sInterrupt Indicator|}{n0.5|syOffset|n0|sxOffset|n0.1|stime|n0|sdist|sFFFFFFFF|scolor|n20|shSize|+sactivated|n20|svSize|}{s%p%%|stext|}{-smouse3|sTarget Unit|smouse0|-smouseover|sDropdown Menu|smouse1|sFocus Unit|smouse2|-sadvancedMouseEnter|-smouse4|+sinvertActions|+sactivated|}{n0|sp|}{{n8|}n1|}{{n9|}sanchors|+sfrequent|sHealth|sname|+sGet|}{{n10|}n1|{n11|}n100|{n12|}n0|}{n1|sa|n1|sr|n0|sg|n0|sb|}{n1|sa|n1|sr|n1|sg|n0|sb|}{n1|sa|n0.7|sr|n0.7|sg|n0.7|sb|}{+sshowBoost|n0.83|sxOffset|-sboxed|+snocombat|+sshowSpeed|+sshowFire|n20|ssize|n0.5|syOffset|n-2|sspace|+sshowFood|+sactivated|{n14|}ssorting|}{sFire|n1|sSpeed|n2|sFood|n3|sBoost|n4|}{sFF41B8FF|sinvColor|n0.5|syOffset|sFFEA0000|sleadColor|-sfill|n0|sxOffset|n6|shSize|+sactivated|n30|svSize|}{n0.03|sxOffset|n22|svSize|n0.5|syOffset|n22|shSize|-sactivated|}{n0.15|sxOffset|n26|svSize|n20|sinterval|n0.5|syOffset|n26|shSize|+sactivated|}{s%p%%|stext|sGetMaxHealth|sreference|s10000|scustomMax|}{n0.5|syOffset|n22|svSize|n1|sxOffset|n22|shSize|+sactivated|}{n40|sdistance|+sactivated|n0.3|sfraction|}{{n22|}snicknames|s%n|stext|}{}{-sfrequent|sFFFFFFFF|sc|sDefault|sname|+sGet|}{sFFF54F4F|n1|sFFFFC830|n2|sFF1591DB|n3|sFF00D030|n4|sFFD23EF4|n5|sFFF47E2F|n7|{n25|}sref|}{-sfrequent|sClass Color|sname|+sGet|}{{n27|}n1|{n28|}n2|{n29|}n3|{n30|}n4|{n31|}n5|{n32|}n6|{n33|}n7|{n34|}n8|}{-sfrequent|sWhite|sname|sFFFFFFFF|sc|+sGet|}{-sfrequent|sBlack|sname|sFF000000|sc|+sGet|}{-sfrequent|sFUIGray|sname|sFF272727|sc|+sGet|}{-sfrequent|sRed|sname|sFFFF0000|sc|+sGet|}{-sfrequent|sLightBlue|sname|sFF00A0FF|sc|+sGet|}{-sfrequent|sYellow|sname|sFFFFD000|sc|+sGet|}{-sfrequent|sInvisible|sname|s00FFFFFF|sc|+sGet|}{}{n-2|sbottomOffset|n-2|sleftOffset|sFFA100FE|scolor|n2|stopOffset|+sactivated|n2|srightOffset|}{n0|sxOffset|{n37|}sbuffs|-sactivated|n0.5|syOffset|}{{n38|}n1|}{s<|stimeComp|n0|sxPos|s|spattern|sFFFFFFFF|scolor|n10|sySiz|-sisSpellID|s<|sstackComp|n10|sxSiz|-sonlyMine|sBuff|sname|sFFFFFFFF|stextColor|n0|syPos|sBuffs Name|sspellName|}{s%n|stext|}{n-3|sbottomOffset|n-50|sleftOffset|sFFFFFFFF|scolor|n50|srightOffset|-sbackdropped|n0.5|sverticalPos|n0|shorizontalPos|n3|sdisptime|-sedge|n-6|stopOffset|}{n1|sfrequent|-seachFrame|n1|sunit|}{n0|sverticalFrameSpace|srow|sdirection|n0|sbottomHeaderSpace|n0|stopHeaderSpace|n0|sxOffset|n1|slength|n0|shorizonalFrameSpace|n0|syOffset|}{{n44|}n1|{n45|}n2|{n47|}{n46|}n1|sinset|sFF000000|sbackcolor|{n48|}ssize|}{sForgeUI_Smooth|srTexture|sName|stextSource|sHealth|smodKey|sc|svTextPos|sc|shTextPos|{n29|}slColor|n4|ssize|{n8|}srColor|sForgeUI_Smooth|slTexture|{n25|}stextColor|}{sForgeUI_Smooth|srTexture|{n29|}slColor|sForgeUI_Smooth|slTexture|sShield|smodKey|{n31|}srColor|n1|ssize|}{n4|n0|}{sForgeUI_Smooth|srTexture|{n32|}slColor|sForgeUI_Smooth|slTexture|sAbsorb|smodKey|{n33|}srColor|n1|ssize|}{n0|n1|n0|n2|n250|n3|n25|n4|}{-suse|{n50|}scache|-spublish|+saccept|+sactivationAccept|{n51|}ssaved|+sdecativationGroup|+slead|}{}{}}>"	

	return MRF:StringToProfile(str)
end

local function getVRF()
	-- This is one line and one string: (even if Houston sais its not -.- God i love this Editor.)
	local str = "<54|{{n2|}smodules|{n40|}sUnit Handler|{n41|}sFrame Handler|{n42|}sframe|{n52|}sGroup Handler|n4|sprofile|}{{n3|}sArrow Icon|{n4|}sShield|{n5|}sMouse Interaction|{n6|}sSpacer|{n7|}sGradient Colors|{n12|}sConsumables|{n14|}sLead Marker|{n15|}sClass Icons|{n16|}sReadycheck|{n17|}sAbsorb|{n18|}sRaid Markers|{n19|}sDistance Fader|{n20|}sClass Colors|{n22|}sDefault Color|{n23|}sName|{n25|}sConstant Colors|{n34|}sDispel Indicator|{n35|}sBuffs|{n38|}sHealth|{n39|}sInterrupt Indicator|}{n20|svSize|sFFFFFFFF|scolor|n0.1|stime|n0|sdist|n0|sxOffset|n20|shSize|-sactivated|n0.5|syOffset|}{s%p%%|stext|}{sTarget Unit|smouse3|sTarget Unit|smouse0|-smouseover|sDropdown Menu|smouse1|+sinvertActions|-sadvancedMouseEnter|sTarget Unit|smouse4|+sactivated|sTarget Unit|smouse2|}{n0|sp|}{{n8|}n1|}{+sfrequent|{n9|}sanchors|sGrayOrDead|sname|+sGet|}{{n10|}n1|{n11|}n0|}{n1|sa|n0.15686275064945|sb|n0.15686275064945|sg|n0.15686275064945|sr|}{n1|sa|n0.74117648601532|sb|n0.74117648601532|sg|n0.74117648601532|sr|}{+sshowBoost|n0.83|sxOffset|-sboxed|+snocombat|+sshowSpeed|+sshowFire|n20|ssize|n0.5|syOffset|n-2|sspace|+sshowFood|-sactivated|{n13|}ssorting|}{sFire|n1|sSpeed|n2|sFood|n3|sBoost|n4|}{sFF41B8FF|sinvColor|n0.5|syOffset|n30|svSize|sFFEA0000|sleadColor|n0|sxOffset|n6|shSize|+sactivated|-sfill|}{n0.5|syOffset|n0.03|sxOffset|n22|shSize|-sactivated|n22|svSize|}{n0.5|syOffset|n60|sinterval|n0.92|sxOffset|n26|shSize|+sactivated|n26|svSize|}{s%p%%|stext|sGetMaxHealth|sreference|s10000|scustomMax|}{n0.5|syOffset|n1.09|sxOffset|n22|shSize|+sactivated|n22|svSize|}{n40|sdistance|+sactivated|n0.65|sfraction|}{sfff54f4f|n1|sffefab48|n2|sff1591db|n3|sffffe757|n4|sffd23ef4|n5|sff98c723|n7|{n21|}sref|}{-sfrequent|sClass Color|sname|+sGet|}{-sfrequent|sDefault|sname|sFFFFFFFF|sc|+sGet|}{{n24|}snicknames|s%f8|stext|}{}{{n26|}n1|{n27|}n2|{n28|}n3|{n29|}n4|{n30|}n5|{n31|}n6|{n32|}n7|{n33|}n8|}{-sfrequent|sFFFFFFFF|sc|sWhite|sname|+sGet|}{-sfrequent|sFF000000|sc|sBlack|sname|+sGet|}{-sfrequent|sff282828|sc|sGrayBack|sname|+sGet|}{-sfrequent|sFFFF0000|sc|sRed|sname|+sGet|}{-sfrequent|sff178e88|sc|sLightBlue|sname|+sGet|}{-sfrequent|sFFFFD000|sc|sYellow|sname|+sGet|}{-sfrequent|s00FFFFFF|sc|sInvisible|sname|+sGet|}{}{n0|sbottomOffset|n0|sleftOffset|sffff0000|scolor|n0|srightOffset|+sactivated|n0|stopOffset|}{n0|sxOffset|{n36|}sbuffs|-sactivated|n0|syOffset|}{{n37|}n1|}{s<|sstackComp|sFFFFFFFF|scolor|n10|sySiz|-sisSpellID|sBuffs Name|sspellName|n10|sxSiz|-sonlyMine|s<|stimeComp|s|spattern|sBuff|sname|n0|syPos|n0|sxPos|sFFFFFFFF|stextColor|}{s%n|stext|}{n-1|sbottomOffset|n17|sleftOffset|s87ffffff|scolor|n-18|srightOffset|n-0.15|shorizontalPos|n1|stopOffset|+sedge|-sbackdropped|n3|sdisptime|+sactivated|n0|sverticalPos|}{n1|sfrequent|-seachFrame|n1|sunit|}{n1|stopHeaderSpace|srow|sdirection|n-1|sbottomHeaderSpace|n-4|sverticalFrameSpace|n0|sxOffset|n3|slength|n17|shorizonalFrameSpace|n0|syOffset|}{sff000000|sbackcolor|{n44|}{n43|}{n46|}{n45|}{n48|}{n47|}{n50|}{n49|}n1|sinset|{n51|}ssize|}{n0|n1|n0|n2|n0.69|n3|n1|n4|}{sc|shTextPos|-stextSource|sHealth|smodKey|sc|svTextPos|n4|ssize|sWhiteFill|slTexture|{n21|}slColor|{n8|}srColor|sWhiteFill|srTexture|{n26|}stextColor|}{n0.69|n1|n0|n2|n0.85|n3|n1|n4|}{sWhiteFill|srTexture|{n30|}slColor|sWhiteFill|slTexture|sShield|smodKey|{n28|}srColor|n1|ssize|}{n0.03|n1|n0|n2|n1|n3|n1|n4|}{sWhiteFill|srTexture|sName|stextSource|sSpacer|smodKey|sc|svTextPos|{n22|}stextColor|{n32|}slColor|sl|shTextPos|{n32|}srColor|sWhiteFill|slTexture|n1|ssize|}{n0.85|n1|n0|n2|n1|n3|n1|n4|}{sWhiteFill|srTexture|{n31|}slColor|sWhiteFill|slTexture|sAbsorb|smodKey|{n28|}srColor|n1|ssize|}{n0|n1|n0|n2|n108|n3|n30|n4|}{sClass|sresort|+saccept|+slead|{n53|}scache|{n54|}ssaved|+sactivationAccept|-spublish|+sdecativationGroup|-suse|}{}{}}>"
	
	return MRF:StringToProfile(str)
end

local function getGrid()
	-- This is one line and one string: (even if Houston sais its not -.- God i love this Editor.)
	local str = "<56|{{n2|}smodules|{n46|}sUnit Handler|{n47|}sframe|{n53|}sGroup Handler|{n56|}sFrame Handler|}{{n3|}sArrow Icon|{n4|}sShield|{n5|}sMouse Interaction|{n6|}sSpacer|{n7|}sGradient Colors|{n18|}sConsumables|{n20|}sLead Marker|{n21|}sClass Icons|{n22|}sReadycheck|{n23|}sAbsorb|{n24|}sRaid Markers|{n25|}sDistance Fader|{n26|}sClass Colors|{n28|}sHealth|{n29|}sName|{n31|}sConstant Colors|{n40|}sDispel Indicator|{n41|}sBuffs|{n44|}sDefault Color|{n45|}sInterrupt Indicator|}{n20|svSize|s8fffffff|scolor|n0.1|stime|n0|sdist|n0.5|sxOffset|n20|shSize|+sactivated|n0.5|syOffset|}{s%p%%|stext|}{-smouse3|sTarget Unit|smouse0|sTarget Unit|smouseover|sDropdown Menu|smouse1|+sinvertActions|+sadvancedMouseEnter|-smouse4|+sactivated|-smouse2|}{n0|sp|}{{n8|}n1|{n13|}n2|}{+sfrequent|{n9|}sanchors|sHealth|sname|+sGet|}{{n10|}n1|{n11|}n100|{n12|}n0|}{n1|sa|n0|sb|n0|sg|n1|sr|}{n1|sa|n0|sb|n1|sg|n1|sr|}{n1|sa|n0.7|sb|n0.7|sg|n0.7|sr|}{{n14|}sanchors|+sfrequent|sAlive/Dead|sname|+sGet|}{{n15|}n1|{n16|}n100|{n17|}n0|}{n1|sa|n0.25098040699959|sb|n0.25098040699959|sg|n0.25098040699959|sr|}{n1|sa|n0.25098040699959|sb|n0.25098040699959|sg|n0.25098040699959|sr|}{n1|sa|n0.78431379795074|sb|n0.78431379795074|sg|n0.78431379795074|sr|}{+sshowBoost|n0.83|sxOffset|-sboxed|+snocombat|+sshowSpeed|+sshowFire|{n19|}ssorting|n0.5|syOffset|n-2|sspace|+sshowFood|-sactivated|n20|ssize|}{sFire|n1|sSpeed|n2|sFood|n3|sBoost|n4|}{sFF41B8FF|sinvColor|n30|svSize|-sfill|n0|sxOffset|sFFEA0000|sleadColor|n6|shSize|-sactivated|n0.5|syOffset|}{n0.5|syOffset|n0.03|sxOffset|n22|shSize|-sactivated|n22|svSize|}{n0.5|syOffset|n0.15|sxOffset|n20|sinterval|n26|shSize|-sactivated|n26|svSize|}{s%p%%|stext|sGetAbsorbtionMax|sreference|s10000|scustomMax|}{n22|svSize|n1|sxOffset|n22|shSize|-sactivated|n0.5|syOffset|}{n25|sdistance|+sactivated|n0.3|sfraction|}{sffab855e|n1|sffa41a31|n2|sff74ddff|n3|sffffffff|n4|sffddd45f|n5|sff826fac|n7|{n27|}sref|}{-sfrequent|sClass Color|sname|+sGet|}{s%n|stext|}{{n30|}snicknames|s%n8|stext|}{}{{n32|}n1|{n33|}n2|{n34|}n3|{n35|}n4|{n36|}n5|{n37|}n6|{n38|}n7|{n39|}n8|}{-sfrequent|sFFFFFFFF|sc|sWhite|sname|+sGet|}{-sfrequent|sFF000000|sc|sBlack|sname|+sGet|}{-sfrequent|sff68ffba|sc|sBlueish|sname|+sGet|}{-sfrequent|sffae9e58|sc|sYellowish|sname|+sGet|}{-sfrequent|s00FFFFFF|sc|sInvisible|sname|+sGet|}{}{}{}{n-2|sbottomOffset|n-2|sleftOffset|sFFA100FE|scolor|n2|srightOffset|+sactivated|n2|stopOffset|}{n0|sxOffset|{n42|}sbuffs|-sactivated|n0|syOffset|}{{n43|}n1|}{s<|sstackComp|sFFFFFFFF|scolor|n10|sySiz|-sisSpellID|sBuffs Name|sspellName|n10|sxSiz|-sonlyMine|s<|stimeComp|s|spattern|sBuff|sname|n0|syPos|n0|sxPos|sFFFFFFFF|stextColor|}{-sfrequent|sDefault|sname|sFFFFFFFF|sc|+sGet|}{n-3|sbottomOffset|n-50|sleftOffset|sFFFFFFFF|scolor|n50|srightOffset|n0|shorizontalPos|n-6|stopOffset|-sbackdropped|n3|sdisptime|-sedge|n0.5|sverticalPos|}{n1|sfrequent|-seachFrame|n1|sunit|}{{n48|}n1|{n49|}n2|sFF000000|sbackcolor|{n51|}{n50|}n2|sinset|{n52|}ssize|}{sWhiteFill|srTexture|sName|stextSource|sHealth|smodKey|sb|svTextPos|{n35|}stextColor|{n27|}slColor|sForgeUI_Smooth|slTexture|{n13|}srColor|sc|shTextPos|n29|ssize|}{sWhiteFill|srTexture|{n34|}slColor|sWhiteFill|slTexture|sShield|smodKey|{n33|}srColor|n1|ssize|}{n0.75|n1|n0.1|n2|n0.91|n3|n0.33|n4|}{sWhiteFill|srTexture|{n35|}slColor|sWhiteFill|slTexture|sAbsorb|smodKey|{n36|}srColor|n1|ssize|}{n0|n1|n0|n2|n64|n3|n44|n4|}{+slead|+saccept|{n54|}scache|{n55|}ssaved|-sactivationAccept|-spublish|-sdecativationGroup|-suse|}{}{}{n-2|stopHeaderSpace|srow|sdirection|n0|sbottomHeaderSpace|n-1|sverticalFrameSpace|n0|sxOffset|n5|slength|n-1|shorizonalFrameSpace|n0|syOffset|}}>"
	
	return MRF:StringToProfile(str)
end
--returns: {[nameOfDefault] = functionReturnsProfile}
function MRF:GetDefaultProfiles()
	return {
		Mischh = getMischh,
		VinceRaidFrames = getVRF,
		Grid = getGrid,
	}
end

function MRF:GetDefaults()
	return getMischh()
end
