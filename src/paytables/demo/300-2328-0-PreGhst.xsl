<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var scenarioWinningNumbers = getNumbers(scenario);
						var scenarioGames = getGames(scenario);
						var scenarioGamePrizes = getGamePrizes(scenario);
						var scenarioGame2Prizes = getGame2Prizes(scenario);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );
						var prizeNames = (prizeNamesDesc.substring(1)).split(','); 

						const gridCols 		= 9;
						const gridRows 		= 5;
						var bCurrSymbAtFront = false;
						var strCurrSymb      = '';
						var strDecSymb       = '';
						var strThouSymb      = '';

						const gamelayout = [[5,2], [4,3], [3,4], [2,5], [1,6], [1,6], [2,5], [2,4], [0,3], [4,2]];

						var r = [];

						/////////////////////////
						// Currency formatting //
						/////////////////////////
						function getCurrencyInfoFromTopPrize()
						{
							var topPrize               = convertedPrizeValues[0];
							var strPrizeAsDigits       = topPrize.replace(new RegExp('[^0-9]', 'g'), '');
							var iPosFirstDigit         = topPrize.indexOf(strPrizeAsDigits[0]);
							var iPosLastDigit          = topPrize.lastIndexOf(strPrizeAsDigits.substr(-1));
							bCurrSymbAtFront           = (iPosFirstDigit != 0);
							strCurrSymb 	           = (bCurrSymbAtFront) ? topPrize.substr(0,iPosFirstDigit) : topPrize.substr(iPosLastDigit+1);
							var strPrizeNoCurrency     = topPrize.replace(new RegExp('[' + strCurrSymb + ']', 'g'), '');
							var strPrizeNoDigitsOrCurr = strPrizeNoCurrency.replace(new RegExp('[0-9]', 'g'), '');
							strDecSymb                 = strPrizeNoDigitsOrCurr.substr(-1);
							strThouSymb                = (strPrizeNoDigitsOrCurr.length > 1) ? strPrizeNoDigitsOrCurr[0] : strThouSymb;
						}

						getCurrencyInfoFromTopPrize();						

						///////////////////////
						// Output Game Parts //
						///////////////////////
						const cellHeight    = 48;
						const cellMargin    = 1;
						const cellSizeX     = 90;
						const cellSizeY     = 48;
						const cellTextX     = 40; 
						const cellTextY     = 15; 
						const cellTextY1    = 26; 
						const colourBlack   = '#000000';
						const colourLime    = '#ccff99';
						const colourRed     = '#ff0000'; // '#ff9999';
						const colourWhite   = '#ffffff';
						const colourBlue	= '#3a32a8';

						var boxColourStr  = '';
						var textColourStr = '';
						var canvasIdStr   = '';
						var elementStr    = '';

						var gridCanvasWinsHeight = cellSizeY + 2 * cellMargin;
						var gridCanvasWinsWidth  = (gridCols+1) * cellSizeX + 2 * cellMargin;
						var gridCanvasYourHeight = gridRows * cellSizeY + 2 * cellMargin;
						var gridCanvasYourWidth  = gridCols * cellSizeX + 2 * cellMargin;

						function showWinningNums(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var canvasWidth  = cellSizeX + 2 * cellMargin;
							var canvasHeight = cellSizeY + 2 * cellMargin;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + cellSizeX.toString() + ', ' + cellSizeY.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (cellSizeX - 2).toString() + ', ' + (cellSizeY - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (cellSizeX / 2 + cellMargin).toString() + ', ' + (cellSizeY / 2 + cellMargin).toString() + ');');

							r.push('</script>');
						}

						/////////////////////////
						// Data pre-processing //
						/////////////////////////
						var scenarioGame2PrizeWins = [false, false, false, false];
						for (var i = 0; i < scenarioGame2Prizes.length -1; i++)
						{
							for (var j = i+1; j < scenarioGame2Prizes.length; j++)
							{
								if (scenarioGame2Prizes[i] == scenarioGame2Prizes[j])
								{
									scenarioGame2PrizeWins[i] = true;
									scenarioGame2PrizeWins[j] = true;
								}
							}
						}

						/////////////////////
						// Winning Numbers //
						/////////////////////
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						// Headings
						r.push('<tr>');
						r.push('<td align="center" colspan="1">');
						r.push(getTranslationByName("game1", translations));
						r.push('</td>');
						r.push('<td align="center" colspan="4">');
						r.push(getTranslationByName("winningNumbers", translations));
						r.push('</td>');
						r.push('</tr>');
						
						var gridCol = 0;
						var prizeCounter = 0;
						var k = 0;
						var boolWinCell = false;

						for (var i = 0; i < gamelayout.length; i++)
						{
							r.push('<tr>');
							// Winning Numbers
							for (var num = 0; num < Number(gamelayout[i][0]); num++)
							{
								canvasIdStr = 'cvsWinningGrid0' + i.toString() + num.toString(); 
								elementStr  = 'eleWinningGrid0' + i.toString() + num.toString(); 

								if ((i+1) < gamelayout.length)
								{
									symbCell = scenarioWinningNumbers[gridCol];
									boolWinCell = (scenarioGames.join(',').split(',').indexOf(symbCell.toString()) > -1);
								}
								else
								{	
									var prizeCell = scenarioGame2Prizes[prizeCounter];
									symbCell = convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeCell)];
									boolWinCell = scenarioGame2PrizeWins[prizeCounter];
									prizeCounter++;
								}

								boxColourStr  = (boolWinCell == true) ? colourRed : colourBlue;
								textColourStr = colourWhite; 

								switch (i)
								{
									case 6:
										symbCell = getTranslationByName("bonus", translations) + ' ' + symbCell + ' X2';
									break;
									case 7:
										symbCell = getTranslationByName("bonus", translations) + ' ' + symbCell + ' X5';
									break;
								}

								r.push('<td>');
								showWinningNums(canvasIdStr, elementStr, boxColourStr, textColourStr, symbCell);
								r.push('</td>');
								gridCol++;
							}
							// Empty cells between numbers and plays
							if (i == 8)
							{
								r.push('<td align="center" colspan="4">');
								r.push(getTranslationByName("game2", translations));
								r.push('</td>');
							}
							if ((i == 7) || (i == 9))
							{
								r.push('<td></td>');
							}
							// Empty Cell between numbers and plays
							r.push('<td></td>'); // All lines need at least 1 empty cell
							// Plays
							for (var j = 0; j < Number(gamelayout[i][1]); j++)
							{
								canvasIdStr = 'cvsWinningGrid1' + i.toString() + j.toString(); 
								elementStr  = 'eleWinningGrid1' + i.toString() + j.toString(); 

								if ((j +1) < Number(gamelayout[i][1])) 
								{ // Game Plays
									k = i;
									if (i > 4)
									{
										k = 14 - i;
									}
									symbCell = scenarioGames[k][j];
									boolWinCell = (scenarioWinningNumbers.indexOf(symbCell) > -1);
								}
								else
								{ // Prize Value
									k = i;
									if (i > 4)
									{
										k = 14 - i;
									}
									var prize = scenarioGamePrizes[k];
									boolWinCell = ((prize.length > 1) && (prize[1] == '*'));
									prize = boolWinCell ? prize[0] : prize;
									symbCell = convertedPrizeValues[getPrizeNameIndex(prizeNames, prize)];
								}

								boxColourStr  = (boolWinCell == true) ? colourRed : colourBlue;
								textColourStr = colourWhite; 

								r.push('<td>');
								showWinningNums(canvasIdStr, elementStr, boxColourStr, textColourStr, symbCell);
								r.push('</td>');
							}
						}

						r.push('</table>');

						r.push('&nbsp;');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						if(debugFlag)
						{
							//////////////////////////////////////
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					function getScenario(jsonContext)
					{
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getNumbers(scenario)
					{
						var numsData = scenario.split("~")[0];
						return numsData.split(",");
					}

					function getGames(scenario)
					{
						var gameInfo = [];
						var gamePlayData = [];
						var numsData = scenario.split("~")[1];
						var gamesData = numsData.split("||||")[0];
						var gameData = gamesData.split ("||");
						for (i = 0; i < gameData.length; i++)
						{
							gamePlayData = gameData[i].split(":")[0];
							gameInfo.push(gamePlayData.split(","));
						}
						return gameInfo;
					}

					function getGamePrizes(scenario)
					{
						var gamePrizes = [];

						var numsData = scenario.split("~")[1];
						var gamesData = numsData.split("||||")[0];
						var gameData = gamesData.split ("||");
						for (i = 0; i < gameData.length; i++)
						{
							gamePrizes.push(gameData[i].slice(gameData[i].indexOf(":") +1, gameData[i].length));
						}
						return gamePrizes;
					}

					function getGame2Prizes(scenario)
					{
						var game2Data = scenario.split("||||")[1];
						var prizesData = game2Data.split(",");
						return prizesData;
					}

					function inArray(needle, haystack) 
					{
 						for (var i = 0; i < haystack.length; i++) 
						{
 							if (haystack[i] == needle)
  								return true;
 						}
 						return false;
					}

					function getPrizeInCents(AA_strPrize)
					{
						return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
					}

					function getCentsInCurr(AA_iPrize)
					{
						var strValue = AA_iPrize.toString();

						strValue = (strValue.length < 3) ? ('00' + strValue).substr(-3) : strValue;
						strValue = strValue.substr(0,strValue.length-2) + strDecSymb + strValue.substr(-2);
						strValue = (strValue.length > 6) ? strValue.substr(0,strValue.length-6) + strThouSymb + strValue.substr(-6) : strValue;
						strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

						return strValue;
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
