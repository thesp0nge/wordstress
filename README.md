# Wordstress

wordstress is an opensource whitebox security scanner for wordpress powered
websites.

## Description

[wordstress](https://rubygems.org/gems/wordstress) is a whitebox
security scanner for wordpress powered websites.

Site owners don't want to spend time in reading complex blackbox security scan
reports trying to remove false positives. A useful security tool must give them
only vulnerabilities really affecting installed plugins or themes.

Let's assume, plugin `foobar_plugin` version 3.4.3 has a sever SQL Injection
vulnerability. In one of several wordpress powered website, you installed
version 3.2.1 version that **is not vulnerable**.

A blackbox security scanner will try to enumerate installed plugins but it
can't tell the exact installed version. So, using a blackbox approach you'll
have a alleged SQL Injection vulnerability you must validate and mitigate.
Unfortunately, you will lose precious time to spot a false positive since your
plugin is safe.

With wordstress plugin, you'll give [the security
tool](https://rubygems.org/gems/wordstress) the exact `foobar_plugin` version
installed on the system, 3.2.1. The tool will scan the knowledge base and
report 0 vulnerabilities. You save time and you can be focused only on stuff
really need your attention.

Of course you may argue that giving on the Internet a place where all your
website third parties plugins and themes name with version is not a wise
decision. This is correct, that's why wordstress plugin creates a secure access
key the scanner must use in order to access /wordstress virtual page.

People without the correct key can't access your website information. The key
is unique per server and created with hashing functions so to be resilient to
guessing account. Bruteforcing the key will lead to an unsuccessful attempt,
and you'll be busted. For sure.

You must pass the correct key value to wordstress ruby gem in order to perform
the whitebox scan. If you provide the wrong key or you won't provide a key at
all, the wordstress plugin will give no information as output and then no
whitebox scan will be possible.

You don't like the key? Just reload the page a couple of times since you're
comfortable about the generated entropy and then save the settings.

## Installation

wordstress scanner, this ruby gem is very easy to install.  You need a working
ruby environment, please ask your preferred search engine if you need
instructions on how to setup ruby on your operating system.  Just issue the
`gem install wordstress` command and you're almost ready to start.

To install the [wordstress plugin for
wordpress](https://wordpress.org/plugins/wordstress/) you may must:

* download wordstress.zip and unpack the content to your `/wp-content/plugins/` directory
* activate the plugin through the 'Plugins' menu in WordPress
* navigate the Settings->Wordstress admin page
* every time you enter wordstress setting page, a new key is automagically
  generated, to increase entropy you may want to reload the page a couple of
  times. When you're comfortable with the generated key, press the "Save Changes"
  button.
  The virtual page is now available at the url http://youblogurl/wordstress?wordstress-key=the_key
* from the command line, use wordstress security scanner this way: `wordstress -u http://yourblogurl/wordstress -k the_key`
* enjoy results

## Why another tool?

[wpscan](https://github.com/wpscanteam/wpscan) is a great tool and wordstress
do use [wpvulndb API](https://wpvulndb.com/api) as knowledge base, that is the
same KB enpowering wpscan.

For some very personal issues I need some features that wpscan doesn't have out
of the box, of couse I can fork it and contributing, but since they are mostly
on presentation and scanning steps, it would be a major rewrite rather than a
pull request.

True to be told, I added basic authentication support in [December
2012](https://github.com/wpscanteam/wpscan/pull/45). I don't want to impose my
own scanning vision and my very particular scanning needs, then I started a
smaller project.

Another thing I don't like about wpscan is that isn't distributed as ruby gem.
I want a security tool that follows 'the ruby way'.

Furthermore, wordstress is designed to be more accurate in whitebox testing.
During those years I was very upset as pentester with false positives about
themes and plugins and their version. Since an authenticated check is necessary
to match scan results with installed plugin (or theme) version, I tought it was
a better idea to start authenticated from the beginning.

## Usage

Using wordstress from command line is pretty easy. There are 2 mandatory
arguments, the key to use to query the wordpress plugin and the target url.

`$ wordstress -k d4a34e43b5d74c822830b5c4690eccbb621aa372 http://mywordpressblog.com`

By default, wordstress doesn't look for inactive themes or inactive plugins
vulnerabilities. This means that if `foobar_plugin` installed version is
vulnerable to privilege escalation, wordstress scanner by default won't raise
an alarm if the `foobar_plugin` **is not active**.

If you want to include vulnerabilities for all themes and vulnerabilities you
can use -T and -P flags.

`$ wordstress -k d4a34e43b5d74c822830b5c4690eccbb621aa372 -T -P http://mywordpressblog.com`

Examples:
$ wordstress -k d4a34e43b5d74c822830b5c4690eccbb621aa372 -B basic_user:basic_password http://mywordpressblog.com

-k, --key                            uses the key to access wordstress plugin content on target website
-B, --basic-auth user:pwd            uses 'user' and 'pwd' as basic auth credentials to target website

Plugins and themes specific flags

-T, --fetch-all-themes-vulns         retrieves vulnerabilities also for inactive themes
-P, --fetch-all-plugins-vulns        retrieves vulnerabilities also for inactive plugins

Service flags

-D, --debug                          enters dawn debug mode
-v, --version                        shows version information
-h, --help                           shows this help

## Online resource

[Wordstress homepage](http://wordstress.org)
[Wordstress plugin](http://wordpress.org/plugins/wordstress/)
[Attacking Wordpress](http://hackertarget.com/attacking-wordpress/)


## Killing features

* A great knowledge base powered by [wpvulndb API](https://wpvulndb.com)
* Standard rubygem distribution
* Whitebox testing using existing wordpress user for template and themes vulnerabilities.
* Information gathering from robots.txt file _(planned)_
* SQL and CSV output. Suitable for script integration _(planned)_
* Massive websites scan from text file _(planned)_
* SSL server rating using [Qualys SSL Labs rating guide](https://www.ssllabs.com/projects/rating-guide/) _(planned)_

## Contributing

1. Fork it ( https://github.com/[my-github-username]/wordstress/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
  3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
  5. Create a new Pull Request
