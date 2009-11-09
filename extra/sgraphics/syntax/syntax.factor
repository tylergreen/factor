USING: arrays assocs continuations grouping inverse kernel
parser quotations sgraphics ;
IN: sgraphics.syntax

SYNTAX: line{ \ } [ >array 2 group [ <point> ] { } assoc>map
                    [ 2array ] undo <line>
] parse-literal ;

SYNTAX: polygon{ \ } [
  >array 2 group [ <point> ] { } assoc>map <polygon>
] parse-literal ;

SYNTAX: scene{ \ } [ >array >quotation
                     { } swap with-datastack <scene>
] parse-literal ;                  
               

                 
                 
                       