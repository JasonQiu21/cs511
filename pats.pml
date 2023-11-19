byte mutex = 1;
byte ticket = 0;

byte _pats = 0;
byte _jets = 0;

inline acquire(sem){
    atomic{
        sem > 0;
        sem--;
    }
}

inline release(sem){
    sem++;
}

active[10] proctype jets(){
    acquire(mutex);
    acquire(ticket);
    acquire(ticket);
    release(mutex);
    _jets++;
    assert(_pats >= 2*_jets);
}

active[10] proctype pats(){
    release(ticket);
    _pats++;
}