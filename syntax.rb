
# classes in this module allow one to define BNF-like grammar directly in Ruby
# Author: Eric Mahurin
# license: free, but you are at your own risk if you use it

module Syntax

    # base class where common operators are defined
    class Base
        def |(other)
            Alteration.new(self,other)
        end
        def +(other)
            Sequence.new(self,other)
        end
        def *(multiplier)
            Repeat.new(self,multiplier)
        end
        def +@
            Positive.new(self)
        end
        def -@
            Negative.new(self)
        end
        def qualify(*args,&code)
            Qualify.new(self,*args,&code)
        end
    end

    # just passes the syntax through - needed for recursive syntax
    class Pass < Base
        def initialize(syntax=NULL)
            @syntax =
                if (syntax.kind_of?Base)
                    syntax
                else
                    Verbatim.new(syntax)
                end
        end
        def <<(syntax)
            initialize(syntax)
        end
        def ===(stream)
            @syntax===stream
        end
    end
    
    # generic code matches to the stream (first arg to the code)
    # [] operator allows additional arguments to be passed to the code
    class Code < Base
        def initialize(*args,&code)
            @args = args
            @code = code
        end
        def ===(stream,*args) # passing args here will bypass creating a new object
            (match = @code[stream,*(@args+args)]) ||
               stream.buffered || raise(Error.new(stream,"a semantic error"))
            match
        end
        def [](*args)
            self.class.new(*(@args+args),&@code)
        end
    end

    # qualify the match with some code that takes the match
    # [] operator allows additional arguments to be passed to the code
    class Qualify < Base
        def initialize(syntax=NULL,*args,&code)
            @syntax =
                if (syntax.kind_of?Base)
                    syntax
                else
                    Verbatim.new(syntax)
                end
            @args = args
            @code = code
        end
        def ===(stream,*args) # passing args here will bypass creating a new object
            (match = (@syntax===stream)) || (return match)
            (match = @code[match,*(@args+args)]) ||
               stream.buffered || raise(Error.new(stream,"a semantic qualification error"))
            match
        end
        def [](*args)
            self.class.new(@syntax,*(@args+args),&@code)
        end
    end

    # sequence of syntaxes
    class Sequence < Base
        def initialize(*syntaxes)
            @syntax = syntaxes.collect do |syntax|
                if (syntax.kind_of?Base)
                    syntax
                else
                    Verbatim.new(syntax)
                end
            end
        end
        def +(other)
            self.class.new(*(@syntax+[other])) # pull in multiple sequence items
        end
        def <<(other)
            @syntax << ((other.kind_of?Base)?other:Verbatim.new(other))
        end
        def ===(stream)
            matches = []
            @syntax.each do |syntax|
                match = (syntax===stream)
                if (!match)
                    matches=NIL
                    break
                end
                matches << match if match!=TRUE
            end
            matches
        end
    end

    # alternative syntaxes
    class Alteration < Base
        def initialize(*syntaxes)
            @syntax = syntaxes.collect do |syntax|
                if (syntax.kind_of?Base)
                    syntax
                else
                    Verbatim.new(syntax)
                end
            end
        end
        def |(other)
            self.class.new(*(@syntax+[other])) # pull in multiple alteration items
        end
        def <<(other)
            @syntax << ((other.kind_of?Base)?other:Verbatim.new(other))
        end
        def ===(stream)
            match = nil
            @syntax.detect do |syntax|
                match = stream.buffer { |stream| syntax===stream }
            end
            match || stream.buffered || raise(Error.new(stream,nil,"an alteration"))
            match
        end
        alias =~ ===
    end

    # repeating syntax
    class Repeat < Base
        def initialize(syntax,multiplier)
            @syntax =
                if (syntax.kind_of?Base)
                    syntax
                else
                    Verbatim.new(syntax)
                end
            @repeat =
                if (multiplier.kind_of?Proc)
                    multiplier
                else
                    lambda do |matches|
                        compare = (multiplier<=>(matches.length+1))
                        if (compare==0)
                            compare = (multiplier<=>matches.length)
                        end
                        compare
                    end
                end
        end
        def ===(stream)
            matches = []
            while ((compare=@repeat[matches])>=0)
                if (compare>0)
                    unless (match = (@syntax===stream))
                        return NIL
                    end
                else
                    unless (match = stream.buffer { |stream| @syntax===stream })
                        break
                    end
                end
                matches << match
            end
            # filter out simple TRUE elements
            matches = matches.find_all { |match| match!=TRUE }
            matches
        end
    end
    
    # positive syntactic predicate
    class Positive < Base
        def initialize(syntax)
            @syntax =
                if (syntax.kind_of?Base)
                    syntax
                else
                    Verbatim.new(syntax)
                end
        end
        def ===(stream)
            stream.buffer { |stream| match = (@syntax===stream); FALSE }
            if (match)
                TRUE
            else
                stream.buffered || raise(Error.new(stream,nil,"a positive syntatic predicate"))
                FALSE
            end
        end
    end

    # negative syntactic predicate
    class Negative < Positive
        def ===(stream)
            stream.buffer { |stream| match = (@syntax===stream); FALSE }
            if (!match)
                TRUE
            else
                stream.buffered || raise(Error.new(stream,nil,"a negative syntatic predicate"))
                FALSE
            end
        end
    end

    # all atoms can also use ~ to invert what's matches

    # element match (uses === to match)
    class Atom < Base
        def initialize(pattern,length=NIL,invert=FALSE)
            @pattern = pattern
            @length = length
            @invert = invert
        end
        def ~@
            new(pattern,length,!invert)
        end
        def ===(stream)
            element = stream.get(@length)
            match = (@pattern===element)
            match = !match if (@invert)
            if (match==TRUE)
                element || TRUE
            else
                match || begin
                    stream.buffered || raise(Error.new(stream,element.inspect,@pattern.inspect))
                    FALSE
                end
            end
        end
    end
    
    # element set (uses include? to match)
    class Set < Atom
        def ===(stream)
            element = stream.get(@length)
            match = @pattern.include?(element)
            match = !match if (@invert)
            if (match==TRUE)
                element || TRUE
            else
                match || begin
                    stream.buffered || raise(Error.new(stream,element.inspect,"one of these: #{@pattern.to_s}"))
                    FALSE
                end
            end
        end
    end
    
    # element lookup array or hash (uses [] to match)
    # translation will occur if the lookup returns anything but TRUE
    class Lookup < Atom
        def =~(stream)
            element = stream.get(@length)
            match = @pattern[element]
            match = !match if (@invert)
            if (match==TRUE)
                element || TRUE
            else
                match || begin
                    stream.buffered || raise(Error.new(stream,element.inspect,"one of these: #{@pattern.keys.to_s}"))
                    FALSE
                end
            end
        end
    end
    
    # element sequence that knows its length
    class Verbatim < Atom
        def initialize(pattern,invert=FALSE)
            @pattern = pattern
            @invert = invert
        end
        def ~@
            new(pattern,!invert)
        end
        def ===(stream)
            element = stream.get(@pattern.length)
            if (element)
                match = (@pattern===element)
                match = !match if (@invert)
            else
                match = FALSE
            end
            if (match==TRUE)
                element || TRUE
            else
                match || begin
                    stream.buffered || raise(Error.new(stream,element.inspect,@pattern.inspect))
                    FALSE
                end
            end
        end
    end

    # any element
    class Any < Atom
        def initialize(length=NIL,invert=FALSE)
            @length = length
            @invert = invert
        end
        def ~@ # create a never matching Atom
            new(length,!invert)
        end
        def ===(stream)
            element = stream.get(@length)
            !@invert && element
        end
    end
    ANY = Any.new
    

    # zero length constants
    FLUSH = Code.new { |stream| stream.flush; TRUE }
    FAIL = Code.new { FALSE }
    NULL = Code.new { TRUE }
    NULLS = Code.new { [] }
    EOF = Code.new { !(element = stream.get) }

    # exception class for handling syntax errors
    class Error < RuntimeError
        attr_accessor(:stream,:found,:expected)
        def initialize(stream=nil,found=nil,expected=nil)
            @stream = stream
            @found = found
            @expected = expected
        end
        def to_s
            err = [super]
            err << "found #{found.to_s}" if found
            err << "expected #{expected.to_s}" if expected
            err << stream.location.to_s if stream
            err * ", "
        end
    end

end


# class acts like an iterator over a string/array/etc
# except that using buffer allows one go back to a certain point
# another class could be designed to work on an IO/File
class RandomAccessStream
    def initialize(s,pos=0)
        @s = s
        @pos = pos
        @buffered = NIL
        self
    end
    def get(termination=NIL)
        if (@pos>=@s.length)
            # end of file/string/array
            element = NIL
        elsif (!termination)
            # read one character/element
            element = @s[@pos]
            @pos += 1
        else
            # read a sub-string/sub-array
            pos1 = (termination.kind_of?(Integer)) ? @pos+termination :
                   (t = @s.index(termination,@pos)) ? t+termination.length :
                                              @s.length
            element = @s[@pos...pos1]
            @pos = pos1
        end
        element
    end
    def buffer(&code)
        old_buffered = @buffered
        @buffered = @pos if (!@buffered || @pos<@buffered)
        pos = @pos
        match = NIL
        match = code[self]
        if (@buffered && @buffered<=pos)
            @buffered = old_buffered
        elsif (!match)
            raise(IndexError,"need to rewind buffer, but it was flushed")
        end
        @pos = pos if !match
        match
    end
    def flush
        @buffered = NIL
    end
    def buffered
        @buffered ? TRUE : FALSE
    end
    def location
        "index #{@pos} in #{@s.inspect}"
    end
end


# put stuff in String to have Syntax objects magically appear
class String
    def |(other)
        Syntax::Verbatim.new(self)|other
    end
    def +@
        +Syntax::Verbatim.new(self)
    end
    def -@
        -Syntax::Verbatim.new(self)
    end
    alias _repeat *
    def *(other)
        if (other.kind_of?Numeric)
            _repeat(other)
        else
            Syntax::Verbatim.new(self)*other
        end
    end
    alias _concat +
    def +(other)
        if (other.kind_of?String)
            _concat(other)
        else
            Syntax::Verbatim.new(self)+other
        end
    end
    def ===(other)
        if (other.kind_of?String)
            self==other
        else
            Syntax::Verbatim.new(self)===other
        end
    end
    def qualify(&code)
        Syntax::Verbatim.new(self).qualify(&code)
    end
end

# allow an Array to look more like a Hash with keys and values
class Array
    def keys
        (0...length).find_all { |i| self[i] }
    end
    def values
        find_all { | element | element }
    end
end

# make things fully comparable to Ranges
# also * makes a Syntax
class Range
    include Comparable
    def <=>(other)
        if (other<self.begin)
            +1
        elsif (if exclude_end? then other>=self.end else other>self.end end)
            -1
        else
            0
        end
    end
    alias _old_equal ==
    def ==(other)
        if (other.kind_of?Range)
            # undocumented previous functionality
            _old_equal(other)
        else
            (self<=>other)==0
        end
    end
    def *(other)
        Syntax::Atom.new(self,1)*other
    end
end




