byte mutex = 1;
byte ticket = 0;

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
}

active[10] proctype pats(){
    release(ticket);
}