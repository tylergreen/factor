USING: kernel arrays sequences sgraphics sgraphics.syntax tools.test math.constants grouping assocs ;
IN: sgraphics-tests

{

    [
        T{ line
           { p1 T{ point { x 20 } { y 20 } } }
           { p2 T{ point { x 120 } { y 120 } } }
        }
    ]
    [ line{ 0 0 
            100 100 }
      { 20 20 } slide
    ]

    [
        T{ polygon
           { points-seq
             {
                 T{ point { x 50 } { y 25 } }
                 T{ point { x 100 } { y 25 } }
                 T{ point { x 50 } { y 75 } }
                 T{ point { x 100 } { y 75 } } } } }
    ]
    [ polygon{ 0 0 
               50 0 
               0 50 
               50 50 } 
      { 50 25 } slide
    ]

    [ T{ circle
         { center T{ point { x 100 } { y 75 } } }
         { radius 20 } }
    ]
    [ 50 50 <point> 20 <circle>
      { 50 25 } slide
    ]

    [ T{ scene
       { objs
         V{
           T{ line
              { p1 T{ point { x 10 } { y 100 } } }
              { p2 T{ point { x 60 } { y 150 } } }
           }
           T{ line
              { p1 T{ point { x 11 } { y 102 } } }
              { p2 T{ point { x 61 } { y 152 } } } } } } }
    ]
    [ line{ 0 0 
          50 50 }
      dup { 1 2 } slide 2array <scene>
      { 10 100 } slide
    ]

} 2 group [ unit-test ] assoc-each 