byte turn = 1;
bool wantP  = false;
bool wantQ = false;
byte cs = 0;

active proctype P(){
    do
        ::wantP = true;
        do
            ::wantQ ->
            if
                :: turn == 2 ->
                    wantP = false;
                    do
                    ::turn == 1 -> break;
                    ::else -> skip;
                    od
                    wantP = true;
                :: else -> skip;
            fi
            ::else -> break;
        od
    progress1:
        cs++;
        assert(cs==1);
        cs--;
        wantP = false;
        turn = 2;
        ::else -> skip;
    od
}

active proctype Q(){
    do
        ::wantQ = true;
        do
            ::wantP ->
            if
                :: turn == 1 ->
                    wantQ = false;
                    do
                    ::turn == 2 -> break;
                    ::else -> skip;
                    od
                    wantQ = true;
                :: else -> skip;
            fi
            ::else -> break;
        od
    progress2:
        cs++;
        assert(cs==1);
        cs--;
        wantQ = false;
        turn = 1;
        ::else -> skip;
    od
}