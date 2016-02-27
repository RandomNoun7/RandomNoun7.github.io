---
published: true
title: Examining and Manipulating Cross Platform Text Files
layout: post
---
Have you ever had to transfer files over FTP to and from Windows and Linux systems and had to deal with an administrator that just could not comprehend why the files he or she is giving you aren't coming out right?

Maybe they are transferring the files to you and they keep showing up with no line breaks. The problem if course is pretty simple on the surface. Windows uses Carriege Return (Char(13))/Line Feed(Char(10)) together to represent line breaks, while many other operating systems only use CR. Of course if you're not very lucky you are dealing with an OS or an import program that expects something even weirder like RS(Char(30)). 

So yeah, the problem is simple to understand, and usually simple to fix. Use ASCII Transfer mode in FTP instead of Binary and most of the time the problem goes away. But what do you do when the admin on the other side doesn't believe you that the file is fine from your perspective? Or maybe they insist that they DID FIX IT!!! How do you convince someone that their encoding is wrong, or that yours is fine? Maybe it's not worth the struggle. How do you fix a file so that they can consume it no matter what?

### Examining the file
{%highlight powershell%}
<#
.Synopsis
   Get a specified number of bytes from a text file for display
.DESCRIPTION
   Read in a specified number of bytes from a text file. Display the bytes as a table that shows each character along with its decimal and hex values.
.EXAMPLE
   Get-TextBytesTable -path c:\textFile.txt -bytes 100
#>
function Get-TextBytesTable
{
    [CmdletBinding()]
    [Alias('gbt')]
    Param
    (
        # Path to file to read.
        [Parameter(Mandatory=$true,
                   Position=0)]
        $Path,

        # Number of bytes to read
        [int]
        $count
    )

    Process
    {
        (Get-Content $path -raw -Encoding Byte)[0..$count] | 
            Foreach-Object{$props = @{
                                      character=[char]$_;
                                      Decimal=$_;
                                      Hex="0x$('{0:x}' -f $_)"
                                     };
                           New-Object -TypeName PSobject -Property $props
                           } | 
                Format-Table Character,Decimal,Hex   
    }
}
{%endhighlight%}
