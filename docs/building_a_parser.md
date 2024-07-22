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
JRB.parse!('{"username": "Shannarra", "language": "Ruby", "version": 3.0}')
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

---
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
  
  TokenType.constants.map { |type| type.to_s.downcase }.each do |type|
    define_method("#{type}_token?") { is_a?(Token) && self.type == type.capitalize }
  end
end
```

It contains an enumerator called `TokenType` that contains all possible types a token can have, as well as a class, defining the notion of a `Token`. A `Token` is a wrapper around a pair of two values - a `TokenType` called "type", and a JSON value, called just "value" for short. It also defines a custom `to_s` method (similar to `toString()` in JavaScript) and a custom equality operator overload.

Moreover, the `Token` class implicitly defines a `X_token?` boolean instance method, where X is one of the possible `TokenType`s defined at the top of the file. This is completely extendable for any value in the `TokenType` enum, and is useful to check if a variable is a `Token` __*AND*__ is of certain type (e.g. to check if the current token is a string you can use the `current.string_token?` method). 

However, this does __NOT__ solve our issue. Reason is that our `Lexer` class and file do not know what a `Token` is yet. To fix that we can add a `require_relative` directive at the top of our `lexer.rb` file, just below the one for `util`. 
Adding this means that the top of your `lexer.rb` file should look something like this:

```ruby
require_relative 'util'
require_relative 'token'

class Lexer
  attr_reader :text, :tokens, :ip

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

---
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

---
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
Null lexing is the same as lexing a boolean, but instead of matching two values, we only need to match for "null".

---
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


## Parsing - or, converting the [Token](../src/token.rb)s to something meaningful

Now, we can generate a linear list of `Token`s, cool, eh? Nah, not really.

Neither the basic `Ruby` language, nor most programmers know how to use those, and they don't give much information on what is nested where, nor are they very descriprive with regards to the nested information within. Thus, we would want to make something useful out of them, and as such we need to go to the next and (almost) final step of our process - Parsing. 

Parsing is the process of converting formatted text into a data structure. A data structure type can be any suitable representation of the information engraved in the source text ([The Mighty Programmer](https://themightyprogrammer.dev/article/parsing)). For our purposes, we would use a [Hash](https://ruby-doc.org/core-2.5.1/Hash.html) data structure, as they perfectly represent the dictionary-based layout of JSON in a neat format to both read and write as programmers. So, how do we do it?

0. First part, obviously, is a setup.  
We'd want to store the parser somewhere, hence we can create a new file in our `src` folder. Let's call it `parser.rb`. Now, if we take a look at our directory tree we can see the following:

```console
$ tree .
.
├── Gemfile
├── main.rb
└── src
    ├── lexer.rb
    ├── parser.rb
    ├── token.rb
    └── util.rb

1 directory, 6 files
```

1. Setting the class up  
Perfect. Now, open the `parser.rb` file and add the following basic content to it:
```ruby
class Parser
  attr_accessor :tokens, :ip

  def initialize(tokens, offset)
    @tokens = tokens
    @ip = offset
  end

  def self.parse!(tokens, is_root: false, offset: 0)
    parser = Parser.new(tokens, offset)
    parser.parse(is_root: is_root)
  end

  def parse(is_root: false, offset: 0)
    puts tokens
  end
end
```

Basically, the static `parse!` method creates a new instance of the `Parser` class and setups the default variables with default values. Those variables are:
- __*tokens*__: A container, or a list of all of the tokens that our `Parser` wiil parse, given by the `parse!` method call as a parameter.
- __*ip*__: Short for `instruction pointer`, not Internet Protocol. A pointer to the current element we are looking at in the __*tokens*__.

The `parse` and `parse!` methods have a couple of *optional* parameters called `is_root` and `offset`. 
- __*is_root*__: Dictates wether the parser should treat the current list of tokens parsed to it as the root of a JSON file/object.
- __*offset*__: Represents an offset from the start of the `tokens` parameter. Used to offset the `ip` in recursive calls during parsing.

In order to test that our parser successfully prints out all our tokens, we would need to modify our `main.rb` file:
```ruby
require_relative 'src/lexer'
require_relative 'src/parser'

class JRB
  def self.parse!(text)
    Parser.parse! Lexer.lex! text
  end
end

def main
  puts JRB.parse! '{"name":"John Doe", "false": true, "true": false, "value": null}'
end

main
```

Notice that we've added a new `require_relative` at the second line of the file, as well as a new `JRB` class. It will be used as a shorthand to lexing and parsing the text content provided for this tutorial's sake, but can also be used to add abstractions and/or configurations if needed.

Running our program now, we will get the same result as at the end of the previous section:
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

2. Parsing objects

Since we already have the basic framework, of walking an array of items, we can modify the `parse` method in our `parser.rb` a bit:
```ruby 
  def parse(is_root: false, offset: 0)
    @ip = offset
    token = current

    error! 'Expected root to be an object!' if is_root && token != JSON[:SYMBOLS][:LEFTBRACE]

    advance
    case token
    when JSON[:SYMBOLS][:LEFTBRACE] then parse_object
    else
      unwrap! token
    end
  end
```
It is fairly simple, we add an error check if the `is_root` check is activated - we error __unless__ the first of our tokens is a `LEFTBRACE` token (a `{`).
Then we advance to the next token, check if the token is a `LEFTBRACE` (a `{`), and if so - parse the following tokens as an object. Else, we return the current token's unwrapped value. 

Parsing the tokens as an object requires us to define a new `private` method called `parse_object`:

```ruby
  private

  def parse_object
    object = {}

    if current == JSON[:SYMBOLS][:RIGHTBRACE]
      advance
      return object
    end

    while current
      key = current

      unless key.is_a?(Token) && key.string_token?
        return object if key == JSON[:SYMBOLS][:RIGHTBRACE]

        error! "Expected a string key in object, got \"#{key}\" at #{ip}"
      end

      advance

      error! "Expected a colon separator character after key in object, got \"#{current}\"" unless current == JSON[:SYMBOLS][:COLON]

      advance
      value = parse(offset: @ip)

      object[key.value.tr('"', '')] = unwrap!(value)

      if current == JSON[:SYMBOLS][:RIGHTBRACE]
        advance
        return object
      elsif current != JSON[:SYMBOLS][:COMMA]
        return object unless current

        next if key.is_a?(Token) && current.string_token?

        error! "Expected a comma after a key-value pair in object, got an \"#{unwrap! current}\""
      end

      advance
    end

    error! "Expected end-of-object symbol #{JSON[:SYMBOLS][:RIGHTBRACE]}"
  end
```

Since JSON objects are the literal backbone of a JSON file, it only makes sense that we start parsing them first. 

#### This is confusing and I wanna go home
The author knows that this function looks *scary* when you first see it, but in reality it's not \*that\* hard to understand. 

If you are interested in what happends in this function and how does it work, expand the following section:

<details>
	<summary> 
        <h4>How does parsing objects work?</h4>
    </summary>
0.  We define a simple variable called `object`, consisting of, you guessed it, an empty object (Hash). 
If the next token is a closing brace ("}") - we return the empty object and exit the function.

1. We enter a loop, not dissimilar to the way the `Lexer` was moving through the characters of the text.

2. If the current token is __*NOT*__ a `String` JSON __key__ as it __*should*__ be, we raise an error stating that we expected an object key, but got something else and exit the program. Otherwise, we advance forward.

3. If the following token is __*NOT*__ a `separator` symbol (JSON uses a `colon`, e.g. `:` by default), we also raise a new error with the following message. Otherwise, we advance forward.

4.  Recursively, call on the `parse` function with an offset of the current `ip`. 
This allows us to parse n-times nested values of both similar and differend kinds, meaning that an array can consist of many nested sub-objects, simple values, or even objects with nested objects within themselves. 

As recursion is __very__ powerful, so it is tricky to learn and understand. If you would like to learn more on how recursion as a concept works, you can check out [this article](https://medium.com/intuition/how-to-use-recursion-to-draw-1eda4f47f307) on using recursion.

5. We store the `unwrap!`-ed value from the previous step into the object's `key` (from step 2.).
Unwrapping the value basicaly means that we get the underlying `Token` __raw__ value and store just it. This gets rid of the notion of `Token`s for when the parser returns the finalized JSON object, having it contain only raw values.

6. If the current token is a `RIGHTBRACE` - we advance one token forward and *return* the object we've accumulated thus far.

7. Else, if the current token is __*NOT*__ a `COMMA` (`,`):
  - 7.1 If the `current` token is __*NOT*__ `nil` - return the currently accumulated object.  
  - 7.2 Move forward to the next iteration of the loop (from step 1.) if the current token is a `Token` of type `string`.  
  - 7.3 Otherwise, we raise an error and exit the program.  

8. If we haven't exited the program or function by now, we advance one token forward and continue from step `1.`

9. After the loop has ended, if the symbol at the current `ip` is __*NOT*__ a `RIGHTBRACE` (e.g. `}`) - we raise an error, because we encountered an object that was not properly closed. 

---
</details>

The more eagle-eyed amongst the readers will notice that we never did define the `current`, `advance` and `unwrap!` methods for the `Parser` class. If you did not come up with your own implementation, here is the implementation the author wrote:

```ruby
  def current
    @tokens[@ip]
  end

  def advance
    @ip += 1
  end
  
  def unwrap!(value)
    return value.value if value.is_a?(Token)

    if value.is_a?(Array)
      advance
      value.map do |item|
        unwrap!(item)
      end
    end

    value
  end
```

After adding those methods, we can test our basic parser by running the `main.rb` file:
```console
$ ruby main.rb 
{"name"=>"\"John Doe\"", "false"=>true, "true"=>false, "value"=>nil}
```

<details>
	<summary>
		Trivia time
	</summary>
You might notice that <code>String</code> values are represented with <i>escaped</i> double quotes. 
How can you make them non-escaped?

In other words, how can you make the <code>value</code> of a <code>string</code> <code>Token</code> be represented like the key is?
Example:

```console
$ ruby main.rb 
{"name"=>"John Doe", "false"=>true, "true"=>false, "value"=>nil}
```

---
</details>

We have parsing of objects working now, horray! 🎉 🎉 🎉 

3. Setting up parsing 

The only thing left for us to do, in order to have a working parser is, of course, to be able to parse arrays. 

In order to do that, let's furst modify our `main` method:

```ruby
def main
  puts JRB.parse! '{"name":"John Doe", "false": true, "true": false, "value": null, "array": [1,2,3}'
end
```
> You may notice that we've basically just added a new property at the end of our object, called "array". This is plenty for basic testing.

If we run the `main.rb` file now, we get greeted by an interesting error message:
```console
$ ruby main.rb 
[ERROR]: Expected a comma after a key-value pair in object, got an "1"
```

This error shows up because our parser currently has absolutely *no* idea on how to parse arrays, therefore it tries treating them as objects. Arrays have a very different structure than objects, as they don't have key-value pairs and are instead a collection of comma-separated values.  

The parser gets confused, and thinks that the initial bracket of the array (`[`) is a key-value pair, thus expecting a comma (`,`) symbol after it, but instead it finds a number, thus - raising an error. In order to resolve this issue, we need to add a way of parsing arrays.

4. Parsing arrays

Adding the notion of parsing arrays would require us to add a new `when` clause in our `parse` method
```ruby 
    when JSON[:SYMBOLS][:LEFTBRACKET] then parse_array
```

therefore making our `parse` method looking like this:
```ruby
  def parse(is_root: false, offset: 0)
    @ip = offset
    token = current

    error! 'Expected root to be an object!' if is_root && token != JSON[:SYMBOLS][:LEFTBRACE]

    advance
    case token
    when JSON[:SYMBOLS][:LEFTBRACKET] then parse_array
    when JSON[:SYMBOLS][:LEFTBRACE] then parse_object
    else
      unwrap! token
    end
  end
```

Adding this line would require us to define a new `private` method called `parse_array`:
```ruby
  def parse_array
    array = []

    return array if current == JSON[:SYMBOLS][:RIGHTBRACKET]

    while current
      item = parse(offset: @ip)
      array << unwrap!(item)

      if current == JSON[:SYMBOLS][:RIGHTBRACKET]
        return array
      elsif current == JSON[:SYMBOLS][:RIGHTBRACE]
        error! 'Improperly closed array in object'
      elsif current != JSON[:SYMBOLS][:COMMA]
        error! "Expected a '#{JSON[:SYMBOLS][:COMMA]}' , got #{current}"
      else
        advance
      end
    end

    error! "Expected an end-of-array #{JSON[:SYMBOLS][:RIGHTBRACKET]}"
  end
```

If you understood the parsing of objects, you can skip the following.
This might look confusing, or even scary, so I'd suggest reading up on the following section:

<details>
	<summary> 
        <h4>Ok, cool, but what's actually happening?</h4>
    </summary>
While it <i>might</i> look complicated, the way this <code>parse_array</code> function works is pretty straightforward:

0. We define a simple variable called `array`, consisting of, you guessed it, an empty array. 
If the next token is a closing bracket (`]`) - we return the empty array and exit the function.

1. We enter a loop, not dissimilar to the way the `Lexer` was moving through the characters of the text.

2. Recursively, call on the `parse` function with an offset of the current `ip`. 
This allows us to parse n-times nested values of both similar and differend kinds, meaning that an array can consist of many nested sub-arrays, simple values, or even objects with arrays within themselves. 

3. Unwrap (extract) the value from the parsed item (`Token`) and add it to our `array` variable.

4. If the current token is a `RIGHTBRACKET`, we return the currently accumulated `array`.

5. Else, if the current token is __*NOT*__ a comma, we raise the apropriate error, whating that we didn't find the correct array items' separator.

6. Else, if the current token is a `RIGHTBRACE`, we can see that the parent object closes without closing the array, therefore we raise an error and exit the program.

7. Otherwise, we advance to the next token and loop back to step `1.`

8. If we haven't returned an array thus far - raise an error.
This is done because the array provided has not been closed.

---
</details>

Running our application, we can see the results:
```console
$ ruby main.rb 
[ERROR]: Improperly closed array in object
```

Womp-womp. 🙁  
We have an error in our JSON.  
Luckily, this error is very simple to fix, just closing the last item ("array") in the object that we pass to the parser
```ruby
def main
  puts JRB.parse! '{"name":"John Doe", "false": true, "true": false, "value": null, "array": [1,2,3]}'
end
```

will fix the issue. Re-running the program we can clearly see the results:

```console
$ ruby main.rb 
{"name"=>"\"John Doe\"", "false"=>true, "true"=>false, "value"=>nil, "array"=>[1, 2, 3]}
```

## Testing 
Let's test our application. This is done pretty simple, just by modifying input we pass to `JRB.parse!`.

Let's test our app with a more involved JSON example:

```ruby
def main
  value = JRB.parse! '
{
    "hello": "world",
    "items": [
        1,
        6.9,
        -1200000,
        "Hello World!",
        [
            1,
            2,
            3
        ],
        {
            "name": "John Doe",
            "false": true,
            "true": false,
            "value": null
        }
    ],
    "foo": {
        "data": {
            "weirdnum": -4.20e69
        },
        "asd": "ASD",
        "items": []
    }
}'

  puts value
  
  puts "A weird number value: #{value.dig('foo', 'data', 'weirdnum')}"
end
```

Running this example, we can see the follwowing output:

```ruby
$ ruby main.rb 
{"hello"=>"\"world\"", "items"=>[1, 6.9, -1200000, "\"Hello World!\"", [1, 2, 3], {"name"=>"\"John Doe\"", "false"=>true, "true"=>false, "value"=>nil}], "foo"=>{"data"=>{"weirdnum"=>-4.2e+69}, "asd"=>"\"ASD\"", "items"=>[]}}
A weird number value: -4.2e+69
```

This means that our involved example works as expected! 🥳

If you'd like to test all moving parts of the application properly, I would suggest using [rspec](https://rspec.info/) in order to write some unit tests that will prove the functionality of the lexer, parser and utilities.

You can find the project's tests (called `spec`s in RSpec) in the [spec folder](../spec). Notable files are the [parser spec](../spec/parser_spec.rb) and [lexer_spec](../spec/lexer_spec.rb).


## Conclusion
Creating a JSON parser is a fantastic project for software engineers at any level, whether you're a beginner, intermediate, advanced, or a seasoned professional. This project demands a good grasp of JSON, the web's data format, as well as an understanding of recursion and solid programming fundamentals.

I hope you enjoyed reading this! If you did so, please give a star to [the repo](https://github.com/Shannarra/json-rb/) and/or share with a friend who might be interested in learning how to build a project like that from scratch!

