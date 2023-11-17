short x=0;

active proctype P(){
    do
        ::if
            :: x<200 -> x++;
            fi
    od
}

active proctype Q(){
    do
        ::if
            ::x>0 -> x--;
            fi
    od
}

active proctype R(){
    do
        ::true ->
            if
            ::x==200 -> x=0;
            ::else -> skip;
            fi
    od
}

active proctype check(){
    do
    ::true -> assert(x >= 0 && x <= 200);
    od
}

init{
    atomic{
        run P();
        run Q();
        run R();
        run check();
    }
}