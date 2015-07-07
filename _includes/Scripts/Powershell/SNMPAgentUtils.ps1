#Requires -Version 4

function Get-SNMPAgent
{
<#
	.SYNOPSIS

		Reads the SNMP Agent string value from a Windows computers registry.
	.DESCRIPTION

		Uses the Microsoft.Win32.RegistryKey class to open registry keys on remote computers even if WinRM is not enabled.
		Output is a series of PSObject's with two string properties: computer and agent.
	.PARAMETER computer

		The name of the computer from which you would like to read the agent value
	.EXAMPLE
		Get-SNMPAgent 'Server1'
		Gets the SNMP agent for the named server
		
	.EXAMPLE
		$computers = 'computer1','computer2','computer3'
		C:\PS>$computers | Get-SNMPAgent

		Gets the agent values for an array of computers

	.EXAMPLE
		Get-Content c:\Users\user1\documents\Computers.txt | Get-SNMPAgent
			
		Read the contents of a text file with computer names and get their SNMP Agent values

	.EXAMPLE
		Get-ComputersByOU -ou 'OU=servers,DC=domain,DC=com' | Get-SNMPAgent

		Get the SNMP Agent values for all computers in the specified Active Directory OU.

	.NOTES
		AUTHOR: BILL HURT
		DATE: 2015-7-02
		GITHUB: https://github.com/randomNoun7
#>

	param
	(
		[parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[String]
		$computer
	)
	
	process
	{
		
		
		try
		{
			$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
			
			$key = $reg.OpenSubKey('SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent', $true)
		}
		catch
		{
			return (New-Object -TypeName PSObject -Property (@{ computer = "$computer"; agent = "<Failure>" }))
		}
		
		
		Write-Output (New-Object -TypeName PSObject -Property (@{
			computer = "$computer";
			agent = $key.GetValue('sysContact')
		})
		)
		
		$reg = $NULL
		$key = $NULL
	}
}

function Set-SNMPAgent
{
<#
	.SYNOPSIS
		Set the SNMP Agent value of a remote computer via Microsoft.Win32.Registry class.

	.DESCRIPTION
		Open remote registry even if WinRM is not enabled. Set agent to the value passed into the -value parameter.
		Enforce usage of a valid email address (using UserPrincipalName as a proxy) or AD Group name via ADSI

	.PARAMETER  computer
		The name of the computer to modify the Agent string.

	.PARAMETER  value
		Value to set the Agent string.
	
	.PARAMETER passThruFailed
		When set, pass any computers that failed to accept agent string update through to output.

	.EXAMPLE
		Set-SNMPAgent -computer Computer1 -value user1@domain.com
	
		Sets the SNMP Agent string of Computer1 to user1@domain.com
	.EXAMPLE
		'computer1','computer2','computer3' | Set-SNMPAgent -value user1@domain.com

		Sets the SNMP Agent values of all three computers to user1@domain.com
	
	.EXAMPLE
		Get-ComputersByOU -ou 'OU=servers,DC=domain,DC=com' | Get-SNMPAgent | Where agent -eq 'oldUser@domain.com' | Set-SNMPAgent -value 'AD-Group-Name'
	
		Set all computers an in OU with an old users email in the Agent value to a AD Group name instead.
	
	.NOTES
		AUTHOR: BILL HURT
		DATE: 2015-7-02
		GITHUB: https://github.com/randomNoun7
	
#>

	param
	(
		[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[String]
		$computer,
		[parameter(Mandatory = $true, ValuefromPipeline = $false)]
		[string]
		$value,
		[switch]
		$passThruFailed
	)
	
	begin
	{
		$root = [adsi]''
		
		$searcher = New-Object DirectoryServices.DirectorySearcher ($root)
		
		$searcher.Filter = "(&(objectClass=user) (UserPrincipalName=$value))"
		
		$adObject = $searcher.FindAll()
		
		if (!($adObject.Properties))
		{
			$root = [adsi]''
			
			$searcher.Filter = "(&(objectClass=group) (Name=$value))"
			
			$adObject = $searcher.FindAll()
		}
		
		if ($adObject.properties)
		{
			$value = ($adObject.Properties.userprincipalname, $adObject.Properties.name -ne $NULL)[0]
		}
		else
		{
			throw "invalid -value parameter. Must be email address for a user or the name of a group."	
		}
	}
	
	process
	{
		
		try
		{
			$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
			
			$key = $reg.OpenSubKey('SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent', $true)
			
			$key.SetValue('sysContact',$value)
		}
		catch
		{
			if ($passThruFailed)
			{
				return (New-Object -TypeName PSObject -Property (@{ computer = "$computer"; agent = "<Failure>" }))
			}
		}
	}
}

function Get-ComputersByOU
{
<#
	.SYNOPSIS
		Get string computer name values for all computers in a specified OU

	.DESCRIPTION
		Takes an AD Path and returns only the string computer name of the computers it finds in that path. By default the search will be recursive.

	.PARAMETER  ou
		The path to an Active Directory OU to search for computers. By default the path subtree is also searched. Accepts normal AD path syntax.
	
	.PARAMETER noRecurse
		Disable Subtree searching.

	.EXAMPLE
		Get-ComputersByOU -ou 'OU=servers,OU=region1,DC=domain,DC=com'

		Get all of the servers in the specified OU and all sub OU's. Return only the string Name property.
	
	.EXAMPLE
		Get-ComputersByOU -ou 'OU=region1,DC=domain,DC=com' -noRecurse
		
		Get only computers in the region1 OU and not any sub folders.

	.EXAMPLE
		$ouCollection = 'OU=SQLServers,OU=region1,DC=domain,DC=com','OU=AppServers,OU=region1,DC=domain,DC=com'
		PS C:\>$ouCollection | Get-ComputersByOU -noRecurse

		Get computers in a list of OU's searching only the immediate paths, not subtree's
	
	.NOTES
	AUTHOR: BILL HURT
	DATE: 2015-7-02
	GITHUB: https://github.com/randomNoun7
#>

	
	param
	(
		[parameter(Mandatory = $true,ValueFromPipeline=$true)]
		[String]
		$ou,
		[switch]
		$noRecurse
	)
	
	process
	{
		$root = [adsi]"LDAP://$ou"
		
		$searcher = New-Object DirectoryServices.DirectorySearcher ($root)
		
		$searcher.Filter = "objectCategory=computer"
		
		if ($noRecurse)
		{
			$searcher.SearchScope = 'OneLevel'
		}
		
		$computers = $searcher.FindAll()
		
		
		Write-output $computers.properties.name
	}
	
}

