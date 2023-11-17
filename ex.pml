int n=0;

proctype P(){
    n++;
    printf("P says %d\n", n);
}

proctype Q(){
    n++;
    printf("Q says %d\n", n);
}

// proctype Q(){
//     int i=0;
//     do
//         :: i<10 -> printf("Q %d\n", _pid);
//             i++
//         :: else -> break
//     od
// }

init {
    atomic{
        run P();
        run Q();
    };
    _nr_pr==1;
    printf("Init says %d\n", n);
}