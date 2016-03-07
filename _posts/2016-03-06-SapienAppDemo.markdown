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
![My helpful screenshot](_images/InitalFullScreen.jpg)