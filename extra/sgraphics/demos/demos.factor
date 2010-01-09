USING: arrays sequences kernel math math.constants
sgraphics sgraphics.syntax sgraphics.shapes colors colors.constants fry random grouping ;
IN: sgraphics.demos

: polygon1 ( -- polygon )
    polygon{ -70 -20
             -50 0
             -30 26
             0 40
             80 150 } ;

: twins ( -- scene )
    polygon1 dup { 50 -70 } slide merge ;

: twins2 ( -- scene )
    twins 0 0 <point> pi rotate ;

: twins-small ( -- scene )
    twins { 0.25 0.25 } skew ;

: twins-big ( -- scene )
    twins { 1.5 1.5 } skew ;

: twins-stretched ( -- scene )
    twins { 1.0 3 } skew ;

: twins-flip ( -- scene )
    twins flip-vertical ;

: pinwheel ( -- scene )
  4 polygon{ 50 50
           0 0
           50 0
  } [ drop 0 0 <point> pi 2 / rotate ] accumulate nip
  <scene> ; foldable

: pinwheels ( -- scene )
  { -100 100 
    -100 -100 
    100 100 
    100 -100
    0 0 
  } 2 group
  [  pinwheel swap slide ] map
  <scene> ; foldable

: cross ( -- scene )
     polygon{ -150 -20
              -150 20
              150 20
              150 -20
     } dup 0 0 <point> pi 2 / rotate merge ;

: cross2 ( -- scene )
     cross 
     dup 0 0 <point> pi 4 / rotate
     merge ;
 
: bullseye ( n -- scene )
  [ [ 0 2array
      0 0 <point> 5 <circle>
      swap skew ]
    [ 3 mod 
      { "red"
        "green"
        "yellow" } [ named-color ] map nth
    ] bi <colored>
  ] map <reversed> <scene> ;

: fade ( n -- scene )
  dup 
  '[ [ 0 2array 
       0 0 <point> 5 <circle>
       swap skew ]
     [ _ 1 / >float * 0 swap 0 0.3 <rgba>
    ] bi <colored>
  ] map <scene> ;

: composite ( -- scene )
  10 bullseye 4 scale { -100 100 } slide
  8 fade 2 scale
  pinwheel { 80 -80 } slide
  3array <scene> ;

             
