USING: inverse
math math.functions math.trig math.vectors math.constants
opengl opengl.gl opengl.glu opengl.demo-support
ui ui.gadgets ui.render
parser grouping assocs
compiler.units words generic accessors
arrays kernel combinators combinators.short-circuit namespaces sequences lists lists.lazy vectors
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

: merge ( x y -- scene ) 
     2array <scene> ;

! **************
! Utilities

MACRO: requot ( quot -- )
     '[ [ tuple>array unclip swap ] dip @
        swap prefix >tuple ] ; 

: restruct ( tuple quot -- tuple )
     [ with-datastack ] requot ; inline

: remap ( tuple quot -- tuple )
     [ map ] requot ; inline

: remapconcat ( tuple -- tuple )
     [ map concat ] requot ; inline

: slope ( line -- float )
  [ <line> ] undo [ point>vec ] bi@ math.points:slope ;

! ************
! Manipulation

GENERIC# slide 1 ( obj vector -- obj )

M: point slide ( point 2array -- point )
  v+ vec>point ; inline

M: points slide ( points 2array -- points )
   '[ [ _ slide ] map ] restruct ;

M: scene slide ( scene 2array -- scene )
  '[ [ _ slide ] map ] restruct ; inline

M: colored slide ( colored 2array -- colored )
  '[ [ _ slide ] dip ] restruct ; inline

M: circle slide ( circle 2array -- circle )
  '[ [ _ slide ] dip ] restruct ; inline

M: line slide ( line 2array -- line )
  '[ [ _ slide ] bi@ ] restruct ; inline

! works but slides the image around unevenly depending on its position.
! need to normalize coordinates first, scale, then move back
GENERIC# skew 1 ( shape vector -- shape )

M: point skew ( point pair -- point )
  v* vec>point ;

M: scene skew ( scene v -- scene )
  '[ [ _ skew ] map ] restruct ;

M: points skew ( points v -- points )
  '[ [ _ skew ] map ] restruct ;

M: line skew ( line v -- line )
  '[ [ _ skew ] bi@ ] restruct ;
 
M: circle skew ( circle v -- circle )
    first '[ _ * ] restruct ;

M: colored skew ( colored n -- colored )
  '[ [ _ skew ] dip ] restruct ;

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

: scale ( obj scalar -- obj )
    dup 2array skew ; inline

: flip-horizontal ( obj -- obj )
     { -1 1 } skew ; inline

: flip-vertical ( obj -- obj )
     { 1 -1 } skew ; inline

! ****************
! Window Parameters

! this method is better than globals if for no other reason than 
! you can print out all the current settings

! support multiple way to specify windows


! square windows that are sgdim distance in real numbers around center
! example
! 

TUPLE: window
{ gldim pair initial: { 300 300 } }
{ center pair initial: { 300 300 } }
{ sgdim pair initial: { 10 10 } }
{ background rgba }
{ title string } ;

: default-window ( -- window )
    window new
    { 300 300 } >>gldim
    { 0 0 } >>center
    { 300 300 } >>sgdim
    COLOR: black  >>background 
    "SGraphics 2D" >>title ;

! window variable
SYMBOL: win
win [ default-window ] initialize

TUPLE: sg-gadget < gadget ;

M: sg-gadget pref-dim* ( gadget -- )
  drop win get gldim>> ;

<PRIVATE

! ****************
! Coordinates System

GENERIC: >winpoint ( x -- y )

! I don't understand this at all
! might want to change this to a generic later
! M: point >winpoint ( cartesian-point -- window-coordinate )
!      #! slide points up and right sgdim/2 distance for primitive window system
!     flip-vertical win get sgdim>> scale ;

: gl-center ( pair -- pair )
     0.5 swap n*v ;

! I don't understand this at all
! might want to change this to a generic later
M: point >winpoint ( cartesian-point -- window-coordinate )
     #! slide points up and right sgdim/2 distance for primitive window system
     flip-vertical 
     win get [ gldim>> ] [ sgdim>> ] bi v/ 0.5 swap n*v skew 
     win get gldim>> gl-center slide ;

! ****************
! OpenGL Backend 

GENERIC: gl-compile ( obj -- quot )

: compile-color ( color -- quot )
  [ <rgba> ] undo '[ _ _ _ _ glColor4f ] ;

M: colored gl-compile ( colored-obj -- quot )
  [ <colored> ] undo swap
  [ compile-color ] dip
  dup scene?
  [ gl-compile 
    '[ [ GL_CURRENT_BIT glPushAttrib ]
     _ @ 
     [ glPopAttrib ] ] concat
  ]
  [ gl-compile 
    '[ [ GL_CURRENT_BIT glPushAttrib ]
     _ _
     [ glPopAttrib ] ] concat
  ] if
  ; inline

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

M: scene gl-compile ( scene -- quot )
     objs>> [ gl-compile ] [ ] map-as ; inline

: link ( compiled-seq -- quot )
  '[ drop
    GL_PROJECTION glMatrixMode
    glLoadIdentity
    0 win get gldim>> [ first ] [ second ] bi 0 0 1 glOrtho
    GL_MODELVIEW glMatrixMode
    glLoadIdentity
    GL_DEPTH_TEST glDisable
    win get background>> [ <rgba> ] undo glClearColor 
    GL_COLOR_BUFFER_BIT glClear
     _ [ call( -- ) ] each
  ] ; inline

! ***************
! Renderer

DEFER: flatten-colored 

! this is ridiculous.  Colored scene ruin everything
! all wrong
: flatten-scene ( obj -- seq )
     { { [ dup scene? ]
         [ objs>> [ flatten-scene ] map concat ]  }
       { [ dup colored? ]
         [ flatten-colored ] }
       [ 1array ]
     } cond >vector ; inline recursive

: flatten-colored ( colored -- seq )
     dup obj>> scene?
     [ [ [ flatten-scene <scene> ] dip ] restruct
     ] when 1array ;

: render ( obj -- )
     flatten-scene <scene>
     gl-compile >array link
    '[ sg-gadget \ draw-gadget* create-method
       _ define
    ]  with-compilation-unit
    [ sg-gadget new win get title>> open-window ] with-ui ; inline

PRIVATE>

! **********************
! Top Level User Drawing Method

: draw-in ( obj window -- )
     win [ render ] with-variable ;
   
: draw ( obj -- )
    default-window draw-in ;

: green-line   ( -- line )
  100 100 <point> 0 0 <point> <line> COLOR: green <colored> ;

! make sure color compiles
: demo ( -- )
  green-line draw ;

MAIN: demo

