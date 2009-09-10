! Copyright (C) 2004, 2009 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien arrays byte-arrays byte-vectors definitions generic
hashtables kernel math namespaces parser lexer sequences strings
strings.parser sbufs vectors words words.symbol words.constant
words.alias quotations io assocs splitting classes.tuple 
generic.standard generic.hook generic.math generic.parser classes
io.pathnames vocabs vocabs.parser classes.parser classes.union
classes.intersection classes.mixin classes.predicate
classes.singleton classes.tuple.parser compiler.units
combinators effects.parser slots ;
IN: bootstrap.syntax

! These words are defined as a top-level form, instead of with
! defining parsing words, because during stage1 bootstrap, the
! "syntax" vocabulary is copied from the host. When stage1
! bootstrap completes, the host's syntax vocabulary is deleted
! from the target, then this top-level form creates the
! target's "syntax" vocabulary as one of the first things done
! in stage2.

: define-delimiter ( name -- )
    "syntax" lookup t "delimiter" set-word-prop ;

: define-core-syntax ( name quot -- )
    [ dup "syntax" lookup [ ] [ no-word-error ] ?if ] dip
    define-syntax ;

: 2group ( seq -- array )
  [ dup length 2 >= ] [ 2 cut swap ] produce
  swap append ;

[
    { "]" "}" ";" ">>" } [ define-delimiter ] each

    { 
        "PRIMITIVE:" [ "Primitive definition is not supported" throw ] 
        
        "CS{" [ "Call stack literals are not supported" throw ] 
        
        "!" [ lexer get next-line ] 
        
        "#!" [ POSTPONE: ! ] 
               
        "IN:" [ scan set-current-vocab ] 
               
        "<PRIVATE" [ begin-private ] 
               
        "PRIVATE>" [ end-private ] 
               
        "USE:" [ scan use-vocab ] 
               
        "UNUSE:" [ scan unuse-vocab ] 
               
        "USING:" [ ";" parse-tokens [ use-vocab ] each ] 
               
        "QUALIFIED:" [ scan dup add-qualified ] 
               
        "QUALIFIED-WITH:" [ scan scan add-qualified ] 
               
        "FROM:" [ scan "=>" expect ";" parse-tokens add-words-from ] 
               
        "EXCLUDE:" [ scan "=>" expect ";" parse-tokens add-words-excluding ] 
               
        "RENAME:" [ scan scan "=>" expect scan add-renamed-word ] 
               
        "HEX:" [ 16 parse-base ] 
        "OCT:" [ 8 parse-base ] 
        "BIN:" [ 2 parse-base ] 
               
        "CHAR:" [ scan
                  { { [ dup length 1 = ] [ first ] }
                    { [ "\\" ?head ] [ next-escape >string "" assert= ] }
                      [ name>char-hook get call( name -- char ) ]
                   } cond parsed ] 
               
         "\"" [ parse-string parsed ] 
               
         "SBUF\"" [ lexer get skip-blank parse-string >sbuf parsed ] 
               
         "P\"" [ lexer get skip-blank parse-string <pathname> parsed ]

         "[" [ parse-quotation parsed ]
         "{" [ \ } [ >array ] parse-literal ]
         "2{" [ \ } [ >array 2group ] parse-literal ]
!         "3{" [ \ } [ >array 3 group* ] parse-literal ]
!         "4{" [ \ } [ >array 4 group* ] parse-literal ]
         "V{" [ \ } [ >vector ] parse-literal ] 
         "B{" [ \ } [ >byte-array ] parse-literal ] 
         "BV{" [ \ } [ >byte-vector ] parse-literal ] 
         "H{" [ \ } [ >hashtable ] parse-literal ] 
         "T{" [ parse-tuple-literal parsed ] 
         "W{" [ \ } [ first <wrapper> ] parse-literal ] 
               
         "POSTPONE:" [ scan-word parsed ] 
         "\\" [ scan-word <wrapper> parsed ] 
         "M\\" [ scan-word scan-word method <wrapper> parsed ] 
         "inline" [ word make-inline ] 
         "recursive" [ word make-recursive ] 
         "foldable" [ word make-foldable ] 
         "flushable" [ word make-flushable ] 
         "delimiter" [ word t "delimiter" set-word-prop ] 
         "deprecated" [ word make-deprecated ] 
               
         "SYNTAX:" [ CREATE-WORD parse-definition define-syntax ] 

         "SYMBOL:" [ CREATE-WORD define-symbol ] 
               
         "SYMBOLS:" [ ";" parse-tokens [ create-in dup reset-generic define-symbol ] each ]
               
        "SINGLETONS:" [ ";" parse-tokens  [ create-class-in define-singleton-class ] each ]

        "DEFER:" [ scan current-vocab create
                   [ fake-definition ] [ set-word ] [ [ undefined ] define ] tri ] 
               
        "ALIAS:" [ CREATE-WORD scan-word define-alias ] 
               
        "CONSTANT:" [ CREATE-WORD scan-object define-constant ] 
               
        ":" [ (:) define-declared ]

        "GENERIC:" [ [ simple-combination ] (GENERIC:) ]
               
        "GENERIC#" [ [ scan-word <standard-combination> ] (GENERIC:) ] 
               
        "MATH:" [ [ math-combination ] (GENERIC:) ] 
               
        "HOOK:" [ [ scan-word <hook-combination> ] (GENERIC:) ] 
               
        "M:" [ (M:) define ]
               
        "UNION:" [ CREATE-CLASS parse-definition define-union-class ]

        "INTERSECTION:" [ CREATE-CLASS parse-definition define-intersection-class ]
               
        "MIXIN:" [ CREATE-CLASS define-mixin-class ]
               
        "INSTANCE:" [ location
                      [ scan-word scan-word 2dup add-mixin-instance <mixin-instance> ] dip                                                          remember-definition ]

        "PREDICATE:" [ CREATE-CLASS
                       scan "<" assert=
                       scan-word
                       parse-definition define-predicate-class ]

        "SINGLETON:" [ CREATE-CLASS define-singleton-class ] 
               
        "TUPLE:" [ parse-tuple-definition define-tuple-class ] 
               
        "SLOT:" [ scan define-protocol-slot ] 
               
        "C:" [ CREATE-WORD scan-word define-boa-word ]
               
        "ERROR:" [ parse-tuple-definition
                   pick save-location
                   define-error-class ]

        "FORGET:" [ scan-object forget ] 
               
        "(" [ ")" parse-effect drop ]
               
        "((" [ "))" parse-effect parsed ] 
               
        "MAIN:" [ scan-word current-vocab (>>main) ] 
               
        "<<" [ [ \ >> parse-until >quotation ] with-nested-compilation-unit call( -- ) ]
               
        "call-next-method" [ current-method get
                             [ literalize parsed \ (call-next-method) parsed ]
                             [ not-in-a-method-error ] if* ]
               
        "call(" [ \ call-effect parse-call( ] 
               
        "execute(" [ \ execute-effect parse-call( ] 

        "f" [ f parsed ]
               
    } 2group [ define-core-syntax ] assoc-each
        
    "t" "syntax" lookup define-singleton-class
        
    "initial:" "syntax" lookup define-symbol

    "read-only" "syntax" lookup define-symbol
        
] with-compilation-unit
