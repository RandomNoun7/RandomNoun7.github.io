---
published: true
title: Event Based Asynchronous Job Management In Powershell
layout: post
---
In my [last post](http://randomnoun7.github.io/2016/03/06/SapienAppDemo.html) I demo'd building an event based GIU app in Powershell Studio. You probably noticed though that some of the code to handle long running tasks in a background job was less than ideal. 
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

**Session Variables:** Creating a session variable takes a little time, but it saves you time later. If you are making a GUI find an unobtrusive place in your app's execution like the FormShown event to create session objects or even a loading spinner before the user is allowed to start if you need to. Create sessions on the local server and to any remote servers you want to execute jobs on. That way they will be ready to go when you need to pass them to Invoke-Command. 

**Job Names:** There might be a better way to do this, but to allow the code to clean up after itself without looping through all background jobs, it's important that the event handling code have a way to know which job it should delete. In typical use you would probably build a string inside a loop for each job name you need, and pass it into the job. 

**Job Name Param:** The script block you pass into the job needs to take at least one parameter so it can receive the name you've assigned the job. This is important because the jobs result set needs to include this name so the callback code block knows which job it's receiving results from.

**Register-EngineEvent in Remote Code Block:** It's not great that you have to repeat the event name so many times, but it's import that you register the engine event in the main session, and also in the background job code block. In the background code block though you use the -Forward parameter to ensure the event you raise later gets forwarded up to the parent session.

**-EventArguments:** This should be the result of your long running operation.

**-Sender:** The sender will be your job name so the callback codeblock knows which job to clean up.

**Making use of values:** If you have a GUI app it' really easy to make use of the jobs results. You can find the UI element you want to modify and assign the value where it's needed. If you are not in a GUI app you can either create the variable ahead of time and do the assignment in the callback code block, or assign a new variable in the code block, but make sure the scope the variable so that it still exists after the code block completes.

**Memory Usage:** I looked for a decent way to do this using runspaces because I think the memory usage is probably lower, but I didn't find a decent way to make it happen. So keep in mind that this works well, but keep an eye on RAM Usage in testing. If you start a loop over a large number of object I can imaging memory consumption getting out of control pretty quickly. But of course, using the looping method the same consideration applies.

**Why Not Runspaces?:** Run spaces have a lot of advantages besides lower memory usage. One of them is persistence. The runspace doesn't need to be cleaned up when it's done with a task. You can also give it lots function definitions and just ask it to execute them as needed. The problem I ran into was that it was a lot harder to get the runspace to communicate results and data back up to the parent runspace than it was to communicate downward. 

Anyway, I hope you like it and please let me know if you think there are ways to improve it! You can reach me on Twitter [@RandomNoun7](https://twitter.com/randomnoun7)