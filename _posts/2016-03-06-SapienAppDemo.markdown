---
published: true
title: Event Driven App with Sapien Powershell Studio
layout: post
---

I was on Twitter the other day and saw that [@juneb_get_help tweeted](https://twitter.com/juneb_get_help/status/705452955068071937) asking people to talk about things they had built with Powershell Studio. I responded, but I thought it really deserved a blog post to talk about the app and the kinds of things you can do with it. 

### The Business Problem
The company I work for installs software inside their clients' networks. We provide the client with a detailed spec of what we would like the servers they give us to look like, but it is very common for servers to be just a little bit wrong. Since we use Puppet for configuration management, it's important to verify that servers are in the correct state before accept them. 

The app I wrote is dropped onto a single server in the environment, and when provided a list of servers to test, invokes a series of remote jobs that instruct each box to test itself for correct state and report back the results. 

### Why Powershell Studio
As we will see shortly, Powershell studio is a good solution for this because it allows you take advantage of the convenience of Powershell for administering servers, while also taking advantage of event based programming and easily wrapping scripts in a GUI that suits the needs of slightly less technical users.

### The App
![Initial View](https://raw.githubusercontent.com/RandomNoun7/RandomNoun7.github.io/master/_images/InitalFullScreen.jpg)

In the screenshot above you can see the design view for the app. The app consists of a main form, a tab control with tabs for the stages of testing. In the tab you see here I am have a couple text boxes for Active Directory account names. Before the machines are tested I use the app to ensure that the Active Directory accounts we asked for have been created. 

Notice on the right side the name says textBoxSQLAccount. That is going to be the name of a variable created by the Studio to reference that text box.

![Add Event](https://raw.githubusercontent.com/RandomNoun7/RandomNoun7.github.io/master/_images/AddEvent.jpg)

In this screenshot we are adding an event handler to the lower text box. When you click ok you get a code block for the objects event handler.

![Event Code Auto Complete](https://raw.githubusercontent.com/RandomNoun7/RandomNoun7.github.io/master/_images/AddEventCodeAutoComplete.jpg)

If you're familiar with Powershell syntax you will recognize a variable with a code block. In the background, when Powershell Studio builds the app, it ensures that code is executed when that event is fired just as the name implies. To keep things neat, the code is factored out into a function and I simply pass the textbox, since both boxes need to run the same check when the Leave event fires. 

One of the cool things about Powershell Studio is how the really great auto complete incentivises you to write good code. The function Validate-Textbox was defined with a parameter of type System.Windows.Forms.Textbox. Powershell Studio knows it, so when auto complete comes up, it only shows me the variables of the correct type.

The code in Validate-TextBox is as follows:
{%highlight powershell%}
function Verify-ADObject
{
	param (
		[string]$name
	)
	
	if ((([ADSISearcher]"Name=$($name)").FindOne(), ([ADSISearcher]"SAMAccountName=$($name)").FindOne() -ne $NULL)[0])
	{
		Write-Output $true
	}
	else
	{
		Write-Output $false
	}
}

function Validate-TextBox
{
	param (
		[System.Windows.Forms.TextBox]$textBox
	)
	
	if (Verify-ADObject -name $textBox.Text)
	{
		$textBox.BackColor = 'LimeGreen'
	}
	else
	{
		$textBox.BackColor = 'Red'
	}
}
{%endhighlight%}

With these event handlers in place, every time my cursor leaves the text box the Validate-TextBox function is called with the current text box as the parameter, which then passes the text value to Verify-ADObject. If an object is returned we know it exists and the textbox turns green, and if not we get a red box. Since this is a demo app this is enough, but in reality we would want some checks in place to ensure such things as that a value actually exists in the text box in case someone just clicked on the text box by accident and then left.

![First Text](https://raw.githubusercontent.com/RandomNoun7/RandomNoun7.github.io/master/_images/FirstTest.jpg)