bool wantQ = false;
bool wantP = false;
byte cs = 0;

active proctype P(){
    do
    :: wantP = true;
        do
            :: wantQ -> skip;
            :: else --> break;
        od
        cs++;
        assert(cs==1);
        cs--;
    progress1:
        wantP=false;
    od
}

active proctype Q(){
    do
    :: wantQ = true;
        do
            :: wantP -> skip;
            :: else --> break;
        od
        cs++;
        assert(cs==1);
        cs--;
    progress2:
        wantQ=false;
    od
}