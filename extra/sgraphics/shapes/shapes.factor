USING: arrays sgraphics sgraphics.syntax sequences locals math kernel ;
IN: sgraphics.shapes

TUPLE: square side ;

: unit-square ( -- polygon )
    polygon{ -1 -1 
             -1 1
             1 1
             1 -1 } ;

: <rectangle> ( height width -- polygon )
    [ 2 / ] bi@ 2array unit-square swap scale ;

: <square> ( side -- polygon )
    dup <rectangle> ;

