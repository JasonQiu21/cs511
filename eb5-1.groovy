import java.util.concurrent.Semaphore

Semaphore sem = new Semaphore(0);
Semaphore jetsMutex = new Semaphore(1);
Boolean itGotLate = false;

NP = 10;
NJ = 7;

NP.times{
    Thread.sleep(200);
    Thread.start{
        sem.release();
        // Go in
        System.out.println("Pats fan went in");
    }
}

NJ.times{
    Thread.start{
        jetsMutex.acquire();
        if(!itGotLate){
    	    sem.acquire();
    	    sem.acquire();
    	}
    	jetsMutex.release();
    	// Go in
        System.out.println("Jets fan went in");
    }
}

Thread.start{
    Thread.sleep(3000);
    System.out.println("It Got Late");
    itGotLate = true;
    sem.release();
    sem.release();
}