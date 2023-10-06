import java.util.concurrent.Semaphore;

Semaphore station0 = new Semaphore(1);
Semaphore station1 = new Semaphore(0);
Semaphore station2 = new Semaphore(0);

permToProcess = [new Semaphore(0), new Semaphore(0), new Semaphore(0)];
doneProcessing = [new Semaphore(0), new Semaphore(0), new Semaphore(0)];

100.times{
    Thread.start{
        station0.acquire();

        permToProcess[0].release();
        doneProcessing[0].acquire();

        station1.acquire();
        station0.release();

        permToProcess[1].release();
        doneProcessing[1].acquire();

        station2.acquire();
        station1.release();

        permToProcess[2].release();
        doneProcessing[1].acquire();

        station2.release();
    }
}

3.times{
    int id = it;
    Thread.start{
        while(true){
            permToProcess[id].acquire();
            doneProcessing[id].release();
        }
    }
}