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

! I will make this more efficient later
: merge ( x y -- scene ) 
     2array <scene> ;

! **************
! Utilities

! is this worth having its own vocabulary? 
: restruct ( x quot -- y )
    [ tuple>array unclip swap ] dip with-datastack
    swap prefix >tuple ; inline

! a tuple walker
: remap ( obj quot -- y )
     [ tuple>array unclip swap ] dip map
     swap prefix >tuple ; inline

: remapconcat ( obj quot -- y )
     [ tuple>array unclip swap ] dip map concat
     swap prefix >tuple ; inline

! assumes leaves are all the same
! this could be improved
! generalized to handle sequences too
:: twalk ( obj pred quot -- obj )
     { { [ obj pred call( x -- y ) ]
         [ obj quot call( x -- y ) ] }
       { [ obj tuple? ]
         [ obj [ pred quot twalk ] remap ] }
       { [ obj { [ number? not ] [ sequence? ]  } 1&& ]
         [ obj [ pred quot twalk ] map ]
       }
       [ obj ] 
     } cond ; inline recursive

: slope ( line -- float )
  [ <line> ] undo [ point>vec ] bi@ math.points:slope ;

! ************
! Manipulation

! I think this can be changed to compile time macro

! transform is a tree walker --
! it walks down the scene object, transforming leaf nodes (aka points),
! leaving the rest of the structure intact

! this transform you have written is incorrect.  Need to rethink this
! approach.  Everything else is fine though
! need to write tuple walker, takes point quotation to apply to leaves

! this strategy doens't work directly for current circle implemen.

: transform ( shape quot -- shape )
     [ point? ] swap twalk ;

! circle

: slide ( obj vector -- obj )
     '[ _ v+ vec>point ] transform ; inline

: skew ( obj vector -- obj )
      '[ _ v* vec>point ] transform ; inline

: scale ( obj scalar -- obj )
     dup 2array skew ;
 
:: rotate-point ( point center radian -- point )
     #! moves point as if center were the origin, then moves the point back
     #! could be a lot simpler
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
     x y <point> ; inline

: rotate ( obj center radian -- obj )
    '[ _ _ rotate-point ] transform ; inline

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

! need to change merge for this
! -- scene should be immediately flattened 
! M: scene gl-compile ( scene -- quot )
!  [ <scene> ] undo [ gl-compile ] [ ] map-as ; inline

! need to change merge for this
! -- scene should be immediately flattened 
M: scene gl-compile ( scene -- quot )
     [ <scene> ] undo [ gl-compile ] [ ] map-as ; inline

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

