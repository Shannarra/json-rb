# Building a JSON parser from scratch
> Motivations, lessons learned and practical and proffessional applications.

## Preface

JSON (JavaScript Object Notation) is a lightweight data-interchange format ([json.org](https://www.json.org/json-en.html)) used to facilitate communication throughout the entire Internet via a multitude of protocols. It is made deliberately easy for humans of all backgrounds to read and understand, leveraging basic text and formatting, based on JavaScript.

Most programming languages have a built-in JSON parsing utility in one form or another, and the language this guide is written for - Ruby, is [no exception](https://ruby-doc.org/stdlib-3.0.2/libdoc/json/rdoc/JSON.html). That being said, creating your own JSON parser from scratch (using only the utilities the language provides, no external libraries) is still nothing but a __*great*__ side project if you'd want to learn the language you are going to be using, or just would like to test your skills. 

The creation of this project would require __strong__ knowledge base in a plethora of software development fundamentals, including but not limited to:
- Text reading and parsing
- Recursion
- Context-aware code behaviour

Using those concepts, we can draw a simple roadmap of the steps we'd take to reach our goal, namely:
1. Lexing and text parsing
2. Tokenizing
3. Creating a context-aware token parser
4. Exposing the parsed information as result from the parser in the form of a single value or a [Hash](https://ruby-doc.org/core-2.5.1/Hash.html)

## What will we be actually building
We will build a basic JSON parser from scratch, called `JRB` (short for `JSON RB`).
It could be used in more or less the same way the built-in Ruby JSON parser is.

For example, using the already provided parser would look somethig like this:
```ruby
JSON.parse!('{"username": "Shannarra", "language": "Ruby", "version": 3.0}')
```
And using our own parser would be of no difference semantically:
```ruby
JRB.parse! '{"username": "Shannarra", "language": "Ruby", "version": 3.0}'
```
Both of those will yield similar result:
```ruby
{"username"=>"Shannarra", "language"=>"Ruby", "version"=>3.0}
```

## Basic setup
First off, we'd need to have a standardized basic setup. For the purpose of this tutorial we'll create an empty folder and add a couple of files.

1. The first file will be an application entry point, we can call it anything, for example `main.rb`. 
For now, we can just print "Hello world!" to the console:
```ruby
def main
	puts "Hello World!"
end

main
```

We can run this basic program by running the following command:
```console
ruby main.rb
```

2. We would also like to add a Ruby-special file called `Gemfile`. 
This file will contain the information for external libraries we might wanna use for testing and debugging.
Just place the `Gemfile` in the root directory of our folder and add the following to it:

```ruby
source 'https://rubygems.org'

# Debugging libraries:
gem 'pry'

# Libraries for testing the application:
gem 'rspec'

# Linting libraries:
gem 'rubocop'
gem 'rubocop-rspec'
```

In order to install the libraries we can run the following command:
```console
bundle install
```

At the end of our setup, the folder should look like this (output of `tree .` command):
```console
.
├── Gemfile
└── main.rb

0 directories, 2 files
```

## Utilities? Let's make life easy!
Since we already have a basic application set up, we can go ahead and start with the initial steps of our project - creating basic utilities and lexing.

First off, we'll create a new folder and file inside our application.
In the root directory, we will create a folder called `src` (short for "source") and add all our important library source code files there. Inside of it, we will create a couple of files called `lexer.rb` and `util.rb`.

The file structure of the project should now look something like this:
```console
.
├── Gemfile
├── main.rb
└── src
    └── lexer.rb
    └── util.rb

1 directory, 4 files
```

Our basic `util` file will contain a couple of utility functions and/or constants definitions. For starters, we can add a simple configuration on how our lexer should percieve the different possible JSON tokens:
```ruby
JSON = {
  SYMBOLS: {
    COMMA: ',',
    COLON: ':',
    LEFTBRACKET: '[',
    RIGHTBRACKET: ']',
    LEFTBRACE: '{',
    RIGHTBRACE: '}',
    QUOTE: '"'
  },
  WHITESPACE: ['', ' ', "\r", "\b", "\n", "\t"],
  BOOLEAN: {
    TRUE: 'true',
    FALSE: 'false'
  },
  NULL: 'null'
}.freeze
```
And underneath that we can add a couple of extention functions to the `Kernel` module:
```ruby

module Kernel
  # inspired by https://stackoverflow.com/a/11455651
  def enum(values)
    Module.new do |mod|
      values.each_with_index { |v, _| mod.const_set(v.to_s.capitalize, v.to_s) }

      def mod.inspect
        "#{name} {#{constants.join(', ')}}"
      end
    end
  end

  def error!(message)
    puts "[ERROR]: #{message}"
    exit(1)
  end
end
```

Those will be useful later on.

## Creating a lexer
In a nutshell, the process of lexing will be a way of going through all characters in our JSON string and converting them to special `Token`s, which we can use later on for the actual parsing.

0. Starting the lexer
Inside `src/lexer.rb` we'll add a basic `Lexer` class:

```ruby
require_relative 'util'

class Lexer
  def self.lex!(text)
    puts text
  end
end
```

It has a simple static `#lex!` method that just prints the passed arguments to the console and incorporates the `util` file with all it's functionality for later use.

We can integrate it into our `main.rb` file by using the `require_relative` functionality of Ruby as follows:
```ruby
require_relative 'src/lexer'

def main
  Lexer.lex! "Hello world!"
end

main
```

Running our program, you will see that for now it is still a glorified "Hello world!", but that will soon change.

1. Setting the class up
We'll continue working on our `lexer.rb` class, adding a simple constructor and a new instance method named `lex`, as well as several attributes for parsing the contents:

```ruby
class Lexer
  attr_reader :text, :tokens, :ip

  def initialize(text)
    @text = text
    @tokens = []
    @ip = 0
  end

  def self.lex!(text)
    lexer = Lexer.new(text)
    lexer.lex
  end

  def lex
    puts text
  end
end
```

Basically, the static `lex!` method creates a new instance of the `Lexer` class and setups the default variables with default values. Those variables are:
- __*text*__: The text that needs to be parsed, the entire file contents or a stream thereof.
- __*tokens*__: A container, or a list of all of the tokens that our `Lexer` will return at the end of the `lex!` method's execution.
- __*ip*__: Short for `instruction pointer`, not Internet Protocol. A pointer to the current element we are looking at in the __*text*__.

Running the application we'll see that it still just prints out the arguments we've passed to the `lex!` method:
```ruby
$ ruby main.rb 
Hello world!
```

2. Continuing on, we can add a couple more helper methods to our lexer class and a basic class-level loop:
```ruby
  def lex
    while current
      puts current
      advance
    end
  end

  private

  def current
    @text[@ip]
  end

  def advance
    @ip += 1
  end
```

The new additions are two [private methods](http://ruby-for-beginners.rubymonstas.org/advanced/private_methods.html) called `current` and `advance`. They will be used to leverage the class-level iteration of the items (characters in this case) out class needs to parse or modify.

The `current` method returns the character in the text at the current instruction pointer (`ip`), and the `advance` method advances said pointer one step forward. This means that we can iterate on the `text` we are lexing on multiple levels at the same time, and as an added bonus - have a loop that is very simple to read and understand:
```ruby
    while current
      puts current
      advance
    end
```
It basically runs while there is a `current` character, prints it and `advance`s the `ip` for the nex iteration.

Saving and running the application (`ruby main.rb`) will result in us printing each character of our input to a new line like so:
```ruby
$ ruby main.rb 
H
e
l
l
o
 
w
o
r
l
d
!
```

3. Adding some basic text lexing
Continuing the work on the lexer, we can modify the `lex` method to the following:

```ruby
  def lex
    while current
      jstr = lex_str

      unless jstr.nil?
        tokens << jstr
        advance
      end

      if JSON[:WHITESPACE].include?(current)
        advance
      elsif JSON[:SYMBOLS].values.include?(current)
        tokens << current
        advance
      else
        break unless current

        error! "Unknown token \"#{current}\" encountered at #{ip}"
      end
    end

    tokens
  end
```
In order for our program to compile, we'd need to add a new `private` method at the end of our file, just below the `advance` function, called `lex_str`:

```ruby 
  def lex_str
    return nil if current != JSON[:SYMBOLS][:QUOTE]

    str = current
    advance
    return Token.new(TokenType::String, (str += current)) if current == JSON[:SYMBOLS][:QUOTE]

    loop do
      if current
        str += current
      elsif current.nil?
        error! 'Unterminated string found.'
      end

      advance
      return Token.new(TokenType::String, (str += current)) if current == JSON[:SYMBOLS][:QUOTE]
    end
  end
```

<details>
	<summary> 
        <h4>How does lexing a string work?</h4>
    </summary>
    
Lexing a string is actually fairly simple. 
We need to check if the current character is a quote, if it isn't - we aren't at the start of a string, so we return `nil` and continue on to the next possibility of parsing the `current` character.

However, if we are at the start of a string, we go ahead and add the quote to the local `str` variable and advance our ip. If the following character is also a quote - we'll return a simple empty string and exit the function. 

After all of those edge-cases have been escaped, we start an "infinite" (not really) loop that does a couple of checks:
1. If there is a current character - add it to the string
2. If there is __NOT__ a current character - raise an `error`, stating that we have found an unterminated string (e.g. it does not end with a `"`).
3. If there was no error - advance the ip
4. If the current symbol is a quote (`"`), this means that we have found the end of the string and we can safely return it and exit the function.
</details>

After saving the `lexer` file, if we run the program we will get greeted by the following error:
```console
$ ruby main.rb 
[ERROR]: Unknown token "H" encountered
```

In order to fix this, we will need to modify our `main.rb` file to pass valid arguments, which is actually very simple:
```ruby
require_relative 'src/lexer'

def main
  puts Lexer.lex! '"Hello world!"'
end

main
```

Now, re-running the application we will be greeted by a `NameError` 😱:
```console
[FULL_PATH_NAME_HERE]/src/lexer.rb:66:in `block in lex_str': uninitialized constant Lexer::Token (NameError)

      return Token.new(TokenType::String, (str += current)) if current == JSON[:SYMBOLS][:QUOTE]
             ^^^^^
	from [FULL_PATH_NAME_HERE]/src/lexer.rb:58:in `loop'
	from [FULL_PATH_NAME_HERE]/src/lexer.rb:58:in `lex_str'
	from [FULL_PATH_NAME_HERE]/src/lexer.rb:19:in `lex'
	from [FULL_PATH_NAME_HERE]/src/lexer.rb:14:in `lex!'
	from main.rb:4:in `main'
	from main.rb:7:in `<main>'
```

The Ruby compiler is telling us that it does not know what this construct called `Token` is, and we ought to fix that immediately!

4. A compiler screaming in horror
In order to fix the compiler error, we'd need to add the notion of `Token` to our project. To do that, we can go ahead and add a new file called `token.rb` into our `src` folder. Inside of it, we will need to add the following contents:
```ruby
TokenType = enum %w[
  Symbol
  Boolean
  Null
  Number
  String
]

class Token
  attr_reader :type, :value

  def initialize(type, value)
    @type = type
    @value = value
  end

  def to_s
    "Token<[#{type}] = #{value}>"
  end

  def ==(other)
    return value == other unless other.is_a? Token

    type == other.type && value == other.value
  end
end
```

It contains an enumerator called `TokenType` that contains all possible types a token can have, as well as a class, defining the notion of a `Token`. A `Token` is a wrapper around a pair of two values - a `TokenType` called "type", and a JSON value, called just "value" for short. It also defines a custom `to_s` method (similar to `toString()` in JavaScript) and a custom equality operator overload.

However, this does __NOT__ solve our issue. Reason is that our `Lexer` class and file do not know what a `Token` is yet. To fix that we can add a `require_relative` directive at the top of our `lexer.rb` file, just below the one for `util`. 
Adding this means that the top of your `lexer.rb` file should look something like this:

```ruby
require_relative 'util'
require_relative 'token'

class Lexer
  attr_reader :text, :tokens, :ip
v
  def initialize(text)
```

Now, if we run the `main.rb` file, we can see that our basic string parsing is working as expected ✅:
```
$ ruby main.rb 
Token<[String] = "Hello world!">
```

5. Numbers
Adding the ability to lex numbers is not *that* difficult either. We'd need to add a new function call to line 27 of our `lexer.rb` (or just below the `end` of our `unless jstr.nil?` clause) in the `lex` method, so it looks something like:

```ruby
  def lex
    while current
      jstr = lex_str

      unless jstr.nil?
        tokens << jstr
        advance
      end

      jnum = lex_num
      tokens << jnum unless jnum.nil?
```

We would also need to add a new method named `lex_num` at the bottom of our class definition:
```ruby
  def lex_num
    num = ''

    num_chars = (0..10).map(&:to_s) + %w[e - .]

    while current
      break unless num_chars.include?(current)

      num += current
      advance
    end

    return nil if num.empty?

    return Token.new(TokenType::Number, num.to_f) if num.include?('.') || num.include?('e')

    Token.new(TokenType::Number, num.to_i)
  end
```

<details>
	<summary> 
        <h4>How does lexing a number work?</h4>
    </summary>
Number lexing is a bit more complex (but not much) than lexing strings.

We iterate through the characters after (and including) the current one and check if said character is a number(0..10), or is one of the symbols `-`, `e` or `.`.

If an invalid character has been encountered - we exit and return `nil`, meaning that we don't return a number token at all and continue lexing in the `lex` method.

If, however, the collected characters constitute a valid number, we check if the number contains a decimal point (`.`) or is in standard notation (e.g. `12e6`).
If it does - we parse it to a `float` and return a new number token. Otherwise, we parse it as an `int` and return it that way.
</details>

In order to test that our number lexing works as expected, we can modify our `main.rb` file so something like:
```ruby
require_relative 'src/lexer'

def main
  puts Lexer.lex! '10 -2 5e6 4.20'
end

main
```

Running it we get the following output, confirming that the functionality works as expected:
```console
$ ruby main.rb 
Token<[Number] = 10>
Token<[Number] = -2>
Token<[Number] = 5000000.0>
Token<[Number] = 4.2>
```

We can clearly see that it works perfectly, and it supports [scientific notation](https://en.wikipedia.org/wiki/Scientific_notation), as well as negative numbers, floats and integers alike.

6. Finishing up with lexing
The only things left to be able to parse is `boolean` values (e.g. `true` and `false`) and `null`. 
We can add a couple more handlers for booleans and "null" values in our `lexer.rb`'s `lex` function. 
At the end of it, our `lex` function should look like so:

```ruby
 def lex
    while current
      jstr = lex_str

      unless jstr.nil?
        tokens << jstr
        advance
      end

      jnum = lex_num
      tokens << jnum unless jnum.nil?

      jbool = lex_bool
      tokens << jbool unless jbool.nil?

      null = lex_null
      tokens << null unless null.nil?

      if JSON[:WHITESPACE].include?(current)
        advance
      elsif JSON[:SYMBOLS].values.include?(current)
        tokens << current
        advance
      else
        break unless current

        error! "Unknown token \"#{current}\" encountered at #{ip}"
      end
    end

    tokens
  end
```

This means that we would need to add two new functions, called `lex_bool` and `lex_null`.
The first one consists of the following:
```ruby
  def lex_bool
    bool_vals = JSON[:BOOLEAN]
    possible_values = bool_vals.values.map(&:chars).flatten.uniq

    jbool = ''

    while current
      break unless possible_values.include?(current)

      jbool += current if possible_values.include?(current)
      advance
    end

    case jbool
    when bool_vals[:TRUE]
      Token.new(TokenType::Boolean, true)
    when bool_vals[:FALSE]
      Token.new(TokenType::Boolean, false)
    end
  end
```
<details>
	<summary> 
        <h4>How does lexing a boolean work?</h4>
    </summary>
Boolean lexing is generally straightforward.

We collect characters until we have enough characters to match a "true" it a "false" string. If we match any of those - we return a `Token` with that value, otherwise we return an invalid token and continue iterating.
</details>

And lexing a `null` value is done in a not too-dissimilar way:
```ruby
  def lex_null
    null = ''

    while current
      break unless JSON[:NULL].chars.include?(current)

      null += current if JSON[:NULL].chars.include?(current)
      advance
    end

    Token.new(TokenType::Null, nil) if null == JSON[:NULL]
  end
```
<details>
	<summary> 
        <h4>How does lexing a null work?</h4>
    </summary>
Null lexing is the same as lexing a boolean, but instead of matching two values, we only need to match for `"null"`.
</details>

Now, if we go ahead and modify our `main.rb` one last time for this section
```ruby 
require_relative 'src/lexer'

def main
  puts Lexer.lex! '{"items":[1,6.9,-1200000,"Hello World!",[1,2,3],{"name":"John Doe", "false": true, "true": false, "value": null}]}'
end

main
```
and run it, we can see that we lex all items correctly:
```console
$ ruby main.rb 
{
Token<[String] = "items">
:
[
Token<[Number] = 1>
,
Token<[Number] = 6.9>
,
Token<[Number] = -1200000>
,
Token<[String] = "Hello World!">
...
```
> (list has been shortened for brevity)

You might see that the symbol tokens are just raw characters and not wrapped in `Token`s. There is a very clear reason for that behaviour that will become apparent when we talk about parsing in the next section.
