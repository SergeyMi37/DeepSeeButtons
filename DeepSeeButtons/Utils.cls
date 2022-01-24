Class DeepSeeButtons.Utils
{

ClassMethod WriteLog(pText As %String, pTabLevel As %Integer = 0)
{
	//If pText?1"***".e Quit
	//Write !,?spaces,string
	&html<#(pText)#>
}

ClassMethod WriteHeader4(pText As %String, pTabLevel As %Integer = 0, pTitle As %String = "")
{
	Do ##class(DeepSeeButtons.Utils).WriteLog("<h4"_$S(pTitle="":"",1:" title="""_pTitle_"""")_">"_pText_"</h4>",pTabLevel)
}

ClassMethod WriteUpdate(pText As %String)
{
	//Use PDev
	//Write $C(13,27)_"[0J"_msg
	//Use LogFile
	Quit
}

ClassMethod WriteParagraph(pName As %String, pTitle As %String, pFlag As %Integer = 1)
{
	Do:pFlag ##class(DeepSeeButtons.Utils).WriteLog("<hr noshade size=""4"">",2)
	Do ##class(DeepSeeButtons.Utils).WriteLog("<a name="""_pName_"""></a>",2)
	Do ##class(DeepSeeButtons.Utils).WriteLog("<h2>"_pTitle_"</h2>",2)
	Quit
}

ClassMethod WriteTrack(phase, mgs = "", details = "", errors = "")
{
	ZN namespace
	Set tStep = $Case(phase,"setup":1,"cubelog":2,"buildsynch":3,"cube":4,"getlogs":5,"databases":6,"tasks":7,"journal":8,"save":9,"warning":10,"complete":12,"error":13,:11)
	Set ^IRIS.Temp.DeepSeeButtonsTrack(+$J,tStep)=$LB(phase,mgs,details,errors)
	//If logging detail info on cubes or a warning, create a third node in the global
	Set:phase="cube" ^IRIS.Temp.DeepSeeButtonsTrack(+$J,tStep,details)=$LB(phase,mgs,details,errors)	
	Set:phase="warning" ^IRIS.Temp.DeepSeeButtonsTrack(+$J,tStep,details)=$LB(phase,mgs,details,errors)
}

ClassMethod WriteAdhocPatch()
{
	Try {
		Set patchvar=$Order(^%qPatch(""))
		While (patchvar'=""){
			Set data=^%qPatch(patchvar)
			Set patchvar2=$Order(^%qPatch(patchvar))			
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p style=""margin-left:3em;"">Adhoc: "_$list(data)_"</p>",8)
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p style=""margin-left:6em;"">Description: "_$list(data,2)_"</p>",8)
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p style=""margin-left:6em;"">Created at: "_$list(data,5)_"</p>",8)
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p style=""margin-left:6em;"">Created on $zv: "_$piece($list(data,6),")",1,2)_")"_"</p>",8)
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p style=""margin-left:6em;"">Applied on: "_$list(data,7)_"</p>",8)
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p style=""margin-left:6em;"">Applied by: "_$list(data,8)_"</p>",8)
			Do ##class(DeepSeeButtons.Utils).WriteLog("")
			Set patchvar=$Order(^%qPatch(patchvar))
		}
	} Catch(ex) {
		//Set tSC = ex.AsStatus()
		Do ##class(DeepSeeButtons.Utils).WriteLog("<p>An error occurred</p>",8)
	}
	Quit
}

ClassMethod GetDeepSeeAuditCode(pNamespace)
{
	Set tAuditCode=""
	Set tAuditQueryCode=""
	
	Do ##class(DeepSeeButtons.Utils).WriteHeader4("Audit",8)
	Try {
		If $D(^[pNamespace]DeepSee.AuditCode){
			Set tAuditCode=$g(^[pNamespace]DeepSee.AuditCode)
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p>DeepSee.AuditCode: "_tAuditCode_"</p>",8)
		} Else{
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p>^DeepSee.AuditCode is undefined</p>",8)
		}
		If $D(^[pNamespace]DeepSee.AuditQueryCode){
			Set tAuditQueryCode=$g(^[pNamespace]DeepSee.AuditQueryCode)
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p>DeepSee.AuditQueryCode: "_tAuditQueryCode_"</p>",8)
		} Else{
			Do ##class(DeepSeeButtons.Utils).WriteLog("<p>^DeepSee.AuditQueryCode is undefined</p>",8)
		}
	} Catch {
		Write "Not Available"
	}
	
	Quit
}

ClassMethod GetLastBuild(pCubeEvent As %String, pCubeName As %String, pNamespace As %String)
{
	Set tRet=""
	Set tOriginalNS=$NAMESPACE
	ZN pNamespace
	
	Set tSQLStatement=##class(%SQL.Statement).%New()
	If $D(pCubeName) {
		Set tSQL="SELECT TOP 1 CubeKey,TotalTime,CubeSize,FinishTime,FactsUpdated"
		Set tSQL=tSQL_" FROM %DeepSee_CubeManager.CubeEvent"
		Set tSQL=tSQL_" WHERE CubeEvent=? AND CubeKey=?"
		Set tSQL=tSQL_" ORDER BY FinishTime DESC"
	} Else {
		Set tSQL="SELECT TOP 1 CubeKey,TotalTime,CubeSize,FinishTime,FactsUpdated"
		Set tSQL=tSQL_" FROM %DeepSee_CubeManager.CubeEvent"
		Set tSQL=tSQL_" WHERE CubeEvent=?"
		Set tSQL=tSQL_" ORDER BY FinishTime DESC"
	}
	Do tSQLStatement.%Prepare(tSQL)
	
	If $D(pCubeName) {
		Set tSQLRS=tSQLStatement.%Execute(pCubeEvent,pCubeName)
	} Else {
		Set tSQLRS=tSQLStatement.%Execute(pCubeEvent)
	}
	
	If tSQLRS.%Next() {
		Set tCubeKey=tSQLRS.%Get("CubeKey")
		Set tTotalTime=tSQLRS.%Get("TotalTime")
		Set tCubeSize=tSQLRS.%Get("CubeSize")
		Set tFinishTime=tSQLRS.%Get("FinishTime")
		Set tFactsUpdated=tSQLRS.%Get("FactsUpdated")
	
		If pCubeEvent="Synch" {
    		Set tRet=$FNUMBER(tFactsUpdated,"O,")_" facts synched on "_tFinishTime_" in "_tTotalTime_" seconds"
		} ElseIf ((pCubeEvent="Build")||(pCubeEvent="Repair")) {
			Set tRet=$FNUMBER(tCubeSize,"O,")_" facts built on "_tFinishTime_" in "_tTotalTime_" seconds"
		} ElseIf pCubeEvent="Update" {
			Set tRet="on "_tFinishTime
		} Else {			
			Set tRet=pCubeEvent_" event on "_tFinishTime_" in "_tTotalTime
		}
		Set:'$D(pCubeName) tRet = tRet_" for the "_tCubeKey_" cube"
   	} ElseIf tSQLRS.%SQLCODE=100 {
	   	Set tRet = "Not found"
   	} Else {
	   	Set tRet = "SQL Error code: "_tSQLRS.%SQLCODE
   	}
   	ZN tOriginalNS
   	Quit tRet
}

ClassMethod PrintGlobal(pNamespace, pGlobal, pSpaces As %Integer = 0)
{
	ZN pNamespace
	Quit:'$D(@pGlobal)
	Quit:pGlobal=""
	Set tQueryAry=$QUERY(@pGlobal@(""))
	Set tRes=@tQueryAry
	Set tQuote=""
	Set:'(tRes=+tRes) tQuote=""""
	If $ListValid(tRes) {
		//This seems to provide good formatting for ^DeepSee.CalcMbrs
		Set tRes="$lb("""_$REPLACE($LISTTOSTRING(tRes,"@"),"""","""""")_""")"
		Set tRes=$REPLACE(tRes,"@",""",""")
		Set tQuote=""
	}
	Do ##class(DeepSeeButtons.Utils).WriteLog("<p>"_tQueryAry_" = "_tQuote_tRes_tQuote_"</p>",pSpaces)
	For   {
    Set tQueryAry=$QUERY(@tQueryAry) 
        Quit:tQueryAry=""
        Set tRes=@tQueryAry
		Set tQuote=""
		Set:'(tRes=+tRes) tQuote=""""
        Do ##class(DeepSeeButtons.Utils).WriteLog("<p>"_tQueryAry_" = "_tQuote_tRes_tQuote_"</p>",pSpaces)
	}
}

ClassMethod IsHealthInsight()
{
	Try{
		//Set x=##class(HSAA.Utils).GetLogDirectory()				//Just testing to see if this method works
		Set HealthShare=##class(%SYSTEM.License).GetFeature(12) 	//Look in license for HealthShare Foundation
		Return HealthShare
	} Catch {
		Return 0						//Method did not work so return 0
	}
}

ClassMethod IsTrak()
{
	Try{
		Set BitTrakCare = ##class(%SYSTEM.License).GetFeature(6) 	//BitTrakCare
		Return BitTrakCare
	} Catch {
		Return 0						//Method did not work so return 0
	}
}

ClassMethod CountNodes(pGlobal)
{
	Return:'$D(@pGlobal) 0
	For tCount=$D(@pGlobal)#10:1 Set pGlobal=$Query(@pGlobal) Quit:pGlobal=""
	Return tCount
}

ClassMethod GetLastStartup(ByRef pStartTime, ByRef pDays, ByRef pHours, ByRef pMinutes, ByRef pSeconds) As %Status
{
	Set tSC=$$$OK
	
	Try {
		Set tZH=$ZHorolog\1, tH=$Horolog
		Set tZH=$ZHorolog\1, now=$Horolog
		Set tUpTime=tZH
		Set pDays=tUpTime\86400
		Set tUpTime=tUpTime-(pDays*86400)
		Set pHours=tUpTime\3600
		Set tUpTime=tUpTime-(pHours*3600)
		Set pMinutes=tUpTime\60
		Set tUpTime=tUpTime-(pMinutes*60)
		Set pSeconds=tUpTime
		Set tToday=+tH
		Set pSeconds=$Piece(tToday,",",2)
		Set tH=(tToday*86400)+pSeconds
		Set tOldH=tH-tZH
		Set tOldDays=tOldH\86400
		Set tOldSeconds=tOldH-(tOldDays*86400)
		Set pStartTime=tOldDays_","_tOldSeconds
	} Catch(ex) {		
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

}
