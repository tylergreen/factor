USING: sgraphics accessors arrays colors compiler.units fry generic
inverse kernel locals math math.trig namespaces
opengl.demo-support opengl.gl sequences sgraphics ui ui.gadgets
ui.render vectors words ;
IN: sgraphic.q-backend

! compile sgraphics language to one big factor quotation
! that draws the scene when called

! ****************
! Coordinates System

GENERIC: >winpoint ( x -- y )

! might want to change this to a generic later
M: point >winpoint ( cartesian-point -- window-coordinate )
    [ neg ] restruct
    win get zoom>> dup 2array scale
    win get center>> slide ;

! *********************
! OpenGL Back End

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

M: scene gl-compile ( scene -- quot )
  [ <scene> ] undo [ gl-compile ] [ ] map-as concat ; inline

: flatten-scene ( scene -- scene )
  [ [ dup scene?
    [ flatten-scene objs>> ]
    [ 1vector ] if  ] map concat
  ] restruct ; inline recursive

TUPLE: sg-gadget < gadget ;

M: sg-gadget pref-dim* ( gadget -- )
  drop win get [ width>> ] [ height>> ] bi 2array ;

: link ( quot -- quot )
  [ drop
    GL_PROJECTION glMatrixMode
    glLoadIdentity
    0 win get [ width>> ] [ height>> ] bi 0 0 1 glOrtho
    GL_MODELVIEW glMatrixMode
    glLoadIdentity
    GL_DEPTH_TEST glDisable
    win get background>> [ <rgba> ] undo glClearColor 
    GL_COLOR_BUFFER_BIT glClear
  ] prepose ; inline

: render ( scene -- )
    gl-compile link
    '[ sg-gadget \ draw-gadget* create-method
       _ define
    ]  with-compilation-unit
    [ sg-gadget new win get title>> open-window ] with-ui ; inline


