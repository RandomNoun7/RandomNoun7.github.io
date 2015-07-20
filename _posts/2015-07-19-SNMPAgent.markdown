---
published: false
title: SNMP Agent Functions
layout: post
---

### Hello
Hello everyone. Welcome to the inaugural blog post in whatever it is that this becomes. I'll take some time in a later post to talk about how this place is set up why I like it, but for now, lets talk about some code. 

### The problem
Your company uses the SNMP Agent string to keep track of who owns equipment on the network. I get why you would do this, it's cross platform, lightweight, but Windows support for managing this value is less than awesome. Most of the tutorials for managing it in Windows are based on clicking around in the GUI. This is the DevOps Era, clicking around in the GUI to accomplish management tasks like this is so 2008.

Specifically there are two questions we want to answer:
1. How 

{%highlight powershell%}
{% include Scripts/Powershell/SNMPAgentUtils.ps1 %}
{%endhighlight%}

### Lets talk about it
Most of us are familiar with the problem. We work in large companies, or have worked with them, and we come across a server on the network and want to know who it belongs to. But just as bad or worse is the problem of keeping that servers contact information up to date.

We've all seen it happen. Someone is leaving the company that was responsible for a lot of stuff, and especially if they are leaving suddenly it might not occur to anyone to transfer ownership of their servers decide if they are even still needed. 
