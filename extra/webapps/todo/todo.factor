! Copyright (c) 2008 Slava Pestov
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel locals sequences
db db.types db.tuples
http.server.components http.server.components.farkup
http.server.forms http.server.templating.chloe
http.server.boilerplate http.server.crud http.server.auth
http.server.actions http.server.db
http.server ;
IN: webapps.todo

TUPLE: todo uid id priority summary description ;

todo "TODO"
{
    { "uid" "UID" { VARCHAR 256 } +not-null+ }
    { "id" "ID" +native-id+ }
    { "priority" "PRIORITY" INTEGER +not-null+ }
    { "summary" "SUMMARY" { VARCHAR 256 } +not-null+ }
    { "description" "DESCRIPTION" { VARCHAR 256 } }
} define-persistent

: init-todo-table todo ensure-table ;

: <todo> ( id -- todo )
    todo new
        swap >>id
        uid >>uid ;

: todo-template ( name -- template )
    "resource:extra/webapps/todo/" swap ".xml" 3append <chloe> ;

: <todo-form> ( -- form )
    "todo" <form>
        "view-todo" todo-template >>view-template
        "edit-todo" todo-template >>edit-template
        "todo-summary" todo-template >>summary-template
        "id" <integer>
            hidden >>renderer
            add-field
        "summary" <string>
            t >>required
            add-field
        "priority" <integer>
            t >>required
            0 >>default
            0 >>min-value
            10 >>max-value
            add-field
        "description" <farkup>
            add-field ;

: <todo-list-form> ( -- form )
    "todo-list" <form>
        "todo-list" todo-template >>view-template
        "list" <todo-form> <list>
        add-field ;

TUPLE: todo-responder < dispatcher ;

:: <todo-responder> ( -- responder )
    [let | todo-form [ <todo-form> ]
           list-form [ <todo-list-form> ]
           ctor [ [ <todo> ] ] |
        todo-responder new-dispatcher
            list-form ctor        <list-action>   "list"   add-main-responder
            todo-form ctor        <view-action>   "view"   add-responder
            todo-form ctor "view" <edit-action>   "edit"   add-responder
                      ctor "list" <delete-action> "delete" add-responder
        <boilerplate>
            "todo" todo-template >>template
    ] ;

! What follows below is somewhat akin to a 'deployment descriptor'
! for the todo application. The <todo-responder> can be integrated
! into an existing web app that provides session management and
! login facilities, or <todo-app> can be used to run a
! self-contained todo instance.
USING: namespaces io.files io.sockets
db.sqlite smtp
http.server.sessions
http.server.auth.login
http.server.auth.providers.db
http.server.sessions.storage.db ;

: test-db "todo.db" resource-path sqlite-db ;

: <todo-app> ( -- responder )
    <todo-responder>
    <login>
        users-in-db >>users
        allow-registration
        allow-password-recovery
        allow-edit-profile
    <boilerplate>
        "page" todo-template >>template
    <url-sessions>
        sessions-in-db >>sessions
    test-db <db-persistence> ;

: init-todo ( -- )
    "factorcode.org" 25 <inet> smtp-server set-global
    "todo@factorcode.org" lost-password-from set-global

    test-db [
        init-todo-table
        init-users-table
        init-sessions-table
    ] with-db

    <dispatcher>
        <todo-app> "todo" add-responder
    main-responder set-global ;