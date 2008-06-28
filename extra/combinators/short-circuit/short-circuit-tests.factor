
USING: kernel math tools.test combinators.short-circuit ;

IN: combinators.short-circuit.tests

! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

: must-be-t ( in -- ) [ t ] swap unit-test ;
: must-be-f ( in -- ) [ f ] swap unit-test ;

! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

[       { [ 1 ] [ 2 ] [ 3 ] }           0&&  3 = ] must-be-t
[ 3     { [ 0 > ] [ odd? ] [ 2 + ] }    1&&  5 = ] must-be-t
[ 10 20 { [ + 0 > ] [ - even? ] [ + ] } 2&& 30 = ] must-be-t

[       { [ 1 ] [ f ] [ 3 ] } 0&&  3 = ]          must-be-f
[ 3     { [ 0 > ] [ even? ] [ 2 + ] } 1&& ]       must-be-f
[ 10 20 { [ + 0 > ] [ - odd? ] [ + ] } 2&& 30 = ] must-be-f

! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

[ { [ 10 0 < ] [ f ] [ "factor" ] } 0|| "factor" = ] must-be-t

[ 10 { [ odd? ] [ 100 > ] [ 1 + ] } 1|| 11 = ]       must-be-t

[ 10 20 { [ + odd? ] [ + 100 > ] [ + ] } 2|| 30 = ]  must-be-t

[ { [ 10 0 < ] [ f ] [ 0 1 = ] } 0|| ] must-be-f

! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
