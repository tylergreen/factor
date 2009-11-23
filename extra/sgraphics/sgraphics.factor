USING: inverse
math math.functions math.trig math.vectors math.constants
opengl opengl.gl opengl.glu opengl.demo-support
ui ui.gadgets ui.render
parser grouping assocs
compiler.units words generic accessors
arrays kernel combinators namespaces sequences lists lists.lazy vectors
words.constant classes.tuple
colors colors.constants
quotations continuations
macros locals fry utils ;
QUALIFIED: math.points
IN: sgraphics

TUPLE: point x y  ;
C: <point> point

: vec>point ( 2array -- point ) [ 2array ] undo point boa ; inline
: point>vec ( point -- 2array ) [ <point> ] undo 2array ; inline

INSTANCE: point sequence
M: point length ( point -- n ) drop 2 ; inline
M: point nth ( n point -- elt ) [ <point> ] undo 2array nth ; inline

TUPLE: points { points-seq array } ;
C: <points> points

TUPLE: line { p1 point } { p2 point } ;
C: <line> line

TUPLE: polyline < points ;
C: <polyline> polyline

TUPLE: circle { center point } radius ;
C: <circle> circle

TUPLE: polygon < points ;
C: <polygon> polygon

TUPLE: polygon-outline < points ;
C: <polygon-outline> polygon-outline

TUPLE: colored obj color ;
C: <colored> colored

TUPLE: scene { objs vector } ;
: <scene> ( array -- scene )  >vector scene boa ;

! I will make this more efficient later
: merge ( x y -- scene ) 
     2array <scene> ;

! **************
! Utilities

! is this worth having its own vocabulary? 
: restruct ( x quot -- y )
    [ tuple>array unclip swap ] dip with-datastack
    swap prefix >tuple ; inline

: slope ( line -- float )
  [ <line> ] undo [ point>vec ] bi@ math.points:slope ;

! ************
! Manipulation

GENERIC# slide 1 ( obj vector -- obj )

M: point slide ( point 2array -- point )
  v+ vec>point ; inline

M: points slide ( points 2array -- points )
   '[ [ _ slide ] map ] restruct ; inline

M: scene slide ( scene 2array -- scene )
  '[ [ _ slide ] map ] restruct ; inline

M: colored slide ( colored 2array -- colored )
  '[ [ _ slide ] dip ] restruct ; inline

M: circle slide ( circle 2array -- circle )
  '[ [ _ slide ] dip ] restruct ; inline

M: line slide ( line 2array -- line )
  '[ [ _ slide ] bi@ ] restruct ; inline

GENERIC# scale 1 ( shape vector -- shape )

M: point scale ( point pair -- point )
  v* vec>point ;

M: scene scale ( scene v -- scene )
  '[ [ _ scale ] map ] restruct ;

M: points scale ( points v -- points )
  '[ [ _ scale ] map ] restruct ;

M: line scale ( line v -- line )
  '[ [ _ scale ] bi@ ] restruct ;
 
M: circle scale ( circle v -- circle )
     dup '[ [ _ scale ] [ _ first * ] bi* ] restruct ;

M: colored scale ( colored n -- colored )
     '[ [ _ scale ] dip ] restruct ;

GENERIC# rotate 2 ( obj center radian -- obj )

! moves point as if center were the origin, then moves the point back
M:: point rotate ( point center radian -- point )
    radian sin :> s 
    radian cos :> c
    center x>> :> xc 
    center y>> :> yc 
    point x>> xc - :> x1 
    point y>> yc - :> y1 
    x1 c * y1 s * + :> x2
    y1 c * x1 s * - :> y2 
    x2 xc + :> x
    y2 yc + :> y 
    x y <point>  ;

M: points rotate ( points center radian -- point )
  '[ [ _ _ rotate ] map ] restruct ;
  
M: line rotate ( line center radian -- line )
  '[ [ _ _ rotate ] bi@ ] restruct ;

M: colored rotate ( colored center radian -- colored )
  '[ [ _ _ rotate ] dip ] restruct ;

M: scene rotate ( scene center radian -- scene )
  '[ [ _ _ rotate ] map ] restruct ; inline

M: circle rotate ( center radian circle -- circle ) 2drop ; inline

: flip-horizontal ( obj -- obj )
     { -1 1 } scale ;

: flip-vertical ( obj -- obj )
     { 1 -1 } scale ;

! ****************
! Window Parameters

! this method is better than globals if for no other reason than 
! you can print out all the current settings
TUPLE: window width height background title center zoom ;

: default-window ( -- window )
    window new
    300 >>width 
    300 >>height 
    COLOR: black  >>background 
    "SGraphics 2D" >>title 
    dup [ width>> ] [ height>> ] bi 2array [ 2.0 / ] map >>center
    1 >>zoom ;

SYMBOL: win
win [ default-window ] initialize

! **********************
! Top Level User Drawing Method

: draw-in ( obj window -- )
     win set-global 
     dup scene?
     [ flatten-scene ]
     [ 1array <scene> ] if
     render ;

: draw ( obj -- )
     default-window draw-in ;

: demo ( -- ) 100 100 <point> 0 0 <point> <line> COLOR: green <colored> draw ;

MAIN: demo
