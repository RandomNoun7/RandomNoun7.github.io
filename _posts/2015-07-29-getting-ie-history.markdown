---
published: true
title: Getting IE History
layout: post
---
Recently someone on Twitter posed an interesting question. Was there an easy way to use Powershell to get the Internet Explorer browsing history for all users on a computer. 

If you've worked long enough in IT you know that this is pretty common request by managers for a variety of reasons. But posing it in this way is the start to a pretty deep rabbit hole if you aren't careful. 

## The Usual Approach
If you start googling around about this problem, probably one of the first links you'll find will be an excellent post at {Richard Siddaway's blog](http://blogs.msmvps.com/richardsiddaway/2011/06/29/ie-history-to-csv/)

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