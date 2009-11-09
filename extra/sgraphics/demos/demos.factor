USING: arrays sequences kernel math math.constants
sgraphics sgraphics.syntax sgraphics.shapes colors colors.constants fry random ;
IN: sgraphics.demos

: pinwheel ( -- scene )
  4 polygon{ 50 50
           0 0
           50 0
  } [ drop 0 0 <point> pi 2 / rotate ] accumulate nip
  <scene> ; inline
 
: bullseye ( n -- scene )
  [ [ 0 2array
      0 0 <point> 5 <circle>
      swap scale ]
    [ 3 mod 
      { "red"
        "green"
        "yellow" } [ named-color ] map nth 
    ] bi <colored>
  ] map reverse <scene> ;

: fade ( n -- scene )
  dup 
  '[ [ 0 2array 
       0 0 <point> 5 <circle>
       swap scale ]
     [ _ 1 / >float * 0 swap 0 0.3 <rgba>
    ] bi <colored>
  ] map <scene> ;

: composite ( -- scene )
  10 bullseye { 0.5 0.5 } scale { -100 100 } slide
  8 fade { 0.4 0.4 } scale
  pinwheel { 80 -80 } slide
  3array <scene> ;

: twins ( -- scene )
     polygon{ 5 5
              100 5
              100 100
              5 100
     } dup { -1 -1 } scale merge ;

: point>square ( point -- square )
     dup
     { 0 5 } 
     { 5 5 } 
     { 5 0 } [ slide ] tri-curry@ tri
     4array <polygon> ;

: carpet ( n -- scene )
     dup '[ _ [ 2array ] with map ] map
     concat [ vec>point { 30 30 } scale point>square ] map <scene>
     dup 0 0 <point> pi rotate
     { -10 -10 } slide
     merge ;

: cross ( -- scene )
     polygon{ -150 -20
              -150 20
              150 20
              150 -20
     } dup 0 0 <point> pi 2 / rotate merge ;

: cross2 ( -- scene )
     cross dup 0 0 <point> pi 4 / rotate merge ;
              
