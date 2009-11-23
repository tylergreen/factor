USING: sgraphics ;
IN: sgraphics.ds-backend

! Compiles sgraphics language to an explicit data structure
! That is traversed during the drawing process

<PRIVATE

! treewalker
! walk over scene data structure instead of call quotations

TUPLE: gl-obj vertices type color ;
: <gl-obj> ( vs type -- obj ) f gl-obj boa ;

! would like to clean this up: hopefully get rid of gl-scene
TUPLE: gl-scene color objs ;
: <gl-scene> ( gl-objs -- gl-scene ) gl-scene new swap >>objs ; inline
  
! can make this so it only is done when needed
GENERIC: draw-gl ( obj -- )

M:: gl-scene draw-gl ( scene -- )
  scene color>> dup
  [ call( -- ) ]
  [ drop ] if
  scene objs>> [ draw-gl ] each ;

! won't compile with regular do-state
: my-do-state ( mode verts -- )
     swap glBegin call( -- ) glEnd ; inline

M:: gl-obj draw-gl ( gl-obj -- )
  GL_CURRENT_BIT glPushAttrib
  gl-obj color>> dup 
  [ call( -- ) ]
  [ drop ] if
  gl-obj type>>
  gl-obj vertices>> my-do-state
  glPopAttrib ; inline

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
  [ <colored> ] undo
  [ gl-compile ]
  [ compile-color ] bi* >>color ;

M: point gl-compile ( point -- quot )
  1array <points> gl-compile ; inline

: compile-points ( points-seq -- quot )
  [ >winpoint [ <point> ] undo '[ _ _ glVertex2f ]
  ] map concat ; inline

M: points gl-compile ( point-seq -- quot )
  points-seq>> compile-points GL_POINTS <gl-obj> ; inline

M: line gl-compile ( line -- quot )
  [ <line> ] undo 2array compile-points GL_LINES <gl-obj> ; inline

M: polyline gl-compile ( polyline -- quot )
  points-seq>> compile-points GL_LINE_STRIP <gl-obj> ; inline

M: polygon gl-compile ( polygon -- quot )
  points-seq>> compile-points GL_POLYGON <gl-obj> ; inline

M: polygon-outline gl-compile ( polygon-outline -- quot )
  points-seq>> compile-points GL_LINE_LOOP <gl-obj> ; inline

! should probably make circle "precision" either accessable to programmer
! or vary due to size of cirlce -- whichever is simpler
M:: circle gl-compile ( circle -- quot )
    circle [ <circle> ] undo :> ( c r )
    c { r 0 } slide
    '[ 12 * deg>rad _ c rot rotate ] 30 swap map compile-points
    '[ GL_POLYGON _ do-state ] ; inline

M: scene gl-compile ( scene -- gl-objs )
     objs>> [ gl-compile ] map <gl-scene> ;

: flatten-scene ( scene -- scene )
  [ [ dup scene?
    [ flatten-scene objs>> ]
    [ 1vector ] if  ] map concat
  ] restruct ; inline recursive

TUPLE: sg-gadget < gadget ;

M: sg-gadget pref-dim* ( gadget -- )
  drop win get [ width>> ] [ height>> ] bi 2array ;

: link ( scene-seq -- quot )
     '[ drop
        GL_PROJECTION glMatrixMode
        glLoadIdentity
        0 win get [ width>> ] [ height>> ] bi 0 0 1 glOrtho
        GL_MODELVIEW glMatrixMode
        glLoadIdentity
        GL_DEPTH_TEST glDisable
        win get background>> [ <rgba> ] undo glClearColor 
        GL_COLOR_BUFFER_BIT glClear
        _ draw-gl
     ] ; inline

: render ( scene -- )
     gl-compile link
    '[ sg-gadget \ draw-gadget* create-method
       _ define
    ]  with-compilation-unit
    [ sg-gadget new win get title>> open-window ] with-ui ; inline

: flatten-colored ( colored -- colored )
  [ [ dup scene?
      [ flatten-scene ]
      [ 1vector <scene> ] if
  ] dip
  ] restruct  ;

PRIVATE>
