---
published: true
title: Event Driven App with Sapien Powershell Studio
layout: post
---

I was on Twitter the other day and saw that [@juneb_get_help tweeted](https://twitter.com/juneb_get_help/status/705452955068071937) asking people to talk about things they had built with Powershell Studio. I responded, but I thought it really deserved a blog post to talk about the app and the kinds of things you can do with it. 

### The Business Problem
The company I work for installs software inside their clients' networks. We provide the client with a detailed spec of what we would like the servers they give us to look like, but it is very common for servers to be just a little bit wrong. Since we use Puppet for configuration management, it's important to verify that servers are in the correct state before we accept them. 

The app I wrote is dropped onto a single server in the environment, and when provided a list of servers to test, invokes a series of remote jobs that instruct each box to test itself for correct state and report back the results. 

### Why Powershell Studio
As we will see shortly, Powershell studio is a good solution for this because it allows you take advantage of the convenience of Powershell for administering servers, while also taking advantage of event based programming and easily wrapping scripts in a GUI that suits the needs of slightly less technical users.

### The App
![Initial View](https://raw.githubusercontent.com/RandomNoun7/RandomNoun7.github.io/master/_images/InitalFullScreen.jpg)

In the screenshot above you can see the design view for the app. The app consists of a main form, a tab control with tabs for the stages of testing, with sub controls for data. In the tab you see here I have a couple text boxes for Active Directory account names. Before the machines are tested I use the app to ensure that the Active Directory accounts we asked for have been created. 

Notice on the right side the name says textBoxSQLAccount. That is going to be the name of a variable created by the Studio to reference that text box.

![Add Event](https://raw.githubusercontent.com/RandomNoun7/RandomNoun7.github.io/master/_images/AddEvent.jpg)

In this screenshot we are adding an event handler to the lower text box. When you click ok you get a code block for the object's event handler.

![Event Code Auto Complete](https://raw.githubusercontent.com/RandomNoun7/RandomNoun7.github.io/master/_images/AddEventCodeAutoComplete.jpg)

If you're familiar with Powershell syntax you will recognize a variable with a code block. In the background, when Powershell Studio builds the app, it ensures that code is executed when that event is fired just as the name implies. To keep things neat, the code is factored out into a function and I simply pass the textbox, since both boxes need to run the same check when the Leave event fires. 

One of the cool things about Powershell Studio is how the really great auto complete incentivises you to write good code. The function Validate-Textbox was defined with a parameter of type System.Windows.Forms.Textbox. Powershell Studio knows it, so when auto complete comes up, it only shows me the variables of the correct type.

The code in Validate-TextBox is as follows:
{%highlight powershell%}
function Verify-ADObject
{
	param (
		[string]$name
	)
	
	if ((([ADSISearcher]"Name=$($name)").FindOne(), ([ADSISearcher]"SAMAccountName=$($name)").FindOne() -ne $NULL)[0])
	{
		Write-Output $true
	}
	else
	{
		Write-Output $false
	}
}

function Validate-TextBox
{
	param (
		[System.Windows.Forms.TextBox]$textBox
	)
	
	if (Verify-ADObject -name $textBox.Text)
	{
		$textBox.BackColor = 'LimeGreen'
	}
	else
	{
		$textBox.BackColor = 'Red'
	}
}
{%endhighlight%}

With these event handlers in place, every time my cursor leaves the text box the Validate-TextBox function is called with the current text box as the parameter, which then passes the text value to Verify-ADObject. If an object is returned we know it exists and the textbox turns green, and if not we get a red box. Since this is a demo app this is enough, but in reality we would want some checks in place to ensure such things as that a value actually exists in the text box in case someone just clicked on the text box by accident and then left.

![First Test](https://raw.githubusercontent.com/RandomNoun7/RandomNoun7.github.io/master/_images/Firsttest.jpg)

Some of you at this point may be wagging your fingers at me, and believe me I know. I shouldn't be making network calls on the UI thread. I don't disagree, but I'm also lazy, and this check happens very quickly so I'm not worried about it for these text boxes. In the next tab though I'm going to do it right. 

![Roles Tab](https://raw.githubusercontent.com/RandomNoun7/RandomNoun7.github.io/master/_images/InstallerRunning.jpg)

This tab is going to install the roles we need on the server. In reality Puppet can take care of this for us, but this is a decent way to demo the next concept I want to cover. Combining Powershell jobs and event driven programming we can spin off long running processes into a background thread that keeps our UI from blocking while the servers go about their business.

The IIS tab consists of little more than a DataviewGrid control, a progress bar and a button. After we add servers to the list in the dataview control we handle the button's Click event to start installing the Web Server roles that we need. 
{%highlight powershell%}
$buttonInstall_Click={
	Begin-Install $datagridview1 -bar $progressbar1
}
{%endhighlight%}

Earlier in the form code that you don't see here I created a timer object, but didn't start it. In the next code section I'll get the list of servers from the DataGridview control, spin off the jobs to the background, and then add a code block to the timer's tick event before starting the timer. The effect is that the invocation of Begin-Install completes and the UI thread is unblocked. In the background however, the timer is still running and with each tick it calls a code block that checks on the status of the jobs we spun off in the background. The Get-JobStatus function that gets called knows how to find the Datagridview control and update the appropriate rows as the servers report their status back to the background job. Here's the code.

{%highlight powershell%}
function Begin-Install
{
	
	$scriptBlock = {
		Add-WindowsFeature Web-WebServer, Web-Mgmt-Console, Web-App-Dev, Web-Asp-Net45, Web-Mgmt-Console
	}
	
	$style = New-Object System.Windows.Forms.DataGridViewCellStyle
	
	$style.BackColor = 'Yellow'
	
	$datagridview1.Rows | Where-Object{$_.Cells[0].Value.length -gt 0} | ForEach-Object{ $_.Cells[1, 2] } | ForEach-Object{ $_.style = $style }
	
	$progressbar1.Style = 'Marquee'
	$progressbar1.Visible = $true
	
	foreach ($server in ($datagridview1.Rows | Where-Object{ $_.Cells[0].value.length -gt 0 } | ForEach-Object{ $_.Cells[0].Value }))
	{
		Invoke-Command -ScriptBlock $scriptBlock -ComputerName $server -AsJob -JobName "installRoles_$server"
	}

	$timer.add_Tick({ Get-JobStatus })
	$timer.Start()
}

function Get-JobStatus
{
	
	if ($jobs = Get-Job | where state -NE 'running')
	{
		foreach ($job in $jobs)
		{
			$results = Receive-Job $job
			Remove-Job $job
			
			$row = $datagridview1.Rows | Where-Object{ $_.Cells[0].Value -eq $results.PScomputername }
			$style = New-Object System.Windows.Forms.DataGridViewCellStyle
			
			if ($results.success)
			{
				$style.BackColor = 'LimeGreen'
				$row.cells[1].style = $style
				$row.cells[1].value = 1
			}
			else
			{
				$style.BackColor = 'Red'
				$row.cells[1].style = $style
			}
		}
	}
	else
	{
		if (!(Get-Job))
		{
			$timer.Stop()
			$timer.Dispose()
			$progressbar1.Visible = $False
		}
	}
}
{%endhighlight%}

In the real version the process of just finding the list of servers and spinning off the jobs can take a noticeable amount of time, so really the entire operation should be in the background, but for a demo, just spinning off the remote portion makes it easier to follow what's happening.

### Troubleshooting
One of the advantages to using Powershell studio forms apps like this is that it allows me to export the entire app not as an executable finished product, but just as a big long script. The reason this can be nice is if there are bugs with the program, I don't have to install the entire Powershell Studio on a client machine to debug. I export the script, set my break points in Powershell ISE, and I can debug on the clients machines using only the tools freely available on any Windows Server. With that in mind, the entire demo app is pasted below as a script. It's very very rough, just thrown together over the course of a few hours to make this blog post happen, so please don't there are bugs, and there's no error handling, etc, I know. but if you want to let me know of any better ways to do this stuff, or just have general thoughts, don't hesitate to let me know. You can find me on twitter [@RandomNoun7](https://twitter.com/RandomNoun7)

{%highlight powershell%}
#------------------------------------------------------------------------
# Source File Information (DO NOT MODIFY)
# Source ID: 1d9b2aea-ddc6-4129-a0a5-07da6d38202b
# Source File: C:\Users\bhurt\Documents\SAPIEN\PowerShell Studio 2015\Projects\Tabbed App Demo\Tabbed App Demo.psproj
#------------------------------------------------------------------------
<#
    .NOTES
    --------------------------------------------------------------------------------
     Code generated by:  SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.99
     Generated on:       3/7/2016 10:25 AM
     Generated by:        
     Organization:        
    --------------------------------------------------------------------------------
    .DESCRIPTION
        Script generated by PowerShell Studio 2015
#>


#region Source: Startup.pss
#----------------------------------------------
#region Import Assemblies
#----------------------------------------------
[void][Reflection.Assembly]::Load('mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][Reflection.Assembly]::Load('System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.DirectoryServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][Reflection.Assembly]::Load('System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.ServiceProcess, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
#endregion Import Assemblies

#Define a Param block to use custom parameters in the project
#Param ($CustomParameter)

function Main {
<#
    .SYNOPSIS
        The Main function starts the project application.
    
    .PARAMETER Commandline
        $Commandline contains the complete argument string passed to the script packager executable.
    
    .NOTES
        Use this function to initialize your script and to call GUI forms.
		
    .NOTES
        To get the console output in the Packager (Forms Engine) use: 
		$ConsoleOutput (Type: System.Collections.ArrayList)
#>
	Param ([String]$Commandline)
		
	#--------------------------------------------------------------------------
	#TODO: Add initialization script here (Load modules and check requirements)
	
	
	#--------------------------------------------------------------------------
	
	if((Call-MainForm_psf) -eq 'OK')
	{
		
	}
	
	$global:ExitCode = 0 #Set the exit code for the Packager
}






#endregion Source: Startup.pss

#region Source: MainForm.psf
function Call-MainForm_psf
{
	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	[void][reflection.assembly]::Load('System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.DirectoryServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	[void][reflection.assembly]::Load('System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.ServiceProcess, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$MainForm = New-Object 'System.Windows.Forms.Form'
	$TabControl = New-Object 'System.Windows.Forms.TabControl'
	$ADTab = New-Object 'System.Windows.Forms.TabPage'
	$tablelayoutpanel1 = New-Object 'System.Windows.Forms.TableLayoutPanel'
	$textBoxSQLAccount = New-Object 'System.Windows.Forms.TextBox'
	$textBoxAppPool = New-Object 'System.Windows.Forms.TextBox'
	$labelSQLServiceAccount = New-Object 'System.Windows.Forms.Label'
	$labelAppPoolServiceAccoun = New-Object 'System.Windows.Forms.Label'
	$IISTab = New-Object 'System.Windows.Forms.TabPage'
	$buttonInstall = New-Object 'System.Windows.Forms.Button'
	$progressbar1 = New-Object 'System.Windows.Forms.ProgressBar'
	$datagridview1 = New-Object 'System.Windows.Forms.DataGridView'
	$ServerName = New-Object 'System.Windows.Forms.DataGridViewTextBoxColumn'
	$IISInstalled = New-Object 'System.Windows.Forms.DataGridViewCheckBoxColumn'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	$timer = New-Object System.Windows.Forms.Timer
	
	$MainForm_Load={
	#TODO: Initialize Form Controls here
	
	}
	
	$MainForm_Shown={
	
	}
	
	$textBoxSQLAccount_Leave={
		Validate-TextBox -textBox $textBoxSQLAccount
	}
	
	$textBoxAppPool_Leave={
		Validate-TextBox -textBox $textBoxAppPool
	}
	
	
	#region Control Helper Functions
	function Load-DataGridView
	{
		<#
		.SYNOPSIS
			This functions helps you load items into a DataGridView.
	
		.DESCRIPTION
			Use this function to dynamically load items into the DataGridView control.
	
		.PARAMETER  DataGridView
			The DataGridView control you want to add items to.
	
		.PARAMETER  Item
			The object or objects you wish to load into the DataGridView's items collection.
		
		.PARAMETER  DataMember
			Sets the name of the list or table in the data source for which the DataGridView is displaying data.
	
		#>
		Param (
			[ValidateNotNull()]
			[Parameter(Mandatory=$true)]
			[System.Windows.Forms.DataGridView]$DataGridView,
			[ValidateNotNull()]
			[Parameter(Mandatory=$true)]
			$Item,
		    [Parameter(Mandatory=$false)]
			[string]$DataMember
		)
		$DataGridView.SuspendLayout()
		$DataGridView.DataMember = $DataMember
		
		if ($Item -is [System.ComponentModel.IListSource]`
		-or $Item -is [System.ComponentModel.IBindingList] -or $Item -is [System.ComponentModel.IBindingListView] )
		{
			$DataGridView.DataSource = $Item
		}
		else
		{
			$array = New-Object System.Collections.ArrayList
			
			if ($Item -is [System.Collections.IList])
			{
				$array.AddRange($Item)
			}
			else
			{	
				$array.Add($Item)	
			}
			$DataGridView.DataSource = $array
		}
		
		$DataGridView.ResumeLayout()
	}
	
	function ConvertTo-DataTable
	{
		<#
			.SYNOPSIS
				Converts objects into a DataTable.
		
			.DESCRIPTION
				Converts objects into a DataTable, which are used for DataBinding.
		
			.PARAMETER  InputObject
				The input to convert into a DataTable.
		
			.PARAMETER  Table
				The DataTable you wish to load the input into.
		
			.PARAMETER RetainColumns
				This switch tells the function to keep the DataTable's existing columns.
			
			.PARAMETER FilterWMIProperties
				This switch removes WMI properties that start with an underline.
		
			.EXAMPLE
				$DataTable = ConvertTo-DataTable -InputObject (Get-Process)
		#>
		[OutputType([System.Data.DataTable])]
		param(
		[ValidateNotNull()]
		$InputObject, 
		[ValidateNotNull()]
		[System.Data.DataTable]$Table,
		[switch]$RetainColumns,
		[switch]$FilterWMIProperties)
		
		if($Table -eq $null)
		{
			$Table = New-Object System.Data.DataTable
		}
	
		if($InputObject-is [System.Data.DataTable])
		{
			$Table = $InputObject
		}
		else
		{
			if(-not $RetainColumns -or $Table.Columns.Count -eq 0)
			{
				#Clear out the Table Contents
				$Table.Clear()
	
				if($InputObject -eq $null){ return } #Empty Data
				
				$object = $null
				#find the first non null value
				foreach($item in $InputObject)
				{
					if($item -ne $null)
					{
						$object = $item
						break	
					}
				}
	
				if($object -eq $null) { return } #All null then empty
				
				#Get all the properties in order to create the columns
				foreach ($prop in $object.PSObject.Get_Properties())
				{
					if(-not $FilterWMIProperties -or -not $prop.Name.StartsWith('__'))#filter out WMI properties
					{
						#Get the type from the Definition string
						$type = $null
						
						if($prop.Value -ne $null)
						{
							try{ $type = $prop.Value.GetType() } catch {}
						}
	
						if($type -ne $null) # -and [System.Type]::GetTypeCode($type) -ne 'Object')
						{
			      			[void]$table.Columns.Add($prop.Name, $type) 
						}
						else #Type info not found
						{ 
							[void]$table.Columns.Add($prop.Name) 	
						}
					}
			    }
				
				if($object -is [System.Data.DataRow])
				{
					foreach($item in $InputObject)
					{	
						$Table.Rows.Add($item)
					}
					return  @(,$Table)
				}
			}
			else
			{
				$Table.Rows.Clear()	
			}
			
			foreach($item in $InputObject)
			{		
				$row = $table.NewRow()
				
				if($item)
				{
					foreach ($prop in $item.PSObject.Get_Properties())
					{
						if($table.Columns.Contains($prop.Name))
						{
							$row.Item($prop.Name) = $prop.Value
						}
					}
				}
				[void]$table.Rows.Add($row)
			}
		}
	
		return @(,$Table)	
	}
	#endregion
	
	$buttonInstall_Click={
		Begin-Install $datagridview1 -bar $progressbar1
	}
	
	#region AD Functions
	
	function Verify-ADObject
	{
		param (
			[string]$name
		)
		
		if ((([ADSISearcher]"Name=$($name)").FindOne(), ([ADSISearcher]"SAMAccountName=$($name)").FindOne() -ne $NULL)[0])
		{
			Write-Output $true
		}
		else
		{
			Write-Output $false
		}
	}
	
	function Validate-TextBox
	{
		param (
			[System.Windows.Forms.TextBox]$textBox
		)
		
		if (Verify-ADObject -name $textBox.Text)
		{
			$textBox.BackColor = 'LimeGreen'
		}
		else
		{
			$textBox.BackColor = 'Red'
		}
	}
	
	#endregion
	
	#region Install Tab Functions
	function Begin-Install
	{
		
		$scriptBlock = {
			Add-WindowsFeature Web-WebServer, Web-Mgmt-Console, Web-App-Dev, Web-Asp-Net45, Web-Mgmt-Console
		}
		
		$style = New-Object System.Windows.Forms.DataGridViewCellStyle
		
		$style.BackColor = 'Yellow'
		
		$datagridview1.Rows | Where-Object{$_.Cells[0].Value.length -gt 0} | ForEach-Object{ $_.Cells[1, 2] } | ForEach-Object{ $_.style = $style }
		
		$progressbar1.Style = 'Marquee'
		$progressbar1.Visible = $true
		
		foreach ($server in ($datagridview1.Rows | Where-Object{ $_.Cells[0].value.length -gt 0 } | ForEach-Object{ $_.Cells[0].Value }))
		{
			Invoke-Command -ScriptBlock $scriptBlock -ComputerName $server -AsJob -JobName "installRoles_$server"
		}
	
		$timer.add_Tick({ Get-JobStatus })
		$timer.Start()
	}
	
	function Get-JobStatus
	{
		
		if ($jobs = Get-Job | where state -NE 'running')
		{
			foreach ($job in $jobs)
			{
				$results = Receive-Job $job
				Remove-Job $job
				
				$row = $datagridview1.Rows | Where-Object{ $_.Cells[0].Value -eq $results.PScomputername }
				$style = New-Object System.Windows.Forms.DataGridViewCellStyle
				
				if ($results.success)
				{
					$style.BackColor = 'LimeGreen'
					$row.cells[1].style = $style
					$row.cells[1].value = 1
				}
				else
				{
					$style.BackColor = 'Red'
					$row.cells[1].style = $style
				}
			}
		}
		else
		{
			if (!(Get-Job))
			{
				$timer.Stop()
				$timer.Dispose()
				$progressbar1.Visible = $False
			}
		}
	}
	#endregion
		# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$MainForm.WindowState = $InitialFormWindowState
	}
	
	$Form_StoreValues_Closing=
	{
		#Store the control values
		$script:MainForm_textBoxSQLAccount = $textBoxSQLAccount.Text
		$script:MainForm_textBoxAppPool = $textBoxAppPool.Text
		$script:MainForm_datagridview1 = $datagridview1.SelectedCells
	}

	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$textBoxSQLAccount.remove_Leave($textBoxSQLAccount_Leave)
			$textBoxAppPool.remove_Leave($textBoxAppPool_Leave)
			$buttonInstall.remove_Click($buttonInstall_Click)
			$MainForm.remove_Load($MainForm_Load)
			$MainForm.remove_Shown($MainForm_Shown)
			$MainForm.remove_Load($Form_StateCorrection_Load)
			$MainForm.remove_Closing($Form_StoreValues_Closing)
			$MainForm.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$MainForm.SuspendLayout()
	$TabControl.SuspendLayout()
	$ADTab.SuspendLayout()
	$tablelayoutpanel1.SuspendLayout()
	$IISTab.SuspendLayout()
	#
	# MainForm
	#
	$MainForm.Controls.Add($TabControl)
	$MainForm.ClientSize = '476, 452'
	$MainForm.Name = 'MainForm'
	$MainForm.StartPosition = 'CenterScreen'
	$MainForm.Text = 'Tabbed App Demo'
	$MainForm.UseWaitCursor = $True
	$MainForm.add_Load($MainForm_Load)
	$MainForm.add_Shown($MainForm_Shown)
	#
	# TabControl
	#
	$TabControl.Controls.Add($ADTab)
	$TabControl.Controls.Add($IISTab)
	$TabControl.Location = '12, 35'
	$TabControl.Name = 'TabControl'
	$TabControl.SelectedIndex = 0
	$TabControl.Size = '452, 405'
	$TabControl.TabIndex = 0
	#
	# ADTab
	#
	$ADTab.Controls.Add($tablelayoutpanel1)
	$ADTab.Location = '4, 22'
	$ADTab.Name = 'ADTab'
	$ADTab.Padding = '3, 3, 3, 3'
	$ADTab.Size = '444, 379'
	$ADTab.TabIndex = 0
	$ADTab.Text = 'Active Directory'
	$ADTab.UseVisualStyleBackColor = $True
	#
	# tablelayoutpanel1
	#
	$tablelayoutpanel1.Controls.Add($textBoxSQLAccount, 1, 0)
	$tablelayoutpanel1.Controls.Add($textBoxAppPool, 1, 1)
	$tablelayoutpanel1.Controls.Add($labelSQLServiceAccount, 0, 0)
	$tablelayoutpanel1.Controls.Add($labelAppPoolServiceAccoun, 0, 1)
	$tablelayoutpanel1.ColumnCount = 2
	$System_Windows_Forms_ColumnStyle_1 = New-Object 'System.Windows.Forms.ColumnStyle' ('Percent', 50)
	[void]$tablelayoutpanel1.ColumnStyles.Add($System_Windows_Forms_ColumnStyle_1)
	$System_Windows_Forms_ColumnStyle_2 = New-Object 'System.Windows.Forms.ColumnStyle' ('Percent', 50)
	[void]$tablelayoutpanel1.ColumnStyles.Add($System_Windows_Forms_ColumnStyle_2)
	$tablelayoutpanel1.Location = '6, 6'
	$tablelayoutpanel1.Name = 'tablelayoutpanel1'
	$tablelayoutpanel1.RowCount = 2
	$System_Windows_Forms_RowStyle_3 = New-Object 'System.Windows.Forms.RowStyle' ('Percent', 50)
	[void]$tablelayoutpanel1.RowStyles.Add($System_Windows_Forms_RowStyle_3)
	$System_Windows_Forms_RowStyle_4 = New-Object 'System.Windows.Forms.RowStyle' ('Percent', 50)
	[void]$tablelayoutpanel1.RowStyles.Add($System_Windows_Forms_RowStyle_4)
	$tablelayoutpanel1.Size = '432, 373'
	$tablelayoutpanel1.TabIndex = 0
	#
	# textBoxSQLAccount
	#
	$textBoxSQLAccount.Anchor = 'Bottom, Left'
	$textBoxSQLAccount.Location = '219, 163'
	$textBoxSQLAccount.Name = 'textBoxSQLAccount'
	$textBoxSQLAccount.Size = '210, 20'
	$textBoxSQLAccount.TabIndex = 0
	$textBoxSQLAccount.add_Leave($textBoxSQLAccount_Leave)
	#
	# textBoxAppPool
	#
	$textBoxAppPool.Location = '219, 189'
	$textBoxAppPool.Name = 'textBoxAppPool'
	$textBoxAppPool.Size = '210, 20'
	$textBoxAppPool.TabIndex = 1
	$textBoxAppPool.add_Leave($textBoxAppPool_Leave)
	#
	# labelSQLServiceAccount
	#
	$labelSQLServiceAccount.Anchor = 'Bottom, Right'
	$labelSQLServiceAccount.Location = '3, 163'
	$labelSQLServiceAccount.Name = 'labelSQLServiceAccount'
	$labelSQLServiceAccount.Size = '210, 23'
	$labelSQLServiceAccount.TabIndex = 2
	$labelSQLServiceAccount.Text = 'SQL Server Service Account'
	$labelSQLServiceAccount.TextAlign = 'MiddleRight'
	#
	# labelAppPoolServiceAccoun
	#
	$labelAppPoolServiceAccoun.Anchor = 'Top, Right'
	$labelAppPoolServiceAccoun.Location = '3, 186'
	$labelAppPoolServiceAccoun.Name = 'labelAppPoolServiceAccoun'
	$labelAppPoolServiceAccoun.Size = '210, 23'
	$labelAppPoolServiceAccoun.TabIndex = 3
	$labelAppPoolServiceAccoun.Text = 'App Pool Service Account'
	$labelAppPoolServiceAccoun.TextAlign = 'MiddleRight'
	#
	# IISTab
	#
	$IISTab.Controls.Add($buttonInstall)
	$IISTab.Controls.Add($progressbar1)
	$IISTab.Controls.Add($datagridview1)
	$IISTab.Location = '4, 22'
	$IISTab.Name = 'IISTab'
	$IISTab.Padding = '3, 3, 3, 3'
	$IISTab.Size = '444, 379'
	$IISTab.TabIndex = 1
	$IISTab.Text = 'IIS'
	$IISTab.UseVisualStyleBackColor = $True
	#
	# buttonInstall
	#
	$buttonInstall.Location = '7, 207'
	$buttonInstall.Name = 'buttonInstall'
	$buttonInstall.Size = '75, 23'
	$buttonInstall.TabIndex = 2
	$buttonInstall.Text = 'Install'
	$buttonInstall.UseVisualStyleBackColor = $True
	$buttonInstall.add_Click($buttonInstall_Click)
	#
	# progressbar1
	#
	$progressbar1.Location = '7, 311'
	$progressbar1.Name = 'progressbar1'
	$progressbar1.Size = '431, 23'
	$progressbar1.TabIndex = 1
	$progressbar1.Visible = $False
	#
	# datagridview1
	#
	$System_Windows_Forms_DataGridViewCellStyle_5 = New-Object 'System.Windows.Forms.DataGridViewCellStyle'
	$System_Windows_Forms_DataGridViewCellStyle_5.Alignment = 'MiddleCenter'
	$System_Windows_Forms_DataGridViewCellStyle_5.BackColor = 'Control'
	$System_Windows_Forms_DataGridViewCellStyle_5.Font = 'Microsoft Sans Serif, 8.25pt'
	$System_Windows_Forms_DataGridViewCellStyle_5.ForeColor = 'WindowText'
	$System_Windows_Forms_DataGridViewCellStyle_5.SelectionBackColor = 'Highlight'
	$System_Windows_Forms_DataGridViewCellStyle_5.SelectionForeColor = 'HighlightText'
	$System_Windows_Forms_DataGridViewCellStyle_5.WrapMode = 'True'
	$datagridview1.ColumnHeadersDefaultCellStyle = $System_Windows_Forms_DataGridViewCellStyle_5
	$datagridview1.ColumnHeadersHeightSizeMode = 'AutoSize'
	[void]$datagridview1.Columns.Add($ServerName)
	[void]$datagridview1.Columns.Add($IISInstalled)
	$datagridview1.Location = '6, 32'
	$datagridview1.Name = 'datagridview1'
	$datagridview1.ScrollBars = 'None'
	$datagridview1.Size = '432, 150'
	$datagridview1.TabIndex = 0
	#
	# ServerName
	#
	$ServerName.HeaderText = 'Server Name'
	$ServerName.Name = 'ServerName'
	#
	# IISInstalled
	#
	$IISInstalled.AutoSizeMode = 'Fill'
	$IISInstalled.HeaderText = 'Roles Installed'
	$IISInstalled.Name = 'IISInstalled'
	$IISInstalled.ReadOnly = $True
	$IISTab.ResumeLayout()
	$tablelayoutpanel1.ResumeLayout()
	$ADTab.ResumeLayout()
	$TabControl.ResumeLayout()
	$MainForm.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $MainForm.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$MainForm.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$MainForm.add_FormClosed($Form_Cleanup_FormClosed)
	#Store the control values when form is closing
	$MainForm.add_Closing($Form_StoreValues_Closing)
	#Show the Form
	return $MainForm.ShowDialog()

}
#endregion Source: MainForm.psf

#region Source: Globals.ps1
	#--------------------------------------------
	# Declare Global Variables and Functions here
	#--------------------------------------------
	
	
	#Sample function that provides the location of the script
	function Get-ScriptDirectory
	{
	<#
		.SYNOPSIS
			Get-ScriptDirectory returns the proper location of the script.
	
		.OUTPUTS
			System.String
		
		.NOTES
			Returns the correct path within a packaged executable.
	#>
		[OutputType([string])]
		param ()
		if ($hostinvocation -ne $null)
		{
			Split-Path $hostinvocation.MyCommand.path
		}
		else
		{
			Split-Path $script:MyInvocation.MyCommand.Path
		}
	}
	
	#Sample variable that provides the location of the script
	[string]$ScriptDirectory = Get-ScriptDirectory
	
	#endregion Source: Globals.ps1

#Start the application
Main ($CommandLine)
{%endhighlight%}