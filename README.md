# Wordstress

wordstress is a application security tool specific for wordpress powered
websites, inspired by [wpscan](https://github.com/wpscanteam/wpscan) tool.

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

## Killing features

* A great knowledge base powered by [wpvulndb API](https://wpvulndb.com)
* Information gathering from robots.txt file
* Standard rubygem distribution
* SQL and CSV output. Suitable for script integration
* Massive websites scan from text file
* SSL server rating using [Qualys SSL Labs rating guide](https://www.ssllabs.com/projects/rating-guide/)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wordstress'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wordstress

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/[my-github-username]/wordstress/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
