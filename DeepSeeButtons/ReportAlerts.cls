Class DeepSeeButtons.ReportAlerts
{

ClassMethod AlertRoutineSize(pRoutineSize, ByRef pAlerts)
{
	Try {
		If (pRoutineSize=0) {
			Set tPre="title=""Routine buffers have the default ''0'' value and might need customization"">"
			Set tAlert = "Alert: Routine buffers have not been customized"
			Set pAlerts($I(pAlerts)) = tPre_tAlert
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p class=""red"" "_tPre_tAlert_"</p>",8)
		}
		Set tSC = 1
	} Catch (ex) {
		Set tSC = ex.AsStatus()
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

ClassMethod AlertGlobalKSize(pGlobalKSize, ByRef pAlerts)
{
	Try {
		If (pGlobalKSize="0,0,0,0,0,0") {
			Set tPre="title=""Global buffers have the default ''0,0,0,0,0,0'' values and might need customization"">"
			Set tAlert="Alert: Global buffers have not been customized"
			Set pAlerts($I(pAlerts)) = tPre_tAlert
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p class=""red"" "_tPre_tAlert_"</p>",8)
		}
		Set tSC = 1
	} Catch (ex) {
		Set tSC = ex.AsStatus()
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

ClassMethod AlertDStimeRW(pDSTimeMapFrom, ByRef pAlerts)
{
	Try {
		ZN "%SYS"
		//Check if DB is Read-Write
		Set tSC = ##class(Config.Databases).Get(pDSTimeMapFrom,.tProp)
		//If a remote DB is used we do not know
		If tProp("Server")'="" {
			Set tDB=##Class(SYS.Database).%OpenId(tProp("Directory"))
			Set tReadOnly=tDB.ReadOnly
			If tReadOnly {
				Set tPre="title=""In Cach&eacute; versions including DevChange DTB422 ^OBJ.DSTIME and ^DeepSee.Update should be mapped to a Read-Write database"">"
				Set tAlert="Alert: ^OBJ.DSTIME and/or ^DeepSee.Update are stored in the "_DSTimeMapFrom_" database, which should be Read-Write"
				Set pAlerts($I(pAlerts)) = tPre_tAlert
				Do ##class(DeepSeeButtons.Utils).WriteLog("<p class=""red"" "_tPre_tAlert_"</p>",8)
			}
		}
		Set tSC = 1
	} Catch (ex) {
		Set tSC = ex.AsStatus()
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

ClassMethod AlertMappings(pNS, pMapping, ByRef pAlerts)
{
	Try {
		//Check if ^DeepSee.Cache.Results, .Axis, .Cells end up in a journaled DB
		ZN "%SYS"		
		Set tSC = $$$OK
		While 1 {
			If pMapping="Cache" {
				Set tCacheGlobal=$LG($LB("DeepSee.Cache.Results","DeepSee.Cache.Axis","DeepSee.Cache.Cells"),$I(i))
			} ElseIf pMapping="JoinIndex" {
				Set tCacheGlobal = $LG($LB("DeepSee.JoinIndex"),$I(i))
			}
			Quit:(tCacheGlobal="")
			Set tSysDir=##class(%SYS.Namespace).GetGlobalDest(pNS,tCacheGlobal)
			//sysdir is system^directory, but only the directory is needed for the following call
			Set tDB=##class(SYS.Database).%OpenId($P(tSysDir,"^",2))
			If (tDB.GlobalJournalState = 3) {
				Do ##Class(Config.Databases).DatabasesByDirectory($P(tSysDir,"^",1),$P(tSysDir,"^",2),.tListDB)
				Set tDBname=$LISTTOSTRING(tListDB,",") //In general I would expect one DB but there could be more
				Set tPre="title=""Journaling the DeepSee cache leads to problems with disk size and query performance"">"
				Set tAlert="Alert: The DeepSee cache stored in the "_tDBname_" database is journaled"
				Set pAlerts($I(pAlerts)) = tPre_tAlert
				Do ##class(DeepSeeButtons.Utils).WriteLog("<p class=""red"" "_tPre_tAlert_"</p>",8)
				Quit
			}	
		}
	} Catch (ex) {
		Set tSC = ex.AsStatus()
		Do ##class(DeepSeeButtons.Utils).WriteLog("<p class=""red"" "_$System.Status.GetErrorText(tSC)_"----ALE</p>",8)
	}
	Quit tSC
}

/*
ClassMethod AlertJoinIndexMappings(tNS, ByRef pAlerts) {
	Try {
		//Check if ^DeepSee.JoinIndex ends up in a journaled DB. 
		//It should go with the cache but it is less bad than journaling ^DeepSee.Cache* globals. 
		//For this reason I keep this alert separate from alertCacheMappings
		ZN "%SYS"		
		Set tSC = $$$OK
		Set cacheGlob = "DeepSee.JoinIndex"
		Set sysdir=##class(%SYS.Namespace).GetGlobalDest(tNS,cacheGlob)
		//sysdir is system^directory, but only the directory is needed for the following call
		Set DB=##class(SYS.Database).%OpenId($P(sysdir,"^",2))
		If (DB.GlobalJournalState = 3) {
			Do ##Class(Config.Databases).DatabasesByDirectory($P(sysdir,"^",1),$P(sysdir,"^",2),.listDB)
			Set DBname=$LISTTOSTRING(listDB,",") //In general I would expect one DB but there could be more
			Set tPre="title=""We suggest mapping the ^DeepSee.JoinIndex global together with the DeepSee cache to an unjournaled database"">"
			Set tAlert="Alert: The ^DeepSee.JoinIndex global stored in the "_DBname_" database is journaled"
			Set pAlerts($I(pAlerts)) = tPre_tAlert
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p class=""red"" "_tPre_tAlert_"</p>",8)
		}	
	} Catch (ex) {
		Set tSC = ex.AsStatus()
		Do ##class(DeepSeeButtons.Utils).WriteLog("<p class=""red"" "_tSC_"</p>",8)
	}
	Quit tSC
}
*/
ClassMethod AlertInitialBuildCubeManager(pCube, pMsgRepair, pMsgBuild, ByRef pAlerts)
{
	Try {
		Set tAlert=""
		Set tPre="title=""Before you synchronize cubes from the Cube Manager, it is necessary to build the cubes at least once from the Cube Manager."">"
		If ((pMsgRepair="Not found") && (pMsgBuild="Not found")) {
			Set tAlert = "Alert: there is no record for the initial build of "_pCube_" from Cube Manager. Check if the cube is updating"
			Set pAlerts($I(pAlerts)) = tPre_tAlert
		}
		Set tSC = 1
	} Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tAlert = tSC
		Set pAlerts($I(pAlerts)) = tAlert
	}
	Do ##class(DeepSeeButtons.Utils).WriteLog("<p class=""red"" "_tPre_tAlert_"</p>",8)
}

ClassMethod AlertTimeLevels(pTimeLevels, ByRef pAlerts)
{
	Try {
		Set throwalert=0
		Set DimNo=$O(pTimeLevels(""))
		For {
			Quit:DimNo=""
			Set HierNo=$O(pTimeLevels(DimNo,""))
			For {
				Quit:HierNo=""
				
				Set typeparent = ""
				Set levelparent = ""	
			
				Set LevelNo=$O(pTimeLevels(DimNo,HierNo,""))
				For {
					Quit:LevelNo=""
					Set levelType = $LG(pTimeLevels(DimNo,HierNo,LevelNo),1)
					
					Set type = $S(levelType="%DeepSee.Time.Decade":"normal",
						levelType="%DeepSee.Time.Year":"normal",
						levelType="%DeepSee.Time.QuarterYear":"normal",
						levelType="%DeepSee.Time.MonthYear":"normal",
						levelType="%DeepSee.Time.DayMonthYear":"normal",
						levelType="%DeepSee.Time.WeekYear":"normal",
						levelType="%DeepSee.Time.WeekNumber":"week",		
						levelType="%DeepSee.Time.QuarterNumber":"normal",
						levelType="%DeepSee.Time.MonthNumber":"normal",
						levelType="%DeepSee.Time.DayNumber":"normal",
						levelType="%DeepSee.Time.DayOfWeek":"normal",
						levelType="%DeepSee.Time.HourNumber":"time",
						levelType="%DeepSee.Time.MinuteNumber":"time",
						1:"custom")
					Set level = $S(levelType="%DeepSee.Time.Decade":9,
						levelType="%DeepSee.Time.Year":8,
						levelType="%DeepSee.Time.QuarterYear":7,
						levelType="%DeepSee.Time.MonthYear":6,
						levelType="%DeepSee.Time.DayMonthYear":3,
						levelType="%DeepSee.Time.WeekYear":5,
						levelType="%DeepSee.Time.WeekNumber":4,
						levelType="%DeepSee.Time.QuarterNumber":7,
						levelType="%DeepSee.Time.MonthNumber":6,
						levelType="%DeepSee.Time.DayNumber":3,
						levelType="%DeepSee.Time.DayOfWeek":3,
						levelType="%DeepSee.Time.HourNumber":2,
						levelType="%DeepSee.Time.MinuteNumber":1,
						1:"custom")
					
					//Start by excluding the custom time dimensions. 
					If (type="custom") || (typeparent="custom") {
						//Custom time levels. Good to go
					} ElseIf (typeparent = "") || (levelparent="") {
						//Top level. Good to go
					} ElseIf (level>levelparent) {
						Set throwalert = 1
					} ElseIf (type'=typeparent) {
						//Check when mixing different types. The previous check took care of several wrong cases
						//Hours and Minutes are incompatible with anything else
						If (type="time") || (typeparent="time") {
							Set throwalert = 1
						} ElseIf (typeparent="normal") && (type="week") { 
							//WeekNumber is under a "normal" level such as Year. WeekYear is ok
							If (level'=4) {
								Set throwalert = 1
							}
						} ElseIf (typeparent="week") {
							//This is fine because type="time" bigger level numbers were caught before. Days are fine
						} ElseIf (typeparent="other") {
							//I assume abstract/custom time functions are ok
						}
					}
 					If throwalert=1 {
	 					Set tl = pTimeLevels(DimNo,HierNo,LevelNo)
	 					Set tPre="title=""Placing certain time levels such as Year of Month in the same hierarchy as a week level will lead to unexpected results"">"
	 					Set tAlert="The "_$LG(tl,3)_"."_$LG(tl,4)_"."_$LG(tl,5)_" level in the "_$LG(tl,2)_
	 						" cube using the "_$LG(tl,1)_" time function is incompatible with other time levels in the same hierarchy"
	 					Set pAlerts($I(pAlerts)) = tPre_tAlert
						Do ##class(DeepSeeButtons.Utils).WriteLog("<p class=""red"" "_tPre_tAlert_"</p>",0)
						Set throwalert=0
	 					//Advance to next hierarchy, right?
	 					Quit
 					}
 					 					
 					Set typeparent = type
 					Set levelparent = level
 					Set LevelNo=$O(pTimeLevels(DimNo,HierNo,LevelNo))
				}
				Set HierNo=$O(pTimeLevels(DimNo,HierNo))
			}
			Set DimNo=$O(pTimeLevels(DimNo))
		}
		Set tSC = 1
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
