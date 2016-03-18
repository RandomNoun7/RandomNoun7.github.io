---
published: true
title: Event Based Asynchronous Job Management In Powershell
layout: post
---
In my last post I demo'd building an event based GIU app in Powershell Studio. You probably noticed though that some of the code to handle long running tasks in a background job was less than ideal. 
To recap it was handled as follows:

* Create a timer object
* Assign a code block to the tick event that knows how to poll for the status of all of your background jobs
* Create and start the jobs running
* Start the timer ticking
* The code block checks for job results and hopefully cleans up after itself when the jobs are done. 

It certainly works, but it can hardly be called clean. In fairness, without C#'s background workers, Powershell is at a cleanliness disadvantage, but I think there's still a better way. 
What if the process looked more like:

* Register an event handler that just waits for your job to finish without sitting there and cycling over and over again.
* Create and start your job
* Inside the code of the job, fire an event when the job is done that calls your registered event handler
* The event handler consumes the results of the long running task and cleans up the job when it's done. 

Check out the code snippet below and then I'll go over it in detail.

{%highlight powershell%}
$session = New-PSSession -ComputerName "RemoteServerName"

$tb = New-Object System.Windows.Controls.TextBox

$block = {
    $tb.Text = "New value from job."

    Write-host $tb.Text -BackgroundColor Green -NoNewline

    Get-Job -Name $event.SourceArgs.jobName | Remove-Job -Force
}

Register-EngineEvent -SourceIdentifier Custom.RaisedEvent -Action $block

$jobName = "EventTestJob"

Invoke-command -Session $session -ScriptBlock{
                                                param([string]$jobName) 
                                                Start-Sleep -Seconds 10
                                                Register-EngineEvent Custom.RaisedEvent -Forward
                                                New-Event Custom.RaisedEvent -EventArguments (@{jobName=$jobName})
                                            } -ArgumentList $jobName -AsJob -JobName $jobName | out-null
{%endhighlight%}

### Considerations in this code

**Session Variables:** Creating a session variable takes a little time, but it saves you time later. If you are making a GUI find an unobtrusive like the FormShown event to create session objects to the local server and to any remote servers you want to execute jobs on. That way they will be ready to go when you need to pass them to Invoke-Command. 

**Job Names:** There might be a better way to do this, but to allow the code to clean up after itself without looping through all background jobs, it's important that the event handling code have a way to know what job it should delete. In typical use you would probably build a string inside a loop for each job name you need, and pass it into the job. 

**Job Name Param:** Your script block you pass into the job needs to take at least one parameter so it can receive the job name you've assigned the job. The problem this solves is allowing the callback code block to identify the job that raised the event so it can delete the job when it's done. If you don't care about deleting the completed job, by all means leave it out.

**Register-EngineEvent in Remote Code Block:** It's not great that you have to repeat the event name so many times, but it's import that you register the engine event in the main session, and also in the background job code block. In the background code block though you use the -Forward parameter to ensure the event you raise later gets forwarded up to the parent session.

**-EventArguments:** Ensure you pass your output in the form of a Hashtable or other collection that passes the job name back out, and also contains whatever other data you need to process.

**Memory Usage:** I looked for a decent way to do this using runspaces because I think the memory usage is probably lower, but I didn't find a decent way to make it happen. So keep in mind that this works well, but keep an eye on RAM Usage in testing. If you start a loop over a large number of object I can imaging memory consumption getting out of control pretty quickly. But of course, using the looping method the same consideration applies.

Anyway, I hope you like it and please let me know if you think there are ways to improve it! You can reach me on Twitter [@RandomNoun7](https://twitter.com/randomnoun7) and I want to say thanks to 