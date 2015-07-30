---
published: true
title: Getting IE History
layout: post
---
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