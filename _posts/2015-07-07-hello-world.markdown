---
published: true
title: Hello World.
layout: post
---
Hello World!

```powershell
#this is a powershell comment
Get-Process | Stop-process
Write-output 'Done'
```

{%highlight SQL linenos=table%}
SELECT
TOP 10
*
FROM Shared_Accounts acc
WHERE
    AccountBalance >= 100
{%endhighlight%}

{%highlight powershell linenos=table%}
{%include /Scripts/Powershell/SNMPAgentUtils.ps1%}
{%endhighlight%}