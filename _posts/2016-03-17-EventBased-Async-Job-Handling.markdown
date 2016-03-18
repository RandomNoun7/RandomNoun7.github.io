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
$session = New-PSSession -ComputerName $env:COMPUTERNAME

$tb = New-Object System.Windows.Controls.TextBox

$block = {
    $tb.Text = "new value asyncjob6"

    Get-Job -Name $event.SourceArgs.jobName | Remove-Job -Force
}

Register-EngineEvent -SourceIdentifier Custom.RaisedEvent -Action $block

$jobName = "MPDEVOPSJENKINSEventTest"

Invoke-command -Session $session -ScriptBlock{
                                                param([string]$jobName) 
                                                Start-Sleep -Seconds 10
                                                New-Event Custom.RaisedEvent -EventArguments (@{jobName=$jobName})
                                            } -ArgumentList $jobName -AsJob -JobName $jobName | out-null
{%endhighlight%}