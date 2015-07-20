---
published: true
title: SNMP Agent Functions
layout: post
---

### Hello
Hello everyone. Welcome to the inaugural blog post in whatever it is that this becomes. I'll take some time in a later post to talk about how this place is set up why I like it, but for now, lets talk about some code. 

### SNMP Agent in a Windows Environment
I found out recently that there are some large organizations out there that use the SNMP Agent string of the SNMP service to keep track of who is responsible for servers. I have to admit I don't fully understand why when the Managed By property in Active Directory is right there, but hey, they didn't ask me right?

The problem becomes that like so many networking tools that *NIX and Mac people take for granted, Windows support for this property, as far as I can tell, is not as easy as many would like it to be. It certainly wasn't an easy thing to automate the way I wanted to. So the result is the functions you see below. It's a lot of text but if you glance at it and you're still interested in how I'm using it then scroll on down and I'll talk about why I wanted a set of functions to automate getting the SNMP agent from a Windows computer and setting it, written in PowerShell.

{%highlight powershell%}
{% include Scripts/Powershell/SNMPAgentUtils.ps1 %}
{%endhighlight%}

### Lets talk about it

