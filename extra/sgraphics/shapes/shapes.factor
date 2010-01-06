USING: accessors arrays fry inverse kernel locals math
math.points math.vectors sequences sgraphics sgraphics.syntax ;
IN: sgraphics.shapes

TUPLE: rectangle < polygon ;

TUPLE: square < rectangle ;

: <unit-square> ( -- polygon )
    polygon{ -1 -1 
             -1  1
              1  1
              1 -1 } ;

: <rectangle> ( height width -- polygon )
    [ 2.0 / ] bi@ 2array <unit-square> swap skew ; inline

: <square> ( side -- polygon )
    dup <rectangle> ;

: center ( rectangle -- point )
    points-seq>>  [ first ] [ third ] bi midpoint vec>point ;

: size ( square -- point )
    points-seq>> [ first ] [ second ] bi distance ;

! *******
! Lines 
: bisect ( line -- half1 half2 )
  [ <line> ] undo 2dup midpoint vec>point '[ _ <line> ] bi@ ;

: line-len ( line -- length )
  [ <line> ] undo distance ;

! ****************
! Regular Polygons

: <ngon> ( n -- polygon )
    ;

: apothem ( regular-polygon -- line )
#! The apothem of a regular polygon is a line segment from the center to the midpoint of one of its sides.
    ;




