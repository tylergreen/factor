USING: arrays sgraphics sgraphics.syntax sequences locals math kernel math.points ;
IN: sgraphics.shapes

TUPLE: square side center ;

: unit-square ( -- polygon )
    polygon{ -1 -1 
             -1 1
             1 1
             1 -1 } ;

: <rectangle> ( height width -- polygon )
    [ 2.0 / ] bi@ 2array unit-square swap scale ; inline

: <square> ( side -- polygon )
    dup <rectangle> ;

GENERIC: center ( shape -- point )

: rec-center ( rectangle -- point )
    points-seq>>  [ first ] [ third ] bi midpoint ;

