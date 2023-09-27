
/*
Quiz 3 - 25 Sep 2023 - Topic 1

Jason Qiu
Jackey Yang
I pledge my honor that I have abided by the Stevens Honor System.

You may only declare semaphores and add acquire/release instructions.
The output should be:

aa(b+c)daa(b+c)daa(b+c)daa(b+c)daa(b+c)d....

*/

import java.util.concurrent.Semaphore;
// Semaphore declarations
Semaphore asem = new Semaphore(2)
Semaphore bsem = new Semaphore(0)
Semaphore csem = new Semaphore(0)
Semaphore dsem = new Semaphore(0)

Thread.start { // P
    while (true) {

    asem.acquire()
	print("a");
    csem.release()
    bsem.release()
    }
}

Thread.start { // Q 

    while (true) {
    bsem.acquire()
    bsem.acquire()
	print("b");
    dsem.release()
    }
}


Thread.start { // R

    while (true) {

    csem.acquire()
    csem.acquire()
	print("c");
    dsem.release()

    }
}


Thread.start { // S

    while (true) {
    dsem.acquire()
    dsem.acquire()
	print("d");
    asem.release()
    asem.release()
    }
}
