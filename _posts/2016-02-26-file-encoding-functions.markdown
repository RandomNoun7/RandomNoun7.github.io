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

Let's create a couple files and take a look at some of the output this function will give us.

{%highlight powershell%}
$string = "Hello World!`r`nAnd here we have another line!"
$string | Set-Content c:\TestFile.txt -Encoding Ascii
$string | Set-Content c:\TestFile2.txt -Encoding UTF32
(Get-Content C:\TestFile.txt).trim() -join [char]10 | Set-Content c:\testFile3.txt -Encoding Ascii -NoNewline

Get-TextBytesTable -path c:\TestFile.txt -count 100
Get-TextBytesTable -path c:\testFile2.txt -count 100
Get-TextBytesTable -path c:\testFile3.txt -count 100
{%endhighlight%}

With the command and output below we see that the first file is a very plain ASII encoded file. No [byte order mark](https://www.w3.org/International/questions/qa-byte-order-mark.en.php) or anything silly like that. Notice the Char 13 and Char 10. That's our line break.
{%highlight powershell%}
PS C:\> Get-TextBytesTable -Path .\testFile.txt -count 100

character Decimal Hex 
--------- ------- --- 
        H      72 0x48
        e     101 0x65
        l     108 0x6c
        l     108 0x6c
        o     111 0x6f
               32 0x20
        W      87 0x57
        o     111 0x6f
        r     114 0x72
        l     108 0x6c
        d     100 0x64
        !      33 0x21
      ...      13 0xd 
      ...      10 0xa 
        A      65 0x41
        n     110 0x6e
        d     100 0x64
               32 0x20
        h     104 0x68
        e     101 0x65
        r     114 0x72
        e     101 0x65
               32 0x20
        w     119 0x77
        e     101 0x65
               32 0x20
        h     104 0x68
        a      97 0x61
        v     118 0x76
        e     101 0x65
               32 0x20
        a      97 0x61
        n     110 0x6e
        o     111 0x6f
        t     116 0x74
        h     104 0x68
        e     101 0x65
        r     114 0x72
               32 0x20
        l     108 0x6c
        i     105 0x69
        n     110 0x6e
        e     101 0x65
        !      33 0x21
      ...      13 0xd 
      ...      10 0xa 
{%endhighlight%}

With UTF32 it gets a little more complicated. We start with the byte order mark and then have a bunch of unused bytes between each letter. Our Char 10 and 13 are still there though. We've taken up more space but this is still a fairly plain windows file. 
{%highlight powershell%}
PS C:\> Get-TextBytesTable -Path .\testFile2.txt -count 100

character Decimal Hex 
--------- ------- --- 
        ÿ     255 0xff
        þ     254 0xfe
                0 0x0 
                0 0x0 
        H      72 0x48
                0 0x0 
                0 0x0 
                0 0x0 
        e     101 0x65
                0 0x0 
                0 0x0 
                0 0x0 
        l     108 0x6c
                0 0x0 
                0 0x0 
                0 0x0 
        l     108 0x6c
                0 0x0 
                0 0x0 
                0 0x0 
        o     111 0x6f
                0 0x0 
                0 0x0 
                0 0x0 
               32 0x20
                0 0x0 
                0 0x0 
                0 0x0 
        W      87 0x57
                0 0x0 
                0 0x0 
                0 0x0 
        o     111 0x6f
                0 0x0 
                0 0x0 
                0 0x0 
        r     114 0x72
                0 0x0 
                0 0x0 
                0 0x0 
        l     108 0x6c
                0 0x0 
                0 0x0 
                0 0x0 
        d     100 0x64
                0 0x0 
                0 0x0 
                0 0x0 
        !      33 0x21
                0 0x0 
                0 0x0 
                0 0x0 
      ...      13 0xd 
                0 0x0 
                0 0x0 
                0 0x0 
      ...      10 0xa 
                0 0x0 
                0 0x0 
                0 0x0 
{%endhighlight%}

Lastly we see what the bytes look like in a file that looks fine to the linux admin but looks like just a blob of text to us. This simple file is easy to fix manually, but if you're trying to set up automated data imports on a Windows system, this can be a real pain.
{%highlight powershell%}
PS C:\> Get-TextBytesTable -Path .\testFile3.txt -count 100

character Decimal Hex 
--------- ------- --- 
        H      72 0x48
        e     101 0x65
        l     108 0x6c
        l     108 0x6c
        o     111 0x6f
               32 0x20
        W      87 0x57
        o     111 0x6f
        r     114 0x72
        l     108 0x6c
        d     100 0x64
        !      33 0x21
      ...      10 0xa 
        A      65 0x41
        n     110 0x6e
        d     100 0x64
               32 0x20
        h     104 0x68
        e     101 0x65
        r     114 0x72
        e     101 0x65
               32 0x20
        w     119 0x77
        e     101 0x65
               32 0x20
        h     104 0x68
        a      97 0x61
        v     118 0x76
        e     101 0x65
               32 0x20
        a      97 0x61
        n     110 0x6e
        o     111 0x6f
        t     116 0x74
        h     104 0x68
        e     101 0x65
        r     114 0x72
               32 0x20
        l     108 0x6c
        i     105 0x69
        n     110 0x6e
        e     101 0x65
        !      33 0x21
{%endhighlight%}

### Fixing the File
So now that we've seen how we can inspect the file, what can we do if the admin on the other end just doesn't know how to fix this. And by the way, this doesn't always mean they are incompetent. I've been told by a very smart admin that getting this right transferring in and out of AIX is just hard. 

That last command really shows us how we can make the other guys life easier for very little effort on our part. If you aren't super familiar with Powershell it's worth looking at exactly how it works.
{%highlight powershell%}
(Get-Content C:\TestFile.txt) -join [char]10 | Set-Content c:\testFile3.txt -Encoding Ascii -NoNewline
{%endhighlight%}

Get-Content reads a file's content, but it will break up each line into a discreet string object, stripping its line endings in the process. The syntax forces the entire file to be processed at once and the newly created array of string objects is handed off to the -join operator. We join by char 10 in this case to give us Linux line endings. We pass that resulting string off to Set-Content choosing ASCII as our encoding (encoding can be whatever the recipient wants), ensuring that we use -NoNewline so we don't get a Windows line ending appended at the very end of the file. Now you can do a binary file transfer and the Linux system is happy.

Need to terminate lines with a "~"? yeah I've seen it. Just use -join [char]126. Any crazy line terminator they want, you can provide.

This also gives us insight into how to fix Linux line endings that they can't figure out how to fix for us. 
{%highlight powershell%}
Get-Content c:\BrokenFile.txt | Set-Content c:\FixedFile.txt
{%endhighlight%}

In this case we take advantage of the fact that while many older Windows programs adhere slavishly to Windows Cr\Lf line endings, Powershell really does attempt to be smarter, so it has been designed such that many commandlets like Get-Content understand Linux line endings by default. Again though it strips the line endings as it breaks the files lines into an array of strings. As those string objects are passed on to Set-Content though, it adds them to file one at a time, but this time it uses the standard Windows line endings, and just like that, a file that just a second ago looked like one long line of gibberish is fixed. 

One last thing, just to save you a minute of frustration, notice that I did not write to the same file as I read the data from. When Powershell starts reading a file and breaking the lines into a string objects, the first of those strings will reach Set-Content before Get-Content has actually finished reading the file. If you want to convert a file in place you will have to stage the data somewhere else first, or Set-Content will just encounter a file that is still open for reading and throw an error that it can't write to the file because it's still locked. 
 
{%highlight powershell%}
PS C:\>$contents = Get-Content c:\BrokenFile.txt 
PS C:\>$contents | Set-Content c:\FixedFile.txt

PS C:\>Get-Content c:\SourceFile.txt | Set-Content c:\temp.txt
PS C:\>Move-Item c:\temp.txt -destination c:\SourceFile.txt
{%endhighlight%}

If the file is small and you have the RAM to spare you can use the first method. If you want to conserve RAM and be nice to the other processes on the box, use the second. 