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
macros locals fry strings ;

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

GENERIC# transform 1 ( shape quot -- shape )
M: point transform
     call( x -- y ) ; inline

M: points transform
     '[ _ map ] restruct ; inline

M: scene transform
     '[ _ map ] restruct ; inline

M: colored transform 
     '[ _ dip ] restruct ; inline

M: line transform
     '[ _ bi@ ] restruct ; inline

! circle

: slide ( obj vector -- obj )
     '[ _ v+ vec>point ] transform ; inline

: skew ( obj vector -- obj )
     '[ _ v* vec>point ] transform ; inline

: scale ( obj scalar -- obj )
     dup 2array skew ;

! moves point as if center were the origin, then moves the point back
:: rotate-point ( point center radian -- point )
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
    x y <point>  ; inline

: rotate ( obj center radian -- obj )
     '[ _ _ rotate-point ] transform ; inline

: flip-horizontal ( obj -- obj )
     { -1 1 } scale ; inline

: flip-vertical ( obj -- obj )
     { 1 -1 } scale ; inline

! ****************
! Window Parameters

! this method is better than globals if for no other reason than 
! you can print out all the current settings

TUPLE: window
{ size pair initial: { 300 300 } }
{ center pair initial: { 300 300 } }
zoom
{ background rgba }
{ title string } ;

: default-window ( -- window )
    window new
    { 300 300 } >>size
    { 150 150 } >>center
    1.0 >>zoom
    COLOR: black  >>background 
    "SGraphics 2D" >>title ;

! window variable
SYMBOL: win
win [ default-window ] initialize

TUPLE: sg-gadget < gadget ;

M: sg-gadget pref-dim* ( gadget -- )
  drop win get size>> ;

<PRIVATE

! ****************
! Coordinates System

GENERIC: >winpoint ( x -- y )

! might want to change this to a generic later
M: point >winpoint ( cartesian-point -- window-coordinate )
    [ neg ] restruct
    win get zoom>> dup 2array scale
    win get center>> slide ;

! ****************
! OpenGL Backend 

GENERIC: gl-compile ( obj -- quot )

: compile-color ( color -- quot )
  [ <rgba> ] undo '[ _ _ _ _ glColor4f ] ;

M: colored gl-compile ( colored-obj -- quot )
  [ <colored> ] undo swap
  [ compile-color ]
  [ gl-compile ] bi*
 '[ GL_CURRENT_BIT glPushAttrib
    @ @
    glPopAttrib ] ; inline

M: point gl-compile ( point -- quot )
   >winpoint [ <point> ] undo '[ _ _ glVertex2f ] ; inline

: compile-points ( points-seq -- quot )
  [ gl-compile ] map concat ; inline

M: points gl-compile ( point-seq -- quot )
  points-seq>> compile-points '[ GL_POINTS _ do-state ] ; inline

M: line gl-compile ( line -- quot )
  [ <line> ] undo 2array compile-points '[ GL_LINES _ do-state ] ; inline

M: polyline gl-compile ( polyline -- quot )
  points-seq>> compile-points '[ GL_LINE_STRIP _ do-state ] ; inline

M: polygon gl-compile ( polygon -- quot )
  points-seq>> compile-points '[ GL_POLYGON _ do-state ] ; inline

M: polygon-outline gl-compile ( polygon-outline -- quot )
  points-seq>> compile-points '[ GL_LINE_LOOP _ do-state ] ; inline

! should probably make circle "precision" either accessable to programmer
! or vary due to size of cirlce -- whichever is simpler
M:: circle gl-compile ( circle -- quot )
    circle [ <circle> ] undo :> ( c r )
    c { r 0 } slide
    '[ 12 * deg>rad _ c rot rotate ] 30 swap map compile-points
    '[ GL_POLYGON _ do-state ] ; inline

! need to change merge for this
! -- scene should be immediately flattened 
M: scene gl-compile ( scene -- quot )
     [ <scene> ] undo [ gl-compile ] { } map-as ; inline

: link ( compiled-seq -- quot )
  '[ drop
    GL_PROJECTION glMatrixMode
    glLoadIdentity
    0 win get size>> [ first ] [ second ] bi 0 0 1 glOrtho
    GL_MODELVIEW glMatrixMode
    glLoadIdentity
    GL_DEPTH_TEST glDisable
    win get background>> [ <rgba> ] undo glClearColor 
    GL_COLOR_BUFFER_BIT glClear
     _ [ call( -- ) ] each
  ] ; inline

! ***************
! Renderer

: render ( scene -- )
     gl-compile link
    '[ sg-gadget \ draw-gadget* create-method
       _ define
    ]  with-compilation-unit
    [ sg-gadget new win get title>> open-window ] with-ui ; inline

: flatten-scene ( scene -- vector )
  [ [ dup scene?
    [ flatten-scene objs>> ]
    [ 1vector ] if  ] map concat
  ] restruct ; inline recursive

: flatten-colored ( colored -- vector )
    [ [ dup scene?
        [ flatten-scene ]
        [ 1vector <scene> ] if
    ] dip
    ] restruct 1vector ;

PRIVATE>

! **********************
! Top Level User Drawing Method

: draw-in ( obj window -- )
     win [
          { { [ dup colored? ] [ flatten-colored ] }
            { [ dup scene? ] [ flatten-scene ] }
            [ 1vector <scene> ]
          } cond 
          render
     ] with-variable ;

: draw ( obj -- )
    default-window draw-in ;

! make sure color compiles
: demo ( -- )
     100 100 <point> 0 0 <point> <line> COLOR: green <colored>
     draw ;

MAIN: demo

