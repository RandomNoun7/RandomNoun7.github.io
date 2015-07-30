---
published: true
title: Getting IE History
layout: post
---
Recently someone on Twitter posed an interesting question. Is there an easy way to use Powershell to get the Internet Explorer browsing history for all users on a computer?

If you've worked long enough in IT you know that this is pretty common request by managers for a variety of reasons. But posing it in this way is the start to a pretty deep rabbit hole if you aren't careful. 

### The Usual Approach
If you start googling around about this problem, probably one of the first links you'll find will be an excellent post at [Richard Siddaway's blog](http://blogs.msmvps.com/richardsiddaway/2011/06/29/ie-history-to-csv/).

The code is very good, but there is one problems that makes it unsuitable for our task. That code will only get the browsing history for the user currently executing the code. We want the history for all users.

The problem lies in call to $shell.NameSpace(34). Looking at the [MSDN documentation](https://msdn.microsoft.com/en-us/library/windows/desktop/bb774096%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396) we see that 34 in this call is a reference to an enum that in Windows Server 2008+ type systems just translates to C:\Users\<currentUser>\AppData\Local\Microsoft\Windows\History. In fact if you change the call to say $shell.NameSpace("C:\Users\<currentUser>\AppData\Local\Microsoft\Windows\History") and insert your user folder name, the script works exactly the same.

You might think you could do something like:
{%highlight powershell%}
function Get-History 
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
...
{%endhighlight%}

But after trying a number of different approaches, including using [PSExec](http://verbalprocessor.com/2007/12/05/running-a-cmd-prompt-as-local-system/) to run as the system user, I was unable to solve the fact that trying to get another users history this way just results in permissions errors. It's just not going to work.

### The Solution

The thing is, Nirsoft has already 90% of the work for us with its [BrowsingHistoryView](http://www.nirsoft.net/utils/browsing_history_view.html) tool. We just need to turn it into a script that will get us across the finish line.
{%highlight powershell%}
$execPath = "C:\BrowsingHistoryView.exe"

$computers = 'MP-BH-Jenkins','MP-BH-PSDEV'

$outPath = "c:\"

$computers | 
    ForEach-Object{ `
        Start-Process $execPath `
            -argumentList "/HistorySource 3", 
                          "/HistorySourceFolder ""\\$_\c$\Users""",
                          "/scomma ""$outpath\history_$_.txt"""
    }
{%endhighlight%}

The summary is we give the script the location of the executable, the list of computers, and where we want the files to go. Execute the script and you get a nice tidy collection of csv text files with all of the browser history you need.

I have no idea how NirSoft is getting this information, but the script is short and to the point, and uses a nice, lightweight, standalone executable to get the job done. It also gets all of the history on the machine, not just IE history. Oh yeah, and it's free.