---
published: true
title: SNMP Agent Functions
layout: post
---

### Hello
Hello everyone. Welcome to the inaugural blog post in whatever it is that this becomes. I'll take some time in a later post to talk about how this place is set up why I like it, but for now, lets talk about some code. 

### The problem
I want to use some automation tools to help me keep this contact info up to date, but Windows support for getting this string programmatically isn't very good. Most tutorials for managing this value involve clicking around in the GUI. Below is the code for a couple easy functions to get and set this value remotely on large numbers of Windows machines, and a helper I wrote for gathering the names of the machines I want to manage based on their Active Directory OU's, just because that happened to be useful to me. Below the code I'll talk briefly about how I'm using the functions with Jenkins and Pester testing to automate notifications when someone leaves the company and I need to make sure some one new takes responsibility for a server.

{%highlight powershell%}
{% include Scripts/Powershell/SNMPAgentUtils.ps1 %}
{%endhighlight%}

### Lets talk about it
Now we have a nice programatic way of getting the contact info for a bunch of servers, but how do we turn that into an actual process?

For me, the answer is that we turn this into a Jenkins job. Many of you are familiar with Jenkins as a build server, but if you think a little more generally, it's also just a great general task runner, especially for anything that you can express in terms of pass fail testing, and that's where Pester comes in. 

In the Jenkins job the tests look like this:

1. Gather my list of computers using the Get-ComputersByOU function.
2. Feed that list to the Get-SNMPAgent function to get your computer and agent objects.
3. Use Pester tests to examine the owner/server pair to see if the combination is still valid. You can use any logic you like for this test. In my case the current test is simple. Is this user still an enabled user in Active Directory or a valid group. If not it means they probably left the company, and any servers they are still responsible for will be represented by failed Pester tests.
4. Jenkins takes the Pester output (did you know Pester can output NUnit XML files? It's fantastic.) and marks the "build" as either successful (all servers have valid owners), or failed and takes action accordingly. In my case it sends me an email that one of my servers needs a new owner.

In a later blog post we'll look at some of the code to make this happen. It's very short and elegant and will help ensure that anyone on the network who wants to know something about a server will always know exactly who to contact.

Thanks for reading.
