# Kindle Hacks
A collection of stuff related to hacking on a kindle. Unless stated assume it's a Paper White 3 (PW3).

# Jail Breaking & Setting up
I used [these instructions](https://www.mobileread.com/forums/showthread.php?t=346037) to jailbreak the device. Things to note in the process:
 - I was running firmware 5.12.x, but the jailbreak needed at least 5.13.4. The Amazon support pages provided a download for 5.15.1 - but that fixes the backdoor used by the jailbreak. Luckily I discovered Amazon still hosts old versions of the firmware, you just need to edit the URL, e.g. here's [5.13.4.bin](https://s3.amazonaws.com/firmwaredownloads/update_kindle_all_new_paperwhite_5.13.4.bin). I upgraded to that first, and the jailbreak worked.
 - Pay attention to how to do the secret gesture once in demo mode. It took me at least 5+ attempts every time I tried. There's an illustration further down the instructions page.

# Screensaver
Many people have turned a kindle into a dashboard or photo frame. My attempts ran into problems with power management, and I ended up making my own solution. See `run_screensaver.sh` for details.

# Wifi with no internet access
When joining a wifi network, the kindle will try and access predefined amazon endpoints on the internet. If connecting to these fail it will assume the network connection is bad and disconnect. This is problem when connecting a kindle to wifi network which intentionally doesn't have internet access.

Using tcpdump I watched what the kindle attempted to do when first connecting to an wifi network. I added entries in my local DNS server to redirect the following domains to a local server. They might not all be needed, but once it worked I just left them.

```
firs-ta-g7g.amazon.com
d18os95hu8sz6h.cloudfront.net
dns.kindle.com
dogvgb9ujhybx.cloudfront.net
kindle-time.amazon.com
kwis-opf-preprod.amazon.com
ntp-g7g.amazon.com
pins.amazon.com
s3.amazonaws.com
spectrum.s3.amazonaws.com
```

The local server I redirected traffic to was already running DNS & NTP (which I'm guessing the dns & ntp domains were being used for). However I had to standup a web server (http/80) with one directory and two files.

```
kindle-wifi/wifistub-eink.html
kindle-wifi/wifistub.html
```

Both files simply contain the string:

```
81ce4465-7167-4dcb-835b-dcc9e44c112a 
```

To test the setup, `curl http://spectrum.s3.amazonaws.com/kindle-wifi/wifistub-eink.html` should return the string.

Now my kindle happily connects (and reconnects after sleeping) to the wifi despite there being no internet access.

## Editing kdb values
You can't normally edit values in the kdb database because they're read from a read-only mount. Instead you can copy the database elsewhere, and create a read-write bind mount over the original path.

I ended up not needing this, but it's a useful hack: https://www.mobileread.com/forums/showpost.php?p=3279358&postcount=3


## Dump of links
 - http://www.mobileread.mobi/forums/showthread.php?t=337314
 - http://www.mobileread.mobi/forums/showthread.php?t=127842
 - http://www.mobileread.mobi/forums/showthread.php?t=271120
 - https://news.ycombinator.com/item?id=11897804
 - https://www.sixfoisneuf.fr/posts/kindle-hacking-deeper-dive-internals/

