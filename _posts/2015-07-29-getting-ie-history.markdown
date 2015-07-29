---
published: true
title: Getting IE History
layout: post
---
{%highlight powershell%}
$shell = New-Object -ComObject Shell.Application 

function Get-History 
{
    param
    (
        [string]$userName
    )

    if($username)
    {
        $users = $username
    }
    else
    {
        $users = Get-ChildItem C:\Users
    }

    Foreach($user in $users)
    {
        $user = Split-Path $user -leaf
        try
        {
            $ErrorActionPreference = 'Stop'
            $hist = $shell.NameSpace("C:\Users\$user\AppData\Local\Microsoft\Windows\History") 
        }
        catch
        {
            continue
        }
        $folder = $hist.Self 
        #$folder.Path
        
            if($hist){
            $hist.Items() | foreach { 
                #""; ""; $_.Name 
                 if ($_.IsFolder) { 
                     $siteFolder = $_.GetFolder 
                     $siteFolder.Items() | foreach { 
                        $site = $_ 
                        #""; $site.Name 
                        if ($site.IsFolder) { 
                            $pageFolder  = $site.GetFolder 
                            $pageFolder.Items() | foreach { 
                                $url = $pageFolder.GetDetailsOf($_,0) 
                                $date =  $pageFolder.GetDetailsOf($_,2) 
                                #"$user`: $date visited $url"  

                                #Write-Output ("$user,$date,`"$url`"" | ConvertFrom-Csv)

                                New-Object -TypeName PSObject -Property @{
                                                                          user=$user;
                                                                          date = $date;
                                                                          url = $url
                                                                          }
                            } 
                        } 
                     } 
                 } 
            }
        }    
    
    }
}
{%endhighlight%}