<!---cftry exists to dump errors and provide immediate feedback on the App if something goes wrong. --->
<cftry>



<!---
First the App needs a string (status) returned in JSON format to do anything. 

This is checking if the URL parameters are non-existent or empty, meaning the app was storing the scans locally on the phone and it is being sent after the fact as a POST request.
--->

<cfif !structKeyExists(URL,"EmployeeID") OR !isDefined("URL.EmployeeID") OR isDefined("URL.EmployeeID") AND URL.EmployeeID is "">
{
"status":"ok",
"result_msg":"Stored records were successfully inserted into database."
}

<!---Gets the JSON from the App's POST request, decodes it, and begins a loop through it.---> 
<cfset requestBody = #replaceNoCase( toString(getHttpRequestData().content), "batch=", "" )#  />
<cfset decodedBody = #URLDecode(requestBody)#>
<cfset ArrayOfStructs = deserializeJson(decodedBody)>
<cfloop array="#ArrayOfStructs#" index="i">

<!---This logic determines whether the scan is of the barcode or the QR code (they contained slightly different information) and changes the string to JUST the EmployeeID. --->
<cfif i.barcode contains "http://exampleURL">
<cfset newBarcode = #Left(REPLACE(#i.barcode#, "http://exampleURL.com/?=", ""),4)#>
<cfelse>
<cfset newBarcode = #REPLACE(#i.barcode#, "http://OtherExample.com/?=", "")#>
</cfif>

<!--- Inserts all scan records into a table. If the query errors, the cftry will dump it on the page, and since the app will interpret that as invalid JSON, it'll throw an error and stop its process.--->
<cfquery name="InsertScans" datasource="CRM">
	INSERT INTO TimeAppTest
	(
		EmployeeID,
		lat,
		long,
		TimoStampo
		)
	VALUES
	(
		'#newBarcode#',
		'#i.lat#',
		'#i.long#',
		'#i.time#'

		)
</cfquery>
</cfloop>

<!---Else if the URL parameters ARE available. In this next case, it means the phone is actively connected to the internet and is sending scans one-by-one as they are happening. --->
<cfelse>

<!---It checks to make sure there are URL parameters available, then formats that string appropriately and executes a query. If the query goes wrong, the cftry will dump it on the page, and since the App will interpret that as invalid JSON, it'll throw an error and stop its process. --->

<cfif URL.EmployeeID does not contain "http://exampleURL.com">
	<cfset EmployeeID = #REPLACE(URL.EmployeeID, "OtherExample.com", "")#>
<cfelse>
	<cfset EmployeeID = #Left(REPLACE(#URL.EmployeeID#, "http://exampleURL.com/?=", ""),4)#>
</cfif>

<cfquery name="insertTime" datasource="CRM" result="insertTime">
	INSERT INTO 
		TimeAppTest
	(
		EmployeeID,
		lat,
		long,
		TimoStampo
		)
	VALUES
	(
		'#EmployeeID#',
		'#URL.lat#',
		'#URL.long#',
		'#URL.time#'

		)
</cfquery> 

{
"status":"ok",
"result_msg":"Scan(s) successfully inserted into database."
}
</cfif>


<!---Do not remove this, please. This dump is what keeps the App honest. If the queries stop working for any reason, the App won't be able to tell you unless this dump is outputted and ruins what it is interpreting as a JSON string. --->

<cfcatch>
<cfdump var="#cfcatch#">
</cfcatch>	
</cftry>
